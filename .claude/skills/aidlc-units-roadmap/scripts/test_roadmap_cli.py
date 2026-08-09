"""Tests for roadmap_cli."""

import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_aidlc-shared" / "scripts"))

from roadmap_cli import (
    get_status,
    init_roadmap,
    parse_status,
    render_roadmap_template,
    resolve_paths,
    slug_to_display_name,
)


def test_slug_to_display_name():
    assert slug_to_display_name("user-auth") == "User Auth"
    assert slug_to_display_name("payment_system") == "Payment System"
    assert slug_to_display_name("checkout") == "Checkout"


def test_render_roadmap_template_contains_title():
    rendered = render_roadmap_template("user-auth", "2026-01-15")
    assert "User Auth" in rendered
    assert "---" in rendered
    assert "artifact_type: roadmap" in rendered
    assert "phase: inception" in rendered
    assert "status: draft" in rendered
    assert "created: 2026-01-15" in rendered
    assert "intent: user-auth" in rendered


def test_render_roadmap_template_no_stale_placeholders():
    rendered = render_roadmap_template("checkout", "2026-06-01")
    assert "<YYYY-MM-DD>" not in rendered
    assert "<Project Name>" not in rendered
    assert "[Project Name]" not in rendered
    assert "**Project**:" not in rendered
    assert "**Created By**:" not in rendered
    assert "_Template:" not in rendered


def test_init_creates_file(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths, created = init_roadmap("user-auth", docs_root=docs_root)
    assert created is True
    assert paths.roadmap_file.exists()
    assert paths.roadmap_file.name == "user-auth_product_roadmap.md"
    content = paths.roadmap_file.read_text()
    assert "artifact_type: roadmap" in content


def test_init_is_idempotent(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths1, created1 = init_roadmap("user-auth", docs_root=docs_root)
    paths2, created2 = init_roadmap("user-auth", docs_root=docs_root)
    assert created1 is True
    assert created2 is False
    assert paths1.roadmap_file == paths2.roadmap_file


def test_init_creates_roadmap_dir(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths, _ = init_roadmap("checkout", docs_root=docs_root)
    assert paths.roadmap_root.is_dir()
    assert paths.roadmap_root.name == "roadmap"


def test_resolve_paths_filename(tmp_path):
    docs_root = tmp_path / "aidlc-docs"
    paths = resolve_paths("payment-system", docs_root=docs_root)
    assert paths.roadmap_file.name == "payment-system_product_roadmap.md"


def test_parse_status_from_frontmatter():
    content = "---\nartifact_type: roadmap\nstatus: approved\n---\n# Title\n"
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
    init_roadmap("user-auth", docs_root=docs_root)
    status = get_status("user-auth", docs_root=docs_root)
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
