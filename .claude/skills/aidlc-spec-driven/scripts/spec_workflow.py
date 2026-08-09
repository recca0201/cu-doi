#!/usr/bin/env python3
"""
AI-DLC Spec-Driven Workflow Orchestrator

Manages spec creation and tracks workflow progress through phases:
- Phase 1: Requirements Clarification
- Phase 2: Design Document Creation
- Phase 3: Implementation Planning
- Phase 4: Task Execution
"""

import re
import sys
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Dict, Optional


SUPPORTED_TEMPLATES = {
    "default": "default.md",
    "checklist": "checklist.md",
    "given-when-then-table": "given-when-then-table.md",
}
SUPPORTED_TASK_TEMPLATES = {
    "test-first": "test-first.md",
    "implement-with-tests": "implement-with-tests.md",
    "tests-later": "tests-later.md",
}
SUPPORTED_DESIGN_TEMPLATES = {
    "standard": "standard.md",
    "lean": "lean.md",
}
DEFAULT_TASK_TEMPLATE = "test-first"
DEFAULT_DESIGN_TEMPLATE = "standard"
CUSTOM_TEMPLATE = "custom"
TEMPLATE_CHOICES = sorted([*SUPPORTED_TEMPLATES, CUSTOM_TEMPLATE])
TASK_TEMPLATE_CHOICES = sorted([*SUPPORTED_TASK_TEMPLATES, CUSTOM_TEMPLATE])
DESIGN_TEMPLATE_CHOICES = sorted([*SUPPORTED_DESIGN_TEMPLATES, CUSTOM_TEMPLATE])
CONFIG_PATH = ".mtv-aidlc/extension-config.json"
DEFAULT_DOCS_ROOT = "aidlc-docs"
SUPPORTED_EXECUTION_APPROACHES = ("inline", "subagent")
DEFAULT_EXECUTION_APPROACH = "subagent"
# Canonical supported-Figma-URL pattern. Documentation copies live in
# references/phase-2-uiux-handoff.md; keep them in sync with this regex.
FIGMA_URL_RE = re.compile(
    r"https?://(?:www\.)?figma\.com/(design|file|proto)/([A-Za-z0-9]+)"
)
MOCKUP_METADATA_MARKER = "AIDLC UI Handoff"
TASK_TEMPLATE_GUIDANCE_WARNING = (
    "Guidance only. Do not paste this output directly into tasks.md. "
    "Use it to write real project-specific tasks from approved requirements.md "
    "and design.md."
)
DESIGN_TEMPLATE_GUIDANCE_WARNING = (
    "Guidance only. Do not paste this output directly into design.md. "
    "Use it to write a real project-specific design from approved requirements.md, "
    "codebase analysis, UI handoff context, and research."
)


@dataclass
class TemplateSource:
    """Resolved Markdown template source."""

    name: str
    content: str
    source_label: str
    warning: Optional[str] = None


def get_template_path(template_name: str) -> Path:
    """Resolve a supported shared user-story block reference."""
    if template_name not in SUPPORTED_TEMPLATES:
        supported = ", ".join(sorted(SUPPORTED_TEMPLATES))
        raise ValueError(
            f"Unsupported template '{template_name}'. Choose one of: {supported}"
        )

    skill_dir = Path(__file__).resolve().parents[1]
    return (
        skill_dir.parent
        / "_aidlc-shared"
        / "user-story-blocks"
        / SUPPORTED_TEMPLATES[template_name]
    )


def get_task_template_path(template_name: str) -> Path:
    """Resolve a supported local implementation task-block reference."""
    if template_name not in SUPPORTED_TASK_TEMPLATES:
        supported = ", ".join(sorted(SUPPORTED_TASK_TEMPLATES))
        raise ValueError(
            f"Unsupported task template '{template_name}'. Choose one of: {supported}"
        )

    skill_dir = Path(__file__).resolve().parents[1]
    return (
        skill_dir
        / "references"
        / "task-blocks"
        / SUPPORTED_TASK_TEMPLATES[template_name]
    )


def get_design_template_path(template_name: str) -> Path:
    """Resolve a supported local design guidance reference."""
    if template_name not in SUPPORTED_DESIGN_TEMPLATES:
        supported = ", ".join(sorted(SUPPORTED_DESIGN_TEMPLATES))
        raise ValueError(
            f"Unsupported design template '{template_name}'. Choose one of: {supported}"
        )

    skill_dir = Path(__file__).resolve().parents[1]
    return (
        skill_dir
        / "references"
        / "design-blocks"
        / SUPPORTED_DESIGN_TEMPLATES[template_name]
    )


def read_builtin_story_block(template_name: str) -> str:
    """Read a supported built-in story block."""
    template_path = get_template_path(template_name)
    return extract_markdown_scaffold(template_path.read_text(), template_name)


def read_builtin_task_block(template_name: str) -> str:
    """Read supported built-in implementation task guidance."""
    template_path = get_task_template_path(template_name)
    return template_path.read_text().strip()


def read_builtin_design_block(template_name: str) -> str:
    """Read supported built-in design guidance."""
    template_path = get_design_template_path(template_name)
    return template_path.read_text().strip()


def get_requirements_wrapper_path() -> Path:
    """Resolve the spec-driven requirements document wrapper."""
    skill_dir = Path(__file__).resolve().parents[1]
    return skill_dir / "references" / "requirements-document-wrapper.md"


def load_metadata_renderer():
    """Import the shared metadata renderer from _aidlc-shared."""
    shared_scripts = Path(__file__).resolve().parents[2] / "_aidlc-shared" / "scripts"
    shared_scripts_str = str(shared_scripts)
    if shared_scripts_str not in sys.path:
        sys.path.insert(0, shared_scripts_str)

    from artifact_metadata import ArtifactMetadata, render_frontmatter

    return ArtifactMetadata, render_frontmatter


