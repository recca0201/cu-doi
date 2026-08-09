#!/usr/bin/env python3
"""
Compare three or more independent BCP estimate outputs for numerical drift.

Inputs are estimate JSON files accepted by generate_bcp_report.py, or
directories containing such JSON files. The script validates each estimate,
groups them by artifact name, then computes deviation for total BCP and every
dimension. It does not generate estimates.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path
from statistics import mean
from typing import Any

from generate_bcp_report import calculate_total_bcp, validate_estimation


def _json_files(path: Path, pattern: str) -> list[Path]:
    if path.is_file():
        return [path]
    return sorted(file_path for file_path in path.rglob(pattern) if file_path.is_file())


def _load_estimate(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    valid, errors = validate_estimation(data)
    if not valid:
        joined = "; ".join(errors)
        raise ValueError(f"{path}: invalid BCP estimate: {joined}")
    return data


def _deviation(values: list[float]) -> float:
    avg = mean(values)
    if avg == 0:
        return 0.0 if max(values) == min(values) else 100.0
    return ((max(values) - min(values)) / avg) * 100


def _collect_runs(paths: list[Path], pattern: str) -> list[dict[str, dict[str, Any]]]:
    runs: list[dict[str, dict[str, Any]]] = []
    for run_no, path in enumerate(paths, start=1):
        files = _json_files(path, pattern)
        if not files:
            raise ValueError(f"Run {run_no} has no JSON estimate files: {path}")
        artifacts: dict[str, dict[str, Any]] = {}
        for file_path in files:
            estimate = _load_estimate(file_path)
            name = str(estimate.get("artifact_name", file_path.stem))
            if name in artifacts:
                raise ValueError(f"Run {run_no} has duplicate artifact_name '{name}'")
            artifacts[name] = {"path": str(file_path), "estimate": estimate}
        runs.append(artifacts)
    return runs


def _compare(runs: list[dict[str, dict[str, Any]]]) -> dict[str, Any]:
    artifact_sets = [set(run.keys()) for run in runs]
    common = set.intersection(*artifact_sets)
    all_artifacts = set.union(*artifact_sets)
    if common != all_artifacts:
        missing = {
            f"run_{idx + 1}": sorted(all_artifacts - artifact_sets[idx])
            for idx in range(len(runs))
            if all_artifacts - artifact_sets[idx]
        }
        raise ValueError(f"Runs do not contain the same artifact names: {missing}")

    artifact_results = []
    max_deviation = 0.0
    dimensions_with_drift = []

    for artifact_name in sorted(common):
        totals = [
            float(calculate_total_bcp(run[artifact_name]["estimate"]["dimensions"]))
            for run in runs
        ]
        total_deviation = _deviation(totals)
        max_deviation = max(max_deviation, total_deviation)

        dimension_names = sorted(
            {
                dim_name
                for run in runs
                for dim_name in run[artifact_name]["estimate"]["dimensions"].keys()
            }
        )
        dimension_results = {}
        for dim_name in dimension_names:
            values = [
                float(run[artifact_name]["estimate"]["dimensions"].get(dim_name, {}).get("points", 0))
                for run in runs
            ]
            deviation = _deviation(values)
            max_deviation = max(max_deviation, deviation)
            dimension_results[dim_name] = {
                "points": values,
                "deviation_percent": round(deviation, 4),
            }
            if deviation > 0:
                dimensions_with_drift.append(
                    {
                        "artifact_name": artifact_name,
                        "dimension": dim_name,
                        "points": values,
                        "deviation_percent": round(deviation, 4),
                    }
                )

        artifact_results.append(
            {
                "artifact_name": artifact_name,
                "totals": totals,
                "total_deviation_percent": round(total_deviation, 4),
                "dimensions": dimension_results,
                "input_paths": [run[artifact_name]["path"] for run in runs],
            }
        )

    return {
        "artifact_results": artifact_results,
        "max_numerical_deviation_percent": round(max_deviation, 4),
        "dimensions_with_drift": dimensions_with_drift,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Compare independent BCP estimate JSON outputs.")
    parser.add_argument("runs", nargs="+", type=Path, help="Estimate JSON files or run directories")
    parser.add_argument("--threshold", type=float, default=20.0, help="Maximum allowed deviation percentage")
    parser.add_argument("--pattern", default="*.json", help="JSON filename glob when a run input is a directory")
    parser.add_argument("--output", type=Path, help="Optional output JSON report path")
    args = parser.parse_args()

    if len(args.runs) < 3:
        raise SystemExit("Provide at least 3 estimate files or run directories for the stability gate")

    try:
        runs = _collect_runs(args.runs, args.pattern)
        measurement = _compare(runs)
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        raise SystemExit(1)

    passed = measurement["max_numerical_deviation_percent"] < args.threshold
    report = {
        "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "run_count": len(args.runs),
        "threshold_percent": args.threshold,
        "passed": passed,
        **measurement,
    }

    text = json.dumps(report, indent=2)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    print(text)
    if not passed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
