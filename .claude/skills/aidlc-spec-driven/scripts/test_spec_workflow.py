#!/usr/bin/env python3
"""Tests for spec_workflow.py"""

import unittest
import tempfile
import shutil
import sys
import subprocess
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from spec_workflow import (
    SpecWorkflow,
    SUPPORTED_DESIGN_TEMPLATES,
    SUPPORTED_TASK_TEMPLATES,
    SUPPORTED_TEMPLATES,
    find_extension_config_path,
    get_design_template_path,
    get_task_template_path,
    get_template_path,
    parse_requirements_criteria,
    resolve_design_template_source,
    resolve_docs_root,
    resolve_execution_approach,
    resolve_task_template_source,
    resolve_template_source,
)


SCRIPT_PATH = Path(__file__).resolve().parent / "spec_workflow.py"
PHASE4_SUBAGENT_REFERENCE = (
    Path(__file__).resolve().parent.parent
    / "references"
    / "phase-4-subagent-execution.md"
)


class TestSpecWorkflow(unittest.TestCase):
    """Test SpecWorkflow functionality"""

    def setUp(self):
        """Create temporary test environment"""
        self.test_dir = Path(tempfile.mkdtemp())
        self.foundation_dir = self.test_dir / "aidlc-docs" / "foundation"
        self.specs_dir = self.test_dir / "aidlc-docs" / "specs"

        # Create foundation directory
        self.foundation_dir.mkdir(parents=True, exist_ok=True)

        self.workflow = SpecWorkflow(self.test_dir)

    def tearDown(self):
        """Clean up test environment"""
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir)

    def test_phase4_implementer_spawn_contract_requires_type_and_model(self):
        """Implementer spawn template must not silently inherit agent/model."""
        content = PHASE4_SUBAGENT_REFERENCE.read_text()

        self.assertIn("subagent_type: ai-orchestration-engineer", content)
        self.assertIn("model: [MODEL — REQUIRED:", content)
        self.assertIn("silently inherits the session model", content)
        self.assertIn("architectural decision with multiple valid approaches", content)
        self.assertIn("Continued file exploration is not producing clarity", content)

    def write_extension_config(self, template, custom_path=None):
        """Write a minimal extension-config.json for template resolution tests."""
        config_dir = self.test_dir / ".mtv-aidlc"
        config_dir.mkdir(parents=True, exist_ok=True)
        custom_value = "null" if custom_path is None else f'"{custom_path}"'
        (config_dir / "extension-config.json").write_text(
            "{\n"
            '  "userStory": {\n'
            f'    "template": "{template}",\n'
            f'    "customTemplatePath": {custom_value}\n'
            "  }\n"
            "}\n"
        )

    def write_task_extension_config(self, template, custom_path=None):
        """Write a minimal extension-config.json for task template tests."""
        config_dir = self.test_dir / ".mtv-aidlc"
        config_dir.mkdir(parents=True, exist_ok=True)
        custom_value = "null" if custom_path is None else f'"{custom_path}"'
        (config_dir / "extension-config.json").write_text(
            "{\n"
            '  "implementationTask": {\n'
            f'    "template": "{template}",\n'
            f'    "customTemplatePath": {custom_value}\n'
            "  }\n"
            "}\n"
        )

    def write_design_extension_config(self, template, custom_path=None):
        """Write a minimal extension-config.json for design template tests."""
        config_dir = self.test_dir / ".mtv-aidlc"
        config_dir.mkdir(parents=True, exist_ok=True)
        custom_value = "null" if custom_path is None else f'"{custom_path}"'
        (config_dir / "extension-config.json").write_text(
            "{\n"
            '  "designDocument": {\n'
            f'    "template": "{template}",\n'
            f'    "customTemplatePath": {custom_value}\n'
            "  }\n"
            "}\n"
        )

    def write_malformed_extension_config(self):
        """Write malformed extension-config.json."""
        config_dir = self.test_dir / ".mtv-aidlc"
        config_dir.mkdir(parents=True, exist_ok=True)
        (config_dir / "extension-config.json").write_text("{ not valid json")

    def write_empty_extension_config(self):
        """Write valid config without template settings."""
        config_dir = self.test_dir / ".mtv-aidlc"
        config_dir.mkdir(parents=True, exist_ok=True)
        (config_dir / "extension-config.json").write_text("{}\n")

    def make_child_app_dir(self):
        """Create a child app with its own aidlc-docs but no extension config."""
        child_dir = self.test_dir / "apps" / "child-app"
        (child_dir / "aidlc-docs").mkdir(parents=True, exist_ok=True)
        return child_dir

    def test_validate_foundation_empty(self):
        """Test foundation validation with no docs"""
        status = self.workflow.validate_foundation()
        self.assertEqual(len(status), 5)
        self.assertFalse(any(status.values()))

    def test_validate_foundation_partial(self):
        """Test foundation validation with some docs"""
        # Create some foundation docs
        (self.foundation_dir / "project-overview-pdr.md").touch()
        (self.foundation_dir / "system-architecture.md").touch()

        status = self.workflow.validate_foundation()
        self.assertTrue(status["project-overview-pdr.md"])
        self.assertTrue(status["system-architecture.md"])
        self.assertFalse(status["code-standards.md"])

    def test_create_spec_structure(self):
        """Test spec directory creation"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        self.assertTrue(spec_path.exists())
        self.assertEqual(spec_path.name, "test-feature")

    def test_create_spec_structure_scaffolds_default_template(self):
        """Test default requirements scaffold creation"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        content = (spec_path / "requirements.md").read_text()

        self.assertIn("# Requirements: Test Feature", content)
        self.assertIn("1.1 WHEN [context/trigger] THEN system SHALL", content)
        self.assertIn("## Next Steps", content)

    def test_init_scaffolds_requirements_with_frontmatter(self):
        """init creates requirements.md with required metadata fields."""
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "init",
                "metadata-contract",
                "--repo-root",
                str(self.test_dir),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0)

        content = (
            self.specs_dir / "metadata-contract" / "requirements.md"
        ).read_text()

        self.assertTrue(content.startswith("---\n"))
        self.assertIn("artifact_type: requirements\n", content)
        self.assertIn("phase: construction\n", content)
        self.assertIn("unit: metadata-contract\n", content)
        self.assertIn("status: draft\n", content)
        self.assertIn("source_artifacts: []\n", content)
        self.assertRegex(content, r"(?m)^created: \d{4}-\d{2}-\d{2}$")
        self.assertRegex(content, r"(?m)^updated: \d{4}-\d{2}-\d{2}$")

    def test_create_spec_structure_scaffolds_checklist_template(self):
        """Test checklist requirements scaffold creation"""
        spec_path = self.workflow.create_spec_structure(
            "test-feature",
            template="checklist",
        )
        content = (spec_path / "requirements.md").read_text()

        self.assertIn("**Acceptance Criteria**", content)
        self.assertIn("- [ ] **1.1**", content)
        self.assertIn("### 2. [Category / Validation & Edge Cases]", content)

    def test_create_spec_structure_scaffolds_given_when_then_template(self):
        """Test Given/When/Then requirements scaffold creation"""
        spec_path = self.workflow.create_spec_structure(
            "test-feature",
            template="given-when-then-table",
        )
        content = (spec_path / "requirements.md").read_text()

        self.assertIn("| No. | Scenario | Given | When | Then |", content)
        self.assertIn("| 1.1 | [Scenario name]", content)
        self.assertIn("**Feature 2: [Another feature name]**", content)

    def test_create_spec_structure_rejects_invalid_template(self):
        """Test invalid template rejection"""
        with self.assertRaises(ValueError) as ctx:
            self.workflow.create_spec_structure(
                "test-feature",
                template="unknown-template",
            )

        message = str(ctx.exception)
        self.assertIn("Unsupported template 'unknown-template'", message)
        for template_name in SUPPORTED_TEMPLATES:
            self.assertIn(template_name, message)
        self.assertFalse((self.specs_dir / "test-feature").exists())

    def test_create_spec_structure_uses_config_template_when_omitted(self):
        """Omitted template reads extension config."""
        self.write_extension_config("checklist")

        spec_path = self.workflow.create_spec_structure("configured-feature")
        content = (spec_path / "requirements.md").read_text()

        self.assertIn("# Requirements: Configured Feature", content)
        self.assertIn("- [ ] **1.1**", content)

    def test_resolve_requirements_template_finds_root_config_from_child_app(self):
        """Config lookup walks upward from child app projects."""
        self.write_extension_config("checklist")
        child_dir = self.make_child_app_dir()

        template = resolve_template_source(None, child_dir)

        self.assertEqual(
            find_extension_config_path(child_dir),
            (self.test_dir / ".mtv-aidlc" / "extension-config.json").resolve(),
        )
        self.assertEqual(template.name, "checklist")
        self.assertEqual(template.source_label, "config:checklist")

    def test_create_spec_structure_explicit_builtin_overrides_config(self):
        """Explicit built-in template bypasses configured template."""
        self.write_extension_config("checklist")

        spec_path = self.workflow.create_spec_structure(
            "explicit-feature",
            template="given-when-then-table",
        )
        content = (spec_path / "requirements.md").read_text()

        self.assertIn("| No. | Scenario | Given | When | Then |", content)
        self.assertNotIn("- [ ] **1.1**", content)

    def test_create_spec_structure_custom_template_from_config(self):
        """Custom template loads userStory.customTemplatePath relative to repo root."""
        custom_dir = self.test_dir / ".mtv-aidlc" / "templates" / "user-story"
        custom_dir.mkdir(parents=True, exist_ok=True)
        custom_file = custom_dir / "custom.md"
        custom_file.write_text(
            "```markdown\n"
            "### US-{ID}: Custom Requirement Story\n\n"
            "**User Story**: As a {persona}, I want {capability}, so that {benefit}\n\n"
            "**Acceptance Criteria**\n\n"
            "- [ ] **1.1** Custom spec criterion from config\n"
            "```\n"
        )
        self.write_extension_config(
            "custom",
            ".mtv-aidlc/templates/user-story/custom.md",
        )

        spec_path = self.workflow.create_spec_structure(
            "custom-feature",
            template="custom",
        )
        content = (spec_path / "requirements.md").read_text()

        self.assertIn("# Requirements: Custom Feature", content)
        self.assertIn("## Requirements", content)
        self.assertIn("### US-1: Custom Requirement Story", content)
        self.assertIn("Custom spec criterion from config", content)
        self.assertIn("## Next Steps", content)

    def test_create_spec_structure_custom_template_whole_file(self):
        """Custom templates do not require fenced markdown blocks."""
        custom_file = self.test_dir / "custom-whole.md"
        custom_file.write_text(
            "### US-{ID}: Whole File Requirement Story\n\n"
            "**Acceptance Criteria**\n\n"
            "- [ ] **1.1** Whole file custom spec criterion\n"
        )
        self.write_extension_config("custom", "custom-whole.md")

        spec_path = self.workflow.create_spec_structure("whole-custom-feature")
        content = (spec_path / "requirements.md").read_text()

        self.assertIn("### US-1: Whole File Requirement Story", content)
        self.assertIn("Whole file custom spec criterion", content)

    def test_create_spec_structure_missing_config_falls_back_to_default(self):
        """Missing extension config falls back to default template."""
        spec_path = self.workflow.create_spec_structure("missing-config-feature")
        content = (spec_path / "requirements.md").read_text()

        self.assertIn("1.1 WHEN [context/trigger] THEN system SHALL", content)

    def test_resolve_requirements_template_defaults_when_config_missing(self):
        """Missing requirements config falls back to default."""
        template = resolve_template_source(None, self.test_dir)

        self.assertEqual(template.name, "default")
        self.assertIsNone(template.warning)
        self.assertIn("1.1 WHEN [context/trigger] THEN system SHALL", template.content)

    def test_resolve_requirements_template_missing_setting_falls_back_to_default(self):
        """Config without userStory.template falls back to default."""
        self.write_empty_extension_config()

        template = resolve_template_source(None, self.test_dir)

        self.assertEqual(template.name, "default")
        self.assertIsNone(template.warning)
        self.assertIn("1.1 WHEN [context/trigger] THEN system SHALL", template.content)

    def test_resolve_requirements_template_malformed_config_falls_back_to_default(self):
        """Malformed extension config warns and falls back to default."""
        self.write_malformed_extension_config()

        template = resolve_template_source(None, self.test_dir)

        self.assertEqual(template.name, "default")
        self.assertIn("Malformed .mtv-aidlc/extension-config.json", template.warning)
        self.assertIn("1.1 WHEN [context/trigger] THEN system SHALL", template.content)

    def test_create_spec_structure_invalid_custom_falls_back_to_default(self):
        """Invalid custom config falls back to default template."""
        self.write_extension_config(
            "custom",
            ".mtv-aidlc/templates/user-story/missing.md",
        )

        spec_path = self.workflow.create_spec_structure("missing-custom-feature")
        content = (spec_path / "requirements.md").read_text()

        self.assertIn("1.1 WHEN [context/trigger] THEN system SHALL", content)
        self.assertNotIn("Custom spec criterion", content)

    def test_shared_story_blocks_do_not_include_spec_wrapper(self):
        """Shared story blocks must not contain spec-only wrapper sections"""
        for template_name in SUPPORTED_TEMPLATES:
            content = get_template_path(template_name).read_text()

            self.assertNotIn("# Requirements:", content)
            self.assertNotIn("## Introduction", content)
            self.assertNotIn("## Next Steps", content)

    def test_requirements_scaffold_composes_wrapper_and_shared_block(self):
        """Spec scaffold includes wrapper sections and selected shared story block"""
        spec_path = self.workflow.create_spec_structure(
            "test-feature",
            template="given-when-then-table",
        )
        content = (spec_path / "requirements.md").read_text()

        self.assertIn("# Requirements: Test Feature", content)
        self.assertIn("## Introduction", content)
        self.assertIn("## Requirements", content)
        self.assertIn("| No. | Scenario | Given | When | Then |", content)
        self.assertIn("## Next Steps", content)

    def test_resolve_design_template_defaults_when_config_missing(self):
        """Missing design config silently falls back to standard."""
        template = resolve_design_template_source(None, self.test_dir)

        self.assertEqual(template.name, "standard")
        self.assertIsNone(template.warning)
        self.assertIn("## Template Structure", template.content)
        self.assertIn("## Open Questions", template.content)

    def test_resolve_design_template_missing_setting_falls_back_to_standard(self):
        """Config without designDocument.template falls back to standard."""
        self.write_empty_extension_config()

        template = resolve_design_template_source(None, self.test_dir)

        self.assertEqual(template.name, "standard")
        self.assertIsNone(template.warning)
        self.assertIn("## Template Structure", template.content)

    def test_resolve_design_template_uses_config_when_omitted(self):
        """Omitted design template reads designDocument config."""
        self.write_design_extension_config("standard")

        template = resolve_design_template_source(None, self.test_dir)

        self.assertEqual(template.name, "standard")
        self.assertEqual(template.source_label, "config:standard")
        self.assertIn("## Template Structure", template.content)

    def test_resolve_design_template_explicit_builtin_overrides_config(self):
        """Explicit design template bypasses configured design template."""
        self.write_design_extension_config("custom", ".mtv-aidlc/templates/design/custom.md")

        template = resolve_design_template_source("standard", self.test_dir)

        self.assertEqual(template.name, "standard")
        self.assertEqual(template.source_label, "built-in:standard")
        self.assertIn("| Test level | What to verify |", template.content)

    def test_resolve_design_template_explicit_lean_builtin(self):
        """Explicit lean design template loads lean guidance."""
        template = resolve_design_template_source("lean", self.test_dir)

        self.assertEqual(template.name, "lean")
        self.assertEqual(template.source_label, "built-in:lean")
        self.assertIn("## Template Structure", template.content)
        self.assertIn("## Codebase Alignment", template.content)
        self.assertIn("## Decisions & Open Questions", template.content)

    def test_resolve_design_template_lean_from_config(self):
        """Configured lean design template resolves without explicit flag."""
        self.write_design_extension_config("lean")

        template = resolve_design_template_source(None, self.test_dir)

        self.assertEqual(template.name, "lean")
        self.assertEqual(template.source_label, "config:lean")
        self.assertIn("## Codebase Alignment", template.content)

    def test_resolve_design_template_rejects_invalid_explicit_value(self):
        """Invalid explicit design template is rejected."""
        with self.assertRaises(ValueError) as ctx:
            resolve_design_template_source("unknown-design-template", self.test_dir)

        message = str(ctx.exception)
        self.assertIn("Unsupported design template 'unknown-design-template'", message)
        for template_name in SUPPORTED_DESIGN_TEMPLATES:
            self.assertIn(template_name, message)

    def test_resolve_design_template_invalid_config_falls_back_to_standard(self):
        """Unsupported configured design template warns and falls back to standard."""
        self.write_design_extension_config("unsupported-template")

        template = resolve_design_template_source(None, self.test_dir)

        self.assertEqual(template.name, "standard")
        self.assertIn("Unsupported configured design template", template.warning)
        self.assertIn("falling back to standard", template.warning)

    def test_resolve_design_template_malformed_config_falls_back_to_standard(self):
        """Malformed extension config warns and falls back to standard."""
        self.write_malformed_extension_config()

        template = resolve_design_template_source(None, self.test_dir)

        self.assertEqual(template.name, "standard")
        self.assertIn("Malformed .mtv-aidlc/extension-config.json", template.warning)
        self.assertIn("## Template Structure", template.content)

    def test_resolve_design_template_custom_from_config(self):
        """Custom design template loads full design guidance."""
        custom_dir = self.test_dir / ".mtv-aidlc" / "templates" / "design"
        custom_dir.mkdir(parents=True, exist_ok=True)
        custom_file = custom_dir / "custom.md"
        custom_file.write_text(
            "# Custom Design Guidance\n\n"
            "```markdown\n"
            "## Custom Architecture Notes\n"
            "[Custom section guidance]\n"
            "```\n\n"
            "## Rules\n\n"
            "1. Keep custom design policy visible in stdout guidance.\n"
        )
        self.write_design_extension_config(
            "custom",
            ".mtv-aidlc/templates/design/custom.md",
        )

        template = resolve_design_template_source("custom", self.test_dir)

        self.assertEqual(template.name, "custom")
        self.assertIn("# Custom Design Guidance", template.content)
        self.assertIn("Custom Architecture Notes", template.content)
        self.assertIn("Keep custom design policy visible", template.content)

    def test_resolve_design_template_configured_custom_from_config(self):
        """Omitted design template loads configured custom guidance."""
        custom_dir = self.test_dir / ".mtv-aidlc" / "templates" / "design"
        custom_dir.mkdir(parents=True, exist_ok=True)
        custom_file = custom_dir / "custom.md"
        custom_file.write_text("# Configured Custom Design Guidance\n")
        self.write_design_extension_config(
            "custom",
            ".mtv-aidlc/templates/design/custom.md",
        )

        template = resolve_design_template_source(None, self.test_dir)

        self.assertEqual(template.name, "custom")
        self.assertIn("Configured Custom Design Guidance", template.content)

    def test_resolve_design_custom_path_relative_to_root_config_from_child_app(self):
        """Custom design paths are relative to the root config location."""
        custom_dir = self.test_dir / ".mtv-aidlc" / "templates" / "design"
        custom_dir.mkdir(parents=True, exist_ok=True)
        custom_file = custom_dir / "custom.md"
        custom_file.write_text("# Root Custom Design Guidance\n")
        self.write_design_extension_config(
            "custom",
            ".mtv-aidlc/templates/design/custom.md",
        )
        child_dir = self.make_child_app_dir()

        template = resolve_design_template_source(None, child_dir)

        self.assertEqual(template.name, "custom")
        self.assertIn("Root Custom Design Guidance", template.content)

    def test_resolve_design_template_invalid_custom_falls_back_to_standard(self):
        """Invalid custom design template falls back to standard."""
        self.write_design_extension_config(
            "custom",
            ".mtv-aidlc/templates/design/missing.md",
        )

        template = resolve_design_template_source(None, self.test_dir)

        self.assertEqual(template.name, "standard")
        self.assertIn("falling back to standard", template.warning)
        self.assertIn("## Template Structure", template.content)

    def test_local_design_blocks_do_not_include_approval_or_next_steps(self):
        """Local design blocks must not contain phase approval boilerplate."""
        for template_name in SUPPORTED_DESIGN_TEMPLATES:
            content = get_design_template_path(template_name).read_text()

            self.assertNotIn("Does the design look good?", content)
            self.assertNotIn("## Next Steps", content)
            self.assertNotIn("/aidlc.construction.create-tasks", content)

    def test_all_builtin_design_templates_render(self):
        """All built-in design templates resolve full guidance."""
        for template_name in SUPPORTED_DESIGN_TEMPLATES:
            template = resolve_design_template_source(template_name, self.test_dir)

            self.assertEqual(template.name, template_name)
            self.assertTrue(template.content.strip())
            self.assertIn("## Template Structure", template.content)
            self.assertIn("## Rules", template.content)
            # Every built-in design guidance must keep a visible home for
            # open questions (standard uses "## Open Questions"; lean uses
            # "## Decisions & Open Questions" near the top, after Summary).
            self.assertIn("Open Questions", template.content)

    def test_design_template_cli_prints_full_guidance(self):
        """design-template prints guidance warning, structure, and rules."""
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "design-template",
                "--design-template",
                "standard",
                "--repo-root",
                str(self.test_dir),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0)
        self.assertIn("# Design Template Guidance: standard", result.stdout)
        self.assertIn("Guidance only. Do not paste this output directly", result.stdout)
        self.assertIn("## Template Structure", result.stdout)
        self.assertIn("## Rules", result.stdout)
        self.assertFalse((self.specs_dir / "cli-design-scaffold").exists())

    def test_design_template_cli_warns_and_falls_back_for_malformed_config(self):
        """design-template warns and prints standard guidance for malformed config."""
        self.write_malformed_extension_config()

        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "design-template",
                "--repo-root",
                str(self.test_dir),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0)
        self.assertIn("Warning: Malformed .mtv-aidlc/extension-config.json", result.stderr)
        self.assertIn("# Design Template Guidance: standard", result.stdout)
        self.assertIn("## Template Structure", result.stdout)
        self.assertFalse((self.specs_dir / "cli-design-scaffold").exists())

    def test_resolve_task_template_defaults_when_config_missing(self):
        """Missing implementation task config silently falls back to test-first."""
        template = resolve_task_template_source(None, self.test_dir)

        self.assertEqual(template.name, "test-first")
        self.assertIsNone(template.warning)
        self.assertIn("Write the failing test", template.content)

    def test_resolve_task_template_missing_setting_falls_back_to_test_first(self):
        """Config without implementationTask.template falls back to test-first."""
        self.write_empty_extension_config()

        template = resolve_task_template_source(None, self.test_dir)

        self.assertEqual(template.name, "test-first")
        self.assertIsNone(template.warning)
        self.assertIn("Write the failing test", template.content)

    def test_resolve_task_template_uses_config_when_omitted(self):
        """Omitted task template reads implementationTask config."""
        self.write_task_extension_config("implement-with-tests")

        template = resolve_task_template_source(None, self.test_dir)

        self.assertEqual(template.name, "implement-with-tests")
        self.assertIn("Coverage target", template.content)
        self.assertIn("Test cases:", template.content)

    def test_resolve_task_template_explicit_builtin_overrides_config(self):
        """Explicit task template bypasses configured task template."""
        self.write_task_extension_config("tests-later")

        template = resolve_task_template_source("test-first", self.test_dir)

        self.assertEqual(template.name, "test-first")
        self.assertIn("Write the failing test", template.content)
        self.assertNotIn("Leave clear test seams", template.content)

    def test_resolve_task_template_supports_tests_later(self):
        """Tests-later template can be selected explicitly."""
        template = resolve_task_template_source("tests-later", self.test_dir)

        self.assertEqual(template.name, "tests-later")
        self.assertIn("Leave clear test seams", template.content)
        self.assertIn("Add automated coverage", template.content)

    def test_resolve_task_template_rejects_invalid_explicit_value(self):
        """Invalid explicit task template is rejected."""
        with self.assertRaises(ValueError) as ctx:
            resolve_task_template_source("unknown-task-template", self.test_dir)

        message = str(ctx.exception)
        self.assertIn("Unsupported task template 'unknown-task-template'", message)
        for template_name in SUPPORTED_TASK_TEMPLATES:
            self.assertIn(template_name, message)

    def test_resolve_task_template_invalid_config_falls_back_to_test_first(self):
        """Unsupported configured task template warns and falls back to test-first."""
        self.write_task_extension_config("unsupported-template")

        template = resolve_task_template_source(None, self.test_dir)

        self.assertEqual(template.name, "test-first")
        self.assertIn("Unsupported configured task template", template.warning)
        self.assertIn("falling back to test-first", template.warning)

    def test_resolve_task_template_malformed_config_falls_back_to_test_first(self):
        """Malformed extension config warns and falls back to test-first."""
        self.write_malformed_extension_config()

        template = resolve_task_template_source(None, self.test_dir)

        self.assertEqual(template.name, "test-first")
        self.assertIn("Malformed .mtv-aidlc/extension-config.json", template.warning)
        self.assertIn("Write the failing test", template.content)

    def test_resolve_task_template_custom_from_config(self):
        """Custom task template loads full implementationTask guidance."""
        custom_dir = self.test_dir / ".mtv-aidlc" / "templates" / "tasks"
        custom_dir.mkdir(parents=True, exist_ok=True)
        custom_file = custom_dir / "custom.md"
        custom_file.write_text(
            "# Custom Task Guidance\n\n"
            "```markdown\n"
            "- [ ] {N}. Custom task format\n"
            "  - Reference: US-{n} AC-{section}.{criterion}\n"
            "```\n\n"
            "## Rules\n\n"
            "1. Keep custom policy visible in stdout guidance.\n"
        )
        self.write_task_extension_config(
            "custom",
            ".mtv-aidlc/templates/tasks/custom.md",
        )

        template = resolve_task_template_source("custom", self.test_dir)

        self.assertEqual(template.name, "custom")
        self.assertIn("# Custom Task Guidance", template.content)
        self.assertIn("Custom task format", template.content)
        self.assertIn("Keep custom policy visible", template.content)

    def test_resolve_task_template_configured_custom_from_config(self):
        """Omitted task template loads configured custom guidance."""
        custom_dir = self.test_dir / ".mtv-aidlc" / "templates" / "tasks"
        custom_dir.mkdir(parents=True, exist_ok=True)
        custom_file = custom_dir / "custom.md"
        custom_file.write_text("# Configured Custom Task Guidance\n")
        self.write_task_extension_config(
            "custom",
            ".mtv-aidlc/templates/tasks/custom.md",
        )

        template = resolve_task_template_source(None, self.test_dir)

        self.assertEqual(template.name, "custom")
        self.assertIn("Configured Custom Task Guidance", template.content)

    def test_resolve_task_custom_path_relative_to_root_config_from_child_app(self):
        """Custom task paths are relative to the root config location."""
        custom_dir = self.test_dir / ".mtv-aidlc" / "templates" / "tasks"
        custom_dir.mkdir(parents=True, exist_ok=True)
        custom_file = custom_dir / "custom.md"
        custom_file.write_text("# Root Custom Task Guidance\n")
        self.write_task_extension_config(
            "custom",
            ".mtv-aidlc/templates/tasks/custom.md",
        )
        child_dir = self.make_child_app_dir()

        template = resolve_task_template_source(None, child_dir)

        self.assertEqual(template.name, "custom")
        self.assertIn("Root Custom Task Guidance", template.content)

    def test_resolve_task_template_invalid_custom_falls_back_to_test_first(self):
        """Invalid custom task template falls back to test-first."""
        self.write_task_extension_config(
            "custom",
            ".mtv-aidlc/templates/tasks/missing.md",
        )

        template = resolve_task_template_source(None, self.test_dir)

        self.assertEqual(template.name, "test-first")
        self.assertIn("falling back to test-first", template.warning)
        self.assertIn("Write the failing test", template.content)

    def test_local_task_blocks_do_not_include_full_tasks_wrapper(self):
        """Local task blocks must not contain spec-only task wrapper sections."""
        for template_name in SUPPORTED_TASK_TEMPLATES:
            content = get_task_template_path(template_name).read_text()

            self.assertNotIn("# Tasks:", content)
            self.assertNotIn("## Implementation Checklist", content)
            self.assertNotIn("## Next Steps", content)

    def test_all_builtin_task_templates_render(self):
        """All built-in task templates resolve full guidance."""
        for template_name in SUPPORTED_TASK_TEMPLATES:
            template = resolve_task_template_source(template_name, self.test_dir)

            self.assertEqual(template.name, template_name)
            self.assertTrue(template.content.strip())
            self.assertIn("## Template Structure", template.content)
            self.assertIn("## Rules", template.content)
            self.assertIn("Reference: US-{n} AC-{section}.{criterion}", template.content)

    def test_task_blocks_have_fenced_markdown_scaffolds(self):
        """Task block references expose a fenced markdown scaffold."""
        for template_name in SUPPORTED_TASK_TEMPLATES:
            content = get_task_template_path(template_name).read_text()

            self.assertIn("```markdown", content)
            self.assertGreaterEqual(content.count("```"), 2)

    def test_task_blocks_show_heading_group_titles(self):
        """Task block references show grouped samples with non-checkbox headings."""
        for template_name in SUPPORTED_TASK_TEMPLATES:
            content = get_task_template_path(template_name).read_text()

            self.assertIn("### {N}. {Group task title}", content)
            self.assertNotIn("- [ ] {N}. {Group task title}", content)

    def test_implement_with_tests_template_keeps_tests_with_implementation(self):
        """Implement-with-tests requires same-task test paths and cases."""
        content = get_task_template_path("implement-with-tests").read_text()

        self.assertIn("tests MUST be included inside the same checkbox task", content)
        self.assertIn("Test file:", content)
        self.assertIn("Test cases:", content)

    def test_tests_later_template_requires_implementation_to_test_traceability(self):
        """Tests-later requires traceability from implementation to later tests."""
        content = get_task_template_path("tests-later").read_text()

        self.assertIn("Leave clear test seams for later coverage in task {N}.2", content)
        self.assertIn("Every implementation task MUST name the later test task", content)

    def test_phase_3_guidance_allows_optional_related_task_grouping(self):
        """Phase 3 guidance supports grouping related tasks without template changes."""
        skill_dir = Path(__file__).resolve().parents[1]
        content = (skill_dir / "references" / "phase-3-tasks.md").read_text()

        self.assertIn("group headings", content)
        self.assertIn("group titles do not need checkboxes", content)
        self.assertIn("do not need groups", content)
        self.assertIn("naturally flat plans", content)

    def test_tasks_template_cli_prints_full_guidance(self):
        """tasks-template prints guidance warning, structure, and rules."""
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "tasks-template",
                "--task-template",
                "implement-with-tests",
                "--repo-root",
                str(self.test_dir),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0)
        self.assertIn("# Task Template Guidance: implement-with-tests", result.stdout)
        self.assertIn("Guidance only. Do not paste this output directly", result.stdout)
        self.assertIn("## Template Structure", result.stdout)
        self.assertIn("## Rules", result.stdout)
        self.assertIn("Coverage target", result.stdout)
        self.assertNotIn("# Tasks:", result.stdout)
        self.assertNotIn("## Next Steps", result.stdout)

    def test_tasks_template_cli_warns_and_falls_back_for_malformed_config(self):
        """tasks-template warns and prints test-first guidance for malformed config."""
        self.write_malformed_extension_config()

        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "tasks-template",
                "--repo-root",
                str(self.test_dir),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0)
        self.assertIn("Warning: Malformed .mtv-aidlc/extension-config.json", result.stderr)
        self.assertIn("# Task Template Guidance: test-first", result.stdout)
        self.assertIn("Write the failing test", result.stdout)
        self.assertFalse((self.specs_dir / "cli-task-scaffold").exists())

    def test_create_spec_structure_does_not_overwrite_existing_requirements(self):
        """Test existing requirements are preserved"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        req_file = spec_path / "requirements.md"
        req_file.write_text("# Existing Requirements\n\nKeep this content.\n")

        self.workflow.create_spec_structure("test-feature", template="checklist")

        self.assertEqual(
            req_file.read_text(),
            "# Existing Requirements\n\nKeep this content.\n",
        )

    def test_get_current_phase_no_spec(self):
        """Test phase detection with no spec"""
        phase = self.workflow.get_current_phase("nonexistent")
        self.assertEqual(phase, 1)

    def test_get_current_phase_requirements_only(self):
        """Test phase detection with only requirements"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        (spec_path / "requirements.md").touch()

        phase = self.workflow.get_current_phase("test-feature")
        self.assertEqual(phase, 2)

    def test_get_current_phase_design_only(self):
        """Test phase detection with requirements and design"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        (spec_path / "requirements.md").touch()
        (spec_path / "design.md").touch()

        phase = self.workflow.get_current_phase("test-feature")
        self.assertEqual(phase, 3)

    def test_get_current_phase_all_docs(self):
        """Test phase detection with all docs"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        (spec_path / "requirements.md").touch()
        (spec_path / "design.md").touch()
        (spec_path / "tasks.md").touch()

        phase = self.workflow.get_current_phase("test-feature")
        self.assertEqual(phase, 4)

    def test_get_status(self):
        """Test status report generation"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        (spec_path / "requirements.md").touch()

        status = self.workflow.get_status("test-feature")

        self.assertEqual(status["spec_name"], "test-feature")
        self.assertEqual(status["current_phase"], 2)
        self.assertEqual(status["current_phase_name"], "Design")
        self.assertTrue(status["phase_status"][1]["exists"])
        self.assertFalse(status["phase_status"][2]["exists"])

    def test_list_specs_empty(self):
        """Test listing specs when none exist"""
        specs = self.workflow.list_specs()
        self.assertEqual(specs, [])

    def test_list_specs_multiple(self):
        """Test listing multiple specs"""
        self.workflow.create_spec_structure("feature-1")
        self.workflow.create_spec_structure("feature-2")
        self.workflow.create_spec_structure("feature-3")

        specs = self.workflow.list_specs()
        self.assertEqual(len(specs), 3)
        self.assertIn("feature-1", specs)
        self.assertIn("feature-2", specs)
        self.assertIn("feature-3", specs)

    def test_mark_task_complete_top_level(self):
        """Test marking a top-level task as complete"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        tasks_file = spec_path / "tasks.md"
        tasks_file.write_text("""# Tasks: Test Feature

- [ ] 1. First task
- [ ] 2. Second task
- [ ] 3. Third task
""")

        success = self.workflow.mark_task_complete("test-feature", "2")
        self.assertTrue(success)

        content = tasks_file.read_text()
        self.assertIn("- [x] 2. Second task", content)
        self.assertIn("- [ ] 1. First task", content)
        self.assertIn("- [ ] 3. Third task", content)

    def test_mark_task_complete_subtask(self):
        """Test marking a sub-task as complete"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        tasks_file = spec_path / "tasks.md"
        tasks_file.write_text("""# Tasks: Test Feature

