#!/usr/bin/env python3
"""
Generate references/mds-components.json from apps/magenta/packages/react/src/components.

For each component, extracts:
  - component name (PascalCase, matches the directory)
  - import path (package + component)
  - props: only union-type props (size, variant, color, state, type, etc.)
    captured as { propName: ["val1", "val2", ...] }

Output: .claude/skills/figma-design/references/mds-components.json

Run from any directory:
  python3 .claude/skills/figma-design/scripts/generate_mds_components.py
"""

import json
import re
import sys
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent
COMPONENTS_SRC = SKILL_DIR.parent.parent.parent / "apps/magenta/packages/react/src/components"
OUT_PATH = SKILL_DIR / "references/mds-components.json"
PACKAGE_NAME = "@ocean-network-express/magenta-react"

# Only keep props whose values are string union literals — these map to Figma variants.
# Exclude purely structural/behavioral props (children, ref, event handlers, etc.)
SKIP_PROPS = {
    "children", "ref", "className", "style", "id", "key",
    "onClick", "onChange", "onFocus", "onBlur", "onKeyDown", "onKeyUp",
    "onOpenChange", "onValueChange", "onDeleted", "onFocusOut",
    "renderTag", "renderSelectedItems", "renderHelperType",
    "items", "value", "defaultValue", "placeholder", "label",
    "helperText", "leftContent", "rightContent", "leftIcon", "rightIcon",
    "containerRef", "dropdownConfig", "limitTags", "open", "placement",
}


def parse_union_prop(type_str: str) -> list[str] | None:
    """
    Extract string literal values from a union type.
    e.g. "'sm' | 'md' | 'lg'" -> ["sm", "md", "lg"]
    Returns None if the type isn't a string-literal union.
    """
    # Must contain at least one quoted literal
    if "'" not in type_str and '"' not in type_str:
        return None

    literals = re.findall(r"""['"]([^'"]+)['"]""", type_str)
    if not literals:
        return None

    # Reject if non-literal tokens exist alongside (e.g. React.ReactNode | 'sm')
    # Strip out the literals and check what remains — if only pipes and whitespace, it's clean
    remainder = re.sub(r"""['"][^'"]*['"]""", "", type_str)
    remainder = re.sub(r"[|\s]", "", remainder)
    if remainder:
        return None

    # Reject CSS-wide keywords that leak in from typed objectFit / CSS property types
    css_globals = {"inherit", "initial", "revert", "revert-layer", "unset",
                   "-moz-initial", "-webkit-fill-available"}
    if css_globals & set(literals):
        return None

    return literals


def parse_model_file(path: Path) -> dict[str, list[str]]:
    """Parse a *.model.ts file and return {propName: [union values]} for union props."""
    src = path.read_text(encoding="utf-8")

    # Strip comments
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.DOTALL)
    src = re.sub(r"//[^\n]*", "", src)

    props: dict[str, list[str]] = {}

    # Match:  propName?: TYPE;  or  propName: TYPE;
    # TYPE can span to the next semicolon (may include newlines for multiline unions)
    prop_pattern = re.compile(
        r"""(\w+)\??\s*:\s*((?:[^;{}\n]|\n(?!\s*\w+\??:))+);""",
        re.MULTILINE,
    )

    for m in prop_pattern.finditer(src):
        name = m.group(1)
        type_str = " ".join(m.group(2).split())  # normalize whitespace

        if name in SKIP_PROPS:
            continue
        if name.startswith("on") and name[2:3].isupper():
            continue  # skip all event handler props

        values = parse_union_prop(type_str)
        if values and len(values) >= 2:
            props[name] = values

    return props


def component_name_from_path(model_path: Path) -> str:
    """Derive the component name from the model file name."""
    stem = model_path.stem  # e.g. "Button.model" -> stem after removing .ts is "Button.model"
    # Remove ".model" suffix
    name = re.sub(r"\.model$", "", stem)
    return name


def collect_components() -> list[dict]:
    components: dict[str, dict] = {}  # keyed by component name to merge sub-models

    for model_file in sorted(COMPONENTS_SRC.rglob("*.model.ts")):
        comp_name = component_name_from_path(model_file)

        # Skip internal/base models that aren't directly imported by consumers
        if comp_name.startswith("Base") or comp_name.startswith("Local"):
            continue
        if comp_name in ("Engine", "common"):
            continue

        props = parse_model_file(model_file)
        if not props:
            continue

        # Group sub-components under their parent (e.g. AccordionItem -> Accordion)
        # but keep them as separate entries so the reference stays granular
        if comp_name not in components:
            components[comp_name] = {
                "component": comp_name,
                "import": f"import {{ {comp_name} }} from '{PACKAGE_NAME}'",
                "props": props,
            }
        else:
            # Merge props from multiple model files for the same component name
            components[comp_name]["props"].update(props)

    # Sort: top-level components first (no parent prefix), then sub-components
    result = sorted(components.values(), key=lambda c: (
        len([ch for ch in c["component"] if ch.isupper()]),  # approximate nesting depth
        c["component"],
    ))
    return result


def main():
    if not COMPONENTS_SRC.exists():
        print(f"Error: components source not found at {COMPONENTS_SRC}", file=sys.stderr)
        sys.exit(1)

    components = collect_components()

    output = {
        "_source": str(COMPONENTS_SRC.relative_to(SKILL_DIR.parent.parent.parent)),
        "_package": PACKAGE_NAME,
        "_component_count": len(components),
        "components": components,
    }

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(output, indent=2, ensure_ascii=False), encoding="utf-8")

    print(
        f"Generated {OUT_PATH.relative_to(Path.cwd())}\n"
        f"  {len(components)} components with variant props",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
