#!/usr/bin/env python3
"""Scaffold standalone AI-DLC user story artifacts."""

import argparse
from datetime import date
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional


SUPPORTED_TEMPLATES = {
    "default": "default.md",
    "checklist": "checklist.md",
    "given-when-then-table": "given-when-then-table.md",
}
CUSTOM_TEMPLATE = "custom"
TEMPLATE_CHOICES = sorted([*SUPPORTED_TEMPLATES, CUSTOM_TEMPLATE])
CONFIG_PATH = ".mtv-aidlc/extension-config.json"
DOCS_ROOT_KEY = "aidlcDocsPath"
DEFAULT_DOCS_ROOT = "aidlc-docs"


@dataclass
class TemplateSource:
    """Resolved story-block template source."""

    name: str
    content: str
    source_label: str
    warning: Optional[str] = None


def get_skill_dir() -> Path:
    """Resolve the requirements-engineering skill directory."""
    return Path(__file__).resolve().parents[1]


def render_story_frontmatter(
    intent: Optional[str] = None,
    source_artifacts: Optional[List[str]] = None,
    workspace_root: Optional[Path] = None,
) -> str:
    """Render compliant frontmatter for story artifact outputs."""
    shared_scripts = get_skill_dir().parent / "_aidlc-shared" / "scripts"
    shared_scripts_path = str(shared_scripts)
    if shared_scripts_path not in sys.path:
        sys.path.insert(0, shared_scripts_path)

    from artifact_metadata import ArtifactMetadata, render_frontmatter

    today = date.today().isoformat()
    metadata = ArtifactMetadata(
        artifact_type="story-artifact",
        phase="inception",
        status="draft",
        created=today,
        updated=today,
        intent=intent,
        source_artifacts=source_artifacts,
    )
    return render_frontmatter(metadata, workspace_root=workspace_root)


def get_template_path(template_name: str) -> Path:
    """Resolve a supported shared user-story block reference."""
    if template_name not in SUPPORTED_TEMPLATES:
        supported = ", ".join(sorted(SUPPORTED_TEMPLATES))
        raise ValueError(
            f"Unsupported template '{template_name}'. Choose one of: {supported}"
        )

    return (
        get_skill_dir().parent
        / "_aidlc-shared"
        / "user-story-blocks"
        / SUPPORTED_TEMPLATES[template_name]
    )


def read_builtin_story_block(template_name: str) -> str:
    """Read a supported built-in story block."""
    template_path = get_template_path(template_name)
    return extract_markdown_scaffold(template_path.read_text(), template_name)


def get_story_wrapper_path() -> Path:
    """Resolve the standalone story artifact wrapper."""
    return get_skill_dir() / "references" / "story-artifact-wrapper.md"


def extract_markdown_scaffold(content: str, source_name: str) -> str:
    """Extract the first fenced markdown scaffold from a reference file."""
    try:
        return content.split("```markdown", 1)[1].split("```", 1)[0].strip()
    except IndexError as exc:
        raise ValueError(
            f"Reference '{source_name}' does not contain a markdown scaffold"
        ) from exc


def extract_custom_markdown(content: str, source_name: str) -> str:
    """Extract custom template content from a fenced markdown block or whole file."""
    if "```markdown" in content:
        return extract_markdown_scaffold(content, source_name)

    scaffold = content.strip()
    if not scaffold:
        raise ValueError(f"Custom template '{source_name}' is empty")
    return scaffold


def read_extension_config(repo_root: Path) -> Optional[Dict]:
    """Read workspace extension config if available and valid."""
    config_path = repo_root / CONFIG_PATH
    if not config_path.exists():
        return None

    try:
        return json.loads(config_path.read_text())
    except json.JSONDecodeError:
        return None


def resolve_docs_root(
    repo_root: Path,
    docs_root_arg: Optional[str] = None,
) -> Path:
    """Resolve the AI-DLC docs root: explicit arg, config aidlcDocsPath, default.

    Mirrors the precedence used by other AI-DLC skills so artifacts land in the
    workspace-configured docs tree instead of a hardcoded ./aidlc-docs.
    """
    if docs_root_arg and docs_root_arg.strip():
        candidate = Path(docs_root_arg.strip())
        return candidate if candidate.is_absolute() else repo_root / candidate

    config = read_extension_config(repo_root)
    if isinstance(config, dict):
        configured = config.get(DOCS_ROOT_KEY)
        if isinstance(configured, str) and configured.strip():
            candidate = Path(configured.strip())
            return (
                candidate if candidate.is_absolute() else repo_root / candidate
            )

    return repo_root / DEFAULT_DOCS_ROOT