- [ ] 1. Main task
  - [ ] 1.1 Subtask one
  - [ ] 1.2 Subtask two
- [ ] 2. Another task
""")

        success = self.workflow.mark_task_complete("test-feature", "1.1")
        self.assertTrue(success)

        content = tasks_file.read_text()
        self.assertIn("- [x] 1.1 Subtask one", content)
        self.assertIn("- [ ] 1.2 Subtask two", content)

    def test_mark_task_complete_nonexistent(self):
        """Test marking a non-existent task"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        tasks_file = spec_path / "tasks.md"
        tasks_file.write_text("""# Tasks: Test Feature

- [ ] 1. First task
- [ ] 2. Second task
""")

        success = self.workflow.mark_task_complete("test-feature", "99")
        self.assertFalse(success)

    def test_mark_task_complete_already_done(self):
        """Test marking an already completed task"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        tasks_file = spec_path / "tasks.md"
        tasks_file.write_text("""# Tasks: Test Feature

- [x] 1. Already done
- [ ] 2. Second task
""")

        success = self.workflow.mark_task_complete("test-feature", "1")
        self.assertFalse(success)

    def test_mark_task_complete_no_file(self):
        """Test marking task when tasks.md doesn't exist"""
        self.workflow.create_spec_structure("test-feature")

        with self.assertRaises(FileNotFoundError):
            self.workflow.mark_task_complete("test-feature", "1")

    def test_get_task_progress_empty(self):
        """Test progress with no tasks"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        tasks_file = spec_path / "tasks.md"
        tasks_file.write_text("# Tasks: Test Feature\n\nNo tasks yet.")

        progress = self.workflow.get_task_progress("test-feature")
        self.assertEqual(progress["total"], 0)
        self.assertEqual(progress["completed"], 0)
        self.assertEqual(progress["percentage"], 0)

    def test_get_task_progress_partial(self):
        """Test progress with partially completed tasks"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        tasks_file = spec_path / "tasks.md"
        tasks_file.write_text("""# Tasks: Test Feature

- [x] 1. Completed task
- [ ] 2. Pending task
- [x] 3. Another completed
- [ ] 4. Another pending
""")

        progress = self.workflow.get_task_progress("test-feature")
        self.assertEqual(progress["total"], 4)
        self.assertEqual(progress["completed"], 2)
        self.assertEqual(progress["pending"], 2)
        self.assertEqual(progress["percentage"], 50.0)

    def test_get_task_progress_all_complete(self):
        """Test progress with all tasks completed"""
        spec_path = self.workflow.create_spec_structure("test-feature")
        tasks_file = spec_path / "tasks.md"
        tasks_file.write_text("""# Tasks: Test Feature

- [x] 1. First task
- [x] 2. Second task
""")

        progress = self.workflow.get_task_progress("test-feature")
        self.assertEqual(progress["total"], 2)
        self.assertEqual(progress["completed"], 2)
        self.assertEqual(progress["pending"], 0)
        self.assertEqual(progress["percentage"], 100.0)

    def test_get_task_progress_no_file(self):
        """Test progress when tasks.md doesn't exist"""
        self.workflow.create_spec_structure("test-feature")

        with self.assertRaises(FileNotFoundError):
            self.workflow.get_task_progress("test-feature")

    # --- Task 4.1: design-template metadata preamble static-check tests ---

    def test_design_template_with_spec_name_includes_metadata_preamble(self):
        """design-template with spec_name outputs helper-rendered frontmatter before guidance."""
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "design-template",
                "metadata-compliant-artifact-production-rollout",
                "--repo-root",
                str(self.test_dir),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0)
        self.assertIn("artifact_type: design\n", result.stdout)
        self.assertIn("phase: construction\n", result.stdout)
        self.assertIn("status: draft\n", result.stdout)
        self.assertIn(
            "unit: metadata-compliant-artifact-production-rollout\n", result.stdout
        )
        self.assertIn("source_artifacts:\n", result.stdout)
        self.assertIn(
            "  - aidlc-docs/specs/metadata-compliant-artifact-production-rollout/requirements.md\n",
            result.stdout,
        )

        # Metadata preamble must appear before selected design body guidance
        metadata_pos = result.stdout.find("artifact_type: design")
        guidance_pos = result.stdout.find("## Template Structure")
        self.assertGreater(
            guidance_pos,
            metadata_pos,
            "artifact_type: design must appear before ## Template Structure",
        )

    def test_design_template_metadata_preamble_before_custom_guidance(self):
        """design-template with custom template still prepends metadata preamble before custom guidance."""
        custom_dir = self.test_dir / ".mtv-aidlc" / "templates" / "design"
        custom_dir.mkdir(parents=True, exist_ok=True)
        custom_file = custom_dir / "custom.md"
        custom_file.write_text(
            "# Custom Design Guidance\n\n"
            "Custom design body guidance for testing.\n"
        )
        self.write_design_extension_config(
            "custom", ".mtv-aidlc/templates/design/custom.md"
        )

        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "design-template",
                "metadata-compliant-artifact-production-rollout",
                "--repo-root",
                str(self.test_dir),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0)
        self.assertIn("artifact_type: design\n", result.stdout)
        self.assertIn(
            "unit: metadata-compliant-artifact-production-rollout\n", result.stdout
        )
        self.assertIn(
            "  - aidlc-docs/specs/metadata-compliant-artifact-production-rollout/requirements.md\n",
            result.stdout,
        )

        # Metadata preamble must appear before custom guidance body
        metadata_pos = result.stdout.find("artifact_type: design")
        custom_pos = result.stdout.find("Custom design body guidance for testing.")
        self.assertGreater(
            custom_pos,
            metadata_pos,
            "artifact_type: design must appear before custom design body guidance",
        )

    # --- Task 4.4: tasks-template metadata preamble static-check tests ---

    def test_tasks_template_with_spec_name_includes_metadata_preamble(self):
        """tasks-template with spec_name outputs helper-rendered frontmatter before guidance."""
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "tasks-template",
                "metadata-compliant-artifact-production-rollout",
                "--repo-root",
                str(self.test_dir),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0)
        self.assertIn("artifact_type: tasks\n", result.stdout)
        self.assertIn("phase: construction\n", result.stdout)
        self.assertIn("status: draft\n", result.stdout)
        self.assertIn(
            "unit: metadata-compliant-artifact-production-rollout\n", result.stdout
        )
        self.assertIn("source_artifacts:\n", result.stdout)
        self.assertIn(
            "  - aidlc-docs/specs/metadata-compliant-artifact-production-rollout/requirements.md\n",
            result.stdout,
        )
        self.assertIn(
            "  - aidlc-docs/specs/metadata-compliant-artifact-production-rollout/design.md\n",
            result.stdout,
        )

        # Metadata preamble must appear before selected task body guidance
        metadata_pos = result.stdout.find("artifact_type: tasks")
        guidance_pos = result.stdout.find("## Template Structure")
        self.assertGreater(
            guidance_pos,
            metadata_pos,
            "artifact_type: tasks must appear before ## Template Structure",
        )

    def test_tasks_template_metadata_preamble_before_custom_guidance(self):
        """tasks-template with custom template still prepends metadata preamble before custom guidance."""
        custom_dir = self.test_dir / ".mtv-aidlc" / "templates" / "tasks"
        custom_dir.mkdir(parents=True, exist_ok=True)
        custom_file = custom_dir / "custom.md"
        custom_file.write_text(
            "# Custom Task Guidance\n\n"
            "Custom task body guidance for testing.\n"
        )
        self.write_task_extension_config(
            "custom", ".mtv-aidlc/templates/tasks/custom.md"
        )

        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "tasks-template",
                "metadata-compliant-artifact-production-rollout",
                "--repo-root",
                str(self.test_dir),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0)
        self.assertIn("artifact_type: tasks\n", result.stdout)
        self.assertIn(
            "unit: metadata-compliant-artifact-production-rollout\n", result.stdout
        )
        self.assertIn(
            "  - aidlc-docs/specs/metadata-compliant-artifact-production-rollout/requirements.md\n",
            result.stdout,
        )
        self.assertIn(
            "  - aidlc-docs/specs/metadata-compliant-artifact-production-rollout/design.md\n",
            result.stdout,
        )

        # Metadata preamble must appear before custom guidance body
        metadata_pos = result.stdout.find("artifact_type: tasks")
        custom_pos = result.stdout.find("Custom task body guidance for testing.")
        self.assertGreater(
            custom_pos,
            metadata_pos,
            "artifact_type: tasks must appear before custom task body guidance",
        )


