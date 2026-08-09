from conftest import load_script_module


generate_mds_reference = load_script_module("generate_mds_reference")


class TestTokenParsing:
    def test_parse_tokens_ts_extracts_nested_values(self):
        src = """
        export const tokens = {
          colors: {
            primary: {
              '500': { value: '#3366ff' },
            },
          },
          spacing: {
            md: { value: '8px' },
          },
          fontSizes: {
            md: { value: '1rem' },
          },
        };
        """

        entries = generate_mds_reference.parse_tokens_ts(src)

        assert entries["colors.primary.500"] == "#3366ff"
        assert entries["spacing.md"] == "8px"
        assert entries["fontSizes.md"] == "1rem"


class TestBuildIndexes:
    def test_build_indexes_normalizes_and_merges_spacing(self):
        indexes = generate_mds_reference.build_indexes(
            {
                "colors.primary.500": "#3366ff",
                "spacing.md": "8px",
                "sizes.control": "8px",
                "radii.md": "4px",
                "fonts.primary": '"Noto Sans", sans-serif',
                "fontSizes.md": "1rem",
                "fontWeights.semiBold": "600",
                "lineHeights.xl": "1.5rem",
                "letterSpacings.normal": "0px",
            }
        )

        assert indexes["hex_to_var"]["#3366ff"] == "var(--mag-colors-primary-500)"
        assert indexes["px_to_spacing"]["8px"] == "var(--mag-spacing-md)"
        assert indexes["px_to_radius"]["4px"] == "var(--mag-radii-md)"
        assert indexes["family_to_font"]["noto sans"] == "var(--mag-fonts-primary)"
        assert indexes["px_to_font_size"]["16px"] == "var(--mag-font-sizes-md)"
        assert indexes["weight_to_font_weight"]["600"] == "var(--mag-font-weights-semi-bold)"
        assert indexes["px_to_line_height"]["24px"] == "var(--mag-line-heights-xl)"
        assert indexes["px_to_letter_spacing"]["0px"] == "var(--mag-letter-spacings-normal)"

    def test_normalize_hex_expands_shorthand(self):
        assert generate_mds_reference.normalize_hex("#abc") == "#aabbcc"