def read_custom_story_block(repo_root: Path) -> TemplateSource:
    """Read custom story-block markdown from extension config."""
    config = read_extension_config(repo_root)
    user_story = config.get("userStory", {}) if isinstance(config, dict) else {}
    custom_path = user_story.get("customTemplatePath")

    if not custom_path:
        raise ValueError(
            f"No userStory.customTemplatePath configured in {CONFIG_PATH}"
        )

    template_path = Path(custom_path)
    if not template_path.is_absolute():
        template_path = repo_root / template_path

    if not template_path.exists():
        raise ValueError(f"Custom template file not found: {custom_path}")

    content = extract_custom_markdown(template_path.read_text(), str(custom_path))
    return TemplateSource(
        name=CUSTOM_TEMPLATE,
        content=content,
        source_label=f"custom:{custom_path}",
    )


def resolve_template_source(
    template_name: Optional[str],
    repo_root: Optional[Path],
) -> TemplateSource:
    """Resolve explicit, configured, or default story-block template source."""
    if template_name in SUPPORTED_TEMPLATES:
        return TemplateSource(
            name=template_name,
            content=read_builtin_story_block(template_name),
            source_label=f"built-in:{template_name}",
        )

    if template_name == CUSTOM_TEMPLATE:
        if repo_root is None:
            raise ValueError("--template custom requires a repository root")
        try:
            return read_custom_story_block(repo_root)
        except ValueError as exc:
            return TemplateSource(
                name="default",
                content=read_builtin_story_block("default"),
                source_label="built-in:default",
                warning=f"{exc}; falling back to default",
            )

    if template_name is not None:
        supported = ", ".join(TEMPLATE_CHOICES)
        raise ValueError(
            f"Unsupported template '{template_name}'. Choose one of: {supported}"
        )

    if repo_root is None:
        return TemplateSource(
            name="default",
            content=read_builtin_story_block("default"),
            source_label="built-in:default",
        )

    config = read_extension_config(repo_root)
    user_story = config.get("userStory", {}) if isinstance(config, dict) else {}
    configured_template = user_story.get("template")

    if configured_template in SUPPORTED_TEMPLATES:
        return TemplateSource(
            name=configured_template,
            content=read_builtin_story_block(configured_template),
            source_label=f"config:{configured_template}",
        )

    if configured_template == CUSTOM_TEMPLATE:
        try:
            return read_custom_story_block(repo_root)
        except ValueError as exc:
            return TemplateSource(
                name="default",
                content=read_builtin_story_block("default"),
                source_label="built-in:default",
                warning=f"{exc}; falling back to default",
            )

    warning = None
    if config is None:
        warning = f"No usable {CONFIG_PATH}; falling back to default"
    elif configured_template is not None:
        warning = (
            f"Unsupported configured template '{configured_template}'; "
            "falling back to default"
        )

    return TemplateSource(
        name="default",
        content=read_builtin_story_block("default"),
        source_label="built-in:default",
        warning=warning,
    )


def format_story_block_for_artifact(story_block: str) -> str:
    """Adapt a shared story block for a standalone story artifact scaffold."""
    return story_block.replace("US-{ID}", "US-001")


def display_name(feature_name: str) -> str:
    """Convert a feature slug or phrase into a readable title."""
    words = re.sub(r"[_-]+", " ", feature_name).strip()
    return " ".join(words.split()).title()


def kebab_case(value: str) -> str:
    """Convert text to a conservative kebab-case filename segment."""
    slug = re.sub(r"[^A-Za-z0-9]+", "-", value).strip("-").lower()
    return slug or "user-stories"


def render_story_artifact_template(
    template_name: Optional[str],
    feature_name: str,
    repo_root: Optional[Path] = None,
    source_artifacts: Optional[List[str]] = None,
) -> str:
    """Render a standalone story artifact scaffold."""
    template_source = resolve_template_source(template_name, repo_root)
    return render_story_artifact_from_source(
        template_source,
        feature_name,
        source_artifacts=source_artifacts,
        workspace_root=repo_root,
    )


def render_story_artifact_from_source(
    template_source: TemplateSource,
    feature_name: str,
    source_artifacts: Optional[List[str]] = None,
    workspace_root: Optional[Path] = None,
) -> str:
    """Render a standalone story artifact scaffold from a resolved template."""
    wrapper_path = get_story_wrapper_path()

    story_block = format_story_block_for_artifact(
        template_source.content
    )
    scaffold = extract_markdown_scaffold(
        wrapper_path.read_text(),
        "story-artifact-wrapper.md",
    )

    if "{{USER_STORY_BLOCK}}" not in scaffold:
        raise ValueError("story-artifact-wrapper.md is missing {{USER_STORY_BLOCK}}")

    body = (
        scaffold.replace("{{FEATURE_NAME}}", display_name(feature_name))
        .replace("{{USER_STORY_BLOCK}}", story_block)
        .rstrip()
        + "\n"
    )
    frontmatter = render_story_frontmatter(
        intent=kebab_case(feature_name),
        source_artifacts=source_artifacts,
        workspace_root=workspace_root,
    )
    return frontmatter + body


