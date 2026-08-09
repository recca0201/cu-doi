"""Tests for brainstorm_cli."""

import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_aidlc-shared" / "scripts"))

from brainstorm_cli import (
    get_status,
    init_dr,
    next_dr_number,
    parse_status,
    render_dr_template,
    resolve_paths,
)


# --- DR numbering ---

def test_next_dr_number_empty_dir(tmp_path):
    assert next_dr_number(tmp_path) == "0001"

def test_next_dr_number_sequential(tmp_path):
    (tmp_path / "0001-foo.md").touch()
    (tmp_path / "0002-bar.md").touch()
    assert next_dr_number(tmp_path) == "0003"

def test_next_dr_number_fills_gap(tmp_path):
    (tmp_path / "0001-foo.md").touch()
    (tmp_path / "0003-bar.md").touch()
    assert next_dr_number(tmp_path) == "0002"

def test_next_dr_number_missing_dir(tmp_path):
    assert next_dr_number(tmp_path / "nonexistent") == "0001"


# --- template rendering ---

def test_render_lite_contains_frontmatter():
    rendered = render_dr_template("auth-approach", "0001", "lite", "inception", "2026-01-15")
    assert "artifact_type: decision-record" in rendered
    assert "phase: inception" in rendered
    assert "status: draft" in rendered
    assert "artifact_id: DR-0001" in rendered
    assert "intent: auth-approach" in rendered

def test_render_full_contains_frontmatter():
    rendered = render_dr_template("auth-approach", "0002", "full", "construction", "2026-01-15", unit="checkout")
    assert "artifact_type: decision-record" in rendered
    assert "phase: construction" in rendered
    assert "artifact_id: DR-0002" in rendered
    assert "unit: checkout" in rendered

def test_render_dr_number_substituted():
    rendered = render_dr_template("foo", "0005", "lite", "inception", "2026-01-15")
    assert "DR-0005" in rendered
    assert "DR-NNNN" not in rendered

def test_render_no_stale_date_placeholders():
    rendered = render_dr_template("foo", "0001", "full", "inception", "2026-01-15")
    assert "YYYY-MM-DD" not in rendered

def test_render_unit_omitted_when_none():
    rendered = render_dr_template("foo", "0001", "lite", "inception", "2026-01-15", unit=None)
    assert "unit:" not in rendered


# --- path resolution ---

def test_resolve_paths_filename(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths = resolve_paths("auth-approach", "inception", docs_root=docs_root)
    assert paths.output_file.name == "0001-auth-approach.md"
    assert paths.dr_number == "0001"
    assert paths.artifact_id == "DR-0001"

def test_resolve_paths_invalid_phase(tmp_path):
    with pytest.raises(ValueError, match="Invalid phase"):
        resolve_paths("foo", "invalid", docs_root=tmp_path)


# --- init ---

def test_init_lite_creates_file(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths, created = init_dr("auth-approach", "lite", "inception", docs_root=docs_root)
    assert created is True
    assert paths.output_file.exists()
    assert paths.output_file.name == "0001-auth-approach.md"
    content = paths.output_file.read_text()
    assert "artifact_type: decision-record" in content

def test_init_full_creates_file(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths, created = init_dr("db-choice", "full", "construction", unit="checkout", docs_root=docs_root)
    assert created is True
    assert "unit: checkout" in paths.output_file.read_text()

def test_init_is_idempotent(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    _, created1 = init_dr("auth-approach", "lite", "inception", docs_root=docs_root)
    _, created2 = init_dr("auth-approach", "lite", "inception", docs_root=docs_root)
    assert created1 is True
    assert created2 is False

def test_init_auto_increments(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths1, _ = init_dr("first", "lite", "inception", docs_root=docs_root)
    paths2, _ = init_dr("second", "lite", "inception", docs_root=docs_root)
    assert paths1.dr_number == "0001"
    assert paths2.dr_number == "0002"

def test_init_creates_brainstorming_dir(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths, _ = init_dr("foo", "lite", "inception", docs_root=docs_root)
    assert paths.brainstorming_root.is_dir()

def test_init_invalid_format(tmp_path):
    with pytest.raises(ValueError, match="Invalid format"):
        init_dr("foo", "invalid", "inception", docs_root=tmp_path)


# --- status ---

def test_parse_status_from_frontmatter():
    content = "---\nartifact_type: decision-record\nstatus: approved\n---\n# DR\n"
    assert parse_status(content) == "approved"

def test_parse_status_unknown():
    assert parse_status("# No frontmatter") == "unknown"

def test_get_status_missing(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    status = get_status("nonexistent", "inception", docs_root=docs_root)
    assert status["exists"] is False
    assert status["status"] == "missing"

def test_get_status_existing(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    init_dr("auth-approach", "lite", "inception", docs_root=docs_root)
    status = get_status("auth-approach", "inception", docs_root=docs_root)
    assert status["exists"] is True
    assert status["status"] == "draft"
    assert status["artifact_id"] == "DR-0001"


# --- config resolution ---

def test_config_docs_root_resolution(tmp_path):
    config_dir = tmp_path / ".mtv-aidlc"
    config_dir.mkdir()
    custom_docs = tmp_path / "custom-docs"
    (config_dir / "extension-config.json").write_text(
        json.dumps({"aidlcDocsPath": "custom-docs"})
    )
    paths = resolve_paths("foo", "inception", repo_root=tmp_path)
    assert paths.docs_root == custom_docs.resolve()
