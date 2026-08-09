from pathlib import Path

from conftest import load_script_module


figma_client = load_script_module("figma_client")


class TestParseFigmaUrl:
    def test_parses_design_url_with_node_id(self):
        file_key, node_id = figma_client.parse_figma_url(
            "https://www.figma.com/design/FILE123/Screen?node-id=4812-38472"
        )

        assert file_key == "FILE123"
        assert node_id == "4812:38472"

    def test_parses_file_url_without_node_id(self):
        file_key, node_id = figma_client.parse_figma_url(
            "https://www.figma.com/file/FILE456/Screen"
        )

        assert file_key == "FILE456"
        assert node_id is None


class TestScopeHelpers:
    def test_derive_scope_prefers_node_name(self):
        assert figma_client.derive_scope("Login Screen", "Design System", "abc123") == "login-screen"

    def test_derive_scope_falls_back_to_file_name(self):
        assert figma_client.derive_scope(None, "Design System", "abc123") == "design-system"

    def test_default_output_path_uses_cwd_temp_folder(self, monkeypatch, tmp_path):
        monkeypatch.chdir(tmp_path)

        output = figma_client.default_output_path("button")

        assert output == tmp_path / "temp" / "figma_button" / "figma-spec.json"


class TestExportArgParsing:
    def test_none_disables_export(self):
        assert figma_client.parse_export_arg(None) is None

    def test_blank_string_means_export_all(self):
        assert figma_client.parse_export_arg("") == []

    def test_comma_separated_string_returns_names(self):
        assert figma_client.parse_export_arg("hero, empty state ,cta") == ["hero", "empty state", "cta"]


class TestSlugifyName:
    def test_slugify_name_normalizes_common_separators(self):
        assert figma_client.slugify_name("Icon / Arrow_Right") == "icon-arrow-right"


class TestChildImageCandidates:
    def test_collects_direct_frames_and_components(self):
        target = {
            "children": [
                {"id": "1:1", "name": "Default", "type": "FRAME", "layout": {"width": 320, "height": 200}},
                {"id": "1:2", "name": "Error", "type": "COMPONENT", "layout": {"width": 320, "height": 200}},
                {"id": "1:3", "name": "Icon", "type": "FRAME", "layout": {"width": 24, "height": 24}},
            ]
        }

        candidates = figma_client.collect_child_image_candidates(target)

        assert [c["id"] for c in candidates] == ["1:1", "1:2"]

    def test_collects_component_set_variants(self):
        target = {
            "type": "COMPONENT_SET",
            "variants": [
                {"id": "2:1", "name": "State=Default", "type": "COMPONENT", "layout": {"width": 240, "height": 80}},
                {"id": "2:2", "name": "State=Hover", "type": "COMPONENT", "layout": {"width": 240, "height": 80}},
            ],
        }

        candidates = figma_client.collect_child_image_candidates(target)

        assert [c["id"] for c in candidates] == ["2:1", "2:2"]

    def test_extract_component_set_variants_preserves_type_for_child_images(self):
        component_set = {
            "id": "4:1",
            "name": "Button",
            "type": "COMPONENT_SET",
            "absoluteBoundingBox": {"width": 500, "height": 200},
            "children": [
                {
                    "id": "4:2",
                    "name": "State=Default",
                    "type": "COMPONENT",
                    "absoluteBoundingBox": {"width": 200, "height": 80},
                }
            ],
        }

        spec = figma_client.extract_component_spec(component_set)

        assert spec["variants"][0]["type"] == "COMPONENT"

    def test_collects_nested_frames_under_wrappers_when_direct_children_are_not_exportable(self):
        target = {
            "children": [
                {
                    "id": "3:1",
                    "name": "Wrapper",
                    "type": "GROUP",
                    "layout": {"width": 800, "height": 400},
                    "children": [
                        {"id": "3:2", "name": "Expanded", "type": "FRAME", "layout": {"width": 360, "height": 260}},
                        {"id": "3:3", "name": "Collapsed", "type": "INSTANCE", "layout": {"width": 360, "height": 120}},
                    ],
                }
            ]
        }

        candidates = figma_client.collect_child_image_candidates(target)

        assert [c["id"] for c in candidates] == ["3:2", "3:3"]

    def test_prefers_nested_states_when_single_direct_frame_wraps_multiple_candidates(self):
        target = {
            "children": [
                {
                    "id": "5:1",
                    "name": "Board Wrapper",
                    "type": "FRAME",
                    "layout": {"width": 1200, "height": 600},
                    "children": [
                        {"id": "5:2", "name": "Default", "type": "FRAME", "layout": {"width": 360, "height": 260}},
                        {"id": "5:3", "name": "Error", "type": "FRAME", "layout": {"width": 360, "height": 260}},
                    ],
                }
            ]
        }

        candidates = figma_client.collect_child_image_candidates(target)

        assert [c["id"] for c in candidates] == ["5:2", "5:3"]


class TestReferencedComponentFetching:
    def test_reports_component_ids_missing_from_api_response(self, monkeypatch):
        def fake_figma_get(_token, _path):
            return {
                "nodes": {
                    "1:1": {
                        "document": {
                            "id": "1:1",
                            "name": "Button",
                            "type": "COMPONENT",
                            "absoluteBoundingBox": {"width": 120, "height": 40},
                        }
                    }
                }
            }

        monkeypatch.setattr(figma_client, "figma_get", fake_figma_get)

        specs, missing = figma_client.fetch_component_specs_with_missing(
            "token",
            "file-key",
            {"1:1", "2:2"},
        )

        assert [spec["id"] for spec in specs] == ["1:1"]
        assert missing == {"2:2"}