def get_spec_source_artifacts(
    artifact_type: str,
    spec_name: Optional[str],
    specs_dir: Optional[Path],
) -> list[str]:
    """Return deterministic source artifacts for spec-driven generated guidance."""
    if not spec_name or specs_dir is None:
        return []

    spec_path = specs_dir / spec_name
    if artifact_type == "design":
        return [str(spec_path / "requirements.md")]
    if artifact_type == "tasks":
        return [
            str(spec_path / "requirements.md"),
            str(spec_path / "design.md"),
        ]

    return []


def render_agent_metadata_preamble(
    artifact_type: str,
    phase: str,
    spec_name: Optional[str],
    repo_root: Optional[Path],
    specs_dir: Optional[Path] = None,
) -> str:
    """Render a metadata preamble section for agent-authored artifacts.

    Returns a Markdown block containing the helper-rendered frontmatter and
    explicit instructions for the agent to emit it as the first bytes of the
    artifact file.
    """
    from datetime import date

    ArtifactMetadata, render_frontmatter = load_metadata_renderer()

    if specs_dir is None and repo_root is not None:
        specs_dir = resolve_docs_root(repo_root) / "specs"

    today = date.today().isoformat()
    source_artifacts = get_spec_source_artifacts(
        artifact_type,
        spec_name,
        specs_dir,
    )
    metadata = ArtifactMetadata(
        artifact_type=artifact_type,
        phase=phase,
        status="draft",
        created=today,
        updated=today,
        unit=spec_name,
        source_artifacts=source_artifacts,
    )
    frontmatter = render_frontmatter(metadata, workspace_root=repo_root)

    if spec_name:
        unit_note = (
            f"  - `unit` is set to `{spec_name}` from the provided spec slug."
        )
        if source_artifacts:
            source_note = (
                "  - `source_artifacts` was derived from the current spec folder."
            )
        else:
            source_note = (
                "  - `source_artifacts` is empty because no deterministic sources "
                "are defined for this artifact type."
            )
    else:
        unit_note = (
            "  - `unit` is a placeholder — replace with the spec folder slug."
        )
        source_note = (
            "  - `source_artifacts` is `[]`; replace it with current spec-folder "
            "source paths when drafting a concrete artifact."
        )

    return (
        "## Agent Instructions: Emit Frontmatter First\n"
        "\n"
        "Place the following YAML frontmatter block as the **first bytes** of the artifact file.\n"
        "Fill in optional fields (`intent`, `related_artifacts`) when known.\n"
        f"{unit_note}\n"
        f"{source_note}\n"
        "Do NOT include `aidlc_schema` or `workflow` fields.\n"
        "\n"
        f"{frontmatter}"
    )


def render_requirements_frontmatter(
    spec_slug: str,
    created_date: str,
    repo_root: Optional[Path] = None,
) -> str:
    """Render compliant frontmatter for scaffolded requirements artifacts."""
    ArtifactMetadata, render_frontmatter = load_metadata_renderer()

    metadata = ArtifactMetadata(
        artifact_type="requirements",
        phase="construction",
        status="draft",
        created=created_date,
        updated=created_date,
        unit=spec_slug,
    )
    return render_frontmatter(metadata, workspace_root=repo_root)


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


def extract_custom_guidance(content: str, source_name: str) -> str:
    """Extract custom guidance from the whole file."""
    guidance = content.strip()
    if not guidance:
        raise ValueError(f"Custom template '{source_name}' is empty")
    return guidance


def read_extension_config(repo_root: Path) -> Optional[Dict]:
    """Read the nearest ancestor workspace extension config if valid."""
    config_path = find_extension_config_path(repo_root)
    if config_path is None:
        return None

    try:
        return json.loads(config_path.read_text())
    except json.JSONDecodeError:
        return None


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


def find_extension_config_root(start_path: Path) -> Optional[Path]:
    """Find the workspace root that owns the nearest extension config."""
    config_path = find_extension_config_path(start_path)
    if config_path is None:
        return None
    return config_path.parent.parent


def resolve_config_relative_path(repo_root: Path, configured_path: str) -> Path:
    """Resolve config paths relative to the workspace that owns the config."""
    template_path = Path(configured_path)
    if template_path.is_absolute():
        return template_path

    config_root = find_extension_config_root(repo_root) or repo_root
    return config_root / template_path


def resolve_docs_root(repo_root: Path, docs_root: Optional[Path] = None) -> Path:
    """Resolve AI-DLC docs root from CLI, config, or default.

    Precedence matches the sibling AI-DLC skill CLIs: explicit --docs-root,
    then `aidlcDocsPath` from the nearest extension config (resolved relative
    to the workspace that owns the config), then `aidlc-docs` at repo root.
    """
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


def resolve_execution_approach(repo_root: Path) -> Dict[str, Optional[str]]:
    """Resolve Phase 4 `taskExecution.approach` from config, else inline.

    Mirrors the context-inject hook: a supported value (after trimming) from
    the nearest extension config wins; anything else defaults with a warning.
    Explicit prompt wording is resolved by the caller and wins over this.
    """
    result: Dict[str, Optional[str]] = {
        "approach": DEFAULT_EXECUTION_APPROACH,
        "source": "default",
        "config_path": None,
        "warning": None,
    }

    config_path = find_extension_config_path(repo_root)
    if config_path is None:
        return result

    result["config_path"] = str(config_path)

    try:
        config = json.loads(config_path.read_text())
    except json.JSONDecodeError:
        result["warning"] = (
            f"{CONFIG_PATH} is not valid JSON; "
            f"using default '{DEFAULT_EXECUTION_APPROACH}'."
        )
        return result

    task_execution = (
        config.get("taskExecution") if isinstance(config, dict) else None
    )
    raw_value = (
        task_execution.get("approach")
        if isinstance(task_execution, dict)
        else None
    )

    if raw_value is None:
        return result

    approach = raw_value.strip() if isinstance(raw_value, str) else raw_value
    if approach in SUPPORTED_EXECUTION_APPROACHES:
        result["approach"] = approach
        result["source"] = "config"
        return result

    result["warning"] = (
        f"Unsupported taskExecution.approach {raw_value!r}; "
        f"using default '{DEFAULT_EXECUTION_APPROACH}'."
    )
    return result


