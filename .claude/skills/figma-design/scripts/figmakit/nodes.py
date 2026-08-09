"""Pure node-tree transforms and collectors (depend only on figmakit.paths and constants)."""

import re
from typing import Optional

from figmakit import (
    CHILD_IMAGE_EXPORT_TYPES,
    CHILD_IMAGE_WRAPPER_TYPES,
    CHILD_IMAGE_MIN_SIZE,
)
from figmakit.paths import slugify


def strip_hidden_nodes(node: dict) -> dict:
    """
    Return a deep copy of *node* with all hidden children removed recursively.
    A node is considered hidden when its ``visible`` property is explicitly ``False``
    (nodes without the property default to visible and are kept).
    The root node itself is never stripped — only its descendants.
    """
    result = {k: v for k, v in node.items() if k != "children"}
    visible_children = [
        c for c in node.get("children", [])
        if c.get("visible", True) is not False
    ]
    result["children"] = [strip_hidden_nodes(c) for c in visible_children]
    return result


def find_nodes_by_name(node: dict, name: str, results: list) -> None:
    if node.get("name", "").lower() == name.lower():
        results.append(node)
    for child in node.get("children", []):
        find_nodes_by_name(child, name, results)


def extract_top_frames(document: dict) -> list:
    frames = []
    for page in document.get("children", []):
        for child in page.get("children", []):
            if child.get("type") in ("FRAME", "COMPONENT", "COMPONENT_SET"):
                bbox = child.get("absoluteBoundingBox") or {}
                frames.append({
                    "id": child["id"],
                    "name": child["name"],
                    "type": child["type"],
                    "page": page["name"],
                    "width": bbox.get("width"),
                    "height": bbox.get("height"),
                    "layoutMode": child.get("layoutMode"),
                })
    return frames


def extract_styles_metadata(file_data: dict) -> dict:
    """
    Styles API returns style IDs; we resolve names + types from the file's styles map.
    """
    result = {"colors": [], "text": [], "effects": [], "grids": []}
    file_styles = file_data.get("styles", {})

    for style_id, meta in file_styles.items():
        entry = {
            "id": style_id,
            "name": meta.get("name"),
            "styleType": meta.get("styleType"),
            "description": meta.get("description", ""),
        }
        stype = meta.get("styleType", "")
        if stype == "FILL":
            result["colors"].append(entry)
        elif stype == "TEXT":
            result["text"].append(entry)
        elif stype == "EFFECT":
            result["effects"].append(entry)
        elif stype == "GRID":
            result["grids"].append(entry)

    return result


def extract_binding_metadata(node: dict) -> Optional[dict]:
    """Preserve node-level style and variable bindings for downstream token resolution.
    Returns None when the node has no bindings, so callers can omit the key entirely."""
    metadata = {}
    for key in ("fillStyleId", "strokeStyleId", "effectStyleId", "gridStyleId", "textStyleId"):
        value = node.get(key)
        if value:
            metadata[key] = value
    if node.get("boundVariables"):
        metadata["boundVariables"] = node.get("boundVariables")
    return metadata if metadata else None


def extract_component_spec(node: dict) -> dict:
    spec: dict = {
        "id": node.get("id"),
        "name": node.get("name"),
        "type": node.get("type"),
    }

    desc = node.get("description", "")
    if desc:
        spec["description"] = desc

    spec["layout"] = extract_layout(node)

    fills = node.get("fills", [])
    if fills:
        spec["fills"] = fills
    strokes = node.get("strokes", [])
    if strokes:
        spec["strokes"] = strokes
    effects = node.get("effects", [])
    if effects:
        spec["effects"] = effects

    chars = node.get("characters")
    if chars is not None:
        spec["characters"] = chars
    style = node.get("style")
    if style:
        spec["style"] = style

    bindings = extract_binding_metadata(node)
    if bindings:
        spec["bindings"] = bindings

    spec["componentProperties"] = node.get("componentPropertyDefinitions", {})
    spec["variants"] = []
    spec["children"] = []

    # For component sets, extract variants
    if node.get("type") == "COMPONENT_SET":
        for child in node.get("children", []):
            if child.get("type") == "COMPONENT":
                variant = {
                    "id": child["id"],
                    "name": child["name"],
                    "type": child.get("type"),
                    "layout": extract_layout(child),
                    "fills": child.get("fills", []),
                }
                spec["variants"].append(variant)
    else:
        for child in node.get("children", []):
            spec["children"].append(extract_component_spec(child))

    return spec