def find_repo_root() -> Path:
    """Find repository root by looking for .mtv-aidlc, .git, or aidlc-docs."""
    markers = (".mtv-aidlc", ".git", "aidlc-docs")
    current = Path.cwd()

    if any((current / marker).exists() for marker in markers):
        return current

    for parent in current.parents:
        if any((parent / marker).exists() for marker in markers):
            return parent

    return current


class StoryArtifactWorkflow:
    """Manage standalone story artifact scaffolds."""

    ARTIFACTS_SUBDIR = "story-artifacts"

    def __init__(self, repo_root: Path, docs_root: Optional[Path] = None):
        self.repo_root = repo_root
        if docs_root is None:
            docs_root = resolve_docs_root(repo_root)
        self.docs_root = docs_root
        self.artifacts_dir = docs_root / self.ARTIFACTS_SUBDIR

    def next_artifact_id(self) -> str:
        """Return the next three-digit artifact ID."""
        if not self.artifacts_dir.exists():
            return "001"

        max_id = 0
        for path in self.artifacts_dir.glob("*.md"):
            match = re.match(r"^(\d{3})_", path.name)
            if match:
                max_id = max(max_id, int(match.group(1)))

        return f"{max_id + 1:03d}"

    def artifact_path(self, feature_name: str) -> Path:
        """Build the next artifact path for a feature."""
        artifact_id = self.next_artifact_id()
        slug = kebab_case(feature_name)
        return self.artifacts_dir / f"{artifact_id}_{slug}_user_stories.md"

    def write_scaffold(
        self,
        feature_name: str,
        template_name: Optional[str],
        template_source: Optional[TemplateSource] = None,
        source_artifacts: Optional[List[str]] = None,
    ) -> Path:
        """Write a scaffold file and refuse to overwrite existing artifacts."""
        if template_source is None:
            content = render_story_artifact_template(
                template_name,
                feature_name,
                repo_root=self.repo_root,
                source_artifacts=source_artifacts,
            )
        else:
            content = render_story_artifact_from_source(
                template_source,
                feature_name,
                source_artifacts=source_artifacts,
                workspace_root=self.repo_root,
            )
        output_path = self.artifact_path(feature_name)

        if output_path.exists():
            raise FileExistsError(f"Refusing to overwrite existing file: {output_path}")

        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(content)
        return output_path


def main() -> None:
    """CLI entrypoint."""
    parser = argparse.ArgumentParser(
        description="Scaffold AI-DLC standalone user story artifacts"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    scaffold = subparsers.add_parser("scaffold", help="Render a story artifact scaffold")
    scaffold.add_argument("feature_name", help="Feature name or slug")
    scaffold.add_argument(
        "--template",
        choices=TEMPLATE_CHOICES,
        default=None,
        help=(
            "Story-block format. If omitted, reads "
            ".mtv-aidlc/extension-config.json and falls back to default."
        ),
    )
    scaffold.add_argument(
        "--repo-root",
        type=Path,
        help="Repository root path (auto-detected if not provided)",
    )
    scaffold.add_argument(
        "--docs-root",
        default=None,
        help=(
            "AI-DLC docs root. If omitted, reads aidlcDocsPath from "
            f"{CONFIG_PATH} and falls back to {DEFAULT_DOCS_ROOT}."
        ),
    )
    scaffold.add_argument(
        "--source",
        action="append",
        default=None,
        metavar="PATH",
        help=(
            "Source artifact path recorded in frontmatter source_artifacts. "
            "Repeat for multiple sources."
        ),
    )
    args = parser.parse_args()

    try:
        repo_root = args.repo_root if args.repo_root else find_repo_root()
        docs_root = resolve_docs_root(repo_root, args.docs_root)
        workflow = StoryArtifactWorkflow(repo_root, docs_root=docs_root)
        template_source = resolve_template_source(args.template, repo_root)
        if template_source.warning:
            print(f"Warning: {template_source.warning}", file=sys.stderr)
        output_path = workflow.write_scaffold(
            args.feature_name,
            args.template,
            template_source=template_source,
            source_artifacts=args.source,
        )
        print(output_path)
        print(f"Resolved template: {template_source.name} ({template_source.source_label})")
    except (ValueError, FileExistsError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
