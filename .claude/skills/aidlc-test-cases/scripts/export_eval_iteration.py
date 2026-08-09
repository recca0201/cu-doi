#!/usr/bin/env python3
"""Batch-export AIDLC test-case Markdown files inside an eval iteration.

This scans an iteration directory for `outputs/test-cases.md` files and derives
CSV/XLSX exports next to each Markdown artifact.

Usage:
    python3 export_eval_iteration.py <iteration_dir>
    python3 export_eval_iteration.py <iteration_dir> --profile xray --with-skill-only
"""

from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path


def load_export_module(script_path: Path):
    spec = importlib.util.spec_from_file_location("aidlc_export_test_cases", script_path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Batch-export AIDLC eval outputs to CSV/XLSX")
    parser.add_argument("iteration_dir", help="Path to the eval iteration directory")
    parser.add_argument(
        "--profile",
        choices=["standard", "xray"],
        default="standard",
        help="CSV export profile to use for generated spreadsheet artifacts.",
    )
    parser.add_argument(
        "--with-skill-only",
        action="store_true",
        help="Only export artifacts under with_skill/outputs.",
    )
    return parser.parse_args()


def iter_markdown_files(iteration_dir: Path, with_skill_only: bool):
    for md_path in iteration_dir.rglob("test-cases.md"):
        text_path = md_path.as_posix()
        if "/outputs/" not in text_path:
            continue
        if with_skill_only and "/with_skill/" not in text_path:
            continue
        yield md_path


def main() -> int:
    args = parse_args()
    iteration_dir = Path(args.iteration_dir)
    if not iteration_dir.exists():
        print(f"Error: iteration directory not found: {iteration_dir}", file=sys.stderr)
        return 1

    script_path = Path(__file__).with_name("export_test_cases.py")
    exporter = load_export_module(script_path)

    markdown_files = list(iter_markdown_files(iteration_dir, args.with_skill_only))
    if not markdown_files:
        print("No test-cases.md files found in iteration directory", file=sys.stderr)
        return 1

    exported = 0
    for md_path in markdown_files:
        content = md_path.read_text(encoding="utf-8")
        rows = exporter.AidlcMarkdownParser(content).parse()
        csv_path = md_path.with_suffix(".csv") if args.profile == "standard" else md_path.with_suffix(".xray.csv")
        xlsx_path = md_path.with_suffix(".xlsx")
        exporter.export_csv_with_profile(rows, csv_path, profile=args.profile)
        exporter.export_xlsx(rows, xlsx_path)
        print(f"Exported: {md_path} -> {csv_path.name}, {xlsx_path.name}")
        exported += 1

    print(f"Processed {exported} Markdown test-case artifacts in {iteration_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())