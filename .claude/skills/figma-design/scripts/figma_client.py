#!/usr/bin/env python3
"""
Figma REST API client — fetches file data, components, styles, variables, and exports assets.
Outputs raw JSON for use by extract_spec.py.

Token resolution order (first found wins):
  1. FIGMA_TOKEN environment variable
  2. FIGMA_TOKEN in .env file (skill directory or current directory)
  Run setup_token.py once to save the token securely.

Usage:
  # Pass a full Figma URL — file key and node-id are parsed automatically
  python3 figma_client.py --url "https://www.figma.com/design/FILE_KEY/Name?node-id=4812-38472" --output out.json

  python3 figma_client.py --output out.json
  python3 figma_client.py --file FILE_KEY --node 4812-38472 --output out.json
  python3 figma_client.py --component "Button" --output out.json
  python3 figma_client.py --frame "Login Screen" --output out.json
  python3 figma_client.py --variables --output out.json

  # Export icons (SVG inline in spec):
  python3 figma_client.py --output out.json --export-icons          # all icons
  python3 figma_client.py --output out.json --export-icons "close"  # one
  python3 figma_client.py --output out.json --export-icons "close,search,arrow-right"  # list

  # Export raster images (downloaded to --export-dir):
  python3 figma_client.py --output out.json --export-images          # all top-level frames
  python3 figma_client.py --output out.json --export-images "Hero"   # one
  python3 figma_client.py --output out.json --export-images "Hero,Empty State" --export-dir ./src/assets

  # Hidden-node behaviour (default: hidden nodes are stripped from the spec):
  python3 figma_client.py --url "..." --include-hidden   # keep nodes with visible=false

Structure:
  The reusable pieces live in the `figmakit/` package (paths, nodes, api, assets, config)
  and are re-exported below so `figma_client.<name>` keeps resolving unchanged. This file
  stays a thin entry point: CLI parsing, run coordination, and the extraction orchestration
  in `main()` / `_extract()`.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import threading
import time
import urllib.parse
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any, Optional

# Coordination helpers live alongside this script; ensure the scripts dir is importable
# even when figma_client is imported from another working directory.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from run_state import RunCoordinator, Heartbeat, print_status  # noqa: E402

# ── Re-export relocated public names so `figma_client.<name>` keeps resolving ──
# Existing callers and the tests reference these on this module unchanged; the
# implementations now live in the figmakit package (see figmakit/).
from figmakit import (  # noqa: E402,F401
    SKILL_DIR,
    BASE_URL,
    NETWORK_TIMEOUT_SECONDS,
    MAX_RETRY_AFTER_WAIT_SECONDS,
    DEFAULT_MAX_RPM,
    CHILD_IMAGE_EXPORT_TYPES,
    CHILD_IMAGE_WRAPPER_TYPES,
    CHILD_IMAGE_MIN_SIZE,
)
from figmakit.paths import (  # noqa: E402,F401
    slugify,
    slugify_name,
    derive_scope,
    default_output_path,
    write_json_atomic,
)
from figmakit.nodes import (  # noqa: E402,F401
    GENERIC_FRAME_NAMES,
    strip_hidden_nodes,
    find_nodes_by_name,
    extract_top_frames,
    extract_styles_metadata,
    extract_binding_metadata,
    extract_component_spec,
    extract_layout,
    collect_components,
    collect_instance_component_ids,
    expand_component_ids_with_sets,
    parse_export_arg,
    collect_nodes_by_names,
    collect_icon_nodes,
    collect_text_snippets,
    friendly_child_frame_name,
    node_has_exportable_size,
    collect_child_image_candidates,
    dedupe_nodes_by_id,
)
from figmakit.api import (  # noqa: E402,F401
    FigmaHTTPError,
    figma_get,
    _handle_rate_limit,
    set_max_rpm,
    _throttle,
    _throttle_lock,
    _last_request_at,
    _min_request_interval,
    fetch_svg_content,
    fetch_image_urls,
    download_file,
)
from figmakit.config import (  # noqa: E402,F401
    load_dotenv,
    resolve_token,
    resolve_file_key,
    parse_figma_url,
)
from figmakit.assets import (  # noqa: E402,F401
    export_single_node_image,
    export_icons,
    export_images,
)


# ── Run coordination (set in main once the run directory is known) ──
_COORD: Optional[RunCoordinator] = None
_HEARTBEAT: Optional[Heartbeat] = None


def resolve_run_dir(args: argparse.Namespace, file_key: str, node_id: Optional[str]) -> Path:
    """Deterministic per-target coordination directory (lock + status + sentinels + detach log).

    Derived from args alone so a second invocation for the same target computes the same
    directory and the lock can catch it. Kept as a stable sidecar (temp/.figma-run/<slug>)
    rather than the artifact scope dir, because the scope name is only known after the
    first API round-trip while the lock must exist before it.
    """
    key = args.output if args.output else f"{file_key}:{node_id or 'file'}"
    slug = hashlib.sha1(key.encode("utf-8")).hexdigest()[:12]
    return Path.cwd() / "temp" / ".figma-run" / slug


def launch_detached(argv: list, run_dir: Path) -> None:
    """Re-exec this script without --detach, fully detached, logging to the run dir; then
    print the poll contract and return so the caller can exit 0 immediately."""
    run_dir.mkdir(parents=True, exist_ok=True)
    log_path = run_dir / "detach.log"
    child_argv = [a for a in argv if a != "--detach"]
    cmd = [sys.executable, str(Path(__file__).resolve())] + child_argv
    log = open(log_path, "w", encoding="utf-8")
    popen_kwargs: dict = {"stdout": log, "stderr": log, "stdin": subprocess.DEVNULL, "cwd": os.getcwd()}
    if os.name == "posix":
        popen_kwargs["start_new_session"] = True  # detach from controlling terminal
    else:
        popen_kwargs["creationflags"] = 0x00000008 | 0x00000200  # DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP
    subprocess.Popen(cmd, **popen_kwargs)
    status_path = run_dir / "run-status.json"
    print(
        "[figma-design] Extraction started in the background.\n"
        f"  Poll:   python3 {Path(__file__).name} --status \"{run_dir}\"\n"
        f"  Status: {status_path}\n"
        f"  Log:    {log_path}\n"
        "  Do NOT re-run the extraction. Poll --status until it reports COMPLETE (exit 0) "
        "or FAILED (exit 1); RUNNING is exit 3.",
        file=sys.stderr,
        flush=True,
    )


def progress(message: str) -> None:
    """Print an immediate progress line for long-running agent workflows.

    Also records the phase in run-status.json and refreshes the heartbeat label, so a
    harness that returned before completion can still see exactly where the run is.
    """
    print(f"[figma-design] {message}", file=sys.stderr, flush=True)
    label = message[:80]
    if _COORD is not None:
        _COORD.phase(label, message)
    if _HEARTBEAT is not None:
        _HEARTBEAT.bump(label)


def populate_target_node_result(
    result: dict,
    token: str,
    file_key: str,
    file_data: dict,
    node_doc: dict,
    args: argparse.Namespace,
) -> None:
    """Attach target-node, preview-image, and frame metadata to the output result."""
    result["node_name"] = node_doc.get("name")
    result["node_type"] = node_doc.get("type")
    result["target_node"] = extract_component_spec(node_doc)
    result["_raw_target_node"] = node_doc  # kept for component filtering; stripped before output

    node_scope = derive_scope(node_doc.get("name"), file_data.get("name"), file_key)
    node_image_dir = (Path(args.output) if args.output else default_output_path(node_scope)).parent
    result["target_node_image"] = export_single_node_image(
        token,
        file_key,
        node_doc,
        export_dir=node_image_dir,
        fmt=args.image_format,
    )

    bbox = node_doc.get("absoluteBoundingBox") or {}
    result["frames"] = [{
        "id": node_doc.get("id"),
        "name": node_doc.get("name"),
        "type": node_doc.get("type"),
        "page": "—",
        "width": bbox.get("width"),
        "height": bbox.get("height"),
        "layoutMode": node_doc.get("layoutMode"),
    }]


def fetch_component_specs(token: str, file_key: str, component_ids: set[str]) -> list[dict]:
    """Fetch component/component-set nodes by ID and return extracted specs."""
    specs, _missing = fetch_component_specs_with_missing(token, file_key, component_ids)
    return specs


def fetch_component_specs_with_missing(token: str, file_key: str, component_ids: set[str]) -> tuple[list[dict], set[str]]:
    """Fetch component/component-set nodes by ID and report IDs Figma did not return.

    Referenced INSTANCE component IDs can point at library components. When the
    current file API cannot resolve them, keep an explicit unresolved list in the
    output rather than making the handoff look complete.
    """
    if not component_ids:
        return [], set()

    component_specs: list[dict] = []
    returned_ids: set[str] = set()
    batches = [list(component_ids)[i:i + 50] for i in range(0, len(component_ids), 50)]
    for batch in batches:
        data = figma_get(token, f"/files/{file_key}/nodes?ids={','.join(batch)}")
        for node_id, node_info in data.get("nodes", {}).items():
            if not node_info:
                continue
            returned_ids.add(node_id)
            node = node_info.get("document", {})
            if node.get("type") in ("COMPONENT", "COMPONENT_SET"):
                component_specs.append(extract_component_spec(node))

    return component_specs, set(component_ids) - returned_ids


def main():
    parser = argparse.ArgumentParser(description="Fetch Figma file data via REST API")
    parser.add_argument("--url", help="Full Figma URL — file key and node-id parsed automatically")
    parser.add_argument("--file", help="Figma file key (or set FIGMA_FILE_KEY in env/.env)")
    parser.add_argument("--node", help="Node ID to highlight as primary frame (e.g. 4812-38472 or 4812:38472)")
    parser.add_argument("--node-only", action="store_true", help="Skip full file fetch — scope everything to the target node (faster but misses file-level components/styles)")
    parser.add_argument("--include-hidden", action="store_true", help="Include hidden nodes (visible=false) in the spec output. By default hidden nodes are stripped.")
    parser.add_argument("--output", default=None, help="Output JSON file path (default: temp/figma_<scope>/figma-spec.json in cwd)")
    parser.add_argument("--component", help="Extract only this component name")
    parser.add_argument("--frame", help="Extract only this frame/screen name")
    parser.add_argument("--variables", action="store_true", help="Also fetch Figma Variables")
    parser.add_argument(
        "--export-icons", nargs="?", const="", metavar="NAMES",
        help="Export icons as SVG (inline in spec). No value = all icons; or comma-separated names."
    )
    parser.add_argument(
        "--export-images", nargs="?", const="", metavar="NAMES",
        help="Export frames as PNG (downloaded to --export-dir). No value = all; or comma-separated names."
    )
    parser.add_argument(
        "--export-dir", default="./figma-exports",
        help="Directory for downloaded image files (default: ./figma-exports)"
    )
    parser.add_argument(
        "--image-format", choices=["png", "jpg", "webp"], default="png",
        help="Format for exported images (default: png)"
    )
    parser.add_argument(
        "--pretty", action="store_true",
        help="Write figma-spec.json with indent=2 (human-readable). Default is compact (no indent) to minimize file size."
    )
    parser.add_argument(
        "--child-images", action="store_true",
        help="After the agent decides the target preview is complex, batch-download preview images for exportable child candidates "
             "(frames, components, component sets, instances, or nested candidates under wrapper groups/sections). "
             "Saves as <N>-<slugified-name>-<node-id>.png alongside figma-spec.json. Useful when the target node is a design board."
    )
    parser.add_argument(
        "--with-spec-md", action="store_true",
        help="After writing figma-spec.json, also run extract_spec.py and write figma-spec.md alongside it."
    )
    parser.add_argument(
        "--mds", action="store_true",
        help="When --with-spec-md is used, apply Magenta Design System token mappings to figma-spec.md."
    )
    parser.add_argument(
        "--no-mds", action="store_true",
        help="When --with-spec-md is used, disable Magenta Design System mappings even if foundation guidance mentions MDS."
    )
    parser.add_argument(
        "--detach", action="store_true",
        help="Start the extraction detached and return immediately, printing the run-status path to poll. "
             "Use in harnesses (e.g. GitHub Copilot) whose terminal may return before a long command finishes."
    )
    parser.add_argument(
        "--status", metavar="RUN_DIR", default=None,
        help="Do not extract; print the status of a run (see --detach output) and exit "
             "(0=complete, 3=running, 1=failed/not-started)."
    )
    parser.add_argument(
        "--force", action="store_true",
        help="Ignore an existing run lock for the same target and extract anyway (use only if a prior run is truly dead)."
    )
    parser.add_argument(
        "--max-rpm", type=float, default=DEFAULT_MAX_RPM,
        help=f"Cap Figma requests per minute (client-side pacing; default {DEFAULT_MAX_RPM}). 429s are always honored via Retry-After."
    )
    args = parser.parse_args()

    # `--status` is a pure read of a prior run; no token or network needed.
    if args.status:
        sys.exit(print_status(Path(args.status)))
    if args.mds and args.no_mds:
        print("Error: --mds and --no-mds cannot be used together.", file=sys.stderr)
        sys.exit(1)

    # Resolve the target first (URL parse / file key need no token or network) so the
    # run can be coordinated — lock acquired, detach decided — before any slow fetch.
    url_node_id: Optional[str] = None
    if args.url:
        file_key, url_node_id = parse_figma_url(args.url)
        print(f"Parsed URL → file: {file_key}" + (f", node: {url_node_id}" if url_node_id else ""), file=sys.stderr)
    else:
        file_key = resolve_file_key(args.file)
    node_id: Optional[str] = args.node or url_node_id  # --node overrides node from URL

    run_dir = resolve_run_dir(args, file_key, node_id)
    if args.detach:
        launch_detached(sys.argv[1:], run_dir)
        return

    set_max_rpm(args.max_rpm)
    coord = RunCoordinator(run_dir)
    if not args.force:
        holder = coord.acquire_lock()
        if holder is not None:
            print(
                f"[figma-design] An extraction for this target is already running "
                f"(pid {holder.get('pid')}). Do NOT start another — poll it instead:\n"
                f"  python3 {Path(__file__).name} --status \"{run_dir}\"\n"
                "  (pass --force only if that run is truly dead).",
                file=sys.stderr,
            )
            return
    else:
        coord.acquire_lock()

    global _COORD, _HEARTBEAT
    _COORD = coord
    _HEARTBEAT = Heartbeat().start()
    coord.start({
        "file_key": file_key, "node_id": node_id,
        "source_url": args.url, "run_dir": str(run_dir),
    })

    try:
        outputs = _extract(args, resolve_token(), file_key, node_id)
        coord.finish(0, outputs)
    except SystemExit as exc:
        code = exc.code if isinstance(exc.code, int) else 1
        if code == 0:
            coord.finish(0, [])
        else:
            coord.fail(f"exited with code {code}")
        raise
    except BaseException as exc:  # record the failure in run-status.json, then re-raise
        coord.fail(f"{type(exc).__name__}: {exc}")
        raise
    finally:
        _HEARTBEAT.stop()
        coord.release_lock()


def _extract(args: argparse.Namespace, token: str, file_key: str, node_id: Optional[str]) -> list:
    """Fetch the Figma data and write figma-spec.json / figma-spec.md / images. Returns artifact paths."""
    progress("Start. Wait for 'Complete', 'Output', and 'Markdown' before reading artifacts.")

    # ── Fetch file metadata + node spec (in parallel when a node is targeted) ──
    result = {
        "file_key": file_key,
        "node_id": node_id,
        "source_url": args.url,
        "extraction_mode": "node-only" if node_id and args.node_only else ("node" if node_id else "file"),
        "target_node": None,
        "target_node_image": None,
        "styles": {},
        "components": [],
        "frames": [],
        "variables": {},
        "icons": [],
        "images": [],
        "unresolved_component_ids": [],
    }

    if node_id and args.node_only:
        # Fast path: scope everything to the node subtree (explicit opt-in)
        api_id = node_id.replace("-", ":")
        fetch_tasks = {
            "file": (f"/files/{file_key}?depth=1", "file metadata (depth=1)"),
            "node": (f"/files/{file_key}/nodes?ids={api_id}", f"node {api_id}"),
        }
        if args.variables:
            fetch_tasks["vars"] = (f"/files/{file_key}/variables/local", "variables")

        progress(f"Fetching node-only metadata + node {api_id}...")
        fetched: dict[str, Any] = {}
        with ThreadPoolExecutor(max_workers=len(fetch_tasks)) as pool:
            futures = {pool.submit(figma_get, token, path): key for key, (path, _) in fetch_tasks.items()}
            for future in as_completed(futures):
                fetched[futures[future]] = future.result()

        file_data = fetched["file"]
        node_info = fetched["node"].get("nodes", {}).get(api_id)
        if not node_info:
            print(f"Error: node '{node_id}' not found in file '{file_key}'.", file=sys.stderr)
            sys.exit(1)
        node_doc = node_info.get("document", {})
        if not args.include_hidden:
            node_doc = strip_hidden_nodes(node_doc)
        document = {"children": [{"children": [node_doc], "name": "Node", "type": "PAGE"}]}
        populate_target_node_result(result, token, file_key, file_data, node_doc, args)
        if "vars" in fetched:
            result["variables"] = fetched["vars"]
    elif node_id:
        # Default: full file fetch + node fetch in parallel.
        # Full file gives complete component/style inventory; node identifies the primary frame.
        # If the full file is too large (HTTP 400), automatically fall back to node-only mode.
        api_id = node_id.replace("-", ":")
        fetch_tasks = {
            "file": (f"/files/{file_key}", "full file"),
            "node": (f"/files/{file_key}/nodes?ids={api_id}", f"node {api_id}"),
        }
        if args.variables:
            fetch_tasks["vars"] = (f"/files/{file_key}/variables/local", "variables")

        progress(f"Fetching full file + node {api_id}...")
        fetched: dict[str, Any] = {}
        full_file_too_large = False
        with ThreadPoolExecutor(max_workers=len(fetch_tasks)) as pool:
            futures = {
                pool.submit(figma_get, token, path, suppress_request_too_large=(key == "file")): key
                for key, (path, _) in fetch_tasks.items()
            }
            for future in as_completed(futures):
                key = futures[future]
                try:
                    fetched[key] = future.result()
                except FigmaHTTPError as exc:
                    if exc.code == 400 and key == "file":
                        print(
                            "Full file too large (HTTP 400); using node-only fallback. Wait for completion.",
                            file=sys.stderr,
                        )
                        full_file_too_large = True
                        fetched[key] = None
                    else:
                        raise

        if full_file_too_large:
            result["extraction_mode"] = "node-only-fallback"
            # Re-run as node-only: fetch metadata at depth=1 + node subtree
            node_fetch_tasks = {
                "file": (f"/files/{file_key}?depth=1", "file metadata (depth=1)"),
                "node": (f"/files/{file_key}/nodes?ids={api_id}", f"node {api_id}"),
            }
            if args.variables:
                node_fetch_tasks["vars"] = (f"/files/{file_key}/variables/local", "variables")

            progress(f"Fetching fallback node-only node {api_id}...")
            fetched = {}
            with ThreadPoolExecutor(max_workers=len(node_fetch_tasks)) as pool:
                futures = {pool.submit(figma_get, token, path): key for key, (path, _) in node_fetch_tasks.items()}
                for future in as_completed(futures):
                    fetched[futures[future]] = future.result()

            file_data = fetched["file"]
            node_info = fetched["node"].get("nodes", {}).get(api_id)
            if not node_info:
                print(f"Error: node '{node_id}' not found in file '{file_key}'.", file=sys.stderr)
                sys.exit(1)
            node_doc = node_info.get("document", {})
            if not args.include_hidden:
                node_doc = strip_hidden_nodes(node_doc)
            document = {"children": [{"children": [node_doc], "name": "Node", "type": "PAGE"}]}
            populate_target_node_result(result, token, file_key, file_data, node_doc, args)
            if "vars" in fetched:
                result["variables"] = fetched["vars"]
        else:
            file_data = fetched["file"]
            node_info = fetched["node"].get("nodes", {}).get(api_id)
            if not node_info:
                print(f"Error: node '{node_id}' not found in file '{file_key}'.", file=sys.stderr)
                sys.exit(1)
            node_doc = node_info.get("document", {})
            if not args.include_hidden:
                node_doc = strip_hidden_nodes(node_doc)
            # Use full document for component/style collection; mark target node as primary frame
            document = file_data.get("document", {})
            if not args.include_hidden:
                document = strip_hidden_nodes(document)
            populate_target_node_result(result, token, file_key, file_data, node_doc, args)
            if "vars" in fetched:
                result["variables"] = fetched["vars"]
    else:
        # Full file fetch — variables can run in parallel if requested
        if args.variables:
            progress("Fetching full file + variables...")
            with ThreadPoolExecutor(max_workers=2) as pool:
                f_file = pool.submit(figma_get, token, f"/files/{file_key}")
                f_vars = pool.submit(figma_get, token, f"/files/{file_key}/variables/local")
                file_data = f_file.result()
                try:
                    result["variables"] = f_vars.result()
                except SystemExit:
                    print("Variables fetch failed — skipping.", file=sys.stderr)
                    result["variables"] = {}
        else:
            progress(f"Fetching file {file_key}...")
            file_data = figma_get(token, f"/files/{file_key}")
        document = file_data.get("document", {})
        if not args.include_hidden:
            document = strip_hidden_nodes(document)

    result["file_name"] = file_data.get("name")
    result["last_modified"] = file_data.get("lastModified")

    # ── Styles (always resolved from file-level styles map) ──
    progress("Resolving styles and tokens...")
    result["styles"] = extract_styles_metadata(file_data)

    style_node_ids = list(file_data.get("styles", {}).keys())
    if style_node_ids:
        # Fetch style node batches in parallel (50 IDs per request)
        batches = [style_node_ids[i:i + 50] for i in range(0, len(style_node_ids), 50)]
        all_nodes: dict = {}
        if len(batches) == 1:
            data = figma_get(token, f"/files/{file_key}/nodes?ids={','.join(batches[0])}")
            all_nodes = data.get("nodes", {})
        else:
            with ThreadPoolExecutor(max_workers=min(len(batches), 5)) as pool:
                futures = [
                    pool.submit(figma_get, token, f"/files/{file_key}/nodes?ids={','.join(b)}")
                    for b in batches
                ]
                for future in as_completed(futures):
                    all_nodes.update(future.result().get("nodes", {}))

        for node_id_s, node_info in all_nodes.items():
            node = node_info.get("document", {})
            stype = file_data["styles"].get(node_id_s, {}).get("styleType")
            entry = {
                "id": node_id_s,
                "name": file_data["styles"][node_id_s]["name"],
                "styleType": stype,
                "fills": node.get("fills", []),
                "strokes": node.get("strokes", []),
                "style": node.get("style", {}),
                "effects": node.get("effects", []),
                "layoutGrids": node.get("layoutGrids", []),
                "bindings": extract_binding_metadata(node),
            }
            if stype == "FILL":
                result["styles"]["colors"].append(entry)
            elif stype == "TEXT":
                result["styles"]["text"].append(entry)
            elif stype == "EFFECT":
                result["styles"]["effects"].append(entry)
            elif stype == "GRID":
                result["styles"]["grids"].append(entry)

    for key in ("colors", "text", "effects", "grids"):
        result["styles"][key] = [s for s in result["styles"][key] if "fills" in s or "style" in s or "effects" in s or "layoutGrids" in s]

    # ── Components ──
    if args.component:
        progress(f"Finding component '{args.component}'...")
        matches = []
        find_nodes_by_name(document, args.component, matches)
        result["components"] = [extract_component_spec(n) for n in matches]
    elif not node_id:
        progress("Collecting components...")
        collect_components(document, result["components"])
    else:
        # Collect only components referenced by the target node's subtree
        raw_target = result.get("_raw_target_node")
        if raw_target:
            referenced_ids: set = set()
            collect_instance_component_ids(raw_target, referenced_ids)
            # Also include the target node itself if it is a component/instance
            target_cid = raw_target.get("componentId") or raw_target.get("id")
            if target_cid:
                referenced_ids.add(target_cid)

            referenced_ids = expand_component_ids_with_sets(
                referenced_ids,
                file_data.get("components", {}),
            )

            if args.node_only:
                result["components"], unresolved_ids = fetch_component_specs_with_missing(token, file_key, referenced_ids)
            else:
                all_components: list = []
                collect_components(document, all_components)
                result["components"] = [c for c in all_components if c.get("id") in referenced_ids]
                found_ids = {c.get("id") for c in result["components"] if c.get("id")}
                missing_ids = referenced_ids - found_ids
                fetched_specs, unresolved_ids = fetch_component_specs_with_missing(token, file_key, missing_ids)
                existing_ids = {c.get("id") for c in result["components"] if c.get("id")}
                result["components"].extend(c for c in fetched_specs if c.get("id") not in existing_ids)
            if unresolved_ids:
                result["unresolved_component_ids"] = sorted(unresolved_ids)
                print(
                    f"  Warning: {len(unresolved_ids)} referenced component ID(s) could not be resolved in this file",
                    file=sys.stderr,
                )
            print(f"  Filtered to {len(result['components'])} component(s) referenced by target node", file=sys.stderr)
        else:
            collect_components(document, result["components"])

    # ── Frames (only when not already set from node fetch) ──
    if not node_id:
        if args.frame:
            progress(f"Finding frame '{args.frame}'...")
            matches = []
            find_nodes_by_name(document, args.frame, matches)
            result["frames"] = [extract_component_spec(n) for n in matches]
        else:
            result["frames"] = extract_top_frames(document)

    # Variables already fetched in parallel above when args.variables is set

    # ── Export icons ──
    icon_names = parse_export_arg(args.export_icons)
    if icon_names is not None:
        label = "all icons" if not icon_names else f"icons: {', '.join(icon_names)}"
        print(f"Exporting {label}...", file=sys.stderr)
        result["icons"] = export_icons(token, file_key, document, icon_names)

    # ── Export images ──
    image_names = parse_export_arg(args.export_images)
    if image_names is not None:
        label = "all frames" if not image_names else f"frames: {', '.join(image_names)}"
        print(f"Exporting {label} as {args.image_format}...", file=sys.stderr)
        result["images"] = export_images(
            token, file_key, document, image_names,
            export_dir=Path(args.export_dir),
            fmt=args.image_format,
        )

    # Resolve output path — default to temp/figma_<scope>/figma-spec.json in cwd
    scope = derive_scope(result.get("node_name"), result.get("file_name"), file_key)
    output_path = Path(args.output) if args.output else default_output_path(scope)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    result.pop("_raw_target_node", None)  # internal use only; not part of output schema
    if not result.get("unresolved_component_ids"):
        result.pop("unresolved_component_ids", None)

    # Deterministic ordering — components and styles are gathered from parallel fetches
    # (as_completed), so their order varies run-to-run. Sort them so re-extractions of an
    # unchanged design diff cleanly and future content-hash caching stays stable.
    result["components"].sort(key=lambda c: (str(c.get("name", "")), str(c.get("id", ""))))
    for _style_group in ("colors", "text", "effects", "grids"):
        result.get("styles", {}).get(_style_group, []).sort(
            key=lambda s: (str(s.get("name", "")), str(s.get("id", "")))
        )

    progress(f"Writing JSON: {output_path}")
    write_json_atomic(output_path, result, args.pretty)
    outputs = [str(output_path)]

    # ── Child frame images (--child-images) ──
    if args.child_images:
        target = result.get("target_node") or {}
        child_candidates = collect_child_image_candidates(target)
        if not child_candidates:
            print("  --child-images: no exportable child candidates found in target node.", file=sys.stderr)
        else:
            type_counts: dict[str, int] = {}
            for candidate in child_candidates:
                ctype = candidate.get("type", "UNKNOWN")
                type_counts[ctype] = type_counts.get(ctype, 0) + 1
            type_summary = ", ".join(f"{count} {ctype}" for ctype, count in sorted(type_counts.items()))
            progress(f"Downloading {len(child_candidates)} child preview(s): {type_summary}...")
            img_dir = output_path.parent
            img_dir.mkdir(parents=True, exist_ok=True)

            child_ids = [c["id"] for c in child_candidates]

            # Batch: Figma /images/ accepts ~50 IDs per request before URL-length issues.
            # Use scale=1 for child-image batches — scale=2 on large frames triggers a render timeout.
            url_map: dict = {}
            for i in range(0, len(child_ids), 50):
                batch = child_ids[i:i + 50]
                url_map.update(fetch_image_urls(token, file_key, batch, fmt=args.image_format, scale=1))

            # Download in parallel (up to 8 threads)
            name_map = {c["id"]: friendly_child_frame_name(c, i) for i, c in enumerate(child_candidates)}
            type_map = {c["id"]: c.get("type") for c in child_candidates}
            child_image_records: list = []

            def _download_child(idx_cid):
                idx, cid = idx_cid
                img_url = url_map.get(cid)
                if not img_url:
                    print(f"  Warning: no image URL for child {cid}", file=sys.stderr)
                    return None
                name_slug = slugify(name_map[cid])
                cid_slug = cid.replace(":", "-")
                fname = img_dir / f"{idx + 1:02d}-{name_slug}-{cid_slug}.{args.image_format}"
                if download_file(img_url, fname):
                    print(f"    ✓ {fname.name}", file=sys.stderr)
                    return {"index": idx + 1, "name": name_map[cid], "node_id": cid, "type": type_map.get(cid), "file_path": str(fname), "format": args.image_format}
                return None

            with ThreadPoolExecutor(max_workers=8) as pool:
                futs = {pool.submit(_download_child, (i, cid)): cid for i, cid in enumerate(child_ids)}
                for fut in as_completed(futs):
                    record = fut.result()
                    if record:
                        child_image_records.append(record)

            # Sort by index so figma-spec.md lists frames in board order
            child_image_records.sort(key=lambda r: r["index"])

            print(f"  --child-images: saved {len(child_image_records)} image(s) to {img_dir}", file=sys.stderr)

            # Persist child image metadata back into figma-spec.json so extract_spec.py can reference them
            result["child_images"] = child_image_records
            write_json_atomic(output_path, result, args.pretty)
            outputs.extend(r["file_path"] for r in child_image_records)

    component_count = len(result["components"])
    style_count = sum(len(v) for v in result["styles"].values())
    icon_count = len(result["icons"])
    image_count = len(result["images"])
    fetch_scope = f"node {node_id}" if node_id else "full file"

    if args.with_spec_md:
        markdown_path = output_path.with_suffix(".md")
        progress(f"Writing Markdown: {markdown_path}")
        extract_command = [
            sys.executable,
            str(SKILL_DIR / "scripts" / "extract_spec.py"),
            "--input",
            str(output_path),
            "--output",
            str(markdown_path),
        ]
        if args.mds:
            extract_command.append("--mds")
        elif args.no_mds:
            extract_command.append("--no-mds")
        try:
            completed = subprocess.run(
                extract_command,
                check=True,
                capture_output=True,
                text=True,
            )
        except subprocess.CalledProcessError as exc:
            if exc.stdout:
                print(exc.stdout, file=sys.stderr, end="" if exc.stdout.endswith("\n") else "\n")
            if exc.stderr:
                print(exc.stderr, file=sys.stderr, end="" if exc.stderr.endswith("\n") else "\n")
            print("Failed to generate markdown spec from figma-spec.json.", file=sys.stderr)
            sys.exit(exc.returncode or 1)

        if completed.stdout:
            print(completed.stdout, file=sys.stderr, end="" if completed.stdout.endswith("\n") else "\n")
        if completed.stderr:
            print(completed.stderr, file=sys.stderr, end="" if completed.stderr.endswith("\n") else "\n")
        outputs.append(str(markdown_path))

    print(
        f"[figma-design] Complete. Done ({fetch_scope}). {component_count} components, {style_count} styles, "
        f"{len(result['frames'])} frames"
        + (f", {icon_count} icons" if icon_count else "")
        + (f", {image_count} images" if image_count else "")
        + f"\nOutput: {output_path}"
        + (f"\nMarkdown: {output_path.with_suffix('.md')}" if args.with_spec_md else ""),
        file=sys.stderr,
        flush=True,
    )
    return outputs


if __name__ == "__main__":
    main()