def read_custom_story_block(repo_root: Path) -> TemplateSource:
    """Read custom story-block markdown from extension config."""
    config = read_extension_config(repo_root)
    user_story = config.get("userStory", {}) if isinstance(config, dict) else {}
    custom_path = user_story.get("customTemplatePath")

    if not custom_path:
        raise ValueError(
            f"No userStory.customTemplatePath configured in {CONFIG_PATH}"
        )

    template_path = resolve_config_relative_path(repo_root, custom_path)

    if not template_path.exists():
        raise ValueError(f"Custom template file not found: {custom_path}")

    content = extract_custom_markdown(template_path.read_text(), str(custom_path))
    return TemplateSource(
        name=CUSTOM_TEMPLATE,
        content=content,
        source_label=f"custom:{custom_path}",
    )


def read_custom_task_block(repo_root: Path) -> TemplateSource:
    """Read custom implementation task guidance from extension config."""
    config = read_extension_config(repo_root)
    task_config = (
        config.get("implementationTask", {}) if isinstance(config, dict) else {}
    )
    custom_path = task_config.get("customTemplatePath")

    if not custom_path:
        raise ValueError(
            f"No implementationTask.customTemplatePath configured in {CONFIG_PATH}"
        )

    template_path = resolve_config_relative_path(repo_root, custom_path)

    if not template_path.exists():
        raise ValueError(f"Custom task template file not found: {custom_path}")

    content = extract_custom_guidance(template_path.read_text(), str(custom_path))
    return TemplateSource(
        name=CUSTOM_TEMPLATE,
        content=content,
        source_label=f"custom:{custom_path}",
    )


def read_custom_design_block(repo_root: Path) -> TemplateSource:
    """Read custom design guidance from extension config."""
    config = read_extension_config(repo_root)
    design_config = (
        config.get("designDocument", {}) if isinstance(config, dict) else {}
    )
    custom_path = design_config.get("customTemplatePath")

    if not custom_path:
        raise ValueError(
            f"No designDocument.customTemplatePath configured in {CONFIG_PATH}"
        )

    template_path = resolve_config_relative_path(repo_root, custom_path)

    if not template_path.exists():
        raise ValueError(f"Custom design template file not found: {custom_path}")

    content = extract_custom_guidance(template_path.read_text(), str(custom_path))
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
    return resolve_template_family_source(
        explicit_template=template_name,
        repo_root=repo_root,
        supported_templates=SUPPORTED_TEMPLATES,
        template_choices=TEMPLATE_CHOICES,
        default_template="default",
        config_section="userStory",
        explicit_label="template",
        configured_label="template",
        cli_option="--template",
        builtin_reader=read_builtin_story_block,
        custom_reader=read_custom_story_block,
    )


def resolve_task_template_source(
    template_name: Optional[str],
    repo_root: Optional[Path],
) -> TemplateSource:
    """Resolve explicit, configured, or default implementation task-block source."""
    return resolve_template_family_source(
        explicit_template=template_name,
        repo_root=repo_root,
        supported_templates=SUPPORTED_TASK_TEMPLATES,
        template_choices=TASK_TEMPLATE_CHOICES,
        default_template=DEFAULT_TASK_TEMPLATE,
        config_section="implementationTask",
        explicit_label="task template",
        configured_label="task template",
        cli_option="--task-template",
        builtin_reader=read_builtin_task_block,
        custom_reader=read_custom_task_block,
    )


def resolve_design_template_source(
    template_name: Optional[str],
    repo_root: Optional[Path],
) -> TemplateSource:
    """Resolve explicit, configured, or default design guidance source."""
    return resolve_template_family_source(
        explicit_template=template_name,
        repo_root=repo_root,
        supported_templates=SUPPORTED_DESIGN_TEMPLATES,
        template_choices=DESIGN_TEMPLATE_CHOICES,
        default_template=DEFAULT_DESIGN_TEMPLATE,
        config_section="designDocument",
        explicit_label="design template",
        configured_label="design template",
        cli_option="--design-template",
        builtin_reader=read_builtin_design_block,
        custom_reader=read_custom_design_block,
    )


def resolve_template_family_source(
    explicit_template: Optional[str],
    repo_root: Optional[Path],
    supported_templates: Dict[str, str],
    template_choices: list,
    default_template: str,
    config_section: str,
    explicit_label: str,
    configured_label: str,
    cli_option: str,
    builtin_reader: Callable[[str], str],
    custom_reader: Callable[[Path], TemplateSource],
) -> TemplateSource:
    """Resolve a template by explicit selection, config, then built-in default."""
    if explicit_template in supported_templates:
        return TemplateSource(
            name=explicit_template,
            content=builtin_reader(explicit_template),
            source_label=f"built-in:{explicit_template}",
        )

    if explicit_template == CUSTOM_TEMPLATE:
        if repo_root is None:
            raise ValueError(f"{cli_option} custom requires a repository root")
        try:
            return custom_reader(repo_root)
        except ValueError as exc:
            return default_template_source(
                default_template,
                builtin_reader,
                warning=f"{exc}; falling back to {default_template}",
            )

    if explicit_template is not None:
        supported = ", ".join(template_choices)
        raise ValueError(
            f"Unsupported {explicit_label} '{explicit_template}'. "
            f"Choose one of: {supported}"
        )

    if repo_root is None:
        return default_template_source(default_template, builtin_reader)

    config_path = find_extension_config_path(repo_root)
    config = read_extension_config(repo_root)
    if config is None:
        warning = None
        if config_path is not None:
            warning = f"Malformed {CONFIG_PATH}; falling back to {default_template}"
        return default_template_source(default_template, builtin_reader, warning)

    template_config = config.get(config_section, {}) if isinstance(config, dict) else {}
    configured_template = template_config.get("template")

    if configured_template in supported_templates:
        return TemplateSource(
            name=configured_template,
            content=builtin_reader(configured_template),
            source_label=f"config:{configured_template}",
        )

    if configured_template == CUSTOM_TEMPLATE:
        try:
            return custom_reader(repo_root)
        except ValueError as exc:
            return default_template_source(
                default_template,
                builtin_reader,
                warning=f"{exc}; falling back to {default_template}",
            )

    warning = None
    if configured_template is not None:
        warning = (
            f"Unsupported configured {configured_label} "
            f"'{configured_template}'; falling back to {default_template}"
        )

    return default_template_source(default_template, builtin_reader, warning)


