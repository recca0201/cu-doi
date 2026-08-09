#!/usr/bin/env python3
"""
Converts figma_client.py JSON output into a structured AI-readable design spec.

Formats:
  md       — Markdown spec for Claude/AI context (default)
  css      — CSS custom properties
  tailwind — Tailwind config theme section
  tokens   — Style Dictionary-compatible design tokens JSON

Usage:
  python3 extract_spec.py --input figma.json --output figma-spec.md
  python3 extract_spec.py --input figma.json --format css --output tokens.css
  python3 extract_spec.py --input figma.json --format tailwind --output tailwind.config.js
  python3 extract_spec.py --input figma.json --format tokens --output tokens.json
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Optional

SKILL_DIR = Path(__file__).resolve().parent.parent
MDS_REFERENCE_PATH = SKILL_DIR / "references/mds-tokens.json"
FOUNDATION_UIUX_GUIDELINE = Path("aidlc-docs/foundation/uiux-guideline.md")
MDS_FOUNDATION_PATTERN = re.compile(r"\bMDS\b|Magenta\s+Design\s+System", re.IGNORECASE)


def load_mds_reference() -> dict:
    """Load the MDS token reference file if it exists. Returns empty dicts on miss."""
    empty = {
        "hex_to_var": {},
        "px_to_spacing": {},
        "px_to_radius": {},
        "family_to_font": {},
        "px_to_font_size": {},
        "weight_to_font_weight": {},
        "px_to_line_height": {},
        "px_to_letter_spacing": {},
    }
    if not MDS_REFERENCE_PATH.exists():
        return empty
    try:
        data = json.loads(MDS_REFERENCE_PATH.read_text(encoding="utf-8"))
        return {
            "hex_to_var": data.get("hex_to_var", {}),
            "px_to_spacing": data.get("px_to_spacing", {}),
            "px_to_radius": data.get("px_to_radius", {}),
            "family_to_font": data.get("family_to_font", {}),
            "px_to_font_size": data.get("px_to_font_size", {}),
            "weight_to_font_weight": data.get("weight_to_font_weight", {}),
            "px_to_line_height": data.get("px_to_line_height", {}),
            "px_to_letter_spacing": data.get("px_to_letter_spacing", {}),
        }
    except Exception:
        return empty


def foundation_mentions_mds(*start_paths: Path) -> bool:
    """Return true when a foundation UI/UX guideline opts into MDS."""
    search_roots: list[Path] = []
    for start_path in (Path.cwd(), *start_paths):
        path = start_path.resolve()
        if path.is_file():
            path = path.parent
        for candidate_root in (path, *path.parents):
            if candidate_root not in search_roots:
                search_roots.append(candidate_root)

    for root in search_roots:
        guideline = root / FOUNDATION_UIUX_GUIDELINE
        if not guideline.exists():
            continue
        try:
            content = guideline.read_text(encoding="utf-8")
        except OSError:
            continue
        if MDS_FOUNDATION_PATTERN.search(content):
            return True
    return False


def should_apply_mds(input_path: Path, *, force: bool = False, disabled: bool = False) -> bool:
    """Apply MDS only when explicitly requested or foundation guidance opts in."""
    if force:
        return True
    if disabled:
        return False
    return foundation_mentions_mds(input_path)


def resolve_mds_color(hex_val: str, mds_ref: dict) -> Optional[str]:
    """Layer 4: look up a hex value in the MDS reference and return the CSS var."""
    return mds_ref["hex_to_var"].get(hex_val.lower())


def resolve_mds_spacing(px_val: str, mds_ref: dict) -> Optional[str]:
    """Layer 4: look up a px spacing/size value in the MDS reference."""
    return mds_ref["px_to_spacing"].get(px_val)


def resolve_mds_radius(px_val: str, mds_ref: dict) -> Optional[str]:
    """Layer 4: look up a px radius value in the MDS reference."""
    return mds_ref["px_to_radius"].get(px_val)


def normalize_font_family(value: str) -> str:
    """Normalize a font-family declaration to its primary family name."""
    return value.split(",", 1)[0].strip().strip("\"'").lower()


def resolve_mds_typography_token(style: dict, mds_ref: dict) -> Optional[str]:
    """Resolve a raw Figma text style to a composite MDS typography token label."""
    parts = []

    font_family = style.get("fontFamily")
    if font_family:
        font_token = mds_ref["family_to_font"].get(normalize_font_family(font_family))
        if font_token:
            parts.append(font_token)

    font_size = format_px_value(style.get("fontSize"))
    if font_size:
        size_token = mds_ref["px_to_font_size"].get(font_size)
        if size_token:
            parts.append(size_token)

    font_weight = style.get("fontWeight")
    if font_weight is not None:
        weight_token = mds_ref["weight_to_font_weight"].get(str(font_weight))
        if weight_token:
            parts.append(weight_token)

    line_height = format_px_value(style.get("lineHeightPx"))
    if line_height:
        line_height_token = mds_ref["px_to_line_height"].get(line_height)
        if line_height_token:
            parts.append(line_height_token)

    letter_spacing = format_px_value(style.get("letterSpacing"))
    if letter_spacing:
        letter_spacing_token = mds_ref["px_to_letter_spacing"].get(letter_spacing)
        if letter_spacing_token and letter_spacing_token != "var(--mag-letter-spacings-normal)":
            parts.append(letter_spacing_token)

    if not parts:
        return None
    return " + ".join(parts)


def _to_relative_path(file_path: str) -> str:
    """Convert an absolute file path to a relative path from CWD, or return as-is if already relative."""
    try:
        return str(Path(file_path).relative_to(Path.cwd()))
    except ValueError:
        return file_path


def _to_slug(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    return text.strip("-") or "figma"


def md_text(value: Any) -> str:
    """Normalize arbitrary Figma-authored text for Markdown output."""
    return re.sub(r"\s+", " ", str(value)).strip()


def md_table_cell(value: Any) -> str:
    """Escape text for a Markdown table cell."""
    return md_text(value).replace("|", r"\|") or "—"


def md_code(value: Any) -> str:
    """Render inline code, choosing a backtick fence that cannot be broken by content."""
    text = md_text(value) or "—"
    longest = max((len(match.group(0)) for match in re.finditer(r"`+", text)), default=0)
    fence = "`" * (longest + 1)
    spacer = " " if longest else ""
    return f"{fence}{spacer}{text}{spacer}{fence}"


def md_code_table_cell(value: Any) -> str:
    return md_table_cell(md_code(value))


def derive_scope(data: dict) -> str:
    node_name = data.get("node_name")
    file_name = data.get("file_name")
    file_key = data.get("file_key", "figma")
    if node_name:
        return _to_slug(node_name)
    if file_name:
        return _to_slug(file_name)[:40]
    return file_key[:16]


def default_output_path(scope: str, fmt: str) -> Path:
    if fmt == "tokens":
        return Path.cwd() / "temp" / f"figma_{scope}" / "figma-spec.tokens.json"
    ext = {"md": "md", "css": "css", "tailwind": "js"}.get(fmt, fmt)
    return Path.cwd() / "temp" / f"figma_{scope}" / f"figma-spec.{ext}"


# ─────────────────────────────────────────────
# Color helpers
# ─────────────────────────────────────────────

def rgba_to_hex(r: float, g: float, b: float, a: float = 1.0) -> str:
    ri, gi, bi = round(r * 255), round(g * 255), round(b * 255)
    if a < 1.0:
        ai = round(a * 255)
        return f"#{ri:02x}{gi:02x}{bi:02x}{ai:02x}"
    return f"#{ri:02x}{gi:02x}{bi:02x}"


def extract_color_from_fills(fills: list) -> Optional[str]:
    for fill in fills:
        if fill.get("type") == "SOLID" and fill.get("visible", True):
            c = fill.get("color", {})
            opacity = fill.get("opacity", 1.0)
            return rgba_to_hex(c.get("r", 0), c.get("g", 0), c.get("b", 0), opacity)
    return None


def build_style_name_index(data: dict) -> dict[str, str]:
    index = {}
    for group in ("colors", "text", "effects", "grids"):
        for style in data.get("styles", {}).get(group, []):
            style_id = style.get("id")
            style_name = style.get("name")
            if style_id and style_name:
                index[style_id] = style_name
    return index


def build_color_hex_index(data: dict) -> dict[str, str]:
    """Map lowercase hex value → color token name, built from the styles.colors list.
    When multiple tokens share the same hex value, tokens containing '--mag-' take priority."""
    index = {}
    for c in data.get("styles", {}).get("colors", []):
        name = c.get("name")
        hex_val = extract_color_from_fills(c.get("fills", []))
        if name and hex_val:
            key = hex_val.lower()
            existing = index.get(key)
            if existing is None or ("--mag-" in name and "--mag-" not in existing):
                index[key] = name
    return index


def build_variable_name_index(data: dict) -> dict[str, str]:
    index = {}
    variables = data.get("variables", {}).get("meta", {}).get("variables", {})
    for var_id, var in variables.items():
        name = var.get("name")
        if not name:
            continue
        candidates = {var_id}
        raw_id = var.get("id")
        if raw_id:
            candidates.add(raw_id)
        key = var.get("key")
        if key:
            candidates.add(key)
        for candidate in list(candidates):
            if candidate.startswith("VariableID:"):
                candidates.add(candidate[len("VariableID:"):])
            if "/" in candidate:
                candidates.add(candidate.split("/", 1)[1])
        for candidate in candidates:
            if candidate:
                index[candidate] = name
    return index


def resolve_variable_alias_name(alias_id: str, variable_name_index: dict[str, str]) -> str:
    candidates = [alias_id]
    if alias_id.startswith("VariableID:"):
        candidates.append(alias_id[len("VariableID:"):])
    if "/" in alias_id:
        candidates.append(alias_id.split("/", 1)[1])
    for candidate in candidates:
        if candidate in variable_name_index:
            return variable_name_index[candidate]
    return alias_id


def extract_token_bindings(node: dict, style_name_index: dict[str, str], variable_name_index: dict[str, str]) -> list[str]:
    bindings = []
    seen = set()

    node_bindings = node.get("bindings", {})
    for key in ("fillStyleId", "strokeStyleId", "effectStyleId", "gridStyleId", "textStyleId"):
        style_id = node_bindings.get(key)
        if style_id:
            label = style_name_index.get(style_id, style_id)
            if label not in seen:
                seen.add(label)
                bindings.append(label)

    variable_sources = []
    if isinstance(node_bindings.get("boundVariables"), dict):
        variable_sources.append(node_bindings["boundVariables"])
    for fill in node.get("fills", []):
        if isinstance(fill.get("boundVariables"), dict):
            variable_sources.append(fill["boundVariables"])

    for source in variable_sources:
        candidates = []
        color_binding = source.get("color")
        if color_binding is not None:
            candidates.append(color_binding)
        fills_binding = source.get("fills")
        if isinstance(fills_binding, list):
            candidates.extend(fills_binding)

        for candidate in candidates:
            if isinstance(candidate, dict) and candidate.get("type") == "VARIABLE_ALIAS":
                alias_id = candidate.get("id")
                if alias_id:
                    label = resolve_variable_alias_name(alias_id, variable_name_index)
                    if label not in seen:
                        seen.add(label)
                        bindings.append(label)

    return bindings


def describe_child_elements(
    children: list[dict],
    style_name_index: dict[str, str],
    variable_name_index: dict[str, str],
    ancestry: Optional[list[str]] = None,
    color_hex_index: Optional[dict[str, str]] = None,
) -> list[str]:
    ancestry = ancestry or []
    descriptions = []

    for child in children:
        path = ancestry + [child.get("name", "Unnamed")]
        child_type = child.get("type", "")
        child_chars = child.get("characters", "")
        child_fill = extract_color_from_fills(child.get("fills", []))
        child_style = child.get("style") or {}
        desc = f"- {md_code(' > '.join(path))} ({child_type.lower()})"
        if child_chars:
            desc += f': "{md_text(child_chars)}"'
        if child_fill:
            desc += f" — color: {md_code(child_fill)}"
            style_token = (color_hex_index or {}).get(child_fill.lower())
            if style_token:
                desc += f" — token: {md_code(style_token)}"
        if child_style.get("fontSize"):
            desc += f" — {child_style['fontSize']}px/{child_style.get('fontWeight', '')}"
        child_bindings = extract_token_bindings(child, style_name_index, variable_name_index)
        if child_bindings:
            desc += f" — token: {', '.join(md_code(binding) for binding in child_bindings)}"
        descriptions.append(desc)

        if child.get("children"):
            descriptions.extend(
                describe_child_elements(
                    child["children"],
                    style_name_index,
                    variable_name_index,
                    path,
                    color_hex_index=color_hex_index,
                )
            )

    return descriptions


def slugify(name: str) -> str:
    return name.lower().replace(" ", "-").replace("/", "-").replace(".", "-")


# ─────────────────────────────────────────────
# Typography helpers
# ─────────────────────────────────────────────


def format_component_properties(props: dict) -> str:
    if not props:
        return ""
    rows = ["| Property | Type | Default | Options |", "|----------|------|---------|---------|"]
    for name, prop in props.items():
        ptype = prop.get("type", "").lower()
        default = prop.get("defaultValue", "")
        options = ""
        if ptype == "variant":
            opts = prop.get("variantOptions", [])
            options = " | ".join(str(opt) for opt in opts)
        rows.append(
            f"| {md_table_cell(name)} | {md_table_cell(ptype)} | "
            f"{md_table_cell(default)} | {md_table_cell(options)} |"
        )
    return "\n".join(rows)


def parse_mag_typography_token(token: Optional[str]) -> dict[str, str]:
    categories: dict[str, str] = {}
    if not token:
        return categories
    for part in token.split(" + "):
        stripped = part.strip()
        match = re.fullmatch(r"var\(--mag-(fonts|font-sizes|font-weights|line-heights|letter-spacings)-([^)]+)\)", stripped)
        if match:
            categories[match.group(1)] = match.group(2)
    return categories


def format_typography_style_label(style: dict, token: Optional[str] = None) -> str:
    """Build a readable label for observed typography rows.

    When we only have raw node styles, keep the first column human-readable and
    move the composite token mapping into its own column.
    """
    categories = parse_mag_typography_token(token)

    font_family = normalize_font_family(style.get("fontFamily", "")) or "text"
    size = format_px_value(style.get("fontSize")) or "size"
    weight = str(style.get("fontWeight", "regular"))
    line_height = format_px_value(style.get("lineHeightPx")) or "auto"

    labels = [
        categories.get("fonts", font_family),
        categories.get("font-sizes", size),
        categories.get("font-weights", weight),
        categories.get("line-heights", line_height),
    ]

    if token:
        return "/".join(labels)
    return f"observed/{'/'.join(labels)}"


def format_typography_token_label(token: Optional[str]) -> str:
    """Render a shorter token string for markdown tables."""
    categories = parse_mag_typography_token(token)
    if not categories:
        return "—"

    parts = []
    order = [
        ("fonts", "font"),
        ("font-sizes", "size"),
        ("font-weights", "weight"),
        ("line-heights", "lh"),
        ("letter-spacings", "ls"),
    ]
    for key, prefix in order:
        value = categories.get(key)
        if value:
            parts.append(f"{prefix}:{value}")
    return " | ".join(parts) if parts else "—"


# ─────────────────────────────────────────────
# Spec builders
# ─────────────────────────────────────────────

def _is_variant_node(comp: dict) -> bool:
    """True for variant instances like 'Property 1=Default' — not standalone component sets."""
    return "=" in comp.get("name", "")


def _is_zero_size_noise(node: dict, has_rendered_children: bool) -> bool:
    """True for zero-size layout artifacts that carry no implementation-relevant data:
    Figma auto-layout ``Resizer`` frames and their ``Start``/``End`` points, and empty
    zero-dimension spacers. Pruning them is lossless for a design handoff and removes the
    bulk of repeated noise on board-style frames (one fixture had 146 such triplets).

    Conservative: only prunes a node with no text and no rendered children. Figma stores
    these artifacts as sub-pixel (0.001px) rather than exactly 0, so a width or height
    below 1px counts as effectively zero. A missing dimension is unknown, not zero, and is
    kept; a container whose children rendered is kept even if it is itself zero-height.
    """
    if node.get("characters") or has_rendered_children:
        return False
    layout = node.get("layout", {}) or {}
    w = layout.get("width")
    h = layout.get("height")
    return (w is not None and w < 1) or (h is not None and h < 1)


def _collapse_repeated_siblings(child_blocks: list[list[str]]) -> list[str]:
    """Collapse consecutive siblings whose entire rendered subtree is identical into one
    block annotated ``(×N identical)``. Lossless: N identical instances become 1 shown +
    a count, instead of N verbatim copies (e.g. repeated table rows, tags, icon slots)."""
    out: list[str] = []
    i = 0
    while i < len(child_blocks):
        j = i
        while j + 1 < len(child_blocks) and child_blocks[j + 1] == child_blocks[i]:
            j += 1
        count = j - i + 1
        block = list(child_blocks[i])
        if count > 1 and block:
            block[0] = f"{block[0]}  (×{count} identical)"
        out.extend(block)
        i = j + 1
    return out


def _compact_hierarchy(
    node: dict,
    style_name_index: dict,
    variable_name_index: dict,
    depth: int = 0,
    max_depth: int = 6,
    color_hex_index: Optional[dict] = None,
    mds_ref: Optional[dict] = None,
) -> list[str]:
    """Single-pass tree: layout + design tokens + text content. Skips pure vector noise,
    prunes zero-size layout artifacts, and collapses identical repeated siblings."""
    if depth > max_depth:
        return []
    # Skip deeply-nested unnamed vectors (implementation detail, not design-relevant)
    if node.get("type") == "VECTOR" and depth > 1:
        return []

    # Render children first so empty/zero-size containers can be pruned and runs of
    # identical siblings collapsed before this node decides whether it is itself noise.
    child_blocks: list[list[str]] = []
    for child in node.get("children", []):
        block = _compact_hierarchy(
            child, style_name_index, variable_name_index,
            depth + 1, max_depth, color_hex_index, mds_ref,
        )
        if block:
            child_blocks.append(block)
    collapsed_children = _collapse_repeated_siblings(child_blocks)

    if _is_zero_size_noise(node, bool(collapsed_children)):
        return []

    indent = "  " * depth
    name = node.get("name", "Unnamed")
    parts = [f"{indent}- {md_code(name)}"]

    layout = node.get("layout", {})
    mode = layout.get("layoutMode")
    if mode:
        direction = "row" if mode == "HORIZONTAL" else "col"
        pad = [layout.get(k, 0) for k in ("paddingTop", "paddingRight", "paddingBottom", "paddingLeft")]
        gap = layout.get("itemSpacing", 0)
        summary = direction
        if any(pad):
            summary += f" pad={pad[0]}/{pad[1]}/{pad[2]}/{pad[3]}"
        if gap:
            summary += f" gap={gap}"
        w = layout.get("width")
        h = layout.get("height")
        if w:
            summary += f" w={int(w)}"
        if h:
            summary += f" h={int(h)}"
        radius = layout.get("cornerRadius")
        if radius:
            summary += f" r={radius}"
        parts.append(f"[{summary}]")
    else:
        w = layout.get("width")
        h = layout.get("height")
        if w and h:
            parts.append(f"[{int(w)}x{int(h)}]")

    chars = node.get("characters")
    if chars:
        compact = " ".join(str(chars).split())
        parts.append(f'"{md_text(compact)}"')
        style = node.get("style") or {}
        token_id = node.get("bindings", {}).get("textStyleId")
        if token_id and token_id in style_name_index:
            parts.append(f"style:{md_text(style_name_index[token_id])}")
        elif style.get("fontSize"):
            parts.append(f"{style['fontSize']}px/{style.get('fontWeight', '')}")

    bindings = extract_token_bindings(node, style_name_index, variable_name_index)
    if bindings:
        parts.append(f"token:{','.join(md_text(binding) for binding in bindings)}")
    else:
        fill = extract_color_from_fills(node.get("fills", []))
        if fill:
            # Layer 3: Figma style name reverse-lookup
            token_name = (color_hex_index or {}).get(fill.lower())
            if not token_name and mds_ref:
                # Layer 4: MDS reference lookup
                token_name = resolve_mds_color(fill, mds_ref)
            parts.append(f"fill:{fill} ({md_text(token_name)})" if token_name else f"fill:{fill}")

    lines = [" ".join(parts)]
    lines.extend(collapsed_children)
    return lines


def _comp_layout_summary(layout: dict, mds_ref: Optional[dict] = None) -> str:
    parts = []
    mode = layout.get("layoutMode")
    if mode:
        parts.append("row" if mode == "HORIZONTAL" else "col")
    w = layout.get("width")
    h = layout.get("height")
    if w:
        parts.append(f"w={int(w)}")
    if h:
        parts.append(f"h={int(h)}")
    pad = [layout.get(k, 0) for k in ("paddingTop", "paddingRight", "paddingBottom", "paddingLeft")]
    if any(pad):
        pad_str = f"{pad[0]}/{pad[1]}/{pad[2]}/{pad[3]}"
        if mds_ref:
            # Annotate unique padding values with MDS spacing tokens
            unique_vals = sorted({v for v in pad if v}, key=lambda x: -x)
            hints = []
            for v in unique_vals:
                tok = resolve_mds_spacing(f"{v}px", mds_ref)
                if tok:
                    hints.append(f"{v}px={tok}")
            pad_str += f" ({', '.join(hints)})" if hints else ""
        parts.append(f"pad={pad_str}")
    gap = layout.get("itemSpacing", 0)
    if gap:
        gap_str = str(gap)
        if mds_ref:
            tok = resolve_mds_spacing(f"{gap}px", mds_ref)
            if tok:
                gap_str += f"({tok})"
        parts.append(f"gap={gap_str}")
    radius = layout.get("cornerRadius")
    if radius:
        r_str = str(radius)
        if mds_ref:
            tok = resolve_mds_radius(f"{radius}px", mds_ref)
            if tok:
                r_str += f"({tok})"
        parts.append(f"r={r_str}")
    return ", ".join(parts)


def iter_nodes(node: Optional[dict]):
    if not node:
        return
    yield node
    for child in node.get("children", []):
        yield from iter_nodes(child)


def format_px_value(value: Any) -> Optional[str]:
    if value is None:
        return None
    try:
        num = float(value)
    except (TypeError, ValueError):
        return None
    if num <= 0:
        return None
    if num.is_integer():
        return f"{int(num)}px"
    return f"{num:.1f}px"


def is_mds_token_label(label: Optional[str]) -> bool:
    if not label:
        return False
    return label.startswith("var(--mag-") or "--mag-" in label


def is_unresolved_variable_alias(label: Optional[str]) -> bool:
    if not label:
        return False
    return label.startswith("VariableID:")


def collect_observed_color_rows(
    root: Optional[dict],
    style_name_index: dict[str, str],
    variable_name_index: dict[str, str],
    color_hex_index: dict[str, str],
    mds_ref: Optional[dict],
) -> list[str]:
    rows = []
    seen: set[tuple[str, str]] = set()
    for node in iter_nodes(root):
        fill = extract_color_from_fills(node.get("fills", []))
        if not fill:
            continue
        bindings = extract_token_bindings(node, style_name_index, variable_name_index)
        token = next((binding for binding in bindings if binding), None)
        if token and not is_mds_token_label(token):
            token = None
        if not token:
            token = color_hex_index.get(fill.lower())
            if token and not is_mds_token_label(token):
                token = None
        if not token and mds_ref:
            token = resolve_mds_color(fill, mds_ref)
        if not token:
            continue
        key = (token, fill.lower())
        if key in seen:
            continue
        seen.add(key)
        rows.append(f"| {md_code_table_cell(token)} | {md_code_table_cell(fill)} |")
    return rows


def collect_observed_typography_rows(
    root: Optional[dict],
    style_name_index: dict[str, str],
    variable_name_index: dict[str, str],
    mds_ref: Optional[dict],
) -> list[str]:
    rows = []
    seen: set[tuple[str, str, str, str, str]] = set()
    for node in iter_nodes(root):
        style = node.get("style") or {}
        font_size = style.get("fontSize")
        if not font_size:
            continue
        bindings = extract_token_bindings(node, style_name_index, variable_name_index)
        token = next((binding for binding in bindings if binding), None)
        font_family = style.get("fontFamily", "—")
        size = f"{font_size}px"
        weight = str(style.get("fontWeight", "—"))
        line_height = style.get("lineHeightPx")
        line_height_str = f"{line_height:.0f}px" if line_height else "—"
        if mds_ref and (not token or is_unresolved_variable_alias(token)):
            token = resolve_mds_typography_token(style, mds_ref)
        style_label = format_typography_style_label(style, token)
        token_label = format_typography_token_label(token)
        token_str = f"`{token_label}`" if token_label != "—" else "—"
        key = (style_label, token or "", font_family, size, weight, line_height_str)
        if key in seen:
            continue
        seen.add(key)
        rows.append(
            f"| {md_code_table_cell(style_label)} | {md_table_cell(token_str)} | "
            f"{md_table_cell(font_family)} | {md_table_cell(size)} | {md_table_cell(weight)} | {md_table_cell(line_height_str)} |"
        )
    return rows


def collect_observed_spacing_lines(root: Optional[dict], mds_ref: Optional[dict]) -> list[str]:
    if not mds_ref:
        return []
    values: dict[str, Optional[str]] = {}
    for node in iter_nodes(root):
        layout = node.get("layout", {})
        gap = format_px_value(layout.get("itemSpacing"))
        if gap:
            values.setdefault(gap, resolve_mds_spacing(gap, mds_ref))
        for key in ("paddingTop", "paddingRight", "paddingBottom", "paddingLeft"):
            padding = format_px_value(layout.get(key))
            if padding:
                values.setdefault(padding, resolve_mds_spacing(padding, mds_ref))

    def sort_key(px_val: str) -> float:
        return float(px_val[:-2])

    lines = []
    for px_val in sorted(values, key=sort_key):
        token = values[px_val]
        if token:
            lines.append(f"- `{px_val}` → `{token}`")
    return lines


def collect_observed_radius_lines(root: Optional[dict], mds_ref: Optional[dict]) -> list[str]:
    if not mds_ref:
        return []
    values: dict[str, Optional[str]] = {}
    for node in iter_nodes(root):
        layout = node.get("layout", {})
        radius = format_px_value(layout.get("cornerRadius"))
        if radius:
            values.setdefault(radius, resolve_mds_radius(radius, mds_ref))
        for radius_value in layout.get("rectangleCornerRadii") or []:
            radius = format_px_value(radius_value)
            if radius:
                values.setdefault(radius, resolve_mds_radius(radius, mds_ref))

    def sort_key(px_val: str) -> float:
        return float(px_val[:-2])

    lines = []
    for px_val in sorted(values, key=sort_key):
        token = values[px_val]
        if token:
            lines.append(f"- `{px_val}` → `{token}`")
    return lines


def format_variable_value(value: Any, resolved_type: str, variable_name_index: dict[str, str]) -> str:
    if isinstance(value, dict) and value.get("type") == "VARIABLE_ALIAS":
        alias_id = value.get("id", "")
        return f"alias → {resolve_variable_alias_name(alias_id, variable_name_index)}"
    if resolved_type == "COLOR" and isinstance(value, dict):
        return rgba_to_hex(value.get("r", 0), value.get("g", 0), value.get("b", 0), value.get("a", 1))
    if resolved_type == "FLOAT" and isinstance(value, (int, float)):
        return format_px_value(value) or str(value)
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "—"
    return str(value)


def build_markdown_spec(data: dict, *, apply_mds: bool = False) -> str:
    lines = []
    generated_from = data.get("last_modified") or "unknown"
    style_name_index = build_style_name_index(data)
    variable_name_index = build_variable_name_index(data)
    color_hex_index = build_color_hex_index(data)
    mds_ref = load_mds_reference() if apply_mds else None

    lines.append(f"# Design Spec: {data.get('file_name', 'Figma File')}")
    lines.append(f"Figma Last Modified: {generated_from}  |  File key: `{data.get('file_key', '')}`\n")

    # ── Source Metadata — stable handoff contract for downstream skills ──
    lines.append("---\n## Source Metadata\n")
    lines.append(f"**Source URL:** {data.get('source_url') or 'none'}")
    lines.append(f"**File Key:** `{data.get('file_key') or 'none'}`")
    lines.append(f"**Node ID:** `{data.get('node_id') or 'none'}`")
    lines.append(f"**Extraction Mode:** `{data.get('extraction_mode') or 'unknown'}`")
    lines.append(f"**Figma Last Modified:** {data.get('last_modified') or 'unknown'}\n")

    # ── Design Tokens — deduplicated ────────────────
    lines.append("---\n## Design Tokens\n")

    colors = data.get("styles", {}).get("colors", [])
    color_rows = []
    if colors:
        seen: set[str] = set()
        for c in colors:
            key = c["name"]
            if key in seen:
                continue
            seen.add(key)
            hex_val = extract_color_from_fills(c.get("fills", [])) or "—"
            color_rows.append(f"| {md_code_table_cell(key)} | {md_code_table_cell(hex_val)} |")
    else:
        color_rows = collect_observed_color_rows(
            data.get("target_node"),
            style_name_index,
            variable_name_index,
            color_hex_index,
            mds_ref,
        )
    if color_rows:
        lines.append("### Colors\n")
        lines.append("| Token | Hex |")
        lines.append("|-------|-----|")
        lines.extend(color_rows)
        lines.append("")

    texts = data.get("styles", {}).get("text", [])
    text_rows = []
    if texts:
        seen_t: set[str] = set()
        for t in texts:
            key = t["name"]
            if key in seen_t:
                continue
            seen_t.add(key)
            s = t.get("style", {})
            lh = s.get("lineHeightPx")
            lh_str = f"{lh:.0f}px" if lh else "—"
            token = resolve_mds_typography_token(s, mds_ref) if s and mds_ref else None
            token_label = format_typography_token_label(token)
            token_str = f"`{token_label}`" if token_label != "—" else "—"
            size_str = f"{s.get('fontSize', '—')}px"
            text_rows.append(
                f"| {md_code_table_cell(key)} | {md_table_cell(token_str)} | "
                f"{md_table_cell(s.get('fontFamily', '—'))} | {md_table_cell(size_str)}"
                f" | {md_table_cell(s.get('fontWeight', '—'))} | {md_table_cell(lh_str)} |"
            )
    else:
        text_rows = collect_observed_typography_rows(
            data.get("target_node"),
            style_name_index,
            variable_name_index,
            mds_ref,
        )
    if text_rows:
        lines.append("### Typography\n")
        lines.append("| Style | Token | Font | Size | Weight | Line Height |")
        lines.append("|-------|-------|------|------|--------|-------------|")
        lines.extend(text_rows)
        lines.append("")

    effects = data.get("styles", {}).get("effects", [])
    if effects:
        seen_e: set[str] = set()
        fx_rows = []
        for e in effects:
            key = e["name"]
            if key in seen_e:
                continue
            seen_e.add(key)
            desc_parts = []
            for eff in e.get("effects", []):
                color = eff.get("color", {})
                hex_c = rgba_to_hex(color.get("r", 0), color.get("g", 0), color.get("b", 0), color.get("a", 1))
                offset = eff.get("offset", {})
                desc_parts.append(f"{offset.get('x', 0)}px {offset.get('y', 0)}px {eff.get('radius', 0)}px {hex_c}")
            fx_rows.append(f"- `{key}`: {'; '.join(desc_parts)}")
        if fx_rows:
            lines.append("### Shadows\n")
            lines.extend(fx_rows)
            lines.append("")

    spacing_lines = collect_observed_spacing_lines(data.get("target_node"), mds_ref)
    if spacing_lines:
        lines.append("### Spacing Scale\n")
        lines.extend(spacing_lines)
        lines.append("")

    radius_lines = collect_observed_radius_lines(data.get("target_node"), mds_ref)
    if radius_lines:
        lines.append("### Border Radius\n")
        lines.extend(radius_lines)
        lines.append("")

    variables = data.get("variables", {})
    meta = variables.get("meta", {})
    var_collections = meta.get("variableCollections", {})
    var_map = meta.get("variables", {})
    if var_collections and var_map:
        lines.append("### Design Variables\n")
        for coll_id, coll in var_collections.items():
            collection_vars = [
                var for var in var_map.values() if var.get("variableCollectionId") == coll_id
            ]
            if not collection_vars:
                continue
            lines.append(f"#### Collection: {md_text(coll.get('name', coll_id))}")
            modes = {mode["modeId"]: mode["name"] for mode in coll.get("modes", [])}
            if modes:
                lines.append(f"Modes: {', '.join(modes.values())}\n")
            lines.append("| Variable | Type | Default Value |")
            lines.append("|----------|------|---------------|")
            default_mode = coll.get("defaultModeId")
            for var in sorted(collection_vars, key=lambda item: item.get("name", "")):
                value = var.get("valuesByMode", {}).get(default_mode)
                formatted_value = format_variable_value(
                    value,
                    var.get("resolvedType", ""),
                    variable_name_index,
                )
                lines.append(
                    f"| {md_code_table_cell(var.get('name', '—'))} | {md_table_cell(var.get('resolvedType', '—'))} | "
                    f"{md_code_table_cell(formatted_value)} |"
                )
            lines.append("")

    # ── Components — parent sets only, variants grouped ──
    components = data.get("components", [])
    if components:
        parents = [c for c in components if not _is_variant_node(c)]
        components_by_id = {c.get("id"): c for c in components if c.get("id")}
        variants_by_parent: dict[str, list[dict]] = {}
        for c in components:
            if _is_variant_node(c):
                parent_key = c["name"].split("=")[0].strip()
                variants_by_parent.setdefault(parent_key, []).append(c)

        components_to_render = []
        for comp in (parents or components):
            children = comp.get("children", [])
            var_children_source = None
            if not children:
                variant_components = [
                    components_by_id[variant["id"]]
                    for variant in comp.get("variants", [])
                    if variant.get("id") in components_by_id
                ]
                default_variant = next(
                    (v for v in variant_components if "default" in v.get("name", "").lower()),
                    None,
                )
                if default_variant is None:
                    default_variant = next(
                        (v for v in variants_by_parent.get(comp["name"], []) if "default" in v["name"].lower()),
                        (variant_components or variants_by_parent.get(comp["name"]) or [None])[0],
                    )
                if default_variant:
                    var_children_source = default_variant

            src = comp if children else var_children_source
            if src and src.get("children"):
                components_to_render.append(comp)

        if components_to_render:
            lines.append("---\n## Components\n")
            for index, comp in enumerate(components_to_render):
                lines.append(f"### {md_text(comp['name'])}")
                if comp.get("description"):
                    lines.append(f"_{md_text(comp['description'])}_\n")

                if _is_variant_node(comp) and not parents:
                    lines.append("_Variant component referenced by the target node._\n")

                props = comp.get("componentProperties", {})
                if props:
                    lines.append(format_component_properties(props))
                    lines.append("")

                layout_str = _comp_layout_summary(comp.get("layout", {}), mds_ref=mds_ref)
                if layout_str:
                    lines.append(f"**Layout:** {layout_str}")

                fill_color = extract_color_from_fills(comp.get("fills", []))
                if fill_color:
                    lines.append(f"**Background:** `{fill_color}`")

                bindings = extract_token_bindings(comp, style_name_index, variable_name_index)
                if bindings:
                    lines.append(f"**Tokens:** {', '.join(f'`{b}`' for b in bindings)}")

                variants = comp.get("variants", [])
                if variants:
                    lines.append(f"**Variants:** {', '.join(md_text(v['name']) for v in variants)}")

                # Structure: prefer the component's own children, else fall back to default variant
                children = comp.get("children", [])
                var_children_source = None
                if not children:
                    variant_components = [
                        components_by_id[variant["id"]]
                        for variant in comp.get("variants", [])
                        if variant.get("id") in components_by_id
                    ]
                    default_variant = next(
                        (v for v in variant_components if "default" in v.get("name", "").lower()),
                        None,
                    )
                    if default_variant is None:
                        default_variant = next(
                            (v for v in variants_by_parent.get(comp["name"], []) if "default" in v["name"].lower()),
                            (variant_components or variants_by_parent.get(comp["name"]) or [None])[0],
                        )
                    if default_variant:
                        var_children_source = default_variant

                src = comp if children else var_children_source
                if src and src.get("children"):
                    lines.append("\n**Structure:**\n")
                    for desc in _compact_hierarchy(src, style_name_index, variable_name_index, color_hex_index=color_hex_index, mds_ref=mds_ref):
                        lines.append(desc)

                if index < len(components_to_render) - 1:
                    lines.append("\n---\n")
                else:
                    lines.append("")

    # ── Screen States (--child-images) ───────────────────
    child_images = data.get("child_images", [])
    if child_images:
        lines.append("---\n## Screen States\n")
        lines.append("Each entry below is an exportable child candidate selected after the preview image was judged to need frame-level review. Candidates can be frames, components, component sets, instances, or nested screen-like nodes under wrappers.\n")
        lines.append("| # | State / Name | Type | Node ID | Preview |")
        lines.append("|---|--------------|------|---------|---------|")
        for img in child_images:
            idx = img.get("index", "")
            name = img.get("name", "—")
            node_type = img.get("type", "—")
            node_id = img.get("node_id", "—")
            raw_path = img.get("file_path", "—")
            preview_path = _to_relative_path(raw_path) if raw_path != "—" else "—"
            lines.append(
                f"| {md_table_cell(idx)} | {md_table_cell(name)} | {md_table_cell(node_type)} | "
                f"{md_code_table_cell(node_id)} | {md_code_table_cell(preview_path)} |"
            )
        lines.append("")

    unresolved_component_ids = data.get("unresolved_component_ids", [])
    if unresolved_component_ids:
        lines.append("---\n## Unresolved Component References\n")
        lines.append("These INSTANCE component IDs were referenced by the target node but could not be resolved from the current Figma file API response. They may belong to a remote library file that needs a separate extraction.\n")
        for component_id in unresolved_component_ids:
            lines.append(f"- {md_code(component_id)}")
        lines.append("")

    # ── Target Node ──────────────────────────────────
    target_node = data.get("target_node")
    if target_node:
        lines.append("---\n## Target Node\n")
        ntype = target_node.get("type", "")
        lines.append(f"### {md_text(target_node['name'])} {md_code(ntype)}")

        layout = target_node.get("layout", {})
        w = layout.get("width")
        h = layout.get("height")
        if w and h:
            lines.append(f"**Size:** {int(w)}×{int(h)}px")

        chars = target_node.get("characters")
        if chars:
            lines.append(f"**Content:** \"{md_text(chars)}\"")
            style = target_node.get("style") or {}
            if style.get("fontSize"):
                lines.append(f"**Typography:** {style['fontSize']}px / weight {style.get('fontWeight', '—')}")

        fill_color = extract_color_from_fills(target_node.get("fills", []))
        if fill_color:
            lines.append(f"**Color:** `{fill_color}`")

        bindings = extract_token_bindings(target_node, style_name_index, variable_name_index)
        if bindings:
            lines.append(f"**Tokens:** {', '.join(f'`{b}`' for b in bindings)}")

        img = data.get("target_node_image")
        if img:
            raw_path = img.get('file_path', '—')
            preview_path = _to_relative_path(raw_path) if raw_path != '—' else '—'
            lines.append(f"**Preview:** `{preview_path}`")

        children = target_node.get("children", [])
        if children:
            lines.append("\n**Structure:**\n")
            for desc in _compact_hierarchy(
                target_node,
                style_name_index,
                variable_name_index,
                max_depth=10,
                color_hex_index=color_hex_index,
                mds_ref=mds_ref,
            ):
                lines.append(desc)
        lines.append("")

    # ── Screens / Frames ──────────────────────────────
    frames = data.get("frames", [])
    if frames:
        lines.append("## Screens / Frames\n")
        lines.append("| Name | Width | Height | Layout |")
        lines.append("|------|-------|--------|--------|")
        for frame in frames:
            w = f"{int(frame['width'])}px" if frame.get("width") else "—"
            h = f"{int(frame['height'])}px" if frame.get("height") else "—"
            layout = frame.get("layoutMode", "none").lower() if frame.get("layoutMode") else "none"
            lines.append(
                f"| {md_table_cell(frame['name'])} | {md_table_cell(w)} | "
                f"{md_table_cell(h)} | {md_table_cell(layout)} |"
            )
        lines.append("")

    # ── Icons (SVG inline) ─────────────────────────────
    icons = data.get("icons", [])
    if icons:
        lines.append("---\n## Icons\n")
        for icon in icons:
            w = f"{int(icon['width'])}px" if icon.get("width") else "?"
            h = f"{int(icon['height'])}px" if icon.get("height") else "?"
            lines.append(f"### {md_text(icon['name'])} ({w} × {h})")
            svg = icon.get("svg_content", "")
            if svg:
                lines.append("```svg")
                lines.append(svg.strip())
                lines.append("```\n")

    # ── Images (file references) ────────────────────────
    images = data.get("images", [])
    if images:
        lines.append("---\n## Exported Images\n")
        lines.append("| Name | File | Width | Height |")
        lines.append("|------|------|-------|--------|")
        for img in images:
            w = f"{int(img['width'])}px" if img.get("width") else "—"
            h = f"{int(img['height'])}px" if img.get("height") else "—"
            raw_path = img.get('file_path', '—')
            display_path = _to_relative_path(raw_path) if raw_path != '—' else '—'
            lines.append(
                f"| {md_table_cell(img['name'])} | {md_code_table_cell(display_path)} | "
                f"{md_table_cell(w)} | {md_table_cell(h)} |"
            )
        lines.append("")

    return "\n".join(lines)


def build_css(data: dict) -> str:
    lines = [":root {"]
    for c in data.get("styles", {}).get("colors", []):
        hex_val = extract_color_from_fills(c.get("fills", []))
        if hex_val:
            var_name = f"--color-{slugify(c['name'])}"
            lines.append(f"  {var_name}: {hex_val};")

    for t in data.get("styles", {}).get("text", []):
        s = t.get("style", {})
        slug = slugify(t["name"])
        if s.get("fontSize"):
            lines.append(f"  --text-{slug}-size: {s['fontSize']}px;")
        if s.get("lineHeightPx"):
            lines.append(f"  --text-{slug}-line-height: {s['lineHeightPx']:.0f}px;")
        if s.get("fontWeight"):
            lines.append(f"  --text-{slug}-weight: {s['fontWeight']};")

    variables = data.get("variables", {}).get("meta", {})
    if variables:
        for var_id, var in variables.get("variables", {}).items():
            coll_id = var.get("variableCollectionId")
            coll = variables.get("variableCollections", {}).get(coll_id, {})
            default_mode = coll.get("defaultModeId")
            val = var.get("valuesByMode", {}).get(default_mode)
            if val is not None and var.get("resolvedType") == "COLOR" and isinstance(val, dict):
                hex_val = rgba_to_hex(val.get("r", 0), val.get("g", 0), val.get("b", 0), val.get("a", 1))
                lines.append(f"  --{slugify(var['name'])}: {hex_val};")
            elif val is not None and var.get("resolvedType") == "FLOAT":
                lines.append(f"  --{slugify(var['name'])}: {val}px;")

    lines.append("}")
    return "\n".join(lines)


def build_tokens(data: dict) -> dict:
    tokens = {"color": {}, "typography": {}, "shadow": {}}

    for c in data.get("styles", {}).get("colors", []):
        hex_val = extract_color_from_fills(c.get("fills", []))
        if hex_val:
            tokens["color"][c["name"]] = {"value": hex_val, "type": "color"}

    for t in data.get("styles", {}).get("text", []):
        s = t.get("style", {})
        tokens["typography"][t["name"]] = {
            "value": {
                "fontFamily": s.get("fontFamily"),
                "fontSize": f"{s.get('fontSize')}px",
                "fontWeight": s.get("fontWeight"),
                "lineHeight": f"{s.get('lineHeightPx', 0):.0f}px",
                "letterSpacing": f"{s.get('letterSpacing', 0)}px",
            },
            "type": "typography",
        }

    for e in data.get("styles", {}).get("effects", []):
        eff_list = e.get("effects", [])
        if eff_list:
            eff = eff_list[0]
            color = eff.get("color", {})
            hex_c = rgba_to_hex(color.get("r", 0), color.get("g", 0), color.get("b", 0), color.get("a", 1))
            offset = eff.get("offset", {})
            tokens["shadow"][e["name"]] = {
                "value": {
                    "x": offset.get("x", 0),
                    "y": offset.get("y", 0),
                    "blur": eff.get("radius", 0),
                    "spread": eff.get("spread", 0),
                    "color": hex_c,
                    "type": "dropShadow",
                },
                "type": "boxShadow",
            }

    return tokens


# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Convert Figma JSON to design spec")
    parser.add_argument("--input", required=True, help="Input JSON from figma_client.py")
    parser.add_argument("--output", default=None, help="Output file path (default: temp/figma_<scope>/figma-spec.<ext> in cwd)")
    parser.add_argument("--format", choices=["md", "css", "tailwind", "tokens"], default="md")
    parser.add_argument(
        "--mds",
        action="store_true",
        help="Apply Magenta Design System token mappings to the Markdown spec.",
    )
    parser.add_argument(
        "--no-mds",
        action="store_true",
        help="Do not apply Magenta Design System mappings, even if foundation guidance mentions MDS.",
    )
    args = parser.parse_args()
    if args.mds and args.no_mds:
        print("Error: --mds and --no-mds cannot be used together.", file=sys.stderr)
        sys.exit(1)

    input_path = Path(args.input)
    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Resolve output path from scope embedded in input JSON
    scope = derive_scope(data)
    output_path = Path(args.output) if args.output else default_output_path(scope, args.format)
    if output_path.resolve() == input_path.resolve():
        print(
            f"Error: output path would overwrite input JSON: {output_path}. "
            "Pass --output or choose a non-conflicting format.",
            file=sys.stderr,
        )
        sys.exit(1)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if args.format == "md":
        content = build_markdown_spec(
            data,
            apply_mds=should_apply_mds(input_path, force=args.mds, disabled=args.no_mds),
        )

    elif args.format == "css":
        content = build_css(data)

    elif args.format == "tailwind":
        colors = {}
        for c in data.get("styles", {}).get("colors", []):
            hex_val = extract_color_from_fills(c.get("fills", []))
            if hex_val:
                colors[slugify(c["name"])] = hex_val
        font_sizes = {}
        for t in data.get("styles", {}).get("text", []):
            s = t.get("style", {})
            if s.get("fontSize"):
                key = slugify(t["name"])
                lh = s.get("lineHeightPx")
                font_sizes[key] = [f"{s['fontSize']}px", {"lineHeight": f"{lh:.0f}px" if lh else "1"}]
        config = {
            "theme": {
                "extend": {
                    "colors": colors,
                    "fontSize": font_sizes,
                }
            }
        }
        content = f"/** @type {{import('tailwindcss').Config}} */\nmodule.exports = {json.dumps(config, indent=2)};\n"

    elif args.format == "tokens":
        content = json.dumps(build_tokens(data), indent=2, ensure_ascii=False)

    # Atomic write (temp + rename) so a polling agent never reads a half-written figma-spec.md.
    tmp = output_path.with_name(output_path.name + f".tmp.{os.getpid()}")
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(content)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, output_path)

    print(f"Wrote {args.format} output to {output_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
