#!/usr/bin/env python3
"""Tests for story_artifact.py."""

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

from story_artifact import (
    StoryArtifactWorkflow,
    TemplateSource,
    get_template_path,
    render_story_artifact_template,
    resolve_docs_root,
)


class TestStoryArtifactWorkflow(unittest.TestCase):
    """Test standalone story artifact scaffolding."""

    def setUp(self):
        """Create temporary test environment."""
        self.test_dir = Path(tempfile.mkdtemp())
        self.workflow = StoryArtifactWorkflow(self.test_dir)

    def tearDown(self):
        """Clean up temporary test environment."""
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir)

    def write_extension_config(self, template, custom_path=None, docs_path=None):
        """Write a minimal extension-config.json for template resolution tests."""
        config_dir = self.test_dir / ".mtv-aidlc"
        config_dir.mkdir(parents=True, exist_ok=True)
        config = {
            "userStory": {
                "template": template,
                "customTemplatePath": custom_path,
            }
        }
        if docs_path is not None:
            config["aidlcDocsPath"] = docs_path
        (config_dir / "extension-config.json").write_text(
            json.dumps(config, indent=2) + "\n"
        )

    def test_default_scaffold_includes_required_sections(self):
        """Default scaffold includes wrapper and EARS-Lite story block."""
        content = render_story_artifact_template("default", "shipment exception triage")

        self.assertIn("# User Stories: Shipment Exception Triage", content)
        self.assertIn("## Overview", content)
        self.assertIn("## User stories", content)
        self.assertIn("### US-001: {User Story Title}", content)
        self.assertIn("**Dependencies**: None |", content)
        self.assertIn("1.1 WHEN [context/trigger] THEN system SHALL", content)

    def test_default_scaffold_starts_with_required_frontmatter(self):
        """Default scaffold should prepend metadata-compliant frontmatter."""
        content = render_story_artifact_template("default", "shipment exception triage")

        self.assertTrue(content.startswith("---\n"))
        self.assertIn("artifact_type: story-artifact", content)
        self.assertIn("phase: inception", content)
        self.assertIn("status: draft", content)
        self.assertRegex(content, r"created: \d{4}-\d{2}-\d{2}", msg=content)
        self.assertRegex(content, r"updated: \d{4}-\d{2}-\d{2}", msg=content)

    def test_checklist_scaffold_includes_checklist_criteria(self):
        """Checklist scaffold includes checklist acceptance criteria."""
        content = render_story_artifact_template("checklist", "document upload")

        self.assertIn("**Dependencies**: None |", content)
        self.assertIn("- [ ] **1.1**", content)
        self.assertIn("### 2. {Category / Validation & Edge Cases}", content)

    def test_given_when_then_scaffold_includes_table(self):
        """Given/When/Then scaffold includes table acceptance criteria."""
        content = render_story_artifact_template(
            "given-when-then-table",
            "commodity lookup",
        )

        self.assertIn("| No. | Scenario | Given | When | Then |", content)
        self.assertIn("**Dependencies**: None |", content)
        self.assertIn("| 1.1 | {Scenario name}", content)

    def test_invalid_template_rejected_before_file_creation(self):
        """Invalid templates fail before artifact directories are created."""
        with self.assertRaises(ValueError):
            get_template_path("unknown-template")

        self.assertFalse((self.test_dir / "aidlc-docs").exists())

    def test_write_scaffold_uses_001_when_empty(self):
        """Scaffold writing creates 001 artifact when no existing artifacts exist."""
        output_path = self.workflow.write_scaffold("shipment exception triage", "default")

        self.assertEqual(
            output_path.name,
            "001_shipment-exception-triage_user_stories.md",
        )
        self.assertTrue(output_path.exists())

    def test_write_scaffold_uses_next_id(self):
        """Scaffold writing chooses the next three-digit artifact ID."""
        artifacts_dir = self.test_dir / "aidlc-docs" / "story-artifacts"
        artifacts_dir.mkdir(parents=True)
        (artifacts_dir / "001_existing_user_stories.md").write_text("existing\n")
        (artifacts_dir / "009_other_user_stories.md").write_text("existing\n")

        output_path = self.workflow.write_scaffold("new feature", "checklist")

        self.assertEqual(output_path.name, "010_new-feature_user_stories.md")

    def test_scaffold_does_not_include_spec_wrapper(self):
        """Standalone story artifacts must not include spec-driven wrapper text."""
        content = render_story_artifact_template("default", "standalone feature")

        self.assertNotIn("# Requirements:", content)
        self.assertNotIn("**Unit**:", content)
        self.assertNotIn("## Next Steps", content)

    def test_overview_appears_before_user_stories(self):
        """Overview appears before User stories in the wrapper."""
        content = render_story_artifact_template("default", "standalone feature")

        self.assertLess(content.index("## Overview"), content.index("## User stories"))

    def test_cli_scaffold_writes_by_default(self):
        """CLI scaffold writes the artifact by default and prints the path."""
        script_path = Path(__file__).resolve().parent / "story_artifact.py"

        result = subprocess.run(
            [
                sys.executable,
                str(script_path),
                "scaffold",
                "shipment exception triage",
                "--template",
                "checklist",
                "--repo-root",
                str(self.test_dir),
            ],
            check=True,
            text=True,
            capture_output=True,
        )

        stdout_lines = result.stdout.strip().splitlines()
        output_path = Path(stdout_lines[0])
        self.assertEqual(
            output_path.name,
            "001_shipment-exception-triage_user_stories.md",
        )
        self.assertTrue(output_path.exists())
        self.assertEqual(
            stdout_lines[1],
            "Resolved template: checklist (built-in:checklist)",
        )

    def test_write_scaffold_uses_config_template_when_omitted(self):
        """Omitted template reads extension config."""
        self.write_extension_config("checklist")

        output_path = self.workflow.write_scaffold("configured template", None)
        content = output_path.read_text()

        self.assertIn("- [ ] **1.1**", content)

    def test_write_scaffold_uses_resolved_template_source_once(self):
        """Resolved template sources are not re-resolved while writing."""
        template_source = TemplateSource(
            name="test",
            content=(
                "### US-{ID}: Resolved Story\n\n"
                "**Acceptance Criteria**\n\n"
                "- [ ] **1.1** Criterion from already resolved source\n"
            ),
            source_label="test:resolved",
        )

        with patch(
            "story_artifact.resolve_template_source",
            side_effect=AssertionError("template source should not be re-resolved"),
        ):
            output_path = self.workflow.write_scaffold(
                "resolved template",
                None,
                template_source=template_source,
            )

        content = output_path.read_text()
        self.assertIn("### US-001: Resolved Story", content)
        self.assertIn("Criterion from already resolved source", content)

    def test_explicit_builtin_template_overrides_config(self):
        """Explicit built-in templates bypass configured template."""
        self.write_extension_config("checklist")

        output_path = self.workflow.write_scaffold(
            "explicit override",
            "given-when-then-table",
        )
        content = output_path.read_text()

        self.assertIn("| No. | Scenario | Given | When | Then |", content)
        self.assertNotIn("- [ ] **1.1**", content)

    def test_custom_template_loads_relative_path_from_config(self):
        """Custom template loads userStory.customTemplatePath relative to repo root."""
        custom_dir = self.test_dir / ".mtv-aidlc" / "templates" / "user-story"
        custom_dir.mkdir(parents=True, exist_ok=True)
        custom_file = custom_dir / "custom.md"
        custom_file.write_text(
            "```markdown\n"
            "### US-{ID}: Custom Story\n\n"
            "**User Story**: As a {persona}, I want {capability}, so that {benefit}\n\n"
            "**Acceptance Criteria**\n\n"
            "- [ ] **1.1** Custom criterion from config\n"
            "```\n"
        )
        self.write_extension_config(
            "custom",
            ".mtv-aidlc/templates/user-story/custom.md",
        )

        output_path = self.workflow.write_scaffold("custom template", "custom")
        content = output_path.read_text()

        self.assertIn("# User Stories: Custom Template", content)
        self.assertIn("### US-001: Custom Story", content)
        self.assertIn("Custom criterion from config", content)
        self.assertNotIn("# Requirements:", content)

    def test_custom_template_accepts_whole_markdown_file(self):
        """Custom templates do not require fenced markdown blocks."""
        custom_file = self.test_dir / "custom-whole.md"
        custom_file.write_text(
            "### US-{ID}: Whole File Story\n\n"
            "**Acceptance Criteria**\n\n"
            "- [ ] **1.1** Whole file custom criterion\n"
        )
        self.write_extension_config("custom", "custom-whole.md")

        output_path = self.workflow.write_scaffold("whole custom", None)
        content = output_path.read_text()

        self.assertIn("### US-001: Whole File Story", content)
        self.assertIn("Whole file custom criterion", content)

    def test_missing_config_falls_back_to_default(self):
        """Missing extension config falls back to default template."""
        output_path = self.workflow.write_scaffold("missing config", None)
        content = output_path.read_text()

        self.assertIn("1.1 WHEN [context/trigger] THEN system SHALL", content)

    def test_invalid_custom_template_falls_back_to_default(self):
        """Invalid custom config falls back to default template."""
        self.write_extension_config("custom", ".mtv-aidlc/templates/user-story/missing.md")

        output_path = self.workflow.write_scaffold("missing custom", None)
        content = output_path.read_text()

        self.assertIn("1.1 WHEN [context/trigger] THEN system SHALL", content)
        self.assertNotIn("Custom criterion", content)

    def test_docs_root_defaults_to_aidlc_docs(self):
        """Without config or arg, docs root is <repo>/aidlc-docs."""
        docs_root = resolve_docs_root(self.test_dir)

        self.assertEqual(docs_root, self.test_dir / "aidlc-docs")

    def test_docs_root_reads_config_aidlc_docs_path(self):
        """Configured aidlcDocsPath places artifacts in the configured tree."""
        self.write_extension_config("checklist", docs_path="apps/demo/aidlc-docs")

        workflow = StoryArtifactWorkflow(self.test_dir)
        output_path = workflow.write_scaffold("configured docs root", "default")

        self.assertEqual(
            output_path.parent,
            self.test_dir / "apps" / "demo" / "aidlc-docs" / "story-artifacts",
        )
        self.assertTrue(output_path.exists())
        self.assertFalse((self.test_dir / "aidlc-docs").exists())

    def test_docs_root_explicit_arg_overrides_config(self):
        """An explicit docs-root argument wins over configured aidlcDocsPath."""
        self.write_extension_config("checklist", docs_path="apps/demo/aidlc-docs")

        docs_root = resolve_docs_root(self.test_dir, "docs/custom-root")

        self.assertEqual(docs_root, self.test_dir / "docs" / "custom-root")

    def test_frontmatter_includes_intent_slug(self):
        """Scaffold frontmatter stamps intent from the feature slug."""
        content = render_story_artifact_template(
            "default",
            "Shipment Exception Triage",
        )

        self.assertIn("intent: shipment-exception-triage", content)

    def test_cli_records_source_artifacts(self):
        """--source paths are recorded in frontmatter source_artifacts."""
        script_path = Path(__file__).resolve().parent / "story_artifact.py"

        result = subprocess.run(
            [
                sys.executable,
                str(script_path),
                "scaffold",
                "sourced feature",
                "--template",
                "default",
                "--repo-root",
                str(self.test_dir),
                "--source",
                "docs/brd/export-brd.md",
                "--source",
                "docs/tickets/ABC-123.md",
            ],
            check=True,
            text=True,
            capture_output=True,
        )

        output_path = Path(result.stdout.strip().splitlines()[0])
        content = output_path.read_text()

        self.assertIn("source_artifacts:", content)
        self.assertIn("  - docs/brd/export-brd.md", content)
        self.assertIn("  - docs/tickets/ABC-123.md", content)


if __name__ == "__main__":
    unittest.main()
