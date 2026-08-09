#!/usr/bin/env python3
"""
Generate references/mds-tokens.json from apps/magenta/packages/css/src/tokens.ts.

Produces indexes used by extract_spec.py Layer 4:
  - hex_to_var:     "#rrggbb" -> "var(--mag-colors-primary-500)"
  - px_to_spacing:  "8px"     -> "var(--mag-spacing-8)"   (spacing + sizes)
  - px_to_radius:   "4px"     -> "var(--mag-radii-md)"
    - family_to_font: "noto sans" -> "var(--mag-fonts-primary)"
    - px_to_font_size: "15px" -> "var(--mag-font-sizes-md)"
    - weight_to_font_weight: "600" -> "var(--mag-font-weights-semi-bold)"
    - px_to_line_height: "24px" -> "var(--mag-line-heights-2xl)"
    - px_to_letter_spacing: "0px" -> "var(--mag-letter-spacings-normal)"

Run from any directory — paths are resolved relative to this script:
  python3 .claude/skills/figma-design/scripts/generate_mds_reference.py

Output: .claude/skills/figma-design/references/mds-tokens.json
"""

import json
import re
import sys
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent
TOKENS_SRC = SKILL_DIR.parent.parent.parent / "apps/magenta/packages/css/src/tokens.ts"
OUT_PATH = SKILL_DIR / "references/mds-tokens.json"


def resolve_rem(value: str) -> str | None:
    """Convert rem string to px string, e.g. '0.5rem' -> '8px'."""
    m = re.fullmatch(r"([\d.]+)rem", value.strip())
    if not m:
        return None
    return f"{round(float(m.group(1)) * 16)}px"


def normalize_hex(value: str) -> str | None:
    """Lowercase and return hex color, or None if not a color."""
    v = value.strip().lower()
    if re.fullmatch(r"#[0-9a-f]{3,8}", v):
        # Expand 3-digit shorthand
        if len(v) == 4:
            v = "#" + "".join(c * 2 for c in v[1:])
        return v
    return None


def normalize_font_family(value: str) -> str | None:
    """Normalize a font-family declaration to its primary family name."""
    primary = value.split(",", 1)[0].strip().strip("\"'")
    if not primary:
        return None
    return primary.lower()


def to_css_var(path: str) -> str:
    """Convert a token path like fontSizes.md to var(--mag-font-sizes-md)."""
    kebab = re.sub(r"([a-z0-9])([A-Z])", r"\1-\2", path).replace(".", "-").lower()
    return f"var(--mag-{kebab})"


def parse_tokens_ts(src: str) -> dict:
    """
    Minimal TypeScript object parser for the flat `tokens = { ... }` structure
    in tokens.ts. Handles nested objects with numeric and string keys.
    Extracts name->value pairs where value is a string literal inside { value: '...' }.
    """
    # Strip TS export wrapper, comments, trailing commas
    src = re.sub(r"//[^\n]*", "", src)
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.DOTALL)

    entries: dict[str, str] = {}

    # Match patterns like:  key: { value: 'VALUE' }
    # Key can be quoted ('foo') or unquoted (foo) or numeric (100)
    token_pattern = re.compile(
        r"""(?:'([^']+)'|"([^"]+)"|(\w+))\s*:\s*\{\s*value\s*:\s*(?:'([^']*)'|"([^"]*)")\s*\}""",
        re.MULTILINE,
    )

    # Walk sections: collect category path by tracking brace depth
    # We do a two-pass: first flatten into path->value, then interpret
    def _walk(text: str, prefix: tuple = ()) -> None:
        # Find top-level keys and their blocks
        pos = 0
        key_re = re.compile(
            r"""(?:'([^']+)'|"([^"]+)"|(\w[\w-]*))\s*:\s*"""
        )
        while pos < len(text):
            m = key_re.search(text, pos)
            if not m:
                break
            key = m.group(1) or m.group(2) or m.group(3)
            after = text[m.end():]
            # Check if value is a simple string literal
            simple = re.match(r"""['"]([^'"]*)['"]\s*[,}]?""", after.lstrip())
            if simple:
                entries[".".join(prefix + (key,))] = simple.group(1)
                pos = m.end() + simple.end()
                continue
            # Check if value is an object { ... }
            if after.lstrip().startswith("{"):
                brace_start = m.end() + after.index("{")
                # Find matching closing brace
                depth = 0
                i = brace_start
                while i < len(text):
                    if text[i] == "{":
                        depth += 1
                    elif text[i] == "}":
                        depth -= 1
                        if depth == 0:
                            break
                    i += 1
                inner = text[brace_start + 1 : i]
                # Check if it's a leaf { value: '...' }
                leaf = re.match(
                    r"""\s*value\s*:\s*(?:'([^']*)'|"([^"]*)")\s*""", inner
                )
                if leaf:
                    entries[".".join(prefix + (key,))] = leaf.group(1) or leaf.group(2) or ""
                else:
                    _walk(inner, prefix + (key,))
                pos = i + 1
                continue
            pos = m.end()

    # Strip the outer `export const tokens = { ... };`
    outer = re.search(r"export\s+const\s+tokens\s*=\s*\{(.+)\};?\s*$", src, re.DOTALL)
    if not outer:
        print("Error: could not find `export const tokens = { ... }` in tokens.ts", file=sys.stderr)
        sys.exit(1)

    _walk(outer.group(1))
    return entries


