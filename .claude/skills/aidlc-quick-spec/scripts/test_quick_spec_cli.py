#!/usr/bin/env python
"""Tests for quick_spec_cli.py."""

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from quick_spec_cli import (  # noqa: E402
    complete_task,
    get_progress,
    get_status,
    init_spec,
    resolve_docs_root,
)


SCRIPT_PATH = Path(__file__).resolve().parent / "quick_spec_cli.py"
SUBAGENT_EXECUTION_REFERENCE = (
    Path(__file__).resolve().parent.parent
    / "references"
    / "subagent-execution.md"
)


class TestQuickSpecCli(unittest.TestCase):
    """Test quick-spec CLI helpers."""

    def setUp(self):
        """Create a temporary repository root."""
        self.test_dir = Path(tempfile.mkdtemp()).resolve()
        (self.test_dir / ".git").mkdir()

    def tearDown(self):
        """Clean up the temporary repository root."""
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir)

    def test_subagent_prompt_requires_spawn_and_escalation_contracts(self):
        """Delegated execution must declare agent/model, fencing, and blockers."""
        content = SUBAGENT_EXECUTION_REFERENCE.read_text()

        self.assertIn("subagent_type: ai-orchestration-engineer", content)
        self.assertIn("model: [MODEL — REQUIRED:", content)
        self.assertIn("## Existing Work to Preserve", content)
        self.assertIn("exact staged and unstaged diffs", content)
        self.assertIn("architectural decision with multiple valid approaches", content)
        self.assertIn("Continued file exploration is not producing clarity", content)

    def write_extension_config(self, payload):
        """Write extension-config.json under the temporary repo."""
        config_dir = self.test_dir / ".mtv-aidlc"
        config_dir.mkdir(parents=True, exist_ok=True)
        (config_dir / "extension-config.json").write_text(
            json.dumps(payload, indent=2) + "\n"
        )

    def test_init_creates_spec_with_frontmatter(self):
        """init creates spec.md with quick-spec metadata."""
        paths, created = init_spec("sample-feature", repo_root=self.test_dir)

        self.assertTrue(created)
        self.assertEqual(
            paths.spec_file,
            self.test_dir / "aidlc-docs" / "specs" / "sample-feature" / "spec.md",
        )

        content = paths.spec_file.read_text()
        self.assertTrue(content.startswith("---\n"))
        self.assertIn("artifact_type: quick-spec\n", content)
        self.assertIn("phase: construction\n", content)
        self.assertIn("status: draft\n", content)
        self.assertIn("unit: sample-feature\n", content)
        self.assertIn("source_artifacts: []\n", content)
        self.assertIn("# Sample Feature — Quick Spec", content)
        self.assertIn("**Status:** Draft", content)
        self.assertNotIn("Draft | Approved | In Progress | Complete", content)

    def test_init_respects_configured_aidlc_docs_path(self):
        """init uses aidlcDocsPath from extension-config.json."""
        self.write_extension_config(
            {"aidlcDocsPath": "apps/mtv-aidlc-vscode/aidlc-docs"}
        )

        paths, created = init_spec("configured-feature", repo_root=self.test_dir)

        self.assertTrue(created)
        self.assertEqual(
            paths.spec_file,
            self.test_dir
            / "apps"
            / "mtv-aidlc-vscode"
            / "aidlc-docs"
            / "specs"
            / "configured-feature"
            / "spec.md",
        )

    def test_explicit_docs_root_overrides_config(self):
        """--docs-root style input wins over configured aidlcDocsPath."""
        self.write_extension_config({"aidlcDocsPath": "configured-docs"})

        paths, created = init_spec(
            "explicit-docs",
            repo_root=self.test_dir,
            docs_root=Path("explicit-docs"),
        )

        self.assertTrue(created)
        self.assertEqual(
            paths.spec_file,
            self.test_dir / "explicit-docs" / "specs" / "explicit-docs" / "spec.md",
        )

    def test_config_search_does_not_escape_nested_repo_boundary(self):
        """A nested repo's own .git boundary blocks inheriting an ancestor's config.

        Regression test: a workspace can have .mtv-aidlc/extension-config.json
        at its root while containing an unrelated nested git repo (e.g. a test
        fixture, a vendored project). find_repo_root() correctly stops at the
        nested repo's own .git, so the config search must stop there too —
        otherwise it silently inherits and applies an unrelated ancestor
        repo's docs-root configuration to the nested repo.
        """
        outer_workspace = self.test_dir
        (outer_workspace / ".mtv-aidlc").mkdir()
        (outer_workspace / ".mtv-aidlc" / "extension-config.json").write_text(
            json.dumps({"aidlcDocsPath": "outer-workspace-docs"}) + "\n"
        )

        nested_repo = outer_workspace / "nested-project"
        nested_repo.mkdir()
        (nested_repo / ".git").mkdir()

        paths, created = init_spec("nested-feature", repo_root=nested_repo)

        self.assertTrue(created)
        self.assertEqual(paths.repo_root, nested_repo)
        self.assertEqual(
            paths.spec_file,
            nested_repo / "aidlc-docs" / "specs" / "nested-feature" / "spec.md",
        )
        self.assertFalse((outer_workspace / "outer-workspace-docs").exists())

    def test_init_does_not_overwrite_existing_spec(self):
        """init leaves an existing spec.md untouched."""
        spec_dir = self.test_dir / "aidlc-docs" / "specs" / "existing-feature"
        spec_dir.mkdir(parents=True)
        spec_file = spec_dir / "spec.md"
        spec_file.write_text("existing content\n")

        paths, created = init_spec("existing-feature", repo_root=self.test_dir)

        self.assertFalse(created)
        self.assertEqual(paths.spec_file.read_text(), "existing content\n")

    def test_progress_counts_checkboxes(self):
        """progress counts pending and completed checkbox lines."""
        paths, _ = init_spec("progress-feature", repo_root=self.test_dir)
        paths.spec_file.write_text(
            "# Progress Feature\n\n"
            "- [ ] pending one\n"
            "- [x] completed one\n"
            "- [X] completed two\n"
        )

        progress = get_progress("progress-feature", repo_root=self.test_dir)

        self.assertEqual(progress["total"], 3)
        self.assertEqual(progress["completed"], 2)
        self.assertEqual(progress["pending"], 1)
        self.assertEqual(progress["percentage"], 66.7)

    def test_complete_marks_all_checkboxes_in_task_block(self):
        """complete marks every unchecked checkbox under the requested task."""
        paths, _ = init_spec("complete-feature", repo_root=self.test_dir)
        paths.spec_file.write_text(
            "# Complete Feature\n\n"
            "### Task 1: First\n\n"
            "- [ ] **Step 1:** Implement first part\n"
            "- [ ] **Step 2:** Verify first part\n\n"
            "### Task 2: Second\n\n"
            "- [ ] **Step 1:** Implement second part\n"
        )

        _, changed = complete_task("complete-feature", "1", repo_root=self.test_dir)

        content = paths.spec_file.read_text()
        self.assertTrue(changed)
        self.assertIn("- [x] **Step 1:** Implement first part", content)
        self.assertIn("- [x] **Step 2:** Verify first part", content)
        self.assertIn("- [ ] **Step 1:** Implement second part", content)

    def test_status_reports_missing_spec(self):
        """status handles missing quick specs without creating files."""
        status = get_status("missing-feature", repo_root=self.test_dir)

        self.assertFalse(status["exists"])
        self.assertEqual(status["status"], "missing")
        self.assertEqual(status["total"], 0)

    def test_malformed_config_falls_back_to_default_docs_root(self):
        """Malformed extension config falls back to aidlc-docs."""
        config_dir = self.test_dir / ".mtv-aidlc"
        config_dir.mkdir(parents=True, exist_ok=True)
        (config_dir / "extension-config.json").write_text("{not valid json")

        docs_root = resolve_docs_root(self.test_dir)

        self.assertEqual(docs_root, self.test_dir / "aidlc-docs")

    def test_cli_init_outputs_created_spec_path(self):
        """The CLI entrypoint can initialize a quick spec."""
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                "init",
                "cli-feature",
                "--repo-root",
                str(self.test_dir),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0)
        self.assertIn("Created quick spec:", result.stdout)
        self.assertTrue(
            (
                self.test_dir
                / "aidlc-docs"
                / "specs"
                / "cli-feature"
                / "spec.md"
            ).exists()
        )


if __name__ == "__main__":
    unittest.main()
