#!/usr/bin/env python
"""CLI helpers for AI-DLC quick-spec artifacts."""

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
SPECS_DIR_NAME = "specs"
SPEC_FILE_NAME = "spec.md"


@dataclass
class QuickSpecPaths:
    """Resolved quick-spec artifact paths."""

    repo_root: Path
    docs_root: Path
    specs_root: Path
    spec_dir: Path
    spec_file: Path


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
    """Find .mtv-aidlc/extension-config.json at the resolved repo root.

    Every caller passes an already-resolved repo_root from find_repo_root(),
    which is the authoritative repo boundary. Searching past it into parent
    directories can escape into an unrelated ancestor repo (e.g. a nested
    test fixture with its own .git living inside a larger workspace that
    happens to have its own .mtv-aidlc/), silently misapplying that repo's
    config and docs root to the nested one.
    """
    current = start_path.resolve()
    if current.is_file():
        current = current.parent

    config_path = current / CONFIG_PATH
    return config_path if config_path.exists() else None


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


def slug_to_display_name(spec_name: str) -> str:
    """Convert a kebab-case spec slug into a display title."""
    return spec_name.replace("-", " ").replace("_", " ").title()


def get_template_path() -> Path:
    """Resolve the bundled quick-spec scaffold template."""
    return Path(__file__).resolve().parents[1] / "assets" / "spec-template.md"


def load_metadata_renderer():
    """Import the shared metadata renderer from _aidlc-shared."""
    shared_scripts = Path(__file__).resolve().parents[2] / "_aidlc-shared" / "scripts"
    shared_scripts_str = str(shared_scripts)
    if shared_scripts_str not in sys.path:
        sys.path.insert(0, shared_scripts_str)

    from artifact_metadata import ArtifactMetadata, render_frontmatter

    return ArtifactMetadata, render_frontmatter


def render_quick_spec_frontmatter(
    spec_name: str,
    created_date: str,
    repo_root: Optional[Path] = None,
) -> str:
    """Render metadata frontmatter for a quick-spec artifact."""
    ArtifactMetadata, render_frontmatter = load_metadata_renderer()
    metadata = ArtifactMetadata(
        artifact_type="quick-spec",
        phase="construction",
        status="draft",
        created=created_date,
        updated=created_date,
        unit=spec_name,
        source_artifacts=[],
    )
    return render_frontmatter(metadata, workspace_root=repo_root)


def render_quick_spec_template(
    spec_name: str,
    created_date: str,
    repo_root: Optional[Path] = None,
) -> str:
    """Render spec.md from the bundled quick-spec template."""
    template = get_template_path().read_text()
    body = template.replace("[Feature Name]", slug_to_display_name(spec_name))
    body = body.replace("YYYY-MM-DD", created_date)
    body = body.replace(
        "**Status:** Draft | Approved | In Progress | Complete",
        "**Status:** Draft",
    )
    return (
        render_quick_spec_frontmatter(spec_name, created_date, repo_root)
        + body.rstrip()
        + "\n"
    )