def build_indexes(entries: dict[str, str]) -> dict:
    hex_to_var: dict[str, str] = {}
    px_to_spacing: dict[str, str] = {}
    px_to_radius: dict[str, str] = {}
    px_to_size: dict[str, str] = {}
    family_to_font: dict[str, str] = {}
    px_to_font_size: dict[str, str] = {}
    weight_to_font_weight: dict[str, str] = {}
    px_to_line_height: dict[str, str] = {}
    px_to_letter_spacing: dict[str, str] = {}

    for path, raw_value in entries.items():
        parts = path.split(".")
        category = parts[0] if parts else ""
        css_var = to_css_var(path)

        value = raw_value.strip()

        # Resolve rem to px for numeric comparisons
        px_value = value if value.endswith("px") else resolve_rem(value)

        if category == "colors":
            hex_val = normalize_hex(value)
            if hex_val:
                # Lower-shade tokens (higher specificity) overwrite higher-shade ones
                if hex_val not in hex_to_var:
                    hex_to_var[hex_val] = css_var
                # Primary color gets priority over generic palette names
                elif "primary" in path or "secondary" in path:
                    hex_to_var[hex_val] = css_var

        elif category == "spacing":
            if px_value:
                if px_value not in px_to_spacing:
                    px_to_spacing[px_value] = css_var

        elif category == "sizes":
            if px_value:
                if px_value not in px_to_size:
                    px_to_size[px_value] = css_var

        elif category == "radii":
            if px_value:
                if px_value not in px_to_radius:
                    px_to_radius[px_value] = css_var

        elif category == "fonts":
            family = normalize_font_family(value)
            if family and family not in family_to_font:
                family_to_font[family] = css_var

        elif category == "fontSizes":
            if px_value and px_value not in px_to_font_size:
                px_to_font_size[px_value] = css_var

        elif category == "fontWeights":
            weight = value.strip()
            if weight and weight not in weight_to_font_weight:
                weight_to_font_weight[weight] = css_var

        elif category == "lineHeights":
            if px_value and px_value not in px_to_line_height:
                px_to_line_height[px_value] = css_var

        elif category == "letterSpacings":
            if px_value and px_value not in px_to_letter_spacing:
                px_to_letter_spacing[px_value] = css_var

    # Merge sizes into spacing (spacing is more semantically correct for padding/gap)
    merged_spacing = {**px_to_size, **px_to_spacing}  # spacing wins over sizes

    return {
        "hex_to_var": hex_to_var,
        "px_to_spacing": merged_spacing,
        "px_to_radius": px_to_radius,
        "family_to_font": family_to_font,
        "px_to_font_size": px_to_font_size,
        "weight_to_font_weight": weight_to_font_weight,
        "px_to_line_height": px_to_line_height,
        "px_to_letter_spacing": px_to_letter_spacing,
    }


def main():
    if not TOKENS_SRC.exists():
        print(f"Error: tokens source not found at {TOKENS_SRC}", file=sys.stderr)
        print("Run this script from within the d-odyssey repo.", file=sys.stderr)
        sys.exit(1)

    src = TOKENS_SRC.read_text(encoding="utf-8")
    entries = parse_tokens_ts(src)

    if not entries:
        print("Error: no token entries parsed — check the tokens.ts format.", file=sys.stderr)
        sys.exit(1)

    indexes = build_indexes(entries)
    indexes["_source"] = str(TOKENS_SRC.relative_to(SKILL_DIR.parent.parent.parent))
    indexes["_token_count"] = len(entries)

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(indexes, indent=2, ensure_ascii=False), encoding="utf-8")

    color_count = len(indexes["hex_to_var"])
    spacing_count = len(indexes["px_to_spacing"])
    radius_count = len(indexes["px_to_radius"])
    typography_count = (
        len(indexes["family_to_font"])
        + len(indexes["px_to_font_size"])
        + len(indexes["weight_to_font_weight"])
        + len(indexes["px_to_line_height"])
        + len(indexes["px_to_letter_spacing"])
    )
    print(
        f"Generated {OUT_PATH.relative_to(Path.cwd())}\n"
        f"  {len(entries)} tokens → {color_count} colors, {spacing_count} spacing, {radius_count} radii, {typography_count} typography refs",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
