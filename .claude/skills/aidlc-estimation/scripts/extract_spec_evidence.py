#!/usr/bin/env python3
"""
Extract a reusable evidence pack from AIDLC spec artifacts.

The output intentionally contains source references and dimension signals, not
BCP scores. Use it to give multiple estimation runs the same factual baseline
without hard-coding business complexity decisions into a script.
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime
from pathlib import Path
from typing import Any


ARTIFACT_FILES = ("requirements.md", "design.md", "tasks.md")
REQUIREMENT_RE = re.compile(r"^\s*(\d+(?:\.\d+)+[a-z]?|REQ-\d+|AC-\d+)\s+(WHEN|IF|WHILE|THEN)\b", re.IGNORECASE)
USER_STORY_RE = re.compile(r"\bUS-\d+\b|As an? ([^,]+),", re.IGNORECASE)
HEADING_RE = re.compile(r"^(#{1,6})\s+(.+)$")
BACKTICK_RE = re.compile(r"`([^`]+)`")
BOLD_LABEL_RE = re.compile(r"-\s+\*\*([^*]+)\*\*:")

DIMENSION_TERMS = {
    "Business Rules": (
        "shall",
        "when",
        "if",
        "while",
        "validate",
        "reject",
        "require",
        "workflow",
        "decision",
        "formula",
    ),
    "Interface Elements": (
        "field",
        "input",
        "button",
        "screen",
        "form",
        "table",
        "endpoint",
        "request",
        "response",
        "schema",
        "parameter",
        "upload",
    ),
    "Roles/Permissions": (
        "role",
        "permission",
        "user",
        "admin",
        "developer",
        "operator",
        "nurse",
        "owner",
        "access",
        "iam",
    ),
    "Solution Variabilities": (
        "configuration",
        "config",
        "option",
        "optional",
        "parameter",
        "environment",
        "tenant",
        "mode",
        "variant",
        "if",
    ),
    "Domain Entities": (
        "entity",
        "model",
        "record",
        "resource",
        "audio",
        "transcription",
        "summary",
        "prompt",
        "request",
        "response",
    ),
    "New Domain Entities": (
        "new",
        "create",
        "add",
        "define",
        "store",
        "persist",
        "table",
        "model",
        "schema",
    ),
    "Boundaries": (
        "api",
        "service",
        "external",
        "http",
        "https",
        "database",
        "queue",
        "device",
        "aws",
        "openai",
        "storage",
    ),
    "Background Processes": (
        "background",
        "scheduled",
        "async",
        "worker",
        "batch",
        "pipeline",
        "retry",
        "parallel",
        "trigger",
        "automated",
    ),
    "Notifications": (
        "notification",
        "notify",
        "email",
        "sms",
        "alert",
    ),
    "Audits": (
        "audit",
        "history",
        "trace",
        "traceability",
        "log",
        "actor",
        "timestamp",
        "before",
        "after",
    ),
}


def _artifact_dirs(path: Path) -> list[Path]:
    if path.is_file():
        return [path.parent]
    if any((path / name).exists() for name in ARTIFACT_FILES):
        return [path]
    return sorted(child for child in path.iterdir() if child.is_dir() and any((child / name).exists() for name in ARTIFACT_FILES))


def _line_ref(file_path: Path, base_dir: Path, line_no: int) -> str:
    try:
        rel = file_path.relative_to(base_dir)
    except ValueError:
        rel = file_path
    return f"{rel}:{line_no}"


def _append_signal(bucket: dict[str, list[dict[str, str]]], dimension: str, ref: str, text: str) -> None:
    entries = bucket.setdefault(dimension, [])
    if len(entries) >= 20:
        return
    normalized = " ".join(text.strip().split())
    if normalized:
        entries.append({"ref": ref, "text": normalized[:220]})


def _extract_from_file(file_path: Path, artifact_dir: Path) -> dict[str, Any]:
    lines = file_path.read_text(encoding="utf-8").splitlines()
    headings: list[dict[str, str]] = []
    requirement_ids: list[dict[str, str]] = []
    user_roles: list[dict[str, str]] = []
    named_items: list[dict[str, str]] = []
    dimension_signals: dict[str, list[dict[str, str]]] = {}

    for idx, line in enumerate(lines, start=1):
        ref = _line_ref(file_path, artifact_dir, idx)
        heading = HEADING_RE.match(line)
        if heading:
            headings.append({"ref": ref, "level": str(len(heading.group(1))), "text": heading.group(2).strip()})

        requirement = REQUIREMENT_RE.match(line)
        if requirement:
            requirement_ids.append({"ref": ref, "id": requirement.group(1), "trigger": requirement.group(2).upper()})

        story = USER_STORY_RE.search(line)
        if story:
            role = story.group(1) or story.group(0)
            user_roles.append({"ref": ref, "role": role.strip()})

        for token in BACKTICK_RE.findall(line):
            if token.strip():
                named_items.append({"ref": ref, "name": token.strip(), "source": "backtick"})
        for label in BOLD_LABEL_RE.findall(line):
            named_items.append({"ref": ref, "name": label.strip(), "source": "bold-label"})

        lowered = line.lower()
        for dimension, terms in DIMENSION_TERMS.items():
            if any(term in lowered for term in terms):
                _append_signal(dimension_signals, dimension, ref, line)

    return {
        "file": file_path.name,
        "line_count": len(lines),
        "headings": headings,
        "requirement_ids": requirement_ids,
        "user_roles": user_roles,
        "named_items": named_items[:80],
        "dimension_signals": dimension_signals,
    }


def extract_artifact(artifact_dir: Path) -> dict[str, Any]:
    files = [artifact_dir / name for name in ARTIFACT_FILES if (artifact_dir / name).exists()]
    extracted = [_extract_from_file(file_path, artifact_dir) for file_path in files]

    warnings: list[str] = []
    if not (artifact_dir / "requirements.md").exists():
        warnings.append("requirements.md missing")
    if not (artifact_dir / "design.md").exists():
        warnings.append("design.md missing; estimate should mark design-dependent dimensions lower confidence")
    if not (artifact_dir / "tasks.md").exists():
        warnings.append("tasks.md missing; remaining-work and implementation-status evidence unavailable")

    dimension_signal_counts: dict[str, int] = {dimension: 0 for dimension in DIMENSION_TERMS}
    for file_data in extracted:
        for dimension, entries in file_data["dimension_signals"].items():
            dimension_signal_counts[dimension] += len(entries)

    return {
        "artifact_name": artifact_dir.name,
        "artifact_path": str(artifact_dir),
        "files_present": [file_path.name for file_path in files],
        "warnings": warnings,
        "dimension_signal_counts": dimension_signal_counts,
        "files": extracted,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract evidence packs from AIDLC spec artifacts.")
    parser.add_argument("path", type=Path, help="Spec directory, specs folder, or a file inside a spec directory")
    parser.add_argument("--output", type=Path, help="Output JSON file. Defaults to stdout.")
    args = parser.parse_args()

    input_path = args.path.resolve()
    artifacts = [extract_artifact(path) for path in _artifact_dirs(input_path)]
    report = {
        "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "source": str(input_path),
        "artifact_count": len(artifacts),
        "artifacts": artifacts,
    }

    text = json.dumps(report, indent=2)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    else:
        print(text)


if __name__ == "__main__":
    main()
