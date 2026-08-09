#!/usr/bin/env python3
"""Shared artifact metadata rendering helpers for AIDLC producers."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from pathlib import Path
import re


ALLOWED_ARTIFACT_TYPES = {
    "requirements",
    "design",
    "tasks",
    "story-artifact",
    "quick-spec",
    "unit-decomposition",
    "roadmap",
    "test-cases",
    "decision-record",
    "memory",
}

ALLOWED_PHASES = {"foundation", "inception", "construction", "operations"}
ALLOWED_STATUSES = {"draft", "review", "approved", "implemented", "archived"}


@dataclass
class ArtifactMetadata:
    """Represents metadata fields used to render artifact frontmatter."""

    artifact_type: str
    phase: str
    status: str
    created: str
    updated: str
    intent: str | None = None
    unit: str | None = None
    lifecycle: str | None = None
    artifact_id: str | None = None
    estimation_bcp: int | None = None
    estimation_report: str | None = None
    source_artifacts: list[str] | None = None
    related_artifacts: list[str] | None = None


def _is_blank(value: str | None) -> bool:
    return value is None or value.strip() == ""


def _validate_required(metadata: ArtifactMetadata) -> None:
    required = {
        "artifact_type": metadata.artifact_type,
        "phase": metadata.phase,
        "status": metadata.status,
        "created": metadata.created,
        "updated": metadata.updated,
    }
    for name, value in required.items():
        if _is_blank(value):
            raise ValueError(f"Missing required field: {name}")

    if metadata.artifact_type not in ALLOWED_ARTIFACT_TYPES:
        raise ValueError(f"Invalid artifact_type: {metadata.artifact_type}")
    if metadata.phase not in ALLOWED_PHASES:
        raise ValueError(f"Invalid phase: {metadata.phase}")
    if metadata.status not in ALLOWED_STATUSES:
        raise ValueError(f"Invalid status: {metadata.status}")


def _validate_estimation(metadata: ArtifactMetadata) -> None:
    bcp = metadata.estimation_bcp
    if bcp is None:
        return
    if not isinstance(bcp, int) or isinstance(bcp, bool) or bcp < 0:
        raise ValueError(f"Invalid estimation_bcp: {bcp!r}")


def _normalize_date(raw_value: str, field_name: str) -> str:
    """Normalize YYYY-M-D and ISO-like values to YYYY-MM-DD."""
    value = raw_value.strip()
    match = re.match(r"^(\d{4})-(\d{1,2})-(\d{1,2})(?:[T\s].*)?$", value)
    if not match:
        raise ValueError(f"Invalid {field_name} date: {raw_value}")

    year = int(match.group(1))
    month = int(match.group(2))
    day = int(match.group(3))

    try:
        normalized = date(year, month, day)
    except ValueError as err:
        raise ValueError(f"Invalid {field_name} date: {raw_value}") from err

    return normalized.isoformat()


def _needs_quotes(value: str) -> bool:
    if value != value.strip():
        return True
    if "\n" in value:
        return True
    if ":" in value or "#" in value:
        return True
    if value.startswith("-"):
        return True
    return False


def _yaml_scalar(value: str) -> str:
    """Render scalars safely for YAML frontmatter."""
    if not _needs_quotes(value):
        return value
    escaped = (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
    )
    return f'"{escaped}"'


def _normalize_source_paths(
    values: list[str] | None,
    workspace_root,
) -> list[str]:
    """Normalize source artifact paths and drop empty values."""
    if not values:
        return []

    normalized: list[str] = []
    root_path = Path(workspace_root).resolve() if workspace_root else None

    for raw_path in values:
        if raw_path is None:
            continue

        candidate = raw_path.strip()
        if not candidate:
            continue
        if "\n" in candidate:
            raise ValueError(
                "Invalid source_artifacts: newline characters are not allowed"
            )

        candidate_path = Path(candidate)
        if root_path and candidate_path.is_absolute():
            resolved_candidate = candidate_path.resolve()
            try:
                candidate = (
                    resolved_candidate.relative_to(root_path).as_posix()
                )
            except ValueError:
                raise ValueError(
                    "Invalid source_artifacts: absolute path is outside "
                    "workspace_root"
                )
        else:
            candidate = candidate.replace("\\", "/")

        normalized.append(candidate)

    return normalized


def render_frontmatter(metadata: ArtifactMetadata, workspace_root=None) -> str:
    """Render metadata into YAML frontmatter with canonical key ordering."""
    _validate_required(metadata)
    _validate_estimation(metadata)

    created = _normalize_date(metadata.created, "created")
    updated = _normalize_date(metadata.updated, "updated")
    source_artifacts = _normalize_source_paths(
        metadata.source_artifacts,
        workspace_root,
    )
    related_artifacts = _normalize_source_paths(
        metadata.related_artifacts,
        None,
    )

    ordered_pairs = [
        ("artifact_type", metadata.artifact_type),
        ("phase", metadata.phase),
        ("status", metadata.status),
        ("created", created),
        ("updated", updated),
        ("intent", metadata.intent),
        ("unit", metadata.unit),
        ("lifecycle", metadata.lifecycle),
        ("artifact_id", metadata.artifact_id),
        ("estimation_bcp", metadata.estimation_bcp),
        ("estimation_report", metadata.estimation_report),
    ]

    lines = ["---"]
    for key, value in ordered_pairs:
        if value is None:
            continue
        if isinstance(value, str) and value.strip() == "":
            continue
        if isinstance(value, str):
            rendered = _yaml_scalar(value)
        else:
            rendered = str(value)
        lines.append(f"{key}: {rendered}")

    if source_artifacts:
        lines.append("source_artifacts:")
        for path in source_artifacts:
            lines.append(f"  - {_yaml_scalar(path)}")
    else:
        lines.append("source_artifacts: []")

    if related_artifacts:
        lines.append("related_artifacts:")
        for artifact in related_artifacts:
            lines.append(f"  - {_yaml_scalar(artifact)}")

    lines.extend(["---", ""])
    return "\n".join(lines) + "\n"