class TestMockupStatus(unittest.TestCase):
    """Test deterministic mockup-status resolution"""

    FIGMA_URL = "https://www.figma.com/design/AbC123xyz/Booking-Form?node-id=12-345"

    def setUp(self):
        self.test_dir = Path(tempfile.mkdtemp())
        self.specs_dir = self.test_dir / "aidlc-docs" / "specs"
        self.spec_dir = self.specs_dir / "booking-form"
        self.spec_dir.mkdir(parents=True, exist_ok=True)
        self.workflow = SpecWorkflow(self.test_dir)

    def tearDown(self):
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir)

    def write_mockup(self, file_key="AbC123xyz", node_id="12:345", metadata=True):
        if metadata:
            content = (
                "<!--\n"
                "AIDLC UI Handoff\n"
                "workflow: aidlc-uiux-design\n"
                "artifact_type: mockup\n"
                f"figma_source: https://www.figma.com/design/{file_key}/Booking-Form\n"
                f"figma_file_key: {file_key}\n"
                f"figma_node_id: {node_id}\n"
                "figma_extraction: succeeded:node\n"
                "visual_qa: completed\n"
                "-->\n"
                "<main>mockup body</main>\n"
            )
        else:
            content = "<main>mockup body without metadata</main>\n"
        (self.spec_dir / "mockup.html").write_text(content)

    def test_no_url_no_mockup_is_not_applicable(self):
        result = self.workflow.get_mockup_status("booking-form")
        self.assertEqual(result["mockup_status"], "not-applicable")
        self.assertFalse(result["mockup_exists"])

    def test_no_url_with_mockup_is_pre_existing(self):
        self.write_mockup()
        result = self.workflow.get_mockup_status("booking-form")
        self.assertEqual(result["mockup_status"], "pre-existing")

    def test_url_without_mockup_is_needs_generation(self):
        result = self.workflow.get_mockup_status(
            "booking-form", figma_url=self.FIGMA_URL
        )
        self.assertEqual(result["mockup_status"], "needs-generation")

    def test_matching_metadata_is_pre_existing_fresh(self):
        self.write_mockup()
        result = self.workflow.get_mockup_status(
            "booking-form", figma_url=self.FIGMA_URL
        )
        self.assertEqual(result["mockup_status"], "pre-existing-fresh")
        self.assertEqual(result["metadata_node_id"], "12:345")

    def test_hyphen_node_id_in_metadata_still_fresh(self):
        # Node IDs appear as 12-345 in URLs and 12:345 in the API; both
        # forms must compare equal after normalization.
        self.write_mockup(node_id="12-345")
        result = self.workflow.get_mockup_status(
            "booking-form", figma_url=self.FIGMA_URL
        )
        self.assertEqual(result["mockup_status"], "pre-existing-fresh")

    def test_file_key_mismatch_is_needs_refresh(self):
        self.write_mockup(file_key="DifferentKey9")
        result = self.workflow.get_mockup_status(
            "booking-form", figma_url=self.FIGMA_URL
        )
        self.assertEqual(result["mockup_status"], "needs-refresh")

    def test_node_id_mismatch_is_needs_refresh(self):
        self.write_mockup(node_id="99:1")
        result = self.workflow.get_mockup_status(
            "booking-form", figma_url=self.FIGMA_URL
        )
        self.assertEqual(result["mockup_status"], "needs-refresh")

    def test_missing_metadata_is_needs_refresh(self):
        self.write_mockup(metadata=False)
        result = self.workflow.get_mockup_status(
            "booking-form", figma_url=self.FIGMA_URL
        )
        self.assertEqual(result["mockup_status"], "needs-refresh")
        self.assertFalse(result["metadata_found"])

    def test_none_file_key_metadata_is_needs_refresh(self):
        self.write_mockup(file_key="none", node_id="none")
        # figma_source URL also contains "none" as the key; only the
        # metadata labels matter, and literal none counts as missing.
        result = self.workflow.get_mockup_status(
            "booking-form", figma_url=self.FIGMA_URL
        )
        self.assertEqual(result["mockup_status"], "needs-refresh")
        self.assertIsNone(result["metadata_file_key"])

    def test_url_without_node_id_compares_file_key_only(self):
        self.write_mockup()
        result = self.workflow.get_mockup_status(
            "booking-form",
            figma_url="https://figma.com/file/AbC123xyz/Booking-Form",
        )
        self.assertEqual(result["mockup_status"], "pre-existing-fresh")

    def test_unsupported_board_url_falls_back_to_local_decision(self):
        self.write_mockup()
        result = self.workflow.get_mockup_status(
            "booking-form",
            figma_url="https://www.figma.com/board/AbC123xyz/Workshop",
        )
        self.assertFalse(result["figma_url_supported"])
        self.assertEqual(result["mockup_status"], "pre-existing")
        self.assertIn("not a supported", result["reason"])

    def test_never_emits_unavailable(self):
        # `unavailable` is orchestrator-owned (failed handoff + explicit
        # user approval); the script must never produce it.
        for figma_url in (None, self.FIGMA_URL):
            for has_mockup in (False, True):
                if has_mockup:
                    self.write_mockup()
                else:
                    (self.spec_dir / "mockup.html").unlink(missing_ok=True)
                result = self.workflow.get_mockup_status(
                    "booking-form", figma_url=figma_url
                )
                self.assertNotEqual(result["mockup_status"], "unavailable")

    def test_cli_mockup_status_outputs_json(self):
        self.write_mockup()
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "mockup-status",
                "booking-form",
                "--figma-url",
                self.FIGMA_URL,
                "--repo-root",
                str(self.test_dir),
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        import json
        payload = json.loads(result.stdout)
        self.assertEqual(payload["mockup_status"], "pre-existing-fresh")


