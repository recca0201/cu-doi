"""Image and icon export orchestration (depends on figmakit.api, .nodes, .paths)."""

import sys
from pathlib import Path
from typing import Optional

from figmakit.api import fetch_image_urls, fetch_svg_content, download_file
from figmakit.nodes import collect_icon_nodes
from figmakit.paths import slugify_name


def export_single_node_image(token: str, file_key: str, node: dict, export_dir: Path, fmt: str = "png") -> Optional[dict]:
    """Export a single node preview image and return its metadata."""
    node_id = node.get("id")
    node_name = node.get("name", "node")
    if not node_id:
        return None

    url_map = fetch_image_urls(token, file_key, [node_id], fmt=fmt, scale=1)
    if not url_map.get(node_id):
        url_map = fetch_image_urls(token, file_key, [node_id], fmt=fmt, scale=2)
    url = url_map.get(node_id)
    if not url:
        print(f"  Warning: no image URL for target node '{node_name}'", file=sys.stderr)
        return None

    export_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{slugify_name(node_name)}-{node_id.replace(':', '-')}.{fmt}"
    dest = export_dir / filename
    if not download_file(url, dest):
        return None

    bbox = node.get("absoluteBoundingBox") or {}
    print(f"  ✓ target node image → {dest}", file=sys.stderr)
    return {
        "name": node_name,
        "node_id": node_id,
        "width": bbox.get("width"),
        "height": bbox.get("height"),
        "format": fmt,
        "file_path": str(dest),
    }


def export_icons(token: str, file_key: str, document: dict, names: list) -> list:
    """
    Collect icon nodes, fetch SVG content, return list of icon records:
    [{name, node_id, width, height, svg_content}]
    """
    nodes = collect_icon_nodes(document, names)
    if not nodes:
        print("  No icon nodes found.", file=sys.stderr)
        return []

    print(f"  Found {len(nodes)} icon(s). Fetching SVG content...", file=sys.stderr)
    node_ids = [n["id"] for n in nodes]

    # Batch requests: Figma image API handles ~100 IDs per request
    svg_map = {}
    for i in range(0, len(node_ids), 100):
        batch = node_ids[i:i + 100]
        svg_map.update(fetch_svg_content(token, file_key, batch))

    records = []
    for node in nodes:
        nid = node["id"]
        bbox = node.get("absoluteBoundingBox") or {}
        records.append({
            "name": node["name"],
            "node_id": nid,
            "width": bbox.get("width"),
            "height": bbox.get("height"),
            "svg_content": svg_map.get(nid, ""),
        })
        print(f"  ✓ {node['name']}", file=sys.stderr)

    return records


def export_images(token: str, file_key: str, document: dict, names: list, export_dir: Path, fmt: str = "png") -> list:
    """
    Find frames by name, download as PNG/JPG, return list of image records:
    [{name, node_id, width, height, format, file_path}]
    """
    # Collect matching top-level frames across all pages
    nodes = []
    for page in document.get("children", []):
        for child in page.get("children", []):
            if child.get("type") in ("FRAME", "COMPONENT", "COMPONENT_SET", "GROUP"):
                if not names or child.get("name", "").lower() in [n.lower() for n in names]:
                    nodes.append(child)

    if not nodes:
        print("  No image frames found.", file=sys.stderr)
        return []

    print(f"  Found {len(nodes)} image frame(s). Fetching URLs...", file=sys.stderr)
    node_ids = [n["id"] for n in nodes]

    url_map = {}
    for i in range(0, len(node_ids), 100):
        batch = node_ids[i:i + 100]
        url_map.update(fetch_image_urls(token, file_key, batch, fmt=fmt, scale=2))

    export_dir.mkdir(parents=True, exist_ok=True)

    records = []
    for node in nodes:
        nid = node["id"]
        url = url_map.get(nid)
        if not url:
            print(f"  Warning: no URL for '{node['name']}'", file=sys.stderr)
            continue

        filename = f"{slugify_name(node['name'])}.{fmt}"
        dest = export_dir / filename
        if download_file(url, dest):
            bbox = node.get("absoluteBoundingBox") or {}
            records.append({
                "name": node["name"],
                "node_id": nid,
                "width": bbox.get("width"),
                "height": bbox.get("height"),
                "format": fmt,
                "file_path": str(dest),
            })
            print(f"  ✓ {node['name']} → {dest}", file=sys.stderr)

    return records