def extract_layout(node: dict) -> dict:
    bbox = node.get("absoluteBoundingBox") or {}
    layout: dict = {}

    # Dimensions are always included
    if bbox.get("width") is not None:
        layout["width"] = bbox["width"]
    if bbox.get("height") is not None:
        layout["height"] = bbox["height"]

    # Only emit flex/auto-layout fields when they carry real information
    for key in ("layoutMode", "primaryAxisSizingMode", "counterAxisSizingMode",
                "primaryAxisAlignItems", "counterAxisAlignItems"):
        val = node.get(key)
        if val is not None:
            layout[key] = val

    # Padding/spacing — omit when zero (the default)
    for key in ("paddingLeft", "paddingRight", "paddingTop", "paddingBottom", "itemSpacing"):
        val = node.get(key, 0)
        if val:
            layout[key] = val

    # Corner radius — omit when absent
    cr = node.get("cornerRadius")
    if cr is not None:
        layout["cornerRadius"] = cr
    rcr = node.get("rectangleCornerRadii")
    if rcr is not None:
        layout["rectangleCornerRadii"] = rcr

    # Structural fields — only when non-default
    constraints = node.get("constraints")
    if constraints is not None:
        layout["constraints"] = constraints
    clips = node.get("clipsContent")
    if clips is not None:
        layout["clipsContent"] = clips
    opacity = node.get("opacity", 1)
    if opacity != 1:
        layout["opacity"] = opacity

    return layout


def collect_components(node: dict, components: list) -> None:
    if node.get("type") in ("COMPONENT", "COMPONENT_SET"):
        components.append(extract_component_spec(node))
    for child in node.get("children", []):
        collect_components(child, components)


def collect_instance_component_ids(node: dict, ids: set) -> None:
    """Walk a node subtree and collect componentId values from INSTANCE nodes."""
    if node.get("type") == "INSTANCE":
        cid = node.get("componentId")
        if cid:
            ids.add(cid)
    for child in node.get("children", []):
        collect_instance_component_ids(child, ids)


def expand_component_ids_with_sets(component_ids: set, file_components: dict) -> set:
    """Include parent component sets for referenced component variants when metadata is available."""
    expanded_ids = set(component_ids)
    for component_id in list(component_ids):
        component_meta = file_components.get(component_id, {})
        component_set_id = component_meta.get("componentSetId")
        if component_set_id:
            expanded_ids.add(component_set_id)
    return expanded_ids


# ─────────────────────────────────────────────
# Asset export helpers
# ─────────────────────────────────────────────

def parse_export_arg(value: Optional[str]) -> Optional[list]:
    """
    None        → export disabled
    ""  / True  → export ALL (caller passes "" or flag with no value)
    "a,b,c"     → export named list
    """
    if value is None:
        return None
    if value.strip() == "":
        return []  # empty list = "all"
    return [n.strip() for n in value.split(",") if n.strip()]


def collect_nodes_by_names(node: dict, names: list, results: list, node_types: tuple) -> None:
    """Walk tree collecting nodes whose name is in `names` and type in `node_types`."""
    if node.get("type") in node_types:
        if not names or node.get("name", "").lower() in [n.lower() for n in names]:
            results.append(node)
    for child in node.get("children", []):
        collect_nodes_by_names(child, names, results, node_types)


def collect_icon_nodes(document: dict, names: list) -> list:
    """
    Collect icon component nodes. Strategy:
    1. Look for a page or frame named 'Icons', 'Icon', 'icon' first.
    2. Fall back to any COMPONENT whose name starts with 'icon/' or 'ic/'.
    3. If `names` is non-empty, filter by those names after collection.
    """
    candidates = []

    # Try dedicated icons page/frame first
    icon_containers = []
    for page in document.get("children", []):
        if "icon" in page.get("name", "").lower():
            icon_containers.append(page)
        for child in page.get("children", []):
            if "icon" in child.get("name", "").lower() and child.get("type") in ("FRAME", "COMPONENT_SET"):
                icon_containers.append(child)

    if icon_containers:
        for container in icon_containers:
            collect_nodes_by_names(container, [], candidates, ("COMPONENT",))
    else:
        # Fall back: collect all components with icon-like names
        def _collect_icon_components(node):
            if node.get("type") == "COMPONENT":
                n = node.get("name", "").lower()
                if n.startswith("icon/") or n.startswith("ic/") or n.startswith("icon-") or "icon" in n:
                    candidates.append(node)
            for child in node.get("children", []):
                _collect_icon_components(child)
        _collect_icon_components(document)

    # Filter by requested names if a specific list was given
    if names:
        name_set = {n.lower() for n in names}
        candidates = [c for c in candidates if any(
            n in c.get("name", "").lower() for n in name_set
        )]

    return candidates


