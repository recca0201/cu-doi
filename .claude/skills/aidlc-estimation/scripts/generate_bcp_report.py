#!/usr/bin/env python3
"""
BCP Estimation Report Generator

This script generates and validates BCP estimation reports for AIDLC artifacts.
It ensures all mandatory dimensions are covered and formats the output consistently.
"""

import json
import math
import sys
import argparse
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

# BCP Dimension Definitions
DIMENSIONS = {
    "Business Rules": {
        "mandatory": False,
        "has_qty": False,
        "allowed": {"XS", "S", "M", "XL", "N/A"},
    },
    "Interface Elements": {
        "mandatory": False,
        "has_qty": True,
        "allowed": {"S", "M", "L", "XL", "N/A"},
        "occurrence_rule": "per_5",
    },
    "Roles/Permissions": {"mandatory": True, "has_qty": False, "allowed": {"XS", "S", "M"}},
    "Solution Variabilities": {
        "mandatory": True,
        "has_qty": False,
        "allowed": {"XS", "M", "XL"},
    },
    "Domain Entities": {
        "mandatory": True,
        "has_qty": True,
        "allowed": {"XS", "S", "M", "L", "XL"},
        "complexity_rule": "domain_entities",
    },
    "New Domain Entities": {
        "mandatory": False,
        "has_qty": True,
        "allowed": {"S", "L", "N/A"},
        "occurrence_rule": "per_3",
    },
    "Boundaries": {"mandatory": True, "has_qty": False, "allowed": {"XS", "S", "M", "XL"}},
    "Background Processes": {
        "mandatory": False,
        "has_qty": False,
        "allowed": {"S", "M", "L", "XL", "N/A"},
    },
    "Notifications": {"mandatory": False, "has_qty": False, "allowed": {"XS", "N/A"}},
    "Audits": {"mandatory": False, "has_qty": False, "allowed": {"XS", "N/A"}},
}

SIZE_POINTS = {
    "XS": 1,
    "S": 2,
    "M": 3,
    "L": 5,
    "XL": 8,
    "N/A": 0,
}

EVIDENCE_MARKERS = (
    "AC-",
    "REQ-",
    "US-",
    "requirements.md",
    "design.md",
    "tasks.md",
    "src/",
    ".ts",
    ".tsx",
    ".js",
    ".py",
    "foundation/",
    "codebase",
    "section",
)


def _as_number(value, field_name: str, dim_name: str, errors: List[str]) -> Optional[float]:
    """Convert numeric JSON fields while preserving clear validation errors."""
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        errors.append(f"{dim_name}: '{field_name}' must be numeric")
        return None
    return float(value)


def _expected_domain_complexity(qty: float) -> str:
    """Return calculator-derived Domain Entities complexity from quantity."""
    if qty > 7:
        return "XL"
    if qty >= 6:
        return "L"
    if qty >= 4:
        return "M"
    if qty >= 2:
        return "S"
    return "XS"


def _has_evidence(dim_data: Dict) -> bool:
    """Check for concrete evidence for validation and report output."""
    evidence = dim_data.get("evidence")
    if isinstance(evidence, list) and any(str(item).strip() for item in evidence):
        return True

    rationale = str(dim_data.get("rationale", ""))
    rationale_lower = rationale.lower()
    return any(marker.lower() in rationale_lower for marker in EVIDENCE_MARKERS)


