"""Path, slug, and atomic-write helpers (no figmakit dependencies)."""

import json
import os
import re
from pathlib import Path
from typing import Any, Optional


def slugify(text: str) -> str:
    """Convert a string to a lowercase slug safe for directory names."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    text = text.strip("-")
    return text or "figma"


def derive_scope(node_name: Optional[str], file_name: Optional[str], file_key: str) -> str:
    """Return a short slug to use as the output scope folder name."""
    if node_name:
        return slugify(node_name)
    if file_name:
        return slugify(file_name)[:40]
    return file_key[:16]


def default_output_path(scope: str) -> Path:
    """Return the default output path: <cwd>/temp/figma_<scope>/figma-spec.json"""
    return Path.cwd() / "temp" / f"figma_{scope}" / "figma-spec.json"


def write_json_atomic(path: Path, obj: Any, pretty: bool) -> None:
    """Serialize then rename into place so a polling agent never reads a half-written figma-spec.json."""
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(obj, indent=2 if pretty else None, ensure_ascii=False)
    tmp = path.with_name(path.name + f".tmp.{os.getpid()}")
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


def slugify_name(name: str) -> str:
    return slugify(name)
