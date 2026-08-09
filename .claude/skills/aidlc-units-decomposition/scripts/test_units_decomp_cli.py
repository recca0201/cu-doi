"""Tests for units_decomp_cli."""

import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_aidlc-shared" / "scripts"))

from units_decomp_cli import (
    DecompPaths,
    get_status,
    init_decomp,
    next_artifact_id,
    parse_status,
    render_decomp_template,
    resolve_paths,
    slug_to_display_name,
)


def test_slug_to_display_name():
    assert slug_to_display_name("user-auth") == "User Auth"
    assert slug_to_display_name("payment_system") == "Payment System"
    assert slug_to_display_name("checkout") == "Checkout"


def test_next_artifact_id_empty_dir(tmp_path):
    assert next_artifact_id(tmp_path) == "001"


def test_next_artifact_id_fills_gap(tmp_path):
    (tmp_path / "001_foo_units_decomposition.md").touch()
    (tmp_path / "003_bar_units_decomposition.md").touch()
    assert next_artifact_id(tmp_path) == "002"


def test_next_artifact_id_sequential(tmp_path):
    (tmp_path / "001_foo_units_decomposition.md").touch()
    (tmp_path / "002_bar_units_decomposition.md").touch()
    assert next_artifact_id(tmp_path) == "003"


def test_next_artifact_id_missing_dir(tmp_path):
    assert next_artifact_id(tmp_path / "nonexistent") == "001"


def test_render_decomp_template_contains_title():
    rendered = render_decomp_template("user-auth", "001", "2026-01-15")
    assert "User Auth" in rendered
    assert "---" in rendered
    assert "artifact_type: unit-decomposition" in rendered
    assert "phase: inception" in rendered
    assert "status: draft" in rendered
    assert "created: 2026-01-15" in rendered
    assert "artifact_id: 001" in rendered


def test_render_decomp_template_no_placeholder_dates():
    rendered = render_decomp_template("checkout", "002", "2026-06-01")
    assert "<YYYY-MM-DD>" not in rendered
    assert "<Project Name>" not in rendered
    assert "[Project Name]" not in rendered


def test_init_creates_file(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths, created = init_decomp("user-auth", docs_root=docs_root)
    assert created is True
    assert paths.decomp_file.exists()
    assert paths.decomp_file.name == "001_user-auth_units_decomposition.md"
    content = paths.decomp_file.read_text()
    assert "artifact_type: unit-decomposition" in content


def test_init_is_idempotent(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths1, created1 = init_decomp("user-auth", docs_root=docs_root)
    paths2, created2 = init_decomp("user-auth", artifact_id="001", docs_root=docs_root)
    assert created1 is True
    assert created2 is False
    assert paths1.decomp_file == paths2.decomp_file


def test_init_auto_increments_id(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths1, _ = init_decomp("user-auth", docs_root=docs_root)
    paths2, _ = init_decomp("payment", docs_root=docs_root)
    assert paths1.artifact_id == "001"
    assert paths2.artifact_id == "002"


def test_init_explicit_id(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths, created = init_decomp("checkout", artifact_id="005", docs_root=docs_root)
    assert created is True
    assert paths.artifact_id == "005"
    assert paths.decomp_file.name == "005_checkout_units_decomposition.md"


def test_parse_status_from_frontmatter():
    content = "---\nartifact_type: unit-decomposition\nstatus: approved\n---\n# Title\n"
    assert parse_status(content) == "approved"


def test_parse_status_unknown_without_frontmatter():
    assert parse_status("# No frontmatter here") == "unknown"


def test_get_status_missing(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    status = get_status("nonexistent", docs_root=docs_root)
    assert status["exists"] is False
    assert status["status"] == "missing"


def test_get_status_existing(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    init_decomp("user-auth", docs_root=docs_root)
    status = get_status("user-auth", artifact_id="001", docs_root=docs_root)
    assert status["exists"] is True
    assert status["status"] == "draft"
    assert status["feature_slug"] == "user-auth"


def test_config_docs_root_resolution(tmp_path):
    config_dir = tmp_path / ".mtv-aidlc"
    config_dir.mkdir()
    custom_docs = tmp_path / "custom-docs"
    (config_dir / "extension-config.json").write_text(
        json.dumps({"aidlcDocsPath": "custom-docs"})
    )
    paths = resolve_paths("checkout", repo_root=tmp_path)
    assert paths.docs_root == custom_docs.resolve()