def validate_estimation(estimation: Dict) -> tuple[bool, List[str]]:
    """
    Validate BCP estimation data.

    Returns:
        tuple: (is_valid, list of error messages)
    """
    errors = []

    # Check required fields
    if "artifact_name" not in estimation:
        errors.append("Missing 'artifact_name' field")
    if "artifact_type" not in estimation:
        errors.append("Missing 'artifact_type' field")
    if "dimensions" not in estimation:
        errors.append("Missing 'dimensions' field")
        return False, errors

    dimensions = estimation["dimensions"]

    # Check mandatory dimensions
    for dim_name, dim_info in DIMENSIONS.items():
        if dim_info["mandatory"]:
            if dim_name not in dimensions:
                errors.append(f"Missing mandatory dimension: {dim_name}")
            elif dimensions[dim_name].get("complexity") == "N/A":
                errors.append(f"Mandatory dimension '{dim_name}' cannot be N/A")

    # Validate each dimension
    for dim_name, dim_data in dimensions.items():
        if dim_name not in DIMENSIONS:
            errors.append(f"Unknown dimension: {dim_name}")
            continue

        # Check required fields
        if "occurrences" not in dim_data:
            errors.append(f"{dim_name}: Missing 'occurrences' field")
        if "complexity" not in dim_data:
            errors.append(f"{dim_name}: Missing 'complexity' field")
        if "points" not in dim_data:
            errors.append(f"{dim_name}: Missing 'points' field")
        if "confidence" not in dim_data:
            errors.append(f"{dim_name}: Missing 'confidence' field")
        if "rationale" not in dim_data:
            errors.append(f"{dim_name}: Missing 'rationale' field")

        # Validate complexity size
        complexity = dim_data.get("complexity")
        if complexity and complexity not in SIZE_POINTS:
            errors.append(f"{dim_name}: Invalid complexity '{complexity}'")
        elif complexity and complexity not in DIMENSIONS[dim_name]["allowed"]:
            allowed = ", ".join(sorted(DIMENSIONS[dim_name]["allowed"]))
            errors.append(
                f"{dim_name}: Complexity '{complexity}' is not allowed by "
                f"calculator rules. Allowed: {allowed}"
            )

        # Validate confidence level
        confidence = dim_data.get("confidence")
        if confidence and confidence not in ["High", "Medium", "Low"]:
            errors.append(f"{dim_name}: Invalid confidence '{confidence}'")

        rationale = str(dim_data.get("rationale", "")).strip()
        if rationale and not _has_evidence(dim_data):
            errors.append(
                f"{dim_name}: Rationale must cite concrete evidence "
                "(AC/REQ/US ID, spec file, source file, or evidence list)"
            )

        occurrences = (
            _as_number(dim_data.get("occurrences"), "occurrences", dim_name, errors)
            if "occurrences" in dim_data
            else None
        )
        points = (
            _as_number(dim_data.get("points"), "points", dim_name, errors)
            if "points" in dim_data
            else None
        )
        qty = (
            _as_number(dim_data.get("qty"), "qty", dim_name, errors)
            if DIMENSIONS[dim_name]["has_qty"] and "qty" in dim_data
            else None
        )

        if complexity in SIZE_POINTS and points is not None and occurrences is not None:
            expected_points = occurrences * SIZE_POINTS[complexity]
            if not math.isclose(points, expected_points):
                errors.append(
                    f"{dim_name}: Points must equal occurrences × size "
                    f"points ({expected_points:g})"
                )

        if complexity == "N/A":
            if points is not None and points != 0:
                errors.append(f"{dim_name}: N/A complexity must have 0 points")
            continue

        if occurrences is not None and occurrences <= 0:
            errors.append(f"{dim_name}: Non-N/A complexity requires occurrences > 0")

        if DIMENSIONS[dim_name].get("occurrence_rule") == "per_5":
            if qty is None:
                errors.append(f"{dim_name}: Missing 'qty' field for calculator occurrence rule")
            elif qty <= 0:
                errors.append(f"{dim_name}: Non-N/A complexity requires qty > 0")
            elif occurrences is not None and occurrences != math.ceil(qty / 5):
                errors.append(f"{dim_name}: Occurrences must be ROUNDUP(qty / 5, 0)")

        if DIMENSIONS[dim_name].get("occurrence_rule") == "per_3":
            if qty is None:
                errors.append(f"{dim_name}: Missing 'qty' field for calculator occurrence rule")
            elif qty <= 0:
                errors.append(f"{dim_name}: Non-N/A complexity requires qty > 0")
            elif occurrences is not None and occurrences != math.ceil(qty / 3):
                errors.append(f"{dim_name}: Occurrences must be ROUNDUP(qty / 3, 0)")

        if DIMENSIONS[dim_name].get("complexity_rule") == "domain_entities":
            if qty is None:
                errors.append(f"{dim_name}: Missing 'qty' field for calculator-derived complexity")
            elif qty <= 0:
                errors.append(f"{dim_name}: Mandatory dimension requires qty > 0")
            else:
                expected_complexity = _expected_domain_complexity(qty)
                if complexity != expected_complexity:
                    errors.append(
                        f"{dim_name}: Complexity must be "
                        f"{expected_complexity} for qty {qty:g}"
                    )

    return len(errors) == 0, errors