def resolve_paths(
    spec_name: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> QuickSpecPaths:
    """Resolve paths for a quick-spec artifact."""
    resolved_repo_root = (repo_root or find_repo_root()).resolve()
    resolved_docs_root = resolve_docs_root(resolved_repo_root, docs_root).resolve()
    specs_root = resolved_docs_root / SPECS_DIR_NAME
    spec_dir = specs_root / spec_name
    return QuickSpecPaths(
        repo_root=resolved_repo_root,
        docs_root=resolved_docs_root,
        specs_root=specs_root,
        spec_dir=spec_dir,
        spec_file=spec_dir / SPEC_FILE_NAME,
    )


def init_spec(
    spec_name: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> tuple[QuickSpecPaths, bool]:
    """Create a quick-spec scaffold if spec.md does not already exist."""
    paths = resolve_paths(spec_name, repo_root, docs_root)
    if paths.spec_file.exists():
        return paths, False

    paths.spec_dir.mkdir(parents=True, exist_ok=True)
    today = date.today().isoformat()
    paths.spec_file.write_text(
        render_quick_spec_template(spec_name, today, paths.repo_root)
    )
    return paths, True


def read_spec(paths: QuickSpecPaths) -> str:
    """Read a quick-spec file, raising with clear context when missing."""
    if not paths.spec_file.exists():
        raise FileNotFoundError(f"spec.md not found: {paths.spec_file}")
    return paths.spec_file.read_text()


def parse_status(content: str) -> str:
    """Extract quick-spec status from frontmatter or body."""
    frontmatter_match = re.match(r"^---\n(.*?)\n---\n", content, flags=re.DOTALL)
    if frontmatter_match:
        status_match = re.search(
            r"(?m)^status:\s*([A-Za-z][A-Za-z -]*)\s*$",
            frontmatter_match.group(1),
        )
        if status_match:
            return status_match.group(1).strip()

    body_match = re.search(r"(?m)^\*\*Status:\*\*\s*(.+?)\s*$", content)
    if body_match:
        return body_match.group(1).strip()

    return "unknown"


def get_progress_from_content(content: str) -> dict:
    """Count checkbox progress in a quick-spec document."""
    total = len(re.findall(r"(?m)^\s*-\s+\[[ xX]\]\s+", content))
    completed = len(re.findall(r"(?m)^\s*-\s+\[[xX]\]\s+", content))
    pending = total - completed
    percentage = round((completed / total * 100) if total else 0, 1)
    return {
        "total": total,
        "completed": completed,
        "pending": pending,
        "percentage": percentage,
    }


def get_progress(
    spec_name: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> dict:
    """Return checkbox progress for a quick-spec document."""
    paths = resolve_paths(spec_name, repo_root, docs_root)
    content = read_spec(paths)
    progress = get_progress_from_content(content)
    progress["spec_name"] = spec_name
    progress["spec_path"] = str(paths.spec_file)
    return progress


def get_status(
    spec_name: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> dict:
    """Return status information for a quick-spec document."""
    paths = resolve_paths(spec_name, repo_root, docs_root)
    exists = paths.spec_file.exists()
    status = "missing"
    progress = {"total": 0, "completed": 0, "pending": 0, "percentage": 0}
    if exists:
        content = paths.spec_file.read_text()
        status = parse_status(content)
        progress = get_progress_from_content(content)

    return {
        "spec_name": spec_name,
        "spec_path": str(paths.spec_file),
        "docs_root": str(paths.docs_root),
        "exists": exists,
        "status": status,
        **progress,
    }


def mark_task_complete_in_content(content: str, task_number: str) -> tuple[str, bool]:
    """Mark checkboxes complete for a task number."""
    task_pattern = re.compile(
        rf"(?ms)^(###\s+Task\s+{re.escape(task_number)}"
        r"(?::|\b).*?)(?=^###\s+Task\s+|\Z)"
    )
    match = task_pattern.search(content)
    if match:
        task_block = match.group(1)
        updated_block = re.sub(
            r"(?m)^(\s*-\s+)\[ \](\s+)",
            r"\1[x]\2",
            task_block,
        )
        if updated_block != task_block:
            return (
                content[: match.start(1)] + updated_block + content[match.end(1) :],
                True,
            )

    checkbox_pattern = re.compile(
        rf"(?m)^(\s*-\s+)\[ \](\s+(?:\*\*)?"
        rf"(?:Task|Step)?\s*{re.escape(task_number)}"
        r"(?:\b|[:.]).*)$",
        flags=re.IGNORECASE,
    )
    updated_content = checkbox_pattern.sub(r"\1[x]\2", content, count=1)
    return updated_content, updated_content != content


def complete_task(
    spec_name: str,
    task_number: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> tuple[QuickSpecPaths, bool]:
    """Mark a task complete in spec.md."""
    paths = resolve_paths(spec_name, repo_root, docs_root)
    content = read_spec(paths)
    updated_content, changed = mark_task_complete_in_content(content, task_number)
    if changed:
        paths.spec_file.write_text(updated_content)
    return paths, changed


def build_parser() -> argparse.ArgumentParser:
    """Build the quick-spec CLI parser."""
    parser = argparse.ArgumentParser(description="AI-DLC quick-spec CLI")
    parser.add_argument(
        "command",
        choices=["init", "status", "progress", "complete"],
        help="Command to execute",
    )
    parser.add_argument("spec_name", help="Quick-spec feature slug")
    parser.add_argument(
        "task_number",
        nargs="?",
        help="Task number to complete, required for complete",
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
    """Run the quick-spec CLI."""
    parser = build_parser()
    args = parser.parse_args()

    try:
        if args.command == "init":
            paths, created = init_spec(
                args.spec_name,
                repo_root=args.repo_root,
                docs_root=args.docs_root,
            )
            if created:
                print(f"Created quick spec: {paths.spec_file}")
            else:
                print(f"Quick spec already exists: {paths.spec_file}")
            return

        if args.command == "status":
            status = get_status(
                args.spec_name,
                repo_root=args.repo_root,
                docs_root=args.docs_root,
            )
            print(f"Spec: {status['spec_name']}")
            print(f"Path: {status['spec_path']}")
            print(f"Docs root: {status['docs_root']}")
            print(f"Exists: {status['exists']}")
            print(f"Status: {status['status']}")
            print(
                "Progress: "
                f"{status['completed']}/{status['total']} "
                f"({status['percentage']}%)"
            )
            return

        if args.command == "progress":
            progress = get_progress(
                args.spec_name,
                repo_root=args.repo_root,
                docs_root=args.docs_root,
            )
            print(f"Progress for: {progress['spec_name']}")
            print(
                "Completed: "
                f"{progress['completed']}/{progress['total']} "
                f"({progress['percentage']}%)"
            )
            print(f"Pending: {progress['pending']}")
            return

        if args.command == "complete":
            if not args.task_number:
                print("Error: task_number required for complete command")
                sys.exit(1)
            paths, changed = complete_task(
                args.spec_name,
                args.task_number,
                repo_root=args.repo_root,
                docs_root=args.docs_root,
            )
            if changed:
                print(f"Marked task {args.task_number} complete: {paths.spec_file}")
            else:
                print(
                    f"Task {args.task_number} not found or already complete: "
                    f"{paths.spec_file}"
                )
            return
    except FileNotFoundError as err:
        print(f"Error: {err}")
        sys.exit(1)


if __name__ == "__main__":
    main()