def default_template_source(
    default_template: str,
    builtin_reader: Callable[[str], str],
    warning: Optional[str] = None,
) -> TemplateSource:
    """Return a built-in default template source with optional fallback warning."""
    return TemplateSource(
        name=default_template,
        content=builtin_reader(default_template),
        source_label=f"built-in:{default_template}",
        warning=warning,
    )


def format_story_block_for_spec(story_block: str) -> str:
    """Adapt the shared story block placeholders for a requirements.md scaffold."""
    story_block = story_block.replace("US-{ID}", "US-1")
    story_block = story_block.replace(
        "As a {persona}, I want {capability}, so that {benefit}",
        "As a [role], I want [feature], so that [benefit]",
    )
    protected = {
        "{User Story Title}": "__USER_STORY_TITLE__",
        "{why this story matters now}": "__BUSINESS_VALUE__",
    }
    for placeholder, token in protected.items():
        story_block = story_block.replace(placeholder, token)

    story_block = re.sub(r"\{([^{}]+)\}", r"[\1]", story_block)

    for placeholder, token in protected.items():
        story_block = story_block.replace(token, placeholder)

    return story_block


def render_requirements_template(
    template_name: Optional[str],
    spec_name: str,
    created_date: str,
    repo_root: Optional[Path] = None,
) -> str:
    """Render a requirements.md scaffold from a wrapper and shared story block."""
    template_source = resolve_template_source(template_name, repo_root)
    wrapper_path = get_requirements_wrapper_path()
    story_block = format_story_block_for_spec(
        template_source.content
    )
    scaffold = extract_markdown_scaffold(
        wrapper_path.read_text(),
        "requirements-document-wrapper.md",
    )

    if "{{USER_STORY_BLOCK}}" not in scaffold:
        raise ValueError(
            "requirements-document-wrapper.md is missing {{USER_STORY_BLOCK}}"
        )

    return (
        scaffold.replace("{{SPEC_NAME}}", spec_name)
        .replace("{{CREATED_DATE}}", created_date)
        .replace("{{USER_STORY_BLOCK}}", story_block)
        .rstrip()
        + "\n"
    )