class TestDocsRootResolution(unittest.TestCase):
    """Test aidlcDocsPath / --docs-root resolution"""

    def setUp(self):
        # resolve() so expected paths match config discovery, which
        # resolves symlinks (macOS tempdirs live under /private/var).
        self.test_dir = Path(tempfile.mkdtemp()).resolve()

    def tearDown(self):
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir)

    def write_config(self, body: str):
        config_dir = self.test_dir / ".mtv-aidlc"
        config_dir.mkdir(parents=True, exist_ok=True)
        (config_dir / "extension-config.json").write_text(body)

    def test_default_docs_root_without_config(self):
        workflow = SpecWorkflow(self.test_dir)
        self.assertEqual(workflow.docs_root, self.test_dir / "aidlc-docs")
        self.assertEqual(
            workflow.specs_dir, self.test_dir / "aidlc-docs" / "specs"
        )
        self.assertEqual(
            workflow.foundation_dir,
            self.test_dir / "aidlc-docs" / "foundation",
        )

    def test_configured_docs_path_is_honored(self):
        self.write_config('{"aidlcDocsPath": "apps/child-app/aidlc-docs"}\n')
        workflow = SpecWorkflow(self.test_dir)
        expected = self.test_dir / "apps" / "child-app" / "aidlc-docs"
        self.assertEqual(workflow.docs_root, expected)
        self.assertEqual(workflow.specs_dir, expected / "specs")

    def test_relative_path_resolves_against_config_owning_root(self):
        # The config lives at the workspace root; a SpecWorkflow constructed
        # from a child app must still resolve the path against that root.
        self.write_config('{"aidlcDocsPath": "apps/child-app/aidlc-docs"}\n')
        child_dir = self.test_dir / "apps" / "child-app"
        child_dir.mkdir(parents=True, exist_ok=True)
        workflow = SpecWorkflow(child_dir)
        self.assertEqual(
            workflow.docs_root,
            self.test_dir / "apps" / "child-app" / "aidlc-docs",
        )

    def test_absolute_configured_path_is_honored(self):
        absolute = self.test_dir / "elsewhere" / "docs"
        self.write_config(
            '{"aidlcDocsPath": "' + str(absolute) + '"}\n'
        )
        workflow = SpecWorkflow(self.test_dir)
        self.assertEqual(workflow.docs_root, absolute)

    def test_explicit_docs_root_overrides_config(self):
        self.write_config('{"aidlcDocsPath": "apps/child-app/aidlc-docs"}\n')
        workflow = SpecWorkflow(self.test_dir, docs_root=Path("aidlc-docs"))
        self.assertEqual(workflow.docs_root, self.test_dir / "aidlc-docs")

    def test_malformed_config_falls_back_to_default(self):
        self.write_config("{ not valid json")
        workflow = SpecWorkflow(self.test_dir)
        self.assertEqual(workflow.docs_root, self.test_dir / "aidlc-docs")

    def test_empty_or_multiline_config_value_falls_back(self):
        for raw in ('""', '"   "', '"a\\nb"', "123"):
            self.write_config('{"aidlcDocsPath": ' + raw + "}\n")
            workflow = SpecWorkflow(self.test_dir)
            self.assertEqual(
                workflow.docs_root,
                self.test_dir / "aidlc-docs",
                f"raw value {raw} should fall back to default",
            )

    def test_resolve_docs_root_relative_cli_value(self):
        resolved = resolve_docs_root(self.test_dir, Path("custom/docs"))
        self.assertEqual(resolved, self.test_dir / "custom" / "docs")

    def test_cli_status_uses_configured_docs_root(self):
        self.write_config('{"aidlcDocsPath": "apps/child-app/aidlc-docs"}\n')
        spec_dir = (
            self.test_dir / "apps" / "child-app" / "aidlc-docs" / "specs"
            / "sample-feature"
        )
        spec_dir.mkdir(parents=True, exist_ok=True)
        (spec_dir / "requirements.md").write_text("# Requirements\n")
        (spec_dir / "design.md").write_text("# Design\n")

        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "status",
                "sample-feature",
                "--repo-root",
                str(self.test_dir),
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Current Phase: 3", result.stdout)
        self.assertIn("apps/child-app/aidlc-docs", result.stdout)

    def test_cli_docs_root_flag_overrides_config(self):
        self.write_config('{"aidlcDocsPath": "apps/child-app/aidlc-docs"}\n')
        spec_dir = self.test_dir / "aidlc-docs" / "specs" / "root-feature"
        spec_dir.mkdir(parents=True, exist_ok=True)
        (spec_dir / "requirements.md").write_text("# Requirements\n")

        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "status",
                "root-feature",
                "--repo-root",
                str(self.test_dir),
                "--docs-root",
                "aidlc-docs",
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Current Phase: 2", result.stdout)

    def test_tasks_template_source_artifacts_use_configured_root(self):
        self.write_config('{"aidlcDocsPath": "apps/child-app/aidlc-docs"}\n')
        spec_dir = (
            self.test_dir / "apps" / "child-app" / "aidlc-docs" / "specs"
            / "sample-feature"
        )
        spec_dir.mkdir(parents=True, exist_ok=True)

        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "tasks-template",
                "sample-feature",
                "--repo-root",
                str(self.test_dir),
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        # The metadata renderer emits workspace-relative source paths.
        self.assertIn(
            "apps/child-app/aidlc-docs/specs/sample-feature/requirements.md",
            result.stdout,
        )