GENERIC_FRAME_NAMES = {"frame", "group", "section", "container", "rectangle", "node"}


def collect_text_snippets(node: dict, snippets: list[str], limit: int = 3) -> None:
    """Collect short descendant text labels for friendly exported image names."""
    if len(snippets) >= limit:
        return

    text = str(node.get("characters") or "").strip()
    if text:
        compact = re.sub(r"\s+", " ", text)
        if compact and compact not in snippets:
            snippets.append(compact[:50])
            if len(snippets) >= limit:
                return

    for child in node.get("children", []):
        collect_text_snippets(child, snippets, limit=limit)
        if len(snippets) >= limit:
            return


def friendly_child_frame_name(frame: dict, index: int) -> str:
    """Return a useful filename stem for child frame image exports."""
    raw_name = str(frame.get("name") or "").strip()
    raw_slug = slugify(raw_name) if raw_name else ""

    if raw_slug and raw_slug not in GENERIC_FRAME_NAMES and not re.fullmatch(r"frame-?\d*", raw_slug):
        return raw_name

    snippets: list[str] = []
    collect_text_snippets(frame, snippets)
    if snippets:
        return " - ".join(snippets)

    return f"frame {index + 1:02d}"


def node_has_exportable_size(node: dict) -> bool:
    """Return true when a node is large enough to be a meaningful visual candidate."""
    layout = node.get("layout") or {}
    width = layout.get("width")
    height = layout.get("height")
    if width is None or height is None:
        return False
    return width >= CHILD_IMAGE_MIN_SIZE and height >= CHILD_IMAGE_MIN_SIZE


def collect_child_image_candidates(target: dict, max_depth: int = 2) -> list[dict]:
    """
    Find nodes worth exporting when an agent has decided a target preview is complex.

    The agent still decides whether to run --child-images. This helper only makes that
    follow-up useful for real Figma boards, where states may be components, instances,
    or nested frames under wrapper groups/sections rather than direct FRAME children.
    """
    direct_children = list(target.get("children") or []) + list(target.get("variants") or [])

    def candidate_record(node: dict) -> Optional[dict]:
        node_type = node.get("type")
        if node_type not in CHILD_IMAGE_EXPORT_TYPES:
            return None
        if not node_has_exportable_size(node):
            return None
        node_id = node.get("id")
        if not node_id:
            return None
        return node

    direct_candidates = [record for child in direct_children if (record := candidate_record(child))]
    if len(direct_candidates) > 1:
        return dedupe_nodes_by_id(direct_candidates)

    nested_candidates: list[dict] = []

    def visit(node: dict, depth: int) -> None:
        if depth > max_depth:
            return
        record = candidate_record(node)
        if record and not (depth == 1 and len(direct_candidates) == 1):
            nested_candidates.append(record)
            return

        node_type = node.get("type")
        if depth > 0 and node_type not in CHILD_IMAGE_WRAPPER_TYPES and node_type not in CHILD_IMAGE_EXPORT_TYPES:
            return

        for child in node.get("children") or []:
            visit(child, depth + 1)

    for child in direct_children:
        visit(child, 1)

    wrapper_candidates = [
        child for child in direct_children
        if child.get("type") in CHILD_IMAGE_WRAPPER_TYPES
        and node_has_exportable_size(child)
        and child.get("id")
    ]

    if len(nested_candidates) > 1:
        return dedupe_nodes_by_id(nested_candidates)
    if direct_candidates:
        return dedupe_nodes_by_id(direct_candidates)
    return dedupe_nodes_by_id(nested_candidates or wrapper_candidates)


def dedupe_nodes_by_id(nodes: list[dict]) -> list[dict]:
    """Preserve order while removing duplicate Figma node IDs."""
    seen_ids: set = set()
    unique_nodes = []
    for node in nodes:
        node_id = node.get("id")
        if not node_id or node_id in seen_ids:
            continue
        seen_ids.add(node_id)
        unique_nodes.append(node)
    return unique_nodes
