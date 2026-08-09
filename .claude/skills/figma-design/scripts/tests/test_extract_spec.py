from conftest import load_script_module


extract_spec = load_script_module("extract_spec")


class TestStyleAndVariableIndexes:
    def test_build_style_name_index_collects_all_style_groups(self):
        data = {
            "styles": {
                "colors": [{"id": "color-1", "name": "color/text/primary"}],
                "text": [{"id": "text-1", "name": "text/body/md"}],
                "effects": [{"id": "effect-1", "name": "shadow/sm"}],
                "grids": [{"id": "grid-1", "name": "grid/base"}],
            }
        }

        assert extract_spec.build_style_name_index(data) == {
            "color-1": "color/text/primary",
            "text-1": "text/body/md",
            "effect-1": "shadow/sm",
            "grid-1": "grid/base",
        }

    def test_build_variable_name_index_supports_alias_forms(self):
        data = {
            "variables": {
                "meta": {
                    "variables": {
                        "VariableID:10:20": {
                            "id": "10:20",
                            "key": "VariableID:10:20",
                            "name": "colors/text/primary",
                        }
                    }
                }
            }
        }

        index = extract_spec.build_variable_name_index(data)

        assert index["VariableID:10:20"] == "colors/text/primary"
        assert index["10:20"] == "colors/text/primary"

    def test_resolve_variable_alias_name_falls_back_to_input(self):
        assert extract_spec.resolve_variable_alias_name("missing", {}) == "missing"


class TestDescribeChildElements:
    def test_uses_explicit_color_hex_index_for_token_lookup(self):
        children = [
            {
                "name": "Label",
                "type": "TEXT",
                "characters": "CTA",
                "fills": [
                    {
                        "type": "SOLID",
                        "visible": True,
                        "color": {"r": 0.0, "g": 0.0, "b": 0.0},
                    }
                ],
                "style": {"fontSize": 14, "fontWeight": 600},
                "bindings": {},
            }
        ]

        lines = extract_spec.describe_child_elements(
            children,
            style_name_index={},
            variable_name_index={},
            color_hex_index={"#000000": "color/text/primary"},
        )

        assert lines == [
            "- `Label` (text): \"CTA\" — color: `#000000` — token: `color/text/primary` — 14px/600"
        ]

    def test_prefers_bound_variable_tokens_when_present(self):
        children = [
            {
                "name": "Icon",
                "type": "VECTOR",
                "fills": [
                    {
                        "type": "SOLID",
                        "visible": True,
                        "color": {"r": 1.0, "g": 1.0, "b": 1.0},
                        "boundVariables": {
                            "color": {"type": "VARIABLE_ALIAS", "id": "10:20"}
                        },
                    }
                ],
                "bindings": {},
                "style": {},
            }
        ]

        lines = extract_spec.describe_child_elements(
            children,
            style_name_index={},
            variable_name_index={"10:20": "colors/icon/inverse"},
            color_hex_index={"#ffffff": "color/icon/fallback"},
        )

        assert "token: `colors/icon/inverse`" in lines[0]


class TestMarkdownEscaping:
    def test_table_cell_escapes_pipes_and_newlines(self):
        assert extract_spec.md_table_cell("A | B\nC") == r"A \| B C"

    def test_inline_code_uses_longer_backtick_fence(self):
        assert extract_spec.md_code("has ` tick") == "`` has ` tick ``"


class TestMdsOptIn:
    def test_should_not_apply_mds_without_request_or_foundation(self, tmp_path, monkeypatch):
        monkeypatch.chdir(tmp_path)
        input_path = tmp_path / "temp" / "figma_sample" / "figma-spec.json"

        assert extract_spec.should_apply_mds(input_path) is False

    def test_should_apply_mds_when_foundation_guideline_mentions_it(self, tmp_path, monkeypatch):
        monkeypatch.chdir(tmp_path)
        guideline = tmp_path / "aidlc-docs" / "foundation" / "uiux-guideline.md"
        guideline.parent.mkdir(parents=True)
        guideline.write_text("Use the Magenta Design System for product UI.", encoding="utf-8")
        input_path = tmp_path / "temp" / "figma_sample" / "figma-spec.json"

        assert extract_spec.should_apply_mds(input_path) is True
        assert extract_spec.should_apply_mds(input_path, disabled=True) is False

    def test_build_markdown_spec_omits_mds_mappings_by_default(self, tmp_path, monkeypatch):
        mds_reference = tmp_path / "mds-tokens.json"
        mds_reference.write_text(
            """
            {
              "hex_to_var": {"#123456": "var(--mag-colors-primary-500)"},
              "px_to_spacing": {},
              "px_to_radius": {},
              "family_to_font": {},
              "px_to_font_size": {},
              "weight_to_font_weight": {},
              "px_to_line_height": {},
              "px_to_letter_spacing": {}
            }
            """,
            encoding="utf-8",
        )
        monkeypatch.setattr(extract_spec, "MDS_REFERENCE_PATH", mds_reference)
        data = {
            "file_name": "Sample",
            "file_key": "abc",
            "target_node": {
                "name": "Card",
                "type": "FRAME",
                "fills": [
                    {
                        "type": "SOLID",
                        "visible": True,
                        "color": {"r": 0x12 / 255, "g": 0x34 / 255, "b": 0x56 / 255},
                    }
                ],
            },
        }

        default_markdown = extract_spec.build_markdown_spec(data)
        mds_markdown = extract_spec.build_markdown_spec(data, apply_mds=True)

        assert "var(--mag-colors-primary-500)" not in default_markdown
        assert "var(--mag-colors-primary-500)" in mds_markdown
