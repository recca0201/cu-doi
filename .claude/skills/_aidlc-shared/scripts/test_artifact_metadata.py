#!/usr/bin/env python3
"""Tests for shared artifact metadata frontmatter rendering."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from artifact_metadata import (  # noqa: E402
    ArtifactMetadata,
    render_frontmatter,
)


class TestArtifactMetadata(unittest.TestCase):
    """Test metadata rendering and validation."""

    def make_valid_metadata(self):
        """Return a fully valid metadata object for baseline assertions."""
        return ArtifactMetadata(
            artifact_type="requirements",
            phase="construction",
            status="draft",
            created="2026-06-05",
            updated="2026-06-05",
        )

    def test_render_frontmatter_has_yaml_delimiters(self):
        """Frontmatter uses delimiters and ends with trailing blank line."""
        output = render_frontmatter(self.make_valid_metadata())

        self.assertTrue(output.startswith("---\n"))
        self.assertTrue(output.endswith("---\n\n"))

    def test_render_frontmatter_includes_required_fields(self):
        """All required keys must be emitted."""
        output = render_frontmatter(self.make_valid_metadata())

        for key in [
            "artifact_type",
            "phase",
            "status",
            "created",
            "updated",
        ]:
            self.assertIn(f"{key}:", output)

    def test_invalid_artifact_type_raises_value_error(self):
        """Invalid artifact types are rejected with field name context."""
        metadata = self.make_valid_metadata()
        metadata.artifact_type = "invalid-type"

        with self.assertRaises(ValueError) as err:
            render_frontmatter(metadata)

        self.assertIn("artifact_type", str(err.exception))

    def test_missing_required_field_raises_value_error(self):
        """Missing required fields are rejected with field name context."""
        metadata = self.make_valid_metadata()
        metadata.phase = ""

        with self.assertRaises(ValueError) as err:
            render_frontmatter(metadata)

        self.assertIn("phase", str(err.exception))

    def test_intent_and_unit_keys_emitted_only_when_present(self):
        """Optional scalar keys should be omitted when unset."""
        metadata = self.make_valid_metadata()
        metadata.intent = "artifact-frontmatter"
        metadata.unit = "metadata-compliant-artifact-production-rollout"

        with_values = render_frontmatter(metadata)
        self.assertIn("intent: artifact-frontmatter", with_values)
        self.assertIn(
            "unit: metadata-compliant-artifact-production-rollout",
            with_values,
        )

        metadata.intent = None
        metadata.unit = None
        without_values = render_frontmatter(metadata)
        self.assertNotIn("intent:", without_values)
        self.assertNotIn("unit:", without_values)

    def test_estimation_keys_emitted_only_when_present(self):
        """Estimation fields render only when populated."""
        metadata = self.make_valid_metadata()
        metadata.estimation_bcp = 42
        metadata.estimation_report = (
            "apps/mtv-aidlc-vscode/aidlc-docs/estimation/spec-x-20260629.md"
        )

        with_values = render_frontmatter(metadata)
        self.assertIn("estimation_bcp: 42", with_values)
        self.assertIn(
            "estimation_report: "
            "apps/mtv-aidlc-vscode/aidlc-docs/estimation/spec-x-20260629.md",
            with_values,
        )

        metadata.estimation_bcp = None
        metadata.estimation_report = None
        without_values = render_frontmatter(metadata)
        self.assertNotIn("estimation_bcp:", without_values)
        self.assertNotIn("estimation_report:", without_values)

    def test_invalid_estimation_bcp_raises_value_error(self):
        """Negative or non-integer BCP totals are rejected."""
        metadata = self.make_valid_metadata()
        metadata.estimation_bcp = -3

        with self.assertRaises(ValueError) as err:
            render_frontmatter(metadata)

        self.assertIn("estimation_bcp", str(err.exception))

    def test_source_artifacts_always_emitted(self):
        """source_artifacts should render as a list or an explicit empty list."""
        metadata = self.make_valid_metadata()
        metadata.source_artifacts = [
            "apps/mtv-aidlc-vscode/aidlc-docs/specs/x/requirements.md",
        ]

        output = render_frontmatter(metadata)
        self.assertIn("source_artifacts:", output)
        self.assertIn(
            "- apps/mtv-aidlc-vscode/aidlc-docs/specs/x/requirements.md",
            output,
        )

        metadata.source_artifacts = []
        output_without_list = render_frontmatter(metadata)
        self.assertIn("source_artifacts: []", output_without_list)

    def test_absolute_source_path_normalized_to_workspace_relative(self):
        """Absolute source paths become relative when workspace_root is set."""
        workspace_root = Path("/repo")
        metadata = self.make_valid_metadata()
        metadata.source_artifacts = [
            "/repo/apps/mtv-aidlc-vscode/aidlc-docs/specs/x/requirements.md",
        ]

        output = render_frontmatter(metadata, workspace_root=workspace_root)

        self.assertIn(
            "- apps/mtv-aidlc-vscode/aidlc-docs/specs/x/requirements.md",
            output,
        )

    def test_source_path_outside_workspace_root_raises_value_error(self):
        """Absolute paths outside workspace root should be rejected."""
        workspace_root = Path("/repo")
        metadata = self.make_valid_metadata()
        metadata.source_artifacts = ["/other/location/requirements.md"]

        with self.assertRaises(ValueError) as err:
            render_frontmatter(metadata, workspace_root=workspace_root)

        self.assertIn("source_artifacts", str(err.exception))

    def test_source_path_with_newline_raises_value_error(self):
        """Newlines in source paths are invalid for YAML list values."""
        metadata = self.make_valid_metadata()
        metadata.source_artifacts = ["path/with\nbreak.md"]

        with self.assertRaises(ValueError) as err:
            render_frontmatter(metadata)

        self.assertIn("source_artifacts", str(err.exception))

    def test_yaml_sensitive_scalar_is_quoted(self):
        """Scalar values containing YAML-sensitive tokens should be quoted."""
        metadata = self.make_valid_metadata()
        metadata.intent = "metadata: rollout"

        output = render_frontmatter(metadata)

        self.assertIn('intent: "metadata: rollout"', output)

    def test_dates_are_normalized_to_iso_format(self):
        """Dates should be normalized to YYYY-MM-DD."""
        metadata = self.make_valid_metadata()
        metadata.created = "2026-6-5"
        metadata.updated = "2026-6-5"

        output = render_frontmatter(metadata)

        self.assertIn("created: 2026-06-05", output)
        self.assertIn("updated: 2026-06-05", output)


if __name__ == "__main__":
    unittest.main()
