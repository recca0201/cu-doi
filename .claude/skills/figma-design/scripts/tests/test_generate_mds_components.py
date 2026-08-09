from pathlib import Path

from conftest import load_script_module


generate_mds_components = load_script_module("generate_mds_components")


class TestParseUnionProp:
    def test_accepts_string_literal_union(self):
        assert generate_mds_components.parse_union_prop("'sm' | 'md' | 'lg'") == ["sm", "md", "lg"]

    def test_rejects_mixed_non_literal_union(self):
        assert generate_mds_components.parse_union_prop("React.ReactNode | 'sm'") is None

    def test_rejects_css_global_literals(self):
        assert generate_mds_components.parse_union_prop("'inherit' | 'initial'") is None


class TestParseModelFile:
    def test_extracts_variant_props_and_skips_structural_fields(self, tmp_path):
        model_file = tmp_path / "Button.model.ts"
        model_file.write_text(
            """
            export interface ButtonProps {
              size?: 'sm' | 'md' | 'lg';
              variant: 'fill' | 'outline';
              children?: React.ReactNode;
              onClick?: () => void;
              objectFit?: 'contain' | 'inherit';
            }
            """,
            encoding="utf-8",
        )

        props = generate_mds_components.parse_model_file(model_file)

        assert props == {
            "size": ["sm", "md", "lg"],
            "variant": ["fill", "outline"],
        }

    def test_component_name_from_path_removes_model_suffix(self):
        assert generate_mds_components.component_name_from_path(Path("AccordionItem.model.ts")) == "AccordionItem"