class SpecWorkflow:
    """Orchestrates spec-driven workflow phases"""

    FOUNDATION_DIR = "aidlc-docs/foundation"
    SPECS_DIR = "aidlc-docs/specs"

    REQUIRED_FOUNDATION = [
        "project-overview-pdr.md",
        "system-architecture.md",
        "codebase-summary.md",
        "code-standards.md",
        "uiux-guideline.md"
    ]

    PHASES = {
        1: {"name": "Requirements", "file": "requirements.md"},
        2: {"name": "Design", "file": "design.md"},
        3: {"name": "Tasks", "file": "tasks.md"},
        4: {"name": "Execution", "file": None}
    }

    def __init__(self, repo_root: Path, docs_root: Optional[Path] = None):
        self.repo_root = repo_root
        self.docs_root = resolve_docs_root(repo_root, docs_root)
        self.foundation_dir = self.docs_root / "foundation"
        self.specs_dir = self.docs_root / "specs"

    def validate_foundation(self) -> Dict[str, bool]:
        """Check which foundation docs exist"""
        status = {}
        for doc in self.REQUIRED_FOUNDATION:
            path = self.foundation_dir / doc
            status[doc] = path.exists()
        return status

    def create_spec_structure(
        self,
        spec_name: str,
        scaffold: bool = True,
        template: Optional[str] = None,
    ) -> Path:
        """Create spec directory and optionally scaffold a requirements.md starter template"""
        if scaffold:
            resolve_template_source(template, self.repo_root)

        spec_path = self.specs_dir / spec_name
        spec_path.mkdir(parents=True, exist_ok=True)

        if scaffold:
            from datetime import date
            req_file = spec_path / "requirements.md"
            if not req_file.exists():
                display_name = spec_name.replace("-", " ").title()
                today = date.today().isoformat()
                req_file.write_text(
                    render_requirements_frontmatter(
                        spec_name,
                        today,
                        repo_root=self.repo_root,
                    )
                    +
                    render_requirements_template(
                        template,
                        display_name,
                        today,
                        repo_root=self.repo_root,
                    )
                )

        return spec_path

    def get_current_phase(self, spec_name: str) -> int:
        """Determine current workflow phase based on existing files"""
        spec_path = self.specs_dir / spec_name

        if not spec_path.exists():
            return 1

        # Check which phase files exist
        if not (spec_path / "requirements.md").exists():
            return 1
        elif not (spec_path / "design.md").exists():
            return 2
        elif not (spec_path / "tasks.md").exists():
            return 3
        else:
            return 4

    def get_status(self, spec_name: str) -> Dict:
        """Get workflow status for a spec"""
        current_phase = self.get_current_phase(spec_name)
        spec_path = self.specs_dir / spec_name

        phase_status = {}
        for phase_num, phase_info in self.PHASES.items():
            if phase_info["file"]:
                file_path = spec_path / phase_info["file"]
                phase_status[phase_num] = {
                    "name": phase_info["name"],
                    "file": phase_info["file"],
                    "exists": file_path.exists(),
                    "completed": phase_num < current_phase
                }

        return {
            "spec_name": spec_name,
            "spec_path": str(spec_path),
            "current_phase": current_phase,
            "current_phase_name": self.PHASES[current_phase]["name"],
            "phase_status": phase_status,
            "foundation_docs": self.validate_foundation()
        }

    def list_specs(self) -> list:
        """List all existing specs"""
        if not self.specs_dir.exists():
            return []

        return [d.name for d in self.specs_dir.iterdir() if d.is_dir()]

    def get_mockup_status(
        self,
        spec_name: str,
        figma_url: Optional[str] = None,
    ) -> Dict:
        """Determine Phase 2 mockup status for this spec (see get_mockup_status)."""
        return get_mockup_status(self.specs_dir, spec_name, figma_url=figma_url)

    def mark_task_complete(self, spec_name: str, task_number: str) -> bool:
        """Mark a task as complete in tasks.md"""
        tasks_file = self.specs_dir / spec_name / "tasks.md"

        if not tasks_file.exists():
            raise FileNotFoundError(f"tasks.md not found for spec '{spec_name}'")

        # Read the tasks file
        content = tasks_file.read_text()

        # Pattern to match the task checkbox
        # Handles both "- [ ] 1." and "- [ ] 1.1" formats
        import re
        pattern = rf'^(\s*- \[ \] {re.escape(task_number)}\.?\s+.*)$'

        # Find and replace
        updated_content = re.sub(
            pattern,
            lambda m: m.group(1).replace('[ ]', '[x]'),
            content,
            flags=re.MULTILINE
        )

        # Check if anything was changed
        if content == updated_content:
            return False

        # Write back
        tasks_file.write_text(updated_content)
        return True

    def get_task_progress(self, spec_name: str) -> Dict:
        """Get task completion progress"""
        tasks_file = self.specs_dir / spec_name / "tasks.md"

        if not tasks_file.exists():
            raise FileNotFoundError(f"tasks.md not found for spec '{spec_name}'")

        content = tasks_file.read_text()

        import re
        # Count checkboxes
        total = len(re.findall(r'- \[[ x]\]', content))
        completed = len(re.findall(r'- \[x\]', content))
        pending = total - completed

        return {
            "spec_name": spec_name,
            "total": total,
            "completed": completed,
            "pending": pending,
            "percentage": round((completed / total * 100) if total > 0 else 0, 1)
        }

    def validate_tasks(self, spec_name: str) -> Dict:
        """Deterministically validate tasks.md structure and AC coverage.

        Errors fail validation; warnings never do. Coverage is checked only
        when requirements.md parses into recognizable criterion IDs, so
        custom requirements formats degrade to a warning instead of a false
        failure.
        """
        spec_path = self.specs_dir / spec_name
        tasks_file = spec_path / "tasks.md"
        requirements_file = spec_path / "requirements.md"

        errors: list = []
        warnings: list = []
        summary = {
            "total_tasks": 0,
            "criteria_total": 0,
            "criteria_covered": 0,
            "uncovered": [],
        }
        result = {
            "spec_name": spec_name,
            "artifact": "tasks",
            "tasks_path": str(tasks_file),
            "requirements_path": (
                str(requirements_file) if requirements_file.exists() else None
            ),
            "valid": False,
            "errors": errors,
            "warnings": warnings,
            "summary": summary,
        }

        if not tasks_file.exists():
            errors.append({
                "check": "tasks-file-missing",
                "detail": f"tasks.md not found for spec '{spec_name}'",
            })
            return result

        content = tasks_file.read_text()

        if not content.startswith("---"):
            errors.append({
                "check": "frontmatter-missing",
                "detail": (
                    "tasks.md must start with the script-owned YAML "
                    "frontmatter (emit the `tasks-template` metadata "
                    "preamble as the first bytes)"
                ),
            })

        items = _parse_task_items(content)
        numbered = [item for item in items if item["number"]]
        summary["total_tasks"] = len(items)

        if not items:
            errors.append({
                "check": "no-tasks",
                "detail": "tasks.md contains no `- [ ]` / `- [x]` checkbox items",
            })

        too_deep = sorted(
            {item["number"] for item in numbered if item["number"].count(".") >= 2}
        )
        if too_deep:
            errors.append({
                "check": "hierarchy-too-deep",
                "detail": "task numbering exceeds 2 hierarchy levels",
                "items": too_deep,
            })

        numbers = {item["number"] for item in numbered}
        missing_reference = []
        for item in numbered:
            has_children = any(
                other.startswith(item["number"] + ".") for other in numbers
            )
            if has_children:
                # Parent tasks may delegate references to their leaf children.
                continue
            block_refs = [
                line for line in item["block_lines"] if "Reference:" in line
            ]
            if not any("US-" in line and "AC-" in line for line in block_refs):
                missing_reference.append(item["number"])
        if missing_reference:
            errors.append({
                "check": "missing-reference",
                "detail": (
                    "checkbox tasks without a `Reference: US-... AC-...` line"
                ),
                "items": missing_reference,
            })

        lines = content.splitlines()
        next_steps_idx = next(
            (
                i
                for i, line in enumerate(lines)
                if re.match(r"^##\s+Next Steps\s*$", line)
            ),
            None,
        )
        if next_steps_idx is None:
            errors.append({
                "check": "next-steps-missing",
                "detail": "tasks.md must end with a `## Next Steps` section",
            })
        else:
            later_headings = [
                line
                for line in lines[next_steps_idx + 1:]
                if re.match(r"^##\s", line)
            ]
            if later_headings:
                errors.append({
                    "check": "next-steps-not-last",
                    "detail": "`## Next Steps` must be the final section",
                    "items": later_headings,
                })

        reference_text = "\n".join(
            line for line in lines if "Reference:" in line
        )

        if not requirements_file.exists():
            warnings.append({
                "check": "requirements-missing",
                "detail": (
                    "requirements.md not found; acceptance-criteria "
                    "coverage was not checked"
                ),
            })
        else:
            parsed = parse_requirements_criteria(requirements_file.read_text())
            if not parsed["parseable"]:
                warnings.append({
                    "check": "criteria-unparseable",
                    "detail": (
                        "no acceptance-criterion IDs recognized in "
                        "requirements.md (custom or unknown story format); "
                        "coverage was not checked"
                    ),
                })
            else:
                uncovered = []
                covered = 0
                for criterion in parsed["criteria"]:
                    criterion_id = criterion["id"]
                    id_re = re.compile(
                        r"(?<![\w.])" + re.escape(criterion_id) + r"(?!\w)(?!\.\d)"
                    )
                    if id_re.search(reference_text):
                        covered += 1
                    else:
                        uncovered.append(
                            f"{criterion['story']} AC-{criterion_id}"
                        )
                summary["criteria_total"] = len(parsed["criteria"])
                summary["criteria_covered"] = covered
                summary["uncovered"] = uncovered
                if uncovered:
                    errors.append({
                        "check": "uncovered-criteria",
                        "detail": (
                            "acceptance criteria not referenced by any task"
                        ),
                        "items": uncovered,
                    })

                known_ids = {c["id"] for c in parsed["criteria"]}
                referenced = set(
                    re.findall(
                        r"AC-([A-Za-z0-9-]*\d+(?:\.\d+)*)", reference_text
                    )
                )
                unknown = sorted(referenced - known_ids)
                if unknown:
                    warnings.append({
                        "check": "unknown-references",
                        "detail": (
                            "task Reference IDs not found in "
                            "requirements.md (ID parsing is heuristic, so "
                            "this is a warning)"
                        ),
                        "items": unknown,
                    })

        result["valid"] = not errors
        return result


