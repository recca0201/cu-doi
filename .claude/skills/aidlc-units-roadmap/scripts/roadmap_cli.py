#!/usr/bin/env python3
"""CLI helpers for AI-DLC units roadmap artifacts."""

import argparse
import json
import re
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Optional


CONFIG_PATH = ".mtv-aidlc/extension-config.json"
DEFAULT_DOCS_ROOT = "aidlc-docs"
ROADMAP_DIR_NAME = "roadmap"
ROADMAP_SUFFIX = "_product_roadmap.md"


@dataclass
class RoadmapPaths:
    """Resolved roadmap artifact paths."""

    repo_root: Path
    docs_root: Path
    roadmap_root: Path
    roadmap_file: Path


def find_repo_root(start_path: Optional[Path] = None) -> Path:
    """Find the nearest repository root from the current path."""
    current = (start_path or Path.cwd()).resolve()
    if current.is_file():
        current = current.parent

    markers = [".git", ".mtv-aidlc", DEFAULT_DOCS_ROOT]
    if any((current / marker).exists() for marker in markers):
        return current

    for parent in current.parents:
        if any((parent / marker).exists() for marker in markers):
            return parent

    return current


def find_extension_config_path(start_path: Path) -> Optional[Path]:
    """Find .mtv-aidlc/extension-config.json from start_path upward."""
    current = start_path.resolve()
    if current.is_file():
        current = current.parent

    for directory in [current, *current.parents]:
        config_path = directory / CONFIG_PATH
        if config_path.exists():
            return config_path

    return None


def read_extension_config(repo_root: Path) -> Optional[dict]:
    """Read extension config when present and valid."""
    config_path = find_extension_config_path(repo_root)
    if config_path is None:
        return None

    try:
        parsed = json.loads(config_path.read_text())
    except json.JSONDecodeError:
        return None

    return parsed if isinstance(parsed, dict) else None


def resolve_config_relative_path(repo_root: Path, configured_path: str) -> Path:
    """Resolve config paths relative to the workspace that owns the config."""
    path = Path(configured_path)
    if path.is_absolute():
        return path

    config_path = find_extension_config_path(repo_root)
    config_root = config_path.parent.parent if config_path else repo_root
    return config_root / path


def resolve_docs_root(repo_root: Path, docs_root: Optional[Path] = None) -> Path:
    """Resolve AI-DLC docs root from CLI, config, or default."""
    if docs_root is not None:
        return docs_root if docs_root.is_absolute() else repo_root / docs_root

    config = read_extension_config(repo_root)
    configured_path = None
    if config:
        raw_path = config.get("aidlcDocsPath")
        if isinstance(raw_path, str) and raw_path.strip() and "\n" not in raw_path:
            configured_path = raw_path.strip()

    if configured_path:
        return resolve_config_relative_path(repo_root, configured_path)

    return repo_root / DEFAULT_DOCS_ROOT


def slug_to_display_name(feature_slug: str) -> str:
    """Convert a kebab-case slug into a display title."""
    return feature_slug.replace("-", " ").replace("_", " ").title()


def get_template_path() -> Path:
    """Resolve the bundled roadmap template."""
    return Path(__file__).resolve().parents[1] / "assets" / "product_roadmap_template.md"


def load_metadata_renderer():
    """Import the shared metadata renderer from _aidlc-shared."""
    shared_scripts = Path(__file__).resolve().parents[2] / "_aidlc-shared" / "scripts"
    shared_scripts_str = str(shared_scripts)
    if shared_scripts_str not in sys.path:
        sys.path.insert(0, shared_scripts_str)

    from artifact_metadata import ArtifactMetadata, render_frontmatter

    return ArtifactMetadata, render_frontmatter


def render_roadmap_frontmatter(
    feature_slug: str,
    created_date: str,
    repo_root: Optional[Path] = None,
) -> str:
    """Render metadata frontmatter for a roadmap artifact."""
    ArtifactMetadata, render_frontmatter = load_metadata_renderer()
    metadata = ArtifactMetadata(
        artifact_type="roadmap",
        phase="inception",
        status="draft",
        created=created_date,
        updated=created_date,
        intent=feature_slug,
        source_artifacts=[],
    )
    return render_frontmatter(metadata, workspace_root=repo_root)


