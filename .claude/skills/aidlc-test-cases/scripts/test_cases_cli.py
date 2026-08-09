#!/usr/bin/env python3
"""CLI helpers for AI-DLC test-cases artifacts."""

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
TEST_CASES_SUFFIX = "-test-cases.md"

SCOPE_STORY = "story"
SCOPE_SPEC = "spec"
VALID_SCOPES = {SCOPE_STORY, SCOPE_SPEC}

FORMAT_GHERKIN_TABLE = "gherkin-table"
FORMAT_GHERKIN_BLOCKS = "gherkin-blocks"
FORMAT_STANDARD_TABLE = "standard-table"
FORMAT_CUSTOM = "custom"
DEFAULT_FORMAT = FORMAT_GHERKIN_TABLE
BUILTIN_FORMATS = {
    FORMAT_GHERKIN_TABLE,
    FORMAT_GHERKIN_BLOCKS,
    FORMAT_STANDARD_TABLE,
}
VALID_FORMATS = {*BUILTIN_FORMATS, FORMAT_CUSTOM}

TYPE_FUNCTIONAL = "functional"
TYPE_UAT = "uat"
TYPE_REGRESSION = "regression"
VALID_TYPES = {TYPE_FUNCTIONAL, TYPE_UAT, TYPE_REGRESSION}


@dataclass
class TestCasesPaths:
    """Resolved test-cases artifact paths."""

    repo_root: Path
    docs_root: Path
    output_file: Path
    scope: str
    phase: str


@dataclass
class TestCaseTemplateSettings:
    """Resolved test-case template and content settings."""

    template_format: str
    test_type: str
    template_path: Path
    source_label: str


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


def phase_for_scope(scope: str) -> str:
    """Return the AI-DLC phase for a given scope."""
    return "construction" if scope == SCOPE_SPEC else "inception"


def load_metadata_renderer():
    """Import the shared metadata renderer from _aidlc-shared."""
    shared_scripts = Path(__file__).resolve().parents[2] / "_aidlc-shared" / "scripts"
    shared_scripts_str = str(shared_scripts)
    if shared_scripts_str not in sys.path:
        sys.path.insert(0, shared_scripts_str)

    from artifact_metadata import ArtifactMetadata, render_frontmatter

    return ArtifactMetadata, render_frontmatter


def get_builtin_template_path(template_format: str) -> Path:
    """Resolve a bundled test-case format template."""
    if template_format not in BUILTIN_FORMATS:
        raise ValueError(
            "Invalid built-in format "
            f"'{template_format}'. Must be one of: {', '.join(sorted(BUILTIN_FORMATS))}"
        )
    return Path(__file__).resolve().parents[1] / "assets" / "templates" / f"{template_format}.md"


def normalize_format(raw_format: object) -> str:
    """Normalize a configured test-case format."""
    return raw_format if raw_format in VALID_FORMATS else DEFAULT_FORMAT


def normalize_type(raw_type: object) -> str:
    """Validate an explicit test-case type. There is no default."""
    if raw_type not in VALID_TYPES:
        raise ValueError(
            "Test-case type is required and must be one of: "
            f"{', '.join(sorted(VALID_TYPES))}. "
            "Pass --type explicitly; the skill confirms the type with the user when unclear."
        )
    return raw_type


def resolve_template_settings(
    repo_root: Optional[Path] = None,
    template_format: Optional[str] = None,
    test_type: Optional[str] = None,
) -> TestCaseTemplateSettings:
    """Resolve format/type from explicit flags, config, or defaults."""
    resolved_repo_root = (repo_root or find_repo_root()).resolve()
    config = read_extension_config(resolved_repo_root) or {}
    test_case_config = config.get("testCase")
    test_case_config = test_case_config if isinstance(test_case_config, dict) else {}

    resolved_format = normalize_format(
        template_format or test_case_config.get("format") or DEFAULT_FORMAT
    )
    resolved_type = normalize_type(test_type)

    if resolved_format == FORMAT_CUSTOM:
        custom_path = test_case_config.get("customTemplatePath")
        if not isinstance(custom_path, str) or not custom_path.strip():
            raise ValueError(
                "testCase.format is custom but testCase.customTemplatePath is not configured"
            )
        template_path = resolve_config_relative_path(resolved_repo_root, custom_path.strip())
        if not template_path.exists():
            raise FileNotFoundError(f"Custom test-case template not found: {custom_path}")
        return TestCaseTemplateSettings(
            template_format=resolved_format,
            test_type=resolved_type,
            template_path=template_path,
            source_label=f"Custom: {custom_path.strip()}",
        )

    return TestCaseTemplateSettings(
        template_format=resolved_format,
        test_type=resolved_type,
        template_path=get_builtin_template_path(resolved_format),
        source_label=f"Built-in: {resolved_format}",
    )


