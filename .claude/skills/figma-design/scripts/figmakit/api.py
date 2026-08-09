"""Figma REST transport: throttling, rate-limit handling, and raw fetch helpers."""

import json
import sys
import threading
import time
import urllib.request
import urllib.error
from pathlib import Path

from figmakit import BASE_URL, NETWORK_TIMEOUT_SECONDS, MAX_RETRY_AFTER_WAIT_SECONDS
from typing import Optional


# ── Client-side pacing (shared across parallel fetch threads) ──
_throttle_lock = threading.Lock()
_last_request_at = [0.0]
_min_request_interval = [0.0]  # seconds between requests; 0 = unthrottled


def set_max_rpm(rpm: Optional[float]) -> None:
    _min_request_interval[0] = 60.0 / rpm if rpm and rpm > 0 else 0.0


def _throttle() -> None:
    if _min_request_interval[0] <= 0:
        return
    with _throttle_lock:
        wait = _min_request_interval[0] - (time.time() - _last_request_at[0])
        if wait > 0:
            time.sleep(wait)
        _last_request_at[0] = time.time()


class FigmaHTTPError(Exception):
    def __init__(self, code: int, body: str):
        self.code = code
        self.body = body
        super().__init__(f"HTTP {code}: {body}")


def figma_get(token: str, path: str, *, suppress_request_too_large: bool = False,
              max_429_retries: int = 4) -> dict:
    url = f"{BASE_URL}{path}"
    for attempt in range(max_429_retries + 1):
        _throttle()
        req = urllib.request.Request(url, headers={"X-Figma-Token": token})
        try:
            with urllib.request.urlopen(req, timeout=NETWORK_TIMEOUT_SECONDS) as resp:
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            if e.code == 429:
                _handle_rate_limit(e, attempt, max_429_retries)
                continue
            body = e.read().decode()
            if not (suppress_request_too_large and e.code == 400):
                print(f"HTTP {e.code} from Figma API: {body}", file=sys.stderr)
            if e.code == 403:
                print(
                    "Check your PAT: it may lack the required scope (file_content:read / "
                    "file:read), or your Figma seat is View/Collab (only ~6 file/node/image "
                    "requests per MONTH). Extraction needs a Dev or Full seat token. "
                    "Note: personal access tokens now expire after 90 days.",
                    file=sys.stderr,
                )
                sys.exit(1)
            elif e.code == 404:
                print("File not found. Verify the file key is correct.", file=sys.stderr)
                sys.exit(1)
            raise FigmaHTTPError(e.code, body)
    # Exhausted 429 retries without success or a hard abort inside _handle_rate_limit
    raise FigmaHTTPError(429, "Rate limited: exhausted retries")


def _handle_rate_limit(e: "urllib.error.HTTPError", attempt: int, max_retries: int) -> None:
    """Wait out a 429 honoring Retry-After, or abort with an actionable message when the
    wait is a multi-hour/day quota (View/Collab seats get ~6 Tier-1 calls per month)."""
    retry_after = 0
    try:
        retry_after = int(e.headers.get("Retry-After", "0") or 0)
    except (TypeError, ValueError):
        retry_after = 0
    rl_type = e.headers.get("X-Figma-Rate-Limit-Type") or "unknown"
    plan = e.headers.get("X-Figma-Plan-Tier") or "unknown"
    wait = retry_after if retry_after > 0 else min(2 ** attempt * 5, MAX_RETRY_AFTER_WAIT_SECONDS)

    if retry_after > MAX_RETRY_AFTER_WAIT_SECONDS or attempt >= max_retries:
        print(
            f"Figma rate limit hit (429, type={rl_type}, plan={plan}). "
            f"Retry-After={retry_after}s exceeds what this run will wait "
            f"({MAX_RETRY_AFTER_WAIT_SECONDS}s cap). "
            + (
                "type=low means a View/Collab seat (≈6 Tier-1 requests/month) — use a "
                "Dev/Full seat PAT."
                if rl_type == "low"
                else "The per-minute quota is exhausted; retry later or slow down with --max-rpm."
            ),
            file=sys.stderr,
        )
        sys.exit(1)

    print(
        f"[figma-design] Rate limited (429, type={rl_type}, plan={plan}); "
        f"waiting {wait}s then retrying (attempt {attempt + 1}/{max_retries})...",
        file=sys.stderr,
        flush=True,
    )
    time.sleep(wait)


def fetch_svg_content(token: str, file_key: str, node_ids: list) -> dict:
    """Fetch SVG export URLs for node IDs, then download SVG content. Returns {node_id: svg_str}."""
    ids_param = ",".join(node_ids)
    data = figma_get(token, f"/images/{file_key}?ids={ids_param}&format=svg&svg_include_id=false")
    images = data.get("images", {})

    results = {}
    for node_id, url in images.items():
        if not url:
            print(f"  Warning: no SVG URL for node {node_id}", file=sys.stderr)
            continue
        try:
            with urllib.request.urlopen(url, timeout=NETWORK_TIMEOUT_SECONDS) as resp:
                results[node_id] = resp.read().decode("utf-8")
        except Exception as e:
            print(f"  Warning: failed to download SVG for {node_id}: {e}", file=sys.stderr)

    return results


def fetch_image_urls(token: str, file_key: str, node_ids: list, fmt: str = "png", scale: int = 2) -> dict:
    """Fetch image export URLs. Returns {node_id: url}."""
    ids_param = ",".join(node_ids)
    data = figma_get(token, f"/images/{file_key}?ids={ids_param}&format={fmt}&scale={scale}")
    return data.get("images", {})


def download_file(url: str, dest: Path) -> bool:
    try:
        with urllib.request.urlopen(url, timeout=NETWORK_TIMEOUT_SECONDS) as resp:
            dest.write_bytes(resp.read())
        return True
    except Exception as e:
        print(f"  Warning: failed to download {url}: {e}", file=sys.stderr)
        return False