# Criterion-ID parsing for `validate`. IDs may be plain (`1.1`) or
# unit-prefixed (`CSA-01.1.1`); the alphabet is deliberately lenient because
# requirements docs own their ID scheme and tasks must cite it verbatim.
CRITERION_ID_PATTERN = r"[A-Za-z0-9-]*\d+(?:\.\d+)+"
STORY_HEADING_RE = re.compile(r"^#{2,4}\s+(US-[A-Za-z0-9-]*\d+)\b")
CHECKLIST_CRITERION_RE = re.compile(
    r"^\s*-\s*\[[ x]\]\s*\*\*(?:AC-)?([A-Za-z0-9-]*\d+(?:\.\d+)*)\*\*"
)
TABLE_CRITERION_RE = re.compile(
    rf"^\s*\|\s*(?:AC-)?({CRITERION_ID_PATTERN})\s*\|"
)
EARS_CRITERION_RE = re.compile(rf"^\s*(?:AC-)?({CRITERION_ID_PATTERN})\s+\S")


def parse_requirements_criteria(requirements_text: str) -> Dict:
    """Parse acceptance-criterion IDs from requirements.md story sections.

    Recognizes the three built-in story blocks — EARS numbered lines,
    checklist items with bold IDs, and Given/When/Then table rows. Only
    lines inside `### US-*` story sections are considered so prose
    numbering elsewhere in the document is not mistaken for criteria.
    Custom story formats may not parse; callers treat zero parsed criteria
    as "coverage unknown", never as a validation failure.
    """
    criteria: list = []
    seen = set()
    current_story: Optional[str] = None

    for line in requirements_text.splitlines():
        story_match = STORY_HEADING_RE.match(line)
        if story_match:
            current_story = story_match.group(1)
            continue
        if current_story is None:
            continue
        for pattern in (
            CHECKLIST_CRITERION_RE,
            TABLE_CRITERION_RE,
            EARS_CRITERION_RE,
        ):
            match = pattern.match(line)
            if match:
                criterion_id = match.group(1)
                if criterion_id not in seen:
                    seen.add(criterion_id)
                    criteria.append({"id": criterion_id, "story": current_story})
                break

    return {"criteria": criteria, "parseable": bool(criteria)}


def _parse_task_items(tasks_text: str) -> list:
    """Extract checkbox tasks and their sub-bullet blocks from tasks.md.

    A task block runs from its checkbox line to the next checkbox line or
    heading, so `Reference:` sub-bullets stay attached to their task.
    """
    checkbox_re = re.compile(r"^\s*-\s*\[[ x]\]\s*(.*)$")
    number_re = re.compile(r"^(\d+(?:\.\d+)*)\.?\s")
    heading_re = re.compile(r"^#{1,6}\s")

    items: list = []
    current: Optional[Dict] = None
    for line in tasks_text.splitlines():
        checkbox_match = checkbox_re.match(line)
        if checkbox_match:
            if current is not None:
                items.append(current)
            number_match = number_re.match(checkbox_match.group(1))
            current = {
                "number": number_match.group(1) if number_match else None,
                "block_lines": [line],
            }
            continue
        if heading_re.match(line):
            if current is not None:
                items.append(current)
                current = None
            continue
        if current is not None:
            current["block_lines"].append(line)
    if current is not None:
        items.append(current)
    return items


def normalize_node_id(node_id: Optional[str]) -> Optional[str]:
    """Normalize a Figma node ID to API form (123:456) for comparison."""
    if node_id is None:
        return None
    node_id = str(node_id).strip()
    if not node_id or node_id.lower() == "none":
        return None
    if re.fullmatch(r"\d+-\d+", node_id):
        return node_id.replace("-", ":")
    return node_id


def parse_figma_url(url: str) -> Dict:
    """Parse a Figma URL into support status, file key, and node ID.

    Only design/file/proto URLs are supported (FIGMA_URL_RE). Board/FigJam
    and other URL types return supported=False so the caller can ask the
    user for a supported URL instead of guessing.
    """
    match = FIGMA_URL_RE.match(url.strip())
    if not match:
        return {"supported": False, "url_type": None, "file_key": None, "node_id": None}

    node_id = None
    node_match = re.search(r"[?&]node-id=([0-9]+[-:][0-9]+)", url)
    if node_match:
        node_id = normalize_node_id(node_match.group(1))

    return {
        "supported": True,
        "url_type": match.group(1),
        "file_key": match.group(2),
        "node_id": node_id,
    }


