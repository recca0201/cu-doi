#!/usr/bin/env python3
"""
Generate references/tokens.md and references/components.md for the magenta-mds skill.

Reads directly from the apps/magenta source files:
  - apps/magenta/packages/css/src/tokens.ts              → references/tokens.md
  - apps/magenta/packages/react/src/components/          → references/components.md (core)
  - apps/magenta/packages/react-dates/src/components/    → references/components.md (dates section)
  - apps/magenta/packages/react-text-editor/src/         → references/components.md (text editor section)
  - apps/magenta/packages/react-templates/src/           → references/components.md (templates section)

Run from any directory:
  python3 .claude/skills/magenta-mds/scripts/generate_references.py
"""

import re
import sys
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = SKILL_DIR.parent.parent.parent

TOKENS_SRC = REPO_ROOT / "apps/magenta/packages/css/src/tokens.ts"
COMPONENTS_SRC = REPO_ROOT / "apps/magenta/packages/react/src/components"
PACKAGE_NAME = "@ocean-network-express/magenta-react"
DATES_COMPONENTS_SRC = REPO_ROOT / "apps/magenta/packages/react-dates/src/components"
DATES_PACKAGE_NAME = "@ocean-network-express/magenta-react-dates"
TEXT_EDITOR_SRC = REPO_ROOT / "apps/magenta/packages/react-text-editor/src/components"
TEXT_EDITOR_PACKAGE_NAME = "@ocean-network-express/magenta-react-text-editor"
TEMPLATES_SRC = REPO_ROOT / "apps/magenta/packages/react-templates/src/components"
TEMPLATES_PACKAGE_NAME = "@ocean-network-express/magenta-react-templates"
ICONS_SRC = REPO_ROOT / "apps/magenta/packages/react-icons/src/svg"
ICONS_PACKAGE_NAME = "@ocean-network-express/magenta-react-icons"

TOKENS_OUT = SKILL_DIR / "references/tokens.md"
COMPONENTS_OUT = SKILL_DIR / "references/components.md"
ICONS_OUT = SKILL_DIR / "references/icons.md"

# ── Token extraction ──────────────────────────────────────────────────────────

def resolve_rem(value: str) -> str | None:
    m = re.fullmatch(r"([\d.]+)rem", value.strip())
    if not m:
        return None
    return f"{round(float(m.group(1)) * 16)}px"


def normalize_hex(value: str) -> str | None:
    v = value.strip().lower()
    if re.fullmatch(r"#[0-9a-f]{3,8}", v):
        if len(v) == 4:
            v = "#" + "".join(c * 2 for c in v[1:])
        return v
    return None


def parse_tokens_ts(src: str) -> dict[str, str]:
    src = re.sub(r"//[^\n]*", "", src)
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.DOTALL)

    entries: dict[str, str] = {}

    def _walk(text: str, prefix: tuple = ()) -> None:
        pos = 0
        key_re = re.compile(r"""(?:'([^']+)'|"([^"]+)"|(\w[\w-]*))\s*:\s*""")
        while pos < len(text):
            m = key_re.search(text, pos)
            if not m:
                break
            key = m.group(1) or m.group(2) or m.group(3)
            after = text[m.end():]
            simple = re.match(r"""['"]([^'"]*)['"]\s*[,}]?""", after.lstrip())
            if simple:
                entries[".".join(prefix + (key,))] = simple.group(1)
                pos = m.end() + simple.end()
                continue
            if after.lstrip().startswith("{"):
                brace_start = m.end() + after.index("{")
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
                inner = text[brace_start + 1:i]
                leaf = re.match(r"""\s*value\s*:\s*(?:'([^']*)'|"([^"]*)")\s*""", inner)
                if leaf:
                    entries[".".join(prefix + (key,))] = leaf.group(1) or leaf.group(2) or ""
                else:
                    _walk(inner, prefix + (key,))
                pos = i + 1
                continue
            pos = m.end()

    outer = re.search(r"export\s+const\s+tokens\s*=\s*\{(.+)\};?\s*$", src, re.DOTALL)
    if not outer:
        print("Error: could not find `export const tokens = { ... }` in tokens.ts", file=sys.stderr)
        sys.exit(1)

    _walk(outer.group(1))
    return entries