class TestExecutionApproachResolution(unittest.TestCase):
    """Test Phase 4 taskExecution.approach resolution"""

    def setUp(self):
        self.test_dir = Path(tempfile.mkdtemp()).resolve()

    def tearDown(self):
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir)

    def write_config(self, body: str):
        config_dir = self.test_dir / ".mtv-aidlc"
        config_dir.mkdir(parents=True, exist_ok=True)
        (config_dir / "extension-config.json").write_text(body)

    def test_default_without_config(self):
        result = resolve_execution_approach(self.test_dir)
        self.assertEqual(
            (result["approach"], result["source"]), ("subagent", "default")
        )
        self.assertIsNone(result["warning"])

    def test_configured_values_are_config_sourced(self):
        for raw, expected in (('"subagent"', "subagent"), ('" inline "', "inline")):
            self.write_config('{"taskExecution": {"approach": ' + raw + "}}\n")
            result = resolve_execution_approach(self.test_dir)
            self.assertEqual(
                (result["approach"], result["source"]), (expected, "config")
            )

    def test_unsupported_or_malformed_config_warns_and_defaults(self):
        for body in ('{"taskExecution": {"approach": "parallel"}}', "{ not json"):
            self.write_config(body)
            result = resolve_execution_approach(self.test_dir)
            self.assertEqual(
                (result["approach"], result["source"]), ("subagent", "default")
            )
            self.assertIsNotNone(result["warning"])

    def test_config_found_from_child_directory(self):
        # A Phase 4 session may run with cwd inside a child app; the walk
        # upward must still find the workspace-root config.
        self.write_config('{"taskExecution": {"approach": "subagent"}}\n')
        child_dir = self.test_dir / "apps" / "child-app"
        child_dir.mkdir(parents=True, exist_ok=True)
        self.assertEqual(
            resolve_execution_approach(child_dir)["approach"], "subagent"
        )

    def test_cli_execution_approach_outputs_json(self):
        import json

        self.write_config('{"taskExecution": {"approach": "subagent"}}\n')
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "execution-approach",
                "--repo-root",
                str(self.test_dir),
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(
            (payload["approach"], payload["source"]), ("subagent", "config")
        )