def render_roadmap_template(
    feature_slug: str,
    created_date: str,
    repo_root: Optional[Path] = None,
) -> str:
    """Render the roadmap file from the bundled template."""
    template = get_template_path().read_text()
    body = template.replace("[Project Name]", slug_to_display_name(feature_slug))
    return (
        render_roadmap_frontmatter(feature_slug, created_date, repo_root)
        + body.rstrip()
        + "\n"
    )


def resolve_paths(
    feature_slug: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> RoadmapPaths:
    """Resolve paths for a roadmap artifact."""
    resolved_repo_root = (repo_root or find_repo_root()).resolve()
    resolved_docs_root = resolve_docs_root(resolved_repo_root, docs_root).resolve()
    roadmap_root = resolved_docs_root / ROADMAP_DIR_NAME
    filename = f"{feature_slug}{ROADMAP_SUFFIX}"

    return RoadmapPaths(
        repo_root=resolved_repo_root,
        docs_root=resolved_docs_root,
        roadmap_root=roadmap_root,
        roadmap_file=roadmap_root / filename,
    )


def init_roadmap(
    feature_slug: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> tuple[RoadmapPaths, bool]:
    """Create a roadmap scaffold if the file does not already exist."""
    paths = resolve_paths(feature_slug, repo_root, docs_root)
    if paths.roadmap_file.exists():
        return paths, False

    paths.roadmap_root.mkdir(parents=True, exist_ok=True)
    today = date.today().isoformat()
    paths.roadmap_file.write_text(
        render_roadmap_template(feature_slug, today, paths.repo_root)
    )
    return paths, True


def parse_status(content: str) -> str:
    """Extract artifact status from YAML frontmatter."""
    frontmatter_match = re.match(r"^---\n(.*?)\n---\n", content, flags=re.DOTALL)
    if frontmatter_match:
        status_match = re.search(
            r"(?m)^status:\s*([A-Za-z][A-Za-z -]*)\s*$",
            frontmatter_match.group(1),
        )
        if status_match:
            return status_match.group(1).strip()
    return "unknown"


def get_status(
    feature_slug: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> dict:
    """Return status information for a roadmap artifact."""
    paths = resolve_paths(feature_slug, repo_root, docs_root)
    exists = paths.roadmap_file.exists()
    status = "missing"
    if exists:
        content = paths.roadmap_file.read_text()
        status = parse_status(content)

    return {
        "feature_slug": feature_slug,
        "roadmap_path": str(paths.roadmap_file),
        "docs_root": str(paths.docs_root),
        "exists": exists,
        "status": status,
    }


def build_parser() -> argparse.ArgumentParser:
    """Build the roadmap CLI parser."""
    parser = argparse.ArgumentParser(description="AI-DLC units roadmap CLI")
    parser.add_argument(
        "command",
        choices=["init", "status"],
        help="Command to execute",
    )
    parser.add_argument("feature_slug", help="Feature slug (kebab-case)")
    parser.add_argument(
        "--repo-root",
        type=Path,
        help="Repository root path; auto-detected when omitted",
    )
    parser.add_argument(
        "--docs-root",
        type=Path,
        help=(
            "AI-DLC docs root path. Relative paths are resolved from repo root; "
            "if omitted, reads aidlcDocsPath from extension config, then falls "
            "back to aidlc-docs."
        ),
    )
    return parser


def main() -> None:
    """Run the roadmap CLI."""
    parser = build_parser()
    args = parser.parse_args()

    try:
        if args.command == "init":
            paths, created = init_roadmap(
                args.feature_slug,
                repo_root=args.repo_root,
                docs_root=args.docs_root,
            )
            if created:
                print(f"Created roadmap: {paths.roadmap_file}")
            else:
                print(f"Roadmap already exists: {paths.roadmap_file}")
            return

        if args.command == "status":
            status = get_status(
                args.feature_slug,
                repo_root=args.repo_root,
                docs_root=args.docs_root,
            )
            print(f"Feature: {status['feature_slug']}")
            print(f"Path: {status['roadmap_path']}")
            print(f"Docs root: {status['docs_root']}")
            print(f"Exists: {status['exists']}")
            print(f"Status: {status['status']}")
            return

    except FileNotFoundError as err:
        print(f"Error: {err}")
        sys.exit(1)


if __name__ == "__main__":
    main()