def calculate_total_bcp(dimensions: Dict) -> int:
    """Calculate total BCP from all dimensions."""
    total = 0
    for dim_data in dimensions.values():
        points = dim_data.get("points", 0)
        if isinstance(points, (int, float)):
            total += points
    return int(total)


def format_markdown_report(estimation: Dict) -> str:
    """
    Generate markdown BCP estimation report.

    Args:
        estimation: Dictionary containing estimation data

    Returns:
        Formatted markdown string
    """
    artifact_name = estimation.get("artifact_name", "Unknown")
    artifact_type = estimation.get("artifact_type", "Unknown")
    estimated_by = estimation.get("estimated_by", "AI + Human Review")
    estimated_at = estimation.get("estimated_at", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    notes = estimation.get("notes", "")
    dimensions = estimation.get("dimensions", {})

    total_bcp = calculate_total_bcp(dimensions)

    # Build markdown report
    md = f"""# BCP Estimation Report

## Artifact Information
- **Name:** {artifact_name}
- **Type:** {artifact_type}
- **Estimated By:** {estimated_by}
- **Date:** {estimated_at}
- **Total BCP:** **{total_bcp} points**

## Complexity Breakdown

| Dimension | Occ | Qty | Complexity | Points | Confidence | Evidence | Rationale |
|-----------|-----|-----|------------|--------|------------|----------|-----------|
"""

    # Add each dimension row
    for dim_name in DIMENSIONS.keys():
        if dim_name in dimensions:
            dim = dimensions[dim_name]
            occ = dim.get("occurrences", "-")
            qty = dim.get("qty", "-") if DIMENSIONS[dim_name]["has_qty"] else "-"
            complexity = dim.get("complexity", "N/A")
            points = dim.get("points", 0)
            confidence = dim.get("confidence", "Unknown")
            evidence = dim.get("evidence", "-")
            if isinstance(evidence, list):
                evidence = ", ".join(str(item).strip() for item in evidence if str(item).strip())
            evidence = str(evidence or "-").replace("\n", " ")
            rationale = dim.get("rationale", "").replace("\n", " ")

            md += f"| {dim_name} | {occ} | {qty} | {complexity} | {points} | {confidence} | {evidence} | {rationale} |\n"
        else:
            # Dimension not assessed
            md += f"| {dim_name} | - | - | N/A | 0 | - | - | Not assessed |\n"

    md += f"\n**Total:** {total_bcp} points\n\n"

    # Add complexity category
    if total_bcp <= 10:
        category = "Trivial"
    elif total_bcp <= 25:
        category = "Simple"
    elif total_bcp <= 50:
        category = "Moderate"
    elif total_bcp <= 100:
        category = "Complex"
    else:
        category = "Very Complex"

    md += f"**Complexity Category:** {category}\n\n"

    # Add notes if present
    if notes:
        md += f"## Notes\n\n{notes}\n\n"

    # Add review summary
    high_conf = sum(1 for d in dimensions.values() if d.get("confidence") == "High")
    med_conf = sum(1 for d in dimensions.values() if d.get("confidence") == "Medium")
    low_conf = sum(1 for d in dimensions.values() if d.get("confidence") == "Low")

    md += f"""## Confidence Summary

- **High Confidence:** {high_conf} dimensions
- **Medium Confidence:** {med_conf} dimensions
- **Low Confidence:** {low_conf} dimensions

"""

    if low_conf > 0:
        md += "⚠️ **Review Recommended:** Some dimensions have low confidence. Consider refining the assessment.\n\n"

    # Add metadata footer
    md += "---\n\n"
    md += "_Business Complexity Points (BCP) estimation report._\n"

    return md


def resolve_docs_root(start: Optional[Path] = None) -> Path:
    """
    Resolve the AI-DLC docs root using the same precedence as the AI-DLC skills:

    1. ``.mtv-aidlc/extension-config.json`` ``aidlcDocsPath`` (searched upward)
    2. ``aidlc-docs`` (fallback)

    Honoring the configured root prevents silently writing reports into a
    repo-level ``aidlc-docs/`` when the project keeps its docs elsewhere
    (e.g. ``apps/<app>/aidlc-docs``). Callers that already know the root should
    pass an explicit ``output_path`` to ``save_report`` instead.
    """
    current = (start or Path.cwd()).resolve()
    for directory in (current, *current.parents):
        config_path = directory / ".mtv-aidlc" / "extension-config.json"
        if config_path.is_file():
            try:
                configured = json.loads(config_path.read_text(encoding="utf-8")).get("aidlcDocsPath")
            except (json.JSONDecodeError, OSError):
                configured = None
            if configured:
                configured_path = Path(configured)
                return configured_path if configured_path.is_absolute() else directory / configured_path
            break
    return Path("aidlc-docs")


def save_report(estimation: Dict, output_path: Optional[str] = None) -> str:
    """
    Save BCP estimation report to file.

    Args:
        estimation: Estimation data dictionary
        output_path: Optional custom output path

    Returns:
        Path to saved file
    """
    if output_path:
        file_path = Path(output_path)
    else:
        # Default: save under the resolved {docs-root}/estimation/
        artifact_name = estimation.get("artifact_name", "unknown").replace(" ", "-").lower()
        artifact_type = estimation.get("artifact_type", "unknown").lower()
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        filename = f"bcp-{artifact_type}-{artifact_name}-{timestamp}.md"

        # Create estimation directory if it doesn't exist
        est_dir = resolve_docs_root() / "estimation"
        est_dir.mkdir(parents=True, exist_ok=True)
        file_path = est_dir / filename

    # Generate and save markdown
    md_content = format_markdown_report(estimation)
    file_path.write_text(md_content, encoding="utf-8")

    return str(file_path)


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Validate and generate a BCP estimation report.")
    parser.add_argument("estimation_json_file", help="Path to the estimation JSON file")
    parser.add_argument("output_path", nargs="?", help="Optional markdown output path")
    args = parser.parse_args()

    json_file = args.estimation_json_file
    output_path = args.output_path

    # Load estimation data
    try:
        with open(json_file, "r", encoding="utf-8") as f:
            estimation = json.load(f)
    except FileNotFoundError:
        print(f"Error: File not found: {json_file}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON: {e}")
        sys.exit(1)

    # Validate estimation
    is_valid, errors = validate_estimation(estimation)
    if not is_valid:
        print("❌ Validation Failed:\n")
        for error in errors:
            print(f"  - {error}")
        sys.exit(1)

    # Generate report
    try:
        saved_path = save_report(estimation, output_path)
        print(f"✅ BCP Report generated successfully!")
        print(f"   Saved to: {saved_path}")

        # Show total BCP
        total = calculate_total_bcp(estimation["dimensions"])
        print(f"\n📊 Total BCP: {total} points")
    except Exception as e:
        print(f"❌ Error generating report: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