class TestValidateTasks(unittest.TestCase):
    """Test deterministic tasks.md validation"""

    GWT_REQUIREMENTS = (
        "---\n"
        "artifact_type: requirements\n"
        "---\n"
        "# Requirements - Sample\n\n"
        "## User Stories\n\n"
        "### US-1: Sample Story\n\n"
        "**Acceptance Criteria**\n\n"
        "**Feature 1: Thing**\n\n"
        "| No. | Scenario | Given | When | Then |\n"
        "|---|---|---|---|---|\n"
        "| 1.1 | Works | a | b | c |\n"
        "| 1.2 | Fails | a | b | c |\n"
    )

    VALID_TASKS = (
        "---\n"
        "artifact_type: tasks\n"
        "---\n"
        "# Tasks: Sample\n\n"
        "## Implementation Checklist\n\n"
        "### 1. Group\n\n"
        "- [ ] 1.1 Do a thing\n"
        "  - Reference: US-1 AC-1.1\n"
        "  - Files: `a.ts`\n\n"
        "- [x] 1.2 Do another\n"
        "  - Reference: US-1 AC-1.2\n\n"
        "## Next Steps\n\n"
        "Once approved, proceed to Phase 4.\n"
    )

    def setUp(self):
        self.test_dir = Path(tempfile.mkdtemp())
        self.spec_dir = self.test_dir / "aidlc-docs" / "specs" / "sample"
        self.spec_dir.mkdir(parents=True, exist_ok=True)
        self.workflow = SpecWorkflow(self.test_dir)

    def tearDown(self):
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir)

    def write_spec(self, tasks=None, requirements=None):
        if requirements is not None:
            (self.spec_dir / "requirements.md").write_text(requirements)
        if tasks is not None:
            (self.spec_dir / "tasks.md").write_text(tasks)

    def error_checks(self, result):
        return [error["check"] for error in result["errors"]]

    def warning_checks(self, result):
        return [warning["check"] for warning in result["warnings"]]

    def test_valid_plan_passes(self):
        self.write_spec(tasks=self.VALID_TASKS, requirements=self.GWT_REQUIREMENTS)
        result = self.workflow.validate_tasks("sample")
        self.assertTrue(result["valid"], result["errors"])
        self.assertEqual(result["errors"], [])
        self.assertEqual(result["summary"]["criteria_total"], 2)
        self.assertEqual(result["summary"]["criteria_covered"], 2)
        self.assertEqual(result["summary"]["total_tasks"], 2)

    def test_missing_tasks_file_fails(self):
        self.write_spec(requirements=self.GWT_REQUIREMENTS)
        result = self.workflow.validate_tasks("sample")
        self.assertFalse(result["valid"])
        self.assertIn("tasks-file-missing", self.error_checks(result))

    def test_missing_frontmatter_fails(self):
        tasks = self.VALID_TASKS.split("---\n", 2)[2]
        self.write_spec(tasks=tasks, requirements=self.GWT_REQUIREMENTS)
        result = self.workflow.validate_tasks("sample")
        self.assertIn("frontmatter-missing", self.error_checks(result))

    def test_missing_next_steps_fails(self):
        tasks = self.VALID_TASKS.split("## Next Steps")[0]
        self.write_spec(tasks=tasks, requirements=self.GWT_REQUIREMENTS)
        result = self.workflow.validate_tasks("sample")
        self.assertIn("next-steps-missing", self.error_checks(result))

    def test_next_steps_not_last_fails(self):
        tasks = self.VALID_TASKS + "\n## Rollback Plan\n\nnope\n"
        self.write_spec(tasks=tasks, requirements=self.GWT_REQUIREMENTS)
        result = self.workflow.validate_tasks("sample")
        self.assertIn("next-steps-not-last", self.error_checks(result))

    def test_checkbox_without_reference_fails(self):
        tasks = self.VALID_TASKS.replace(
            "  - Reference: US-1 AC-1.2\n", "  - Files: `b.ts`\n"
        )
        self.write_spec(tasks=tasks, requirements=self.GWT_REQUIREMENTS)
        result = self.workflow.validate_tasks("sample")
        checks = {error["check"]: error for error in result["errors"]}
        self.assertIn("missing-reference", checks)
        self.assertEqual(checks["missing-reference"]["items"], ["1.2"])

    def test_three_level_numbering_fails(self):
        tasks = self.VALID_TASKS.replace(
            "- [x] 1.2 Do another",
            "- [x] 1.2.1 Too deep",
        )
        self.write_spec(tasks=tasks, requirements=self.GWT_REQUIREMENTS)
        result = self.workflow.validate_tasks("sample")
        checks = {error["check"]: error for error in result["errors"]}
        self.assertIn("hierarchy-too-deep", checks)
        self.assertEqual(checks["hierarchy-too-deep"]["items"], ["1.2.1"])

    def test_no_checkboxes_fails(self):
        tasks = (
            "---\nartifact_type: tasks\n---\n"
            "# Tasks: Sample\n\n## Next Steps\n\ndone\n"
        )
        self.write_spec(tasks=tasks, requirements=self.GWT_REQUIREMENTS)
        result = self.workflow.validate_tasks("sample")
        self.assertIn("no-tasks", self.error_checks(result))

    def test_uncovered_criterion_reported(self):
        tasks = self.VALID_TASKS.replace(
            "  - Reference: US-1 AC-1.2\n", "  - Reference: US-1 AC-1.1\n"
        )
        self.write_spec(tasks=tasks, requirements=self.GWT_REQUIREMENTS)
        result = self.workflow.validate_tasks("sample")
        checks = {error["check"]: error for error in result["errors"]}
        self.assertIn("uncovered-criteria", checks)
        self.assertEqual(checks["uncovered-criteria"]["items"], ["US-1 AC-1.2"])
        self.assertEqual(result["summary"]["uncovered"], ["US-1 AC-1.2"])

    def test_ears_criteria_parse(self):
        requirements = (
            "### US-1: Sample Story\n\n"
            "**Acceptance Criteria**:\n\n"
            "**1. Section**\n\n"
            "1.1 WHEN x THEN system SHALL y\n\n"
            "1.2 WHEN x THEN system SHALL z\n"
        )
        parsed = parse_requirements_criteria(requirements)
        self.assertTrue(parsed["parseable"])
        self.assertEqual(
            [c["id"] for c in parsed["criteria"]], ["1.1", "1.2"]
        )

    def test_checklist_criteria_parse(self):
        requirements = (
            "### US-2: Checklist Story\n\n"
            "**Acceptance Criteria**\n\n"
            "- [ ] **2.1** User can do a thing.\n"
            "- [ ] **2.2** System rejects invalid input.\n"
        )
        parsed = parse_requirements_criteria(requirements)
        self.assertEqual(
            [c["id"] for c in parsed["criteria"]], ["2.1", "2.2"]
        )
        self.assertEqual(parsed["criteria"][0]["story"], "US-2")

    def test_unit_prefixed_ids_cover_criteria(self):
        requirements = (
            "### US-CSA-05: Prefixed Story\n\n"
            "CSA-05.2.1 WHEN x THEN system SHALL y\n\n"
            "CSA-05.2.4 WHEN x THEN system SHALL z\n"
        )
        tasks = (
            "---\nartifact_type: tasks\n---\n"
            "# Tasks: Sample\n\n"
            "- [ ] 1. Extend types\n"
            "  - Reference: US-CSA-05 AC-CSA-05.2.1, CSA-05.2.4\n\n"
            "## Next Steps\n\ndone\n"
        )
        self.write_spec(tasks=tasks, requirements=requirements)
        result = self.workflow.validate_tasks("sample")
        self.assertTrue(result["valid"], result["errors"])
        self.assertEqual(result["summary"]["criteria_covered"], 2)

    def test_unparseable_requirements_warns_but_passes(self):
        self.write_spec(
            tasks=self.VALID_TASKS,
            requirements="# Requirements\n\nFreeform custom format.\n",
        )
        result = self.workflow.validate_tasks("sample")
        self.assertTrue(result["valid"], result["errors"])
        self.assertIn("criteria-unparseable", self.warning_checks(result))

    def test_missing_requirements_warns_but_passes(self):
        self.write_spec(tasks=self.VALID_TASKS)
        result = self.workflow.validate_tasks("sample")
        self.assertTrue(result["valid"], result["errors"])
        self.assertIn("requirements-missing", self.warning_checks(result))
        self.assertIsNone(result["requirements_path"])

    def test_unknown_reference_warns_only(self):
        tasks = self.VALID_TASKS.replace(
            "  - Reference: US-1 AC-1.2\n",
            "  - Reference: US-1 AC-1.2, AC-9.9\n",
        )
        self.write_spec(tasks=tasks, requirements=self.GWT_REQUIREMENTS)
        result = self.workflow.validate_tasks("sample")
        self.assertTrue(result["valid"], result["errors"])
        warnings = {w["check"]: w for w in result["warnings"]}
        self.assertIn("unknown-references", warnings)
        self.assertEqual(warnings["unknown-references"]["items"], ["9.9"])

    def test_parent_task_delegates_reference_to_children(self):
        tasks = (
            "---\nartifact_type: tasks\n---\n"
            "# Tasks: Sample\n\n"
            "- [ ] 1 Parent task\n"
            "- [ ] 1.1 Leaf one\n"
            "  - Reference: US-1 AC-1.1\n"
            "- [ ] 1.2 Leaf two\n"
            "  - Reference: US-1 AC-1.2\n\n"
            "## Next Steps\n\ndone\n"
        )
        self.write_spec(tasks=tasks, requirements=self.GWT_REQUIREMENTS)
        result = self.workflow.validate_tasks("sample")
        self.assertTrue(result["valid"], result["errors"])

    def test_cli_validate_exit_codes(self):
        import json

        self.write_spec(tasks=self.VALID_TASKS, requirements=self.GWT_REQUIREMENTS)
        ok = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "validate",
                "sample",
                "--repo-root",
                str(self.test_dir),
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(ok.returncode, 0, ok.stderr)
        payload = json.loads(ok.stdout)
        self.assertTrue(payload["valid"])

        missing = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "validate",
                "no-such-spec",
                "--repo-root",
                str(self.test_dir),
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(missing.returncode, 1)
        payload = json.loads(missing.stdout)
        self.assertFalse(payload["valid"])
        self.assertEqual(
            payload["errors"][0]["check"], "tasks-file-missing"
        )


if __name__ == "__main__":
    unittest.main()