def build_token_tables(entries: dict[str, str]) -> tuple[list, list, list]:
    """Returns (colors, spacing, radii) as lists of (display_key, value) tuples."""
    colors: list[tuple[str, str]] = []
    spacing: dict[str, str] = {}  # px -> css_var (spacing wins over sizes on collision)
    sizes: dict[str, str] = {}
    radii: list[tuple[str, str]] = []

    for path, raw_value in entries.items():
        parts = path.split(".")
        category = parts[0] if parts else ""
        token_name = path.replace(".", "-")
        css_var = f"var(--mag-{token_name})"
        value = raw_value.strip()
        px_value = value if value.endswith("px") else resolve_rem(value)

        if category == "colors":
            hex_val = normalize_hex(value)
            if hex_val:
                colors.append((css_var, hex_val))

        elif category == "spacing":
            if px_value and px_value not in spacing:
                spacing[px_value] = css_var

        elif category == "sizes":
            if px_value and px_value not in sizes:
                sizes[px_value] = css_var

        elif category == "radii":
            if px_value:
                radii.append((px_value, css_var))

    # Merge sizes into spacing (spacing wins)
    merged: dict[str, str] = {**sizes, **spacing}

    def _px_sort(item):
        px_str = item[0]
        try:
            return float(px_str.replace("px", ""))
        except ValueError:
            return 9999999

    spacing_list = sorted(merged.items(), key=_px_sort)
    radii_list = sorted(set(radii), key=_px_sort)

    return colors, spacing_list, radii_list


def write_tokens_md(colors, spacing, radii) -> None:
    lines = [
        "# MDS Design Tokens",
        "_Generated from `apps/magenta/packages/css/src/tokens.ts`_",
        "Regenerate: `python3 .claude/skills/magenta-mds/scripts/generate_references.py`",
        "",
        "## Colors",
        "| CSS Variable | Hex |",
        "|---|---|",
    ]
    for css_var, hex_val in colors:
        lines.append(f"| `{css_var}` | `{hex_val}` |")

    lines += [
        "",
        "## Spacing & Sizes",
        "| px | CSS Variable |",
        "|---|---|",
    ]
    for px, css_var in spacing:
        lines.append(f"| `{px}` | `{css_var}` |")

    lines += [
        "",
        "## Border Radii",
        "| px | CSS Variable |",
        "|---|---|",
    ]
    for px, css_var in radii:
        lines.append(f"| `{px}` | `{css_var}` |")

    TOKENS_OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Written {TOKENS_OUT.relative_to(Path.cwd())}", file=sys.stderr)


# ── Component extraction ──────────────────────────────────────────────────────

SKIP_PROPS = {
    "children", "ref", "className", "style", "id", "key",
    "onClick", "onChange", "onFocus", "onBlur", "onKeyDown", "onKeyUp",
    "onOpenChange", "onValueChange", "onDeleted", "onFocusOut",
    "renderTag", "renderSelectedItems", "renderHelperType",
    "items", "value", "defaultValue", "placeholder", "label",
    "helperText", "leftContent", "rightContent", "leftIcon", "rightIcon",
    "containerRef", "dropdownConfig", "limitTags", "open", "placement",
}

CSS_GLOBALS = {
    "inherit", "initial", "revert", "revert-layer", "unset",
    "-moz-initial", "-webkit-fill-available",
}


def parse_union_prop(type_str: str) -> list[str] | None:
    if "'" not in type_str and '"' not in type_str:
        return None
    literals = re.findall(r"""['"]([^'"]+)['"]""", type_str)
    if not literals:
        return None
    remainder = re.sub(r"""['"][^'"]*['"]""", "", type_str)
    remainder = re.sub(r"[|\s]", "", remainder)
    if remainder:
        return None
    if CSS_GLOBALS & set(literals):
        return None
    return literals


def parse_model_file(path: Path) -> dict[str, list[str]]:
    src = path.read_text(encoding="utf-8")
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.DOTALL)
    src = re.sub(r"//[^\n]*", "", src)

    props: dict[str, list[str]] = {}
    prop_pattern = re.compile(
        r"""(\w+)\??\s*:\s*((?:[^;{}\n]|\n(?!\s*\w+\??:))+);""",
        re.MULTILINE,
    )
    for m in prop_pattern.finditer(src):
        name = m.group(1)
        type_str = " ".join(m.group(2).split())
        if name in SKIP_PROPS:
            continue
        if name.startswith("on") and name[2:3].isupper():
            continue
        values = parse_union_prop(type_str)
        if values and len(values) >= 2:
            props[name] = values

    return props