def parse_mockup_metadata(html: str) -> Optional[Dict[str, str]]:
    """Parse the AIDLC UI Handoff metadata comment from mockup.html.

    Returns a key/value dict from the first HTML comment containing the
    marker, or None when no handoff metadata comment exists.
    """
    for comment_match in re.finditer(r"<!--(.*?)-->", html, flags=re.DOTALL):
        body = comment_match.group(1)
        if MOCKUP_METADATA_MARKER not in body:
            continue
        metadata: Dict[str, str] = {}
        for line in body.splitlines():
            line = line.strip()
            if ":" not in line:
                continue
            key, _, value = line.partition(":")
            key = key.strip()
            if re.fullmatch(r"[a-z0-9_]+", key):
                metadata[key] = value.strip()
        return metadata
    return None


def _metadata_value(metadata: Optional[Dict[str, str]], key: str) -> Optional[str]:
    """Read a metadata value, treating empty and 'none' as missing."""
    if not metadata:
        return None
    value = (metadata.get(key) or "").strip()
    if not value or value.lower() == "none":
        return None
    return value


def get_mockup_status(
    specs_dir: Path,
    spec_name: str,
    figma_url: Optional[str] = None,
) -> Dict:
    """Determine the Phase 2 mockup status for a spec deterministically.

    Emits one of: pre-existing, not-applicable, pre-existing-fresh,
    needs-refresh, needs-generation. The sixth vocabulary value,
    `unavailable`, is never emitted here — it is an orchestrator state set
    only after a failed UI handoff plus explicit user approval to continue.
    Vocabulary definitions live in references/phase-2-uiux-handoff.md.
    """
    mockup_path = specs_dir / spec_name / "mockup.html"
    mockup_exists = mockup_path.exists()

    parsed_url = parse_figma_url(figma_url) if figma_url else None
    url_supported = parsed_url["supported"] if parsed_url else None

    metadata = None
    if mockup_exists:
        metadata = parse_mockup_metadata(mockup_path.read_text())

    result = {
        "spec_name": spec_name,
        "mockup_path": str(mockup_path) if mockup_exists else None,
        "mockup_exists": mockup_exists,
        "figma_url": figma_url or None,
        "figma_url_supported": url_supported,
        "figma_url_file_key": parsed_url["file_key"] if parsed_url else None,
        "figma_url_node_id": parsed_url["node_id"] if parsed_url else None,
        "metadata_found": metadata is not None,
        "metadata_file_key": _metadata_value(metadata, "figma_file_key"),
        "metadata_node_id": normalize_node_id(
            _metadata_value(metadata, "figma_node_id")
        ),
    }

    effective_url = parsed_url if (parsed_url and parsed_url["supported"]) else None
    unsupported_note = (
        "Figma URL is not a supported design/file/proto URL; "
        "ask for a supported URL if the design depends on it. "
        if figma_url and not effective_url
        else ""
    )

    if effective_url is None:
        if mockup_exists:
            result["mockup_status"] = "pre-existing"
            result["reason"] = (
                unsupported_note
                + "mockup.html exists and no supported Figma URL was provided."
            )
        else:
            result["mockup_status"] = "not-applicable"
            result["reason"] = (
                unsupported_note
                + "No mockup.html and no supported Figma URL was provided."
            )
        return result

    if not mockup_exists:
        result["mockup_status"] = "needs-generation"
        result["reason"] = "Supported Figma URL provided but mockup.html is missing."
        return result

    if result["metadata_file_key"] is None:
        result["mockup_status"] = "needs-refresh"
        result["reason"] = (
            "mockup.html has no usable AIDLC UI Handoff metadata "
            "(missing comment or figma_file_key)."
        )
        return result

    if result["metadata_file_key"] != effective_url["file_key"]:
        result["mockup_status"] = "needs-refresh"
        result["reason"] = "mockup.html metadata file key does not match the Figma URL."
        return result

    if effective_url["node_id"] and result["metadata_node_id"] != effective_url["node_id"]:
        result["mockup_status"] = "needs-refresh"
        result["reason"] = "mockup.html metadata node ID does not match the Figma URL."
        return result

    result["mockup_status"] = "pre-existing-fresh"
    result["reason"] = "mockup.html metadata matches the Figma URL file key/node ID."
    return result


def find_repo_root() -> Path:
    """Find repository root by looking for .git or aidlc-docs"""
    current = Path.cwd()

    # Try current directory first
    if (current / "aidlc-docs").exists() or (current / ".git").exists():
        return current

    # Walk up to find root
    for parent in current.parents:
        if (parent / "aidlc-docs").exists() or (parent / ".git").exists():
            return parent

    return current


