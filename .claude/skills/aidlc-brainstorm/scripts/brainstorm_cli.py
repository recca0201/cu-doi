#!/usr/bin/env python3
"""CLI helpers for AI-DLC brainstorming / decision-record artifacts."""

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
BRAINSTORMING_DIR = "brainstorming"

FORMAT_LITE = "lite"
FORMAT_FULL = "full"
VALID_FORMATS = {FORMAT_LITE, FORMAT_FULL}

VALID_PHASES = {"foundation", "inception", "construction"}


@dataclass
class BrainstormPaths:
    """Resolved decision-record artifact paths."""

    repo_root: Path
    docs_root: Path
    brainstorming_root: Path
    output_file: Path
    dr_number: str
    artifact_id: str


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


def next_dr_number(brainstorming_root: Path) -> str:
    """Determine the next 4-digit sequential DR number from existing files."""
    if not brainstorming_root.exists():
        return "0001"

    pattern = re.compile(r"^(\d{4})-")
    used = set()
    for path in brainstorming_root.iterdir():
        match = pattern.match(path.name)
        if match:
            used.add(int(match.group(1)))

    candidate = 1
    while candidate in used:
        candidate += 1

    return f"{candidate:04d}"


def get_template_path(fmt: str) -> Path:
    """Resolve the bundled DR template for the given format."""
    assets = Path(__file__).resolve().parents[1] / "assets"
    if fmt == FORMAT_LITE:
        return assets / "dr-lite.md"
    return assets / "decision-record-template.md"


def load_metadata_renderer():
    """Import the shared metadata renderer from _aidlc-shared."""
    shared_scripts = Path(__file__).resolve().parents[2] / "_aidlc-shared" / "scripts"
    shared_scripts_str = str(shared_scripts)
    if shared_scripts_str not in sys.path:
        sys.path.insert(0, shared_scripts_str)

    from artifact_metadata import ArtifactMetadata, render_frontmatter

    return ArtifactMetadata, render_frontmatter


def render_dr_frontmatter(
    slug: str,
    dr_number: str,
    phase: str,
    created_date: str,
    unit: Optional[str] = None,
    repo_root: Optional[Path] = None,
) -> str:
    """Render metadata frontmatter for a decision-record artifact."""
    ArtifactMetadata, render_frontmatter = load_metadata_renderer()
    metadata = ArtifactMetadata(
        artifact_type="decision-record",
        phase=phase,
        status="draft",
        created=created_date,
        updated=created_date,
        intent=slug,
        unit=unit,
        artifact_id=f"DR-{dr_number}",
        source_artifacts=[],
    )
    return render_frontmatter(metadata, workspace_root=repo_root)


def render_dr_template(
    slug: str,
    dr_number: str,
    fmt: str,
    phase: str,
    created_date: str,
    unit: Optional[str] = None,
    repo_root: Optional[Path] = None,
) -> str:
    """Render the DR file from the bundled template."""
    body = get_template_path(fmt).read_text()
    artifact_id = f"DR-{dr_number}"
    body = body.replace("DR-NNNN", artifact_id)
    return (
        render_dr_frontmatter(slug, dr_number, phase, created_date, unit, repo_root)
        + body.rstrip()
        + "\n"
    )