def component_name_from_path(model_path: Path) -> str:
    stem = model_path.stem
    return re.sub(r"\.model$", "", stem)


def collect_components(src: Path, package_name: str) -> list[dict]:
    components: dict[str, dict] = {}

    for model_file in sorted(src.rglob("*.model.ts")):
        comp_name = component_name_from_path(model_file)
        if comp_name.startswith("Base") or comp_name.startswith("Local"):
            continue
        if comp_name in ("Engine", "common"):
            continue

        props = parse_model_file(model_file)
        if not props:
            continue

        if comp_name not in components:
            components[comp_name] = {
                "component": comp_name,
                "import": f"import {{ {comp_name} }} from '{package_name}'",
                "props": props,
            }
        else:
            components[comp_name]["props"].update(props)

    return sorted(components.values(), key=lambda c: (
        len([ch for ch in c["component"] if ch.isupper()]),
        c["component"],
    ))


def _component_rows(components: list[dict]) -> list[str]:
    rows = []
    for comp in components:
        name = comp["component"]
        imp = comp["import"]
        props_parts = []
        for prop, values in comp["props"].items():
            vals = " \\| ".join(f"`{v}`" for v in values)
            props_parts.append(f"`{prop}`: {vals}")
        props_cell = "<br>".join(props_parts)
        rows.append(f"| **{name}** | `{imp}` | {props_cell} |")
    return rows


def write_components_md(
    core: list[dict],
    dates: list[dict],
    text_editor: list[dict],
    templates: list[dict],
) -> None:
    table_header = [
        "| Component | Import | Props |",
        "|---|---|---|",
    ]

    def section(title: str, package: str, components: list[dict]) -> list[str]:
        if not components:
            return []
        return [
            f"## {title}",
            "",
            f"Package: `{package}`",
            "",
            *table_header,
            *_component_rows(components),
            "",
        ]

    lines = [
        "# MDS Components — Variant Props",
        "",
        "_Generated from `apps/magenta/packages/react*/src/**/*.model.ts`_",
        "",
        "Regenerate: `python3 .claude/skills/magenta-mds/scripts/generate_references.py`",
        "",
        *section("Core components", PACKAGE_NAME, core),
        *section("Date & time components", DATES_PACKAGE_NAME, dates),
        *section("Text editor components", TEXT_EDITOR_PACKAGE_NAME, text_editor),
        *section("Template components", TEMPLATES_PACKAGE_NAME, templates),
    ]

    COMPONENTS_OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Written {COMPONENTS_OUT.relative_to(Path.cwd())}", file=sys.stderr)


# ── Icon extraction ───────────────────────────────────────────────────────────

ICON_SIZES = {
    "sm": "16x16px",
    "md": "20x20px",
    "lg": "24x24px",
    "xl": "32x32px",
}


def collect_icons() -> dict[str, list[str]]:
    icons: dict[str, list[str]] = {}

    for style_dir in sorted(path for path in ICONS_SRC.iterdir() if path.is_dir()):
        style = style_dir.name
        icons[style] = sorted(file.stem for file in style_dir.glob("*.tsx") if file.stem != "index")

    return icons