def main():
    """CLI interface for spec workflow management"""
    import argparse

    parser = argparse.ArgumentParser(
        description="AI-DLC Spec-Driven Workflow Orchestrator"
    )
    parser.add_argument(
        "command",
        choices=[
            "init",
            "status",
            "list",
            "design-template",
            "tasks-template",
            "mockup-status",
            "execution-approach",
            "validate",
            "complete",
            "progress",
        ],
        help="Command to execute"
    )
    parser.add_argument(
        "spec_name",
        nargs="?",
        help=(
            "Spec name (required for init, status, mockup-status, validate, "
            "complete, progress; optional for design-template and "
            "tasks-template metadata guidance)"
        )
    )
    parser.add_argument(
        "task_number",
        nargs="?",
        help="Task number to mark complete (e.g., '2.1')"
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        help="Repository root path (auto-detected if not provided)"
    )
    parser.add_argument(
        "--docs-root",
        type=Path,
        default=None,
        help=(
            "AI-DLC docs root. If omitted, reads `aidlcDocsPath` from "
            ".mtv-aidlc/extension-config.json, then falls back to "
            "aidlc-docs at the repo root."
        )
    )
    parser.add_argument(
        "--template",
        choices=TEMPLATE_CHOICES,
        default=None,
        help=(
            "Story-block format for init. If omitted, reads "
            ".mtv-aidlc/extension-config.json and falls back to default."
        )
    )
    parser.add_argument(
        "--task-template",
        choices=TASK_TEMPLATE_CHOICES,
        default=None,
        help=(
            "Implementation task-block format for Phase 3. If omitted, reads "
            ".mtv-aidlc/extension-config.json and falls back to test-first."
        )
    )
    parser.add_argument(
        "--design-template",
        choices=DESIGN_TEMPLATE_CHOICES,
        default=None,
        help=(
            "Design document guidance format for Phase 2. If omitted, reads "
            ".mtv-aidlc/extension-config.json and falls back to standard."
        )
    )
    parser.add_argument(
        "--figma-url",
        default=None,
        help=(
            "Figma URL from requirements/user context for mockup-status. "
            "Omit when no Figma URL is present."
        )
    )
    args = parser.parse_args()

    # Find or use provided repo root
    repo_root = args.repo_root if args.repo_root else find_repo_root()
    workflow = SpecWorkflow(repo_root, docs_root=args.docs_root)

    if args.command == "list":
        specs = workflow.list_specs()
        if specs:
            print("📋 Existing specs:")
            for spec in specs:
                print(f"  • {spec}")
        else:
            print("No specs found.")
        return

    if args.command == "execution-approach":
        result = resolve_execution_approach(repo_root)
        print(json.dumps(result, indent=2))
        return

    if args.command == "tasks-template":
        task_template_source = resolve_task_template_source(
            args.task_template,
            repo_root,
        )
        if task_template_source.warning:
            print(f"Warning: {task_template_source.warning}", file=sys.stderr)

        print(
            f"# Task Template Guidance: {task_template_source.name} "
            f"({task_template_source.source_label})\n"
        )
        print(
            render_agent_metadata_preamble(
                artifact_type="tasks",
                phase="construction",
                spec_name=args.spec_name,
                repo_root=repo_root,
                specs_dir=workflow.specs_dir,
            )
        )
        print(f"{TASK_TEMPLATE_GUIDANCE_WARNING}\n")
        print(task_template_source.content)
        return

    if args.command == "design-template":
        design_template_source = resolve_design_template_source(
            args.design_template,
            repo_root,
        )
        if design_template_source.warning:
            print(f"Warning: {design_template_source.warning}", file=sys.stderr)

        print(
            f"# Design Template Guidance: {design_template_source.name} "
            f"({design_template_source.source_label})\n"
        )
        print(
            render_agent_metadata_preamble(
                artifact_type="design",
                phase="construction",
                spec_name=args.spec_name,
                repo_root=repo_root,
                specs_dir=workflow.specs_dir,
            )
        )
        print(f"{DESIGN_TEMPLATE_GUIDANCE_WARNING}\n")
        print(design_template_source.content)
        return

    if not args.spec_name:
        print("Error: spec_name required for this command")
        sys.exit(1)

    if args.command == "mockup-status":
        result = workflow.get_mockup_status(
            args.spec_name,
            figma_url=args.figma_url,
        )
        print(json.dumps(result, indent=2))
        return

    if args.command == "validate":
        result = workflow.validate_tasks(args.spec_name)
        print(json.dumps(result, indent=2))
        sys.exit(0 if result["valid"] else 1)

    if args.command == "init":
        req_existed = (workflow.specs_dir / args.spec_name / "requirements.md").exists()
        template_source = resolve_template_source(args.template, repo_root)
        if template_source.warning:
            print(f"Warning: {template_source.warning}", file=sys.stderr)
        spec_path = workflow.create_spec_structure(
            args.spec_name,
            template=args.template,
        )
        print(f"✅ Created spec directory: {spec_path}")

        if not req_existed and (spec_path / "requirements.md").exists():
            print(
                "✅ Scaffolded requirements.md starter template: "
                f"{template_source.name} ({template_source.source_label})"
            )

        foundation_status = workflow.validate_foundation()
        missing = [doc for doc, exists in foundation_status.items() if not exists]

        if missing:
            print("\n⚠️  Missing foundation docs:")
            for doc in missing:
                print(f"  ✗ {doc}")
        else:
            print("\n✅ All foundation docs present")

        status = workflow.get_status(args.spec_name)
        print(f"\n📍 Starting at Phase {status['current_phase']}: {status['current_phase_name']}")

    elif args.command == "status":
        status = workflow.get_status(args.spec_name)
        print(f"📊 Spec: {status['spec_name']}")
        print(f"📍 Current Phase: {status['current_phase']} - {status['current_phase_name']}")
        print(f"📁 Path: {status['spec_path']}\n")

        print("Phase Status:")
        for phase_num, phase_info in status["phase_status"].items():
            icon = "✅" if phase_info["completed"] else "🔄" if phase_num == status["current_phase"] else "⏳"
            print(f"  {icon} Phase {phase_num}: {phase_info['name']} - {phase_info['file']}")

        print("\nFoundation Docs:")
        for doc, exists in status["foundation_docs"].items():
            icon = "✅" if exists else "✗"
            print(f"  {icon} {doc}")

    elif args.command == "complete":
        if not args.task_number:
            print("Error: task_number required for complete command")
            sys.exit(1)

        try:
            success = workflow.mark_task_complete(args.spec_name, args.task_number)
            if success:
                print(f"✅ Marked task {args.task_number} as complete in {args.spec_name}")
            else:
                print(f"⚠️  Task {args.task_number} not found or already completed")
        except FileNotFoundError as e:
            print(f"❌ {e}")
            sys.exit(1)

    elif args.command == "progress":
        try:
            progress = workflow.get_task_progress(args.spec_name)
            print(f"📊 Progress for: {progress['spec_name']}")
            print(f"✅ Completed: {progress['completed']}/{progress['total']} ({progress['percentage']}%)")
            print(f"⏳ Pending: {progress['pending']}")
        except FileNotFoundError as e:
            print(f"❌ {e}")
            sys.exit(1)


if __name__ == "__main__":
    main()
