"""Tests for test_cases_cli."""

import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_aidlc-shared" / "scripts"))

from test_cases_cli import (
    DEFAULT_FORMAT,
    FORMAT_GHERKIN_BLOCKS,
    FORMAT_GHERKIN_TABLE,
    FORMAT_STANDARD_TABLE,
    TYPE_FUNCTIONAL,
    TYPE_REGRESSION,
    TYPE_UAT,
    get_status,
    init_test_cases,
    normalize_type,
    parse_status,
    phase_for_scope,
    render_test_cases_template,
    resolve_paths,
    resolve_template_settings,
)

TEMPLATES_DIR = Path(__file__).resolve().parents[1] / "assets" / "templates"


def read_template(name: str) -> str:
    return (TEMPLATES_DIR / name).read_text()


def test_phase_story():
    assert phase_for_scope("story") == "inception"


def test_phase_spec():
    assert phase_for_scope("spec") == "construction"


def test_resolve_paths_story(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths = resolve_paths("auth-flow", "story", docs_root=docs_root)
    assert paths.output_file == docs_root.resolve() / "test-cases" / "auth-flow-test-cases.md"
    assert paths.phase == "inception"


def test_resolve_paths_spec(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths = resolve_paths("checkout-flow", "spec", docs_root=docs_root)
    assert paths.output_file == docs_root.resolve() / "specs" / "checkout-flow" / "test-cases.md"
    assert paths.phase == "construction"


def test_resolve_paths_invalid_scope(tmp_path):
    with pytest.raises(ValueError, match="Invalid scope"):
        resolve_paths("foo", "unit", docs_root=tmp_path)


def test_render_default_format_with_explicit_type(tmp_path):
    rendered = render_test_cases_template(
        "auth-flow",
        "story",
        "2026-01-15",
        repo_root=tmp_path,
        test_type=TYPE_FUNCTIONAL,
    )
    assert "artifact_type: test-cases" in rendered
    assert "phase: inception" in rendered
    assert "intent: auth-flow" in rendered
    assert f"Test case format: {DEFAULT_FORMAT}" in rendered
    assert "type: functional" in rendered
    assert "| Test case ID | Scenario | Given | When | Then | Source ID |" in rendered


def test_render_requires_explicit_type(tmp_path):
    with pytest.raises(ValueError, match="Test-case type is required"):
        render_test_cases_template(
            "auth-flow",
            "story",
            "2026-01-15",
            repo_root=tmp_path,
        )


def test_normalize_type_rejects_missing():
    with pytest.raises(ValueError, match="Test-case type is required"):
        normalize_type(None)


def test_render_spec_frontmatter(tmp_path):
    rendered = render_test_cases_template(
        "checkout-flow",
        "spec",
        "2026-01-15",
        repo_root=tmp_path,
        test_type=TYPE_FUNCTIONAL,
    )
    assert "phase: construction" in rendered
    assert "unit: checkout-flow" in rendered
    assert "intent:" not in rendered


def test_render_gherkin_blocks(tmp_path):
    rendered = render_test_cases_template(
        "auth-flow",
        "story",
        "2026-06-01",
        repo_root=tmp_path,
        template_format=FORMAT_GHERKIN_BLOCKS,
        test_type=TYPE_UAT,
    )
    assert "Test case format: gherkin-blocks" in rendered
    assert "type: uat" in rendered
    assert "## Scenario inventory" in rendered
    assert "```gherkin" in rendered


def test_render_standard_table(tmp_path):
    rendered = render_test_cases_template(
        "auth-flow",
        "story",
        "2026-06-01",
        repo_root=tmp_path,
        template_format=FORMAT_STANDARD_TABLE,
        test_type=TYPE_REGRESSION,
    )
    assert "Test case format: standard-table" in rendered
    assert "type: regression" in rendered
    assert "| Test case ID | Title | Preconditions | Steps | Expected result |" in rendered


def test_render_no_stale_legacy_template_text(tmp_path):
    rendered = render_test_cases_template(
        "auth-flow", "story", "2026-06-01", repo_root=tmp_path, test_type=TYPE_FUNCTIONAL
    )
    assert "## Traceability matrix" not in rendered
    assert "## Coverage summary" in rendered
    assert "E2E automation handoff" not in rendered
    assert "Export-ready tabular schema" not in rendered
    assert "Use this schema" not in rendered


def test_builtin_templates_keep_lean_coverage_shape():
    for template_name in ["gherkin-table.md", "gherkin-blocks.md", "standard-table.md"]:
        content = read_template(template_name)
        assert "## Traceability matrix" not in content
        assert "## Coverage summary" in content
        assert 50 <= len(content.splitlines()) <= 80


def test_coverage_summary_is_below_primary_test_content():
    gherkin_table = read_template("gherkin-table.md")
    assert gherkin_table.index("## Coverage summary") > gherkin_table.index("| TC-001 |")

    standard_table = read_template("standard-table.md")
    assert standard_table.index("## Coverage summary") > standard_table.index("| TC-001 |")

    gherkin_blocks = read_template("gherkin-blocks.md")
    assert gherkin_blocks.index("## Coverage summary") > gherkin_blocks.index("## Gherkin scenarios")
    assert gherkin_blocks.index("## Coverage summary") < gherkin_blocks.index("## Coverage gaps")


def test_gherkin_blocks_keeps_scenario_inventory_header():
    content = read_template("gherkin-blocks.md")
    assert "| Test case ID | Title | Source ID | Coverage type | Automation target | Priority |" in content


def test_resolve_template_settings_from_config(tmp_path):
    config_dir = tmp_path / ".mtv-aidlc"
    config_dir.mkdir()
    (config_dir / "extension-config.json").write_text(
        json.dumps(
            {
                "testCase": {
                    "format": FORMAT_GHERKIN_BLOCKS,
                }
            }
        )
    )

    settings = resolve_template_settings(repo_root=tmp_path, test_type=TYPE_FUNCTIONAL)
    assert settings.template_format == FORMAT_GHERKIN_BLOCKS
    assert settings.test_type == TYPE_FUNCTIONAL


def test_resolve_template_settings_requires_type(tmp_path):
    with pytest.raises(ValueError, match="Test-case type is required"):
        resolve_template_settings(repo_root=tmp_path)


def test_resolve_template_settings_cli_overrides_config(tmp_path):
    config_dir = tmp_path / ".mtv-aidlc"
    config_dir.mkdir()
    (config_dir / "extension-config.json").write_text(
        json.dumps(
            {
                "testCase": {
                    "format": FORMAT_GHERKIN_BLOCKS,
                }
            }
        )
    )

    settings = resolve_template_settings(
        repo_root=tmp_path,
        template_format=FORMAT_STANDARD_TABLE,
        test_type=TYPE_REGRESSION,
    )
    assert settings.template_format == FORMAT_STANDARD_TABLE
    assert settings.test_type == TYPE_REGRESSION


def test_resolve_custom_template_from_config(tmp_path):
    config_dir = tmp_path / ".mtv-aidlc"
    custom_dir = config_dir / "templates" / "test-cases"
    custom_dir.mkdir(parents=True)
    custom_file = custom_dir / "custom.md"
    custom_file.write_text("# Custom test cases\n")
    (config_dir / "extension-config.json").write_text(
        json.dumps(
            {
                "testCase": {
                    "format": "custom",
                    "customTemplatePath": ".mtv-aidlc/templates/test-cases/custom.md",
                }
            }
        )
    )

    settings = resolve_template_settings(repo_root=tmp_path, test_type=TYPE_FUNCTIONAL)
    assert settings.template_format == "custom"
    assert settings.template_path == custom_file


def test_init_story_creates_file(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths, created = init_test_cases("auth-flow", "story", repo_root=tmp_path, docs_root=docs_root, test_type=TYPE_FUNCTIONAL)
    assert created is True
    assert paths.output_file.exists()
    assert paths.output_file.name == "auth-flow-test-cases.md"
    assert "artifact_type: test-cases" in paths.output_file.read_text()


def test_init_spec_creates_file(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths, created = init_test_cases("checkout-flow", "spec", repo_root=tmp_path, docs_root=docs_root, test_type=TYPE_FUNCTIONAL)
    assert created is True
    assert paths.output_file.name == "test-cases.md"
    assert paths.output_file.parent.name == "checkout-flow"


def test_init_is_idempotent(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    _, created1 = init_test_cases("auth-flow", "story", repo_root=tmp_path, docs_root=docs_root, test_type=TYPE_FUNCTIONAL)
    _, created2 = init_test_cases("auth-flow", "story", repo_root=tmp_path, docs_root=docs_root, test_type=TYPE_FUNCTIONAL)
    assert created1 is True
    assert created2 is False


def test_parse_status_from_frontmatter():
    content = "---\nartifact_type: test-cases\nstatus: approved\n---\n# Title\n"
    assert parse_status(content) == "approved"


def test_parse_status_unknown():
    assert parse_status("# No frontmatter") == "unknown"


def test_get_status_missing(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    status = get_status("nonexistent", "story", repo_root=tmp_path, docs_root=docs_root)
    assert status["exists"] is False
    assert status["status"] == "missing"


def test_get_status_existing(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    init_test_cases("auth-flow", "story", repo_root=tmp_path, docs_root=docs_root, test_type=TYPE_FUNCTIONAL)
    status = get_status("auth-flow", "story", repo_root=tmp_path, docs_root=docs_root)
    assert status["exists"] is True
    assert status["status"] == "draft"
    assert status["scope"] == "story"


def test_config_docs_root_resolution(tmp_path):
    config_dir = tmp_path / ".mtv-aidlc"
    config_dir.mkdir()
    custom_docs = tmp_path / "custom-docs"
    (config_dir / "extension-config.json").write_text(
        json.dumps({"aidlcDocsPath": "custom-docs"})
    )
    paths = resolve_paths("auth-flow", "story", repo_root=tmp_path)
    assert paths.docs_root == custom_docs.resolve()