def write_icons_md(icons: dict[str, list[str]]) -> None:
    total_icons = sum(len(names) for names in icons.values())
    lines = [
        "# MDS Icons",
        "",
        "_Generated from `apps/magenta/packages/react-icons/src/svg/**/*`_",
        "",
        "Regenerate: `python3 .claude/skills/magenta-mds/scripts/generate_references.py`",
        "",
        f"Package: `{ICONS_PACKAGE_NAME}`",
        "",
        "## Usage",
        "",
        "```tsx",
        f"import {{ BookingOutline, AddCircleFill }} from '{ICONS_PACKAGE_NAME}'",
        "",
        "<BookingOutline size=\"md\" />",
        "<AddCircleFill size=\"lg\" />",
        "```",
        "",
        "## Common props",
        "",
        "| Prop | Type | Default | Notes |",
        "|---|---|---|---|",
        "| `size` | `sm` \\| `md` \\| `lg` \\| `xl` | `md` | Preset icon size; `width` and `height` override it. |",
        "| `width` | `number` \\| `string` | — | Custom width. |",
        "| `height` | `number` \\| `string` | — | Custom height. |",
        "| `className` | `string` | — | Additional CSS classes. |",
        "| `style` | `CSSProperties` | — | Inline styles. |",
        "| `...props` | `SVGProps<SVGSVGElement>` | — | Standard SVG props such as `aria-hidden`, `role`, or `onClick`. |",
        "",
        "## Size reference",
        "",
        "| Size | Pixels |",
        "|---|---|",
    ]

    for size, pixels in ICON_SIZES.items():
        lines.append(f"| `{size}` | `{pixels}` |")

    lines += [
        "",
        "## Icon sets",
        "",
        "| Style | Count | Example imports |",
        "|---|---|---|",
    ]

    for style, names in icons.items():
        examples = ", ".join(f"`{name}`" for name in names[:3]) if names else "—"
        lines.append(f"| `{style}` | `{len(names)}` | {examples} |")

    lines += [
        "",
        f"Total icons: `{total_icons}`",
    ]

    for style, names in icons.items():
        lines += [
            "",
            f"## {style} icons",
            "",
        ]
        for name in names:
            lines.append(f"- `{name}`")

    ICONS_OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Written {ICONS_OUT.relative_to(Path.cwd())}", file=sys.stderr)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    if not TOKENS_SRC.exists():
        print(f"Error: tokens source not found at {TOKENS_SRC}", file=sys.stderr)
        sys.exit(1)
    if not COMPONENTS_SRC.exists():
        print(f"Error: components source not found at {COMPONENTS_SRC}", file=sys.stderr)
        sys.exit(1)
    if not DATES_COMPONENTS_SRC.exists():
        print(f"Error: react-dates components source not found at {DATES_COMPONENTS_SRC}", file=sys.stderr)
        sys.exit(1)
    if not TEXT_EDITOR_SRC.exists():
        print(f"Error: react-text-editor components source not found at {TEXT_EDITOR_SRC}", file=sys.stderr)
        sys.exit(1)
    if not TEMPLATES_SRC.exists():
        print(f"Error: react-templates components source not found at {TEMPLATES_SRC}", file=sys.stderr)
        sys.exit(1)
    if not ICONS_SRC.exists():
        print(f"Error: icons source not found at {ICONS_SRC}", file=sys.stderr)
        sys.exit(1)

    TOKENS_OUT.parent.mkdir(parents=True, exist_ok=True)
    COMPONENTS_OUT.parent.mkdir(parents=True, exist_ok=True)
    ICONS_OUT.parent.mkdir(parents=True, exist_ok=True)

    # Tokens
    src = TOKENS_SRC.read_text(encoding="utf-8")
    entries = parse_tokens_ts(src)
    if not entries:
        print("Error: no token entries parsed — check tokens.ts format.", file=sys.stderr)
        sys.exit(1)
    colors, spacing, radii = build_token_tables(entries)
    write_tokens_md(colors, spacing, radii)
    print(
        f"  {len(colors)} colors, {len(spacing)} spacing values, {len(radii)} radii",
        file=sys.stderr,
    )

    # Components
    core_components = collect_components(COMPONENTS_SRC, PACKAGE_NAME)
    dates_components = collect_components(DATES_COMPONENTS_SRC, DATES_PACKAGE_NAME)
    text_editor_components = collect_components(TEXT_EDITOR_SRC, TEXT_EDITOR_PACKAGE_NAME)
    templates_components = collect_components(TEMPLATES_SRC, TEMPLATES_PACKAGE_NAME)
    write_components_md(core_components, dates_components, text_editor_components, templates_components)
    print(
        f"  {len(core_components)} core, {len(dates_components)} date/time, "
        f"{len(text_editor_components)} text editor, {len(templates_components)} template components",
        file=sys.stderr,
    )

    # Icons
    icons = collect_icons()
    write_icons_md(icons)
    print(
        f"  {sum(len(names) for names in icons.values())} icons across {len(icons)} sets",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