def render_test_cases_frontmatter(
    slug: str,
    scope: str,
    created_date: str,
    repo_root: Optional[Path] = None,
) -> str:
    """Render metadata frontmatter for a test-cases artifact."""
    ArtifactMetadata, render_frontmatter = load_metadata_renderer()
    phase = phase_for_scope(scope)
    intent = slug if scope == SCOPE_STORY else None
    unit = slug if scope == SCOPE_SPEC else None
    metadata = ArtifactMetadata(
        artifact_type="test-cases",
        phase=phase,
        status="draft",
        created=created_date,
        updated=created_date,
        intent=intent,
        unit=unit,
        source_artifacts=[],
    )
    return render_frontmatter(metadata, workspace_root=repo_root)


def render_test_cases_template(
    slug: str,
    scope: str,
    created_date: str,
    repo_root: Optional[Path] = None,
    template_format: Optional[str] = None,
    test_type: Optional[str] = None,
) -> str:
    """Render the test-cases file from the selected template."""
    resolved_repo_root = (repo_root or find_repo_root()).resolve()
    settings = resolve_template_settings(
        resolved_repo_root,
        template_format=template_format,
        test_type=test_type,
    )
    body = settings.template_path.read_text()
    header = (
        f"<!-- Test case format: {settings.template_format}; "
        f"type: {settings.test_type}; template: {settings.source_label} -->\n\n"
    )
    return (
        render_test_cases_frontmatter(slug, scope, created_date, resolved_repo_root)
        + header
        + body.rstrip()
        + "\n"
    )


def resolve_paths(
    slug: str,
    scope: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> TestCasesPaths:
    """Resolve output paths for a test-cases artifact."""
    if scope not in VALID_SCOPES:
        raise ValueError(
            f"Invalid scope '{scope}'. Must be one of: {', '.join(sorted(VALID_SCOPES))}"
        )

    resolved_repo_root = (repo_root or find_repo_root()).resolve()
    resolved_docs_root = resolve_docs_root(resolved_repo_root, docs_root).resolve()
    phase = phase_for_scope(scope)

    if scope == SCOPE_STORY:
        output_file = resolved_docs_root / "test-cases" / f"{slug}{TEST_CASES_SUFFIX}"
    else:
        output_file = resolved_docs_root / "specs" / slug / "test-cases.md"

    return TestCasesPaths(
        repo_root=resolved_repo_root,
        docs_root=resolved_docs_root,
        output_file=output_file,
        scope=scope,
        phase=phase,
    )


def init_test_cases(
    slug: str,
    scope: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
    template_format: Optional[str] = None,
    test_type: Optional[str] = None,
) -> tuple[TestCasesPaths, bool]:
    """Create a test-cases scaffold if the file does not already exist."""
    paths = resolve_paths(slug, scope, repo_root, docs_root)
    if paths.output_file.exists():
        return paths, False

    paths.output_file.parent.mkdir(parents=True, exist_ok=True)
    today = date.today().isoformat()
    paths.output_file.write_text(
        render_test_cases_template(
            slug,
            scope,
            today,
            paths.repo_root,
            template_format=template_format,
            test_type=test_type,
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
    scope: str,
    repo_root: Optional[Path] = None,
    docs_root: Optional[Path] = None,
) -> dict:
    """Return status information for a test-cases artifact."""
    paths = resolve_paths(slug, scope, repo_root, docs_root)
    exists = paths.output_file.exists()
    status = "missing"
    if exists:
        content = paths.output_file.read_text()
        status = parse_status(content)

    return {
        "slug": slug,
        "scope": scope,
        "phase": paths.phase,
        "output_path": str(paths.output_file),
        "docs_root": str(paths.docs_root),
        "exists": exists,
        "status": status,
    }


def build_parser() -> argparse.ArgumentParser:
    """Build the test-cases CLI parser."""
    parser = argparse.ArgumentParser(description="AI-DLC test-cases CLI")
    parser.add_argument(
        "command",
        choices=["init", "status"],
        help="Command to execute",
    )
    parser.add_argument("slug", help="Artifact slug (kebab-case)")
    parser.add_argument(
        "--scope",
        choices=sorted(VALID_SCOPES),
        required=True,
        help="Scope level: story or spec",
    )
    parser.add_argument(
        "--format",
        choices=sorted(VALID_FORMATS),
        default=None,
        help="Display format for init: gherkin-table, gherkin-blocks, standard-table, or custom",
    )
    parser.add_argument(
        "--type",
        choices=sorted(VALID_TYPES),
        default=None,
        help=(
            "Test-case type: functional, uat, or regression. Required for init "
            "(no default); the skill confirms it with the user when unclear."
        ),
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
    """Run the test-cases CLI."""
    parser = build_parser()
    args = parser.parse_args()

    try:
        if args.command == "init":
            paths, created = init_test_cases(
                args.slug,
                args.scope,
                repo_root=args.repo_root,
                docs_root=args.docs_root,
                template_format=args.format,
                test_type=args.type,
            )
            if created:
                print(f"Created test cases ({args.scope}): {paths.output_file}")
            else:
                print(f"Test cases already exist: {paths.output_file}")
            return

        if args.command == "status":
            status = get_status(
                args.slug,
                args.scope,
                repo_root=args.repo_root,
                docs_root=args.docs_root,
            )
            print(f"Slug: {status['slug']}")
            print(f"Scope: {status['scope']}")
            print(f"Phase: {status['phase']}")
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