def resolve_paths(
    slug: str,
    phase: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> BrainstormPaths:
    """Resolve output paths for a decision-record artifact."""
    if phase not in VALID_PHASES:
        raise ValueError(
            f"Invalid phase '{phase}'. Must be one of: {', '.join(sorted(VALID_PHASES))}"
        )

    resolved_repo_root = (repo_root or find_repo_root()).resolve()
    resolved_docs_root = resolve_docs_root(resolved_repo_root, docs_root).resolve()
    brainstorming_root = resolved_docs_root / BRAINSTORMING_DIR

    dr_number = next_dr_number(brainstorming_root)
    filename = f"{dr_number}-{slug}.md"

    return BrainstormPaths(
        repo_root=resolved_repo_root,
        docs_root=resolved_docs_root,
        brainstorming_root=brainstorming_root,
        output_file=brainstorming_root / filename,
        dr_number=dr_number,
        artifact_id=f"DR-{dr_number}",
    )


def find_existing_dr(brainstorming_root: Path, slug: str) -> Optional[Path]:
    """Return the existing DR file for a slug, or None if not found."""
    if not brainstorming_root.exists():
        return None
    pattern = re.compile(rf"^\d{{4}}-{re.escape(slug)}\.md$")
    for path in brainstorming_root.iterdir():
        if pattern.match(path.name):
            return path
    return None


def init_dr(
    slug: str,
    fmt: str,
    phase: str,
    unit: Optional[str] = None,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> tuple[BrainstormPaths, bool]:
    """Create a decision-record scaffold if the file does not already exist."""
    if fmt not in VALID_FORMATS:
        raise ValueError(
            f"Invalid format '{fmt}'. Must be one of: {', '.join(sorted(VALID_FORMATS))}"
        )

    resolved_repo_root = (repo_root or find_repo_root()).resolve()
    resolved_docs_root = resolve_docs_root(resolved_repo_root, docs_root).resolve()
    brainstorming_root = resolved_docs_root / BRAINSTORMING_DIR

    # Return early if slug already exists under any NNNN prefix
    existing = find_existing_dr(brainstorming_root, slug)
    if existing is not None:
        dr_match = re.match(r"^(\d{4})-", existing.name)
        dr_number = dr_match.group(1) if dr_match else "????"
        return BrainstormPaths(
            repo_root=resolved_repo_root,
            docs_root=resolved_docs_root,
            brainstorming_root=brainstorming_root,
            output_file=existing,
            dr_number=dr_number,
            artifact_id=f"DR-{dr_number}",
        ), False

    paths = resolve_paths(slug, phase, repo_root=resolved_repo_root, docs_root=resolved_docs_root)
    if paths.output_file.exists():
        return paths, False

    paths.brainstorming_root.mkdir(parents=True, exist_ok=True)
    today = date.today().isoformat()
    paths.output_file.write_text(
        render_dr_template(
            slug, paths.dr_number, fmt, phase, today, unit, paths.repo_root
        )
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
    slug: str,
    phase: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> dict:
    """Return status information for a decision-record artifact by slug."""
    resolved_repo_root = (repo_root or find_repo_root()).resolve()
    resolved_docs_root = resolve_docs_root(resolved_repo_root, docs_root).resolve()
    brainstorming_root = resolved_docs_root / BRAINSTORMING_DIR

    # Find existing file matching slug (any NNNN prefix)
    pattern = re.compile(rf"^\d{{4}}-{re.escape(slug)}\.md$")
    matched = None
    if brainstorming_root.exists():
        for path in brainstorming_root.iterdir():
            if pattern.match(path.name):
                matched = path
                break

    exists = matched is not None
    status = "missing"
    artifact_id = None
    if exists:
        content = matched.read_text()
        status = parse_status(content)
        id_match = re.search(r"(?m)^artifact_id:\s*(.+)\s*$", content)
        if id_match:
            artifact_id = id_match.group(1).strip()

    return {
        "slug": slug,
        "phase": phase,
        "output_path": str(matched) if matched else str(brainstorming_root / f"????-{slug}.md"),
        "docs_root": str(resolved_docs_root),
        "exists": exists,
        "status": status,
        "artifact_id": artifact_id,
    }


def build_parser() -> argparse.ArgumentParser:
    """Build the brainstorm CLI parser."""
    parser = argparse.ArgumentParser(description="AI-DLC brainstorm / decision-record CLI")
    parser.add_argument(
        "command",
        choices=["init", "status"],
        help="Command to execute",
    )
    parser.add_argument("slug", help="Decision slug (kebab-case)")
    parser.add_argument(
        "--format",
        dest="fmt",
        choices=list(VALID_FORMATS),
        default=FORMAT_LITE,
        help="DR template: lite (default) or full",
    )
    parser.add_argument(
        "--phase",
        choices=list(VALID_PHASES),
        default="inception",
        help="AI-DLC phase (default: inception)",
    )
    parser.add_argument(
        "--unit",
        help="Unit slug for Construction-phase DRs",
    )
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
    """Run the brainstorm CLI."""
    parser = build_parser()
    args = parser.parse_args()

    try:
        if args.command == "init":
            paths, created = init_dr(
                args.slug,
                args.fmt,
                args.phase,
                unit=args.unit,
                repo_root=args.repo_root,
                docs_root=args.docs_root,
            )
            if created:
                print(f"Created {args.fmt} DR ({paths.artifact_id}): {paths.output_file}")
            else:
                print(f"DR already exists: {paths.output_file}")
            return

        if args.command == "status":
            status = get_status(
                args.slug,
                args.phase,
                repo_root=args.repo_root,
                docs_root=args.docs_root,
            )
            print(f"Slug: {status['slug']}")
            print(f"Phase: {status['phase']}")
            print(f"Artifact ID: {status['artifact_id'] or 'unknown'}")
            print(f"Path: {status['output_path']}")
            print(f"Docs root: {status['docs_root']}")
            print(f"Exists: {status['exists']}")
            print(f"Status: {status['status']}")
            return

    except (FileNotFoundError, ValueError) as err:
        print(f"Error: {err}")
        sys.exit(1)


if __name__ == "__main__":
    main()
