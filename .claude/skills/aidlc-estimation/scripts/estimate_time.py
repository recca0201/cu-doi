#!/usr/bin/env python3
"""
BCP -> Time estimator.

Converts a finalized BCP total into effort (man-months / person-days) and
calendar duration (working days / weeks) with an Optimistic/Likely/Pessimistic
range, using a team capacity profile (delivery rate, working days, focus
factor, effective parallel FTE).

The three layers are kept separate on purpose:
  Complexity (BCP)  -> what the estimation workflow already produces
  Effort            -> BCP / delivery rate            (person-time)
  Duration          -> Effort / (parallel FTE * focus) (calendar time)

The org default delivery rate is 170 BCP per man-month. That standard is
derived from delivered work, so it already absorbs typical overhead
(meetings, context switching) - which is why focus factor defaults to 1.0.

Single artifact:
    python3 estimate_time.py --bcp 57 --level spec --parallel-fte 2 \
        [--team-size 3] [--rate 170] [--rate-source org-default] \
        [--days-per-month 20] [--days-per-week 5] [--focus 1.0] \
        [--low-confidence-dims 0] [--json-out PATH]

Batch rollup (per-unit values in a JSON file):
    python3 estimate_time.py --units-json units.json [capacity flags] [--json-out PATH]

units.json schema:
    {
      "units": [
        {"name": "unit-1-auth", "bcp": 24, "level": "unit",
         "parallel_fte": 2, "low_confidence_dims": 1}
      ]
    }
Per-unit fields override the CLI capacity flags for that unit.

Markdown for the report's "Time Estimate" section is printed to stdout.
"""

import argparse
import json
import math
import sys
from typing import Dict, List, Optional

ORG_DEFAULT_RATE = 170.0  # BCP per man-month
DEFAULT_DAYS_PER_MONTH = 20
DEFAULT_DAYS_PER_WEEK = 5
DEFAULT_FOCUS = 1.0

VALID_LEVELS = ("story", "unit", "spec")
VALID_RATE_SOURCES = ("org-default", "team-calibrated")

# Range bands reuse the skill's estimation-accuracy table (SKILL.md Step 5).
# Ordered narrow -> wide so "widen one level" is an index increment.
BANDS = [
    {"key": "spec", "low": 0.87, "high": 1.15, "label": "±10-15% (spec-level)"},
    {"key": "unit", "low": 0.75, "high": 1.30, "label": "±20-30% (unit-level)"},
    {"key": "story", "low": 0.65, "high": 1.40, "label": "±30-40% (story-level)"},
    {"key": "wide", "low": 0.60, "high": 1.50, "label": "±40-50% (widened)"},
]
LEVEL_BAND_INDEX = {"spec": 0, "unit": 1, "story": 2}
LOW_CONFIDENCE_WIDEN_THRESHOLD = 3


def _fail(message: str) -> None:
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(1)


def _validate_inputs(
    bcp: float,
    level: str,
    rate: float,
    rate_source: str,
    days_per_month: float,
    days_per_week: float,
    focus: float,
    parallel_fte: float,
    low_confidence_dims: int,
) -> None:
    if bcp <= 0:
        _fail(f"BCP must be > 0, got {bcp:g}")
    if level not in VALID_LEVELS:
        _fail(f"level must be one of {VALID_LEVELS}, got '{level}'")
    if rate <= 0:
        _fail(f"delivery rate must be > 0, got {rate:g}")
    if rate_source not in VALID_RATE_SOURCES:
        _fail(f"rate-source must be one of {VALID_RATE_SOURCES}, got '{rate_source}'")
    if days_per_month <= 0:
        _fail(f"days-per-month must be > 0, got {days_per_month:g}")
    if days_per_week <= 0:
        _fail(f"days-per-week must be > 0, got {days_per_week:g}")
    if not 0 < focus <= 1:
        _fail(f"focus factor must be in (0, 1], got {focus:g}")
    if parallel_fte <= 0:
        _fail(f"parallel-fte must be > 0, got {parallel_fte:g}")
    if low_confidence_dims < 0:
        _fail(f"low-confidence-dims must be >= 0, got {low_confidence_dims}")


def _select_band(level: str, rate_source: str, low_confidence_dims: int) -> Dict:
    """Pick the range band: start at the artifact level, widen for weak inputs."""
    index = LEVEL_BAND_INDEX[level]
    widen_reasons: List[str] = []
    if rate_source == "org-default":
        index += 1
        widen_reasons.append("delivery rate is the org default (no team-calibrated data)")
    if low_confidence_dims >= LOW_CONFIDENCE_WIDEN_THRESHOLD:
        index += 1
        widen_reasons.append(
            f"{low_confidence_dims} BCP dimensions have Low confidence"
        )
    index = min(index, len(BANDS) - 1)
    band = dict(BANDS[index])
    band["widen_reasons"] = widen_reasons
    return band


def estimate_one(
    bcp: float,
    level: str,
    parallel_fte: float,
    team_size: Optional[float] = None,
    rate: float = ORG_DEFAULT_RATE,
    rate_source: str = "org-default",
    days_per_month: float = DEFAULT_DAYS_PER_MONTH,
    days_per_week: float = DEFAULT_DAYS_PER_WEEK,
    focus: float = DEFAULT_FOCUS,
    low_confidence_dims: int = 0,
    name: Optional[str] = None,
) -> Dict:
    """Compute effort, duration, and range for a single artifact."""
    _validate_inputs(
        bcp, level, rate, rate_source, days_per_month, days_per_week,
        focus, parallel_fte, low_confidence_dims,
    )
    if team_size is not None and parallel_fte > team_size:
        _fail(
            f"parallel-fte ({parallel_fte:g}) cannot exceed team size ({team_size:g})"
        )

    effort_mm = bcp / rate
    effort_pd = effort_mm * days_per_month
    duration_wd = effort_pd / (parallel_fte * focus)
    duration_weeks = duration_wd / days_per_week

    band = _select_band(level, rate_source, low_confidence_dims)

    def scaled(multiplier: float) -> Dict:
        return {
            "effort_person_days": round(effort_pd * multiplier, 1),
            "duration_working_days": round(duration_wd * multiplier, 1),
            "duration_weeks": round(duration_weeks * multiplier, 1),
        }

    assumptions = [
        f"Delivery rate {rate:g} BCP/man-month ({rate_source})",
        f"1 man-month = {days_per_month:g} working days; "
        f"{days_per_week:g} working days/week",
        f"Focus factor {focus:g}"
        + (
            " (rate already includes typical overhead)"
            if focus == 1.0
            else " (team-specific adjustment on top of the delivery rate)"
        ),
        f"Effective parallel FTE: {parallel_fte:g}"
        + (f" of team size {team_size:g}" if team_size is not None else ""),
    ]
    assumptions += [f"Range widened: {reason}" for reason in band["widen_reasons"]]

    return {
        "name": name,
        "inputs": {
            "bcp": bcp,
            "level": level,
            "rate_bcp_per_mm": rate,
            "rate_source": rate_source,
            "days_per_month": days_per_month,
            "days_per_week": days_per_week,
            "focus_factor": focus,
            "parallel_fte": parallel_fte,
            "team_size": team_size,
            "low_confidence_dims": low_confidence_dims,
        },
        "effort": {
            "man_months": round(effort_mm, 2),
            "person_days": round(effort_pd, 1),
        },
        "duration": {
            "working_days": round(duration_wd, 1),
            "weeks": round(duration_weeks, 1),
        },
        "range": {
            "band": band["label"],
            "optimistic": scaled(band["low"]),
            "likely": scaled(1.0),
            "pessimistic": scaled(band["high"]),
        },
        "assumptions": assumptions,
    }


def estimate_rollup(units: List[Dict], defaults: Dict) -> Dict:
    """Estimate every unit, then aggregate.

    Sequential total assumes units run one after another; the parallel floor
    (longest single unit) is the theoretical best case if every unit could run
    concurrently. Real scheduling with dependencies belongs to the
    aidlc-units-roadmap skill, which consumes this rollup.
    """
    if not units:
        _fail("units-json contains no units")

    results = []
    for unit in units:
        if "name" not in unit or "bcp" not in unit:
            _fail(f"every unit needs 'name' and 'bcp': {unit}")
        results.append(
            estimate_one(
                bcp=float(unit["bcp"]),
                level=unit.get("level", "unit"),
                parallel_fte=float(unit.get("parallel_fte", defaults["parallel_fte"])),
                team_size=defaults.get("team_size"),
                rate=float(unit.get("rate", defaults["rate"])),
                rate_source=unit.get("rate_source", defaults["rate_source"]),
                days_per_month=float(
                    unit.get("days_per_month", defaults["days_per_month"])
                ),
                days_per_week=float(
                    unit.get("days_per_week", defaults["days_per_week"])
                ),
                focus=float(unit.get("focus", defaults["focus"])),
                low_confidence_dims=int(unit.get("low_confidence_dims", 0)),
                name=str(unit["name"]),
            )
        )

    total_bcp = sum(r["inputs"]["bcp"] for r in results)
    total_mm = sum(r["effort"]["man_months"] for r in results)
    total_pd = sum(r["effort"]["person_days"] for r in results)
    sequential_wd = sum(r["duration"]["working_days"] for r in results)
    parallel_floor_wd = max(r["duration"]["working_days"] for r in results)
    days_per_week = defaults["days_per_week"]

    seq_pessimistic = sum(
        r["range"]["pessimistic"]["duration_working_days"] for r in results
    )
    seq_optimistic = sum(
        r["range"]["optimistic"]["duration_working_days"] for r in results
    )

    return {
        "units": results,
        "totals": {
            "total_bcp": round(total_bcp, 1),
            "effort_man_months": round(total_mm, 2),
            "effort_person_days": round(total_pd, 1),
            "sequential_duration_working_days": round(sequential_wd, 1),
            "sequential_duration_weeks": round(sequential_wd / days_per_week, 1),
            "sequential_range_working_days": [
                round(seq_optimistic, 1),
                round(seq_pessimistic, 1),
            ],
            "parallel_floor_working_days": round(parallel_floor_wd, 1),
        },
        "note": (
            "Sequential total assumes one unit at a time; parallel floor is the "
            "longest single unit. Dependency-aware scheduling is done by "
            "aidlc-units-roadmap, which re-derives these numbers from per-unit "
            "BCP and team capacity when building the schedule."
        ),
    }


def format_single_markdown(result: Dict) -> str:
    """Render the 'Time Estimate' section appended to a BCP report."""
    inputs = result["inputs"]
    effort = result["effort"]
    duration = result["duration"]
    rng = result["range"]

    title = "## Time Estimate"
    if result.get("name"):
        title += f" — {result['name']}"

    lines = [
        title,
        "",
        f"- **Total BCP:** {inputs['bcp']:g}",
        f"- **Delivery rate:** {inputs['rate_bcp_per_mm']:g} BCP per man-month"
        f" ({inputs['rate_source']})",
        f"- **Effort:** {effort['man_months']:g} man-months"
        f" ≈ {effort['person_days']:g} person-days",
        f"- **Duration (likely):** {duration['working_days']:g} working days"
        f" ≈ {duration['weeks']:g} weeks",
        f"- **Range band:** {rng['band']}",
        "",
        "| Scenario | Effort (person-days) | Duration (working days) | Weeks |",
        "|----------|---------------------|--------------------------|-------|",
    ]
    for label in ("optimistic", "likely", "pessimistic"):
        row = rng[label]
        lines.append(
            f"| {label.capitalize()} | {row['effort_person_days']:g} "
            f"| {row['duration_working_days']:g} | {row['duration_weeks']:g} |"
        )
    lines += ["", "**Assumptions:**", ""]
    lines += [f"- {item}" for item in result["assumptions"]]
    return "\n".join(lines) + "\n"


def format_rollup_markdown(rollup: Dict) -> str:
    """Render the rollup section embedded in a consolidated batch report."""
    totals = rollup["totals"]
    lines = [
        "## Time Rollup",
        "",
        "Per-unit effort and duration derived from finalized BCP estimates.",
        "`aidlc-units-roadmap` re-derives the same numbers from per-unit BCP",
        "and team capacity when building the Gantt schedule.",
        "",
        "| Unit | BCP | Effort (mm) | Effort (pd) | Duration likely (wd) "
        "| Duration range (wd) | Band |",
        "|------|-----|-------------|-------------|----------------------"
        "|---------------------|------|",
    ]
    for unit in rollup["units"]:
        rng = unit["range"]
        lines.append(
            f"| {unit['name']} | {unit['inputs']['bcp']:g} "
            f"| {unit['effort']['man_months']:g} "
            f"| {unit['effort']['person_days']:g} "
            f"| {unit['duration']['working_days']:g} "
            f"| {rng['optimistic']['duration_working_days']:g}"
            f"–{rng['pessimistic']['duration_working_days']:g} "
            f"| {rng['band']} |"
        )
    lines += [
        "",
        "### Totals",
        "",
        f"- **Total BCP:** {totals['total_bcp']:g}",
        f"- **Total effort:** {totals['effort_man_months']:g} man-months"
        f" ≈ {totals['effort_person_days']:g} person-days",
        f"- **Sequential duration:** {totals['sequential_duration_working_days']:g}"
        f" working days ≈ {totals['sequential_duration_weeks']:g} weeks"
        f" (range {totals['sequential_range_working_days'][0]:g}"
        f"–{totals['sequential_range_working_days'][1]:g} wd)",
        f"- **Parallel floor:** {totals['parallel_floor_working_days']:g}"
        " working days (longest single unit; theoretical best case)",
        "",
        f"> {rollup['note']}",
    ]
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert finalized BCP into effort/duration with a range."
    )
    parser.add_argument("--bcp", type=float, help="Total finalized BCP")
    parser.add_argument(
        "--level", choices=VALID_LEVELS, help="Artifact level (sets the range band)"
    )
    parser.add_argument(
        "--units-json", help="JSON file with a 'units' list for batch rollup"
    )
    parser.add_argument(
        "--parallel-fte",
        type=float,
        default=1.0,
        help="People who can actually work this concurrently (default 1)",
    )
    parser.add_argument("--team-size", type=float, help="Team headcount (for display/validation)")
    parser.add_argument(
        "--rate",
        type=float,
        default=ORG_DEFAULT_RATE,
        help=f"Delivery rate in BCP per man-month (default {ORG_DEFAULT_RATE:g})",
    )
    parser.add_argument(
        "--rate-source",
        choices=VALID_RATE_SOURCES,
        default="org-default",
        help="Where the rate came from; org-default widens the range one level",
    )
    parser.add_argument(
        "--days-per-month", type=float, default=DEFAULT_DAYS_PER_MONTH,
        help=f"Working days per man-month (default {DEFAULT_DAYS_PER_MONTH})",
    )
    parser.add_argument(
        "--days-per-week", type=float, default=DEFAULT_DAYS_PER_WEEK,
        help=f"Working days per week (default {DEFAULT_DAYS_PER_WEEK})",
    )
    parser.add_argument(
        "--focus", type=float, default=DEFAULT_FOCUS,
        help="Focus factor in (0,1]; default 1.0 because the org rate already "
        "includes typical overhead",
    )
    parser.add_argument(
        "--low-confidence-dims", type=int, default=0,
        help="Count of Low-confidence BCP dimensions; >=3 widens the range",
    )
    parser.add_argument("--json-out", help="Also write the result JSON to this path")
    args = parser.parse_args()

    if args.units_json:
        try:
            with open(args.units_json, "r", encoding="utf-8") as handle:
                payload = json.load(handle)
        except FileNotFoundError:
            _fail(f"file not found: {args.units_json}")
        except json.JSONDecodeError as exc:
            _fail(f"invalid JSON in {args.units_json}: {exc}")
        defaults = {
            "parallel_fte": args.parallel_fte,
            "team_size": args.team_size,
            "rate": args.rate,
            "rate_source": args.rate_source,
            "days_per_month": args.days_per_month,
            "days_per_week": args.days_per_week,
            "focus": args.focus,
        }
        result = estimate_rollup(payload.get("units", []), defaults)
        markdown = format_rollup_markdown(result)
    else:
        if args.bcp is None or args.level is None:
            _fail("either --units-json, or both --bcp and --level, are required")
        result = estimate_one(
            bcp=args.bcp,
            level=args.level,
            parallel_fte=args.parallel_fte,
            team_size=args.team_size,
            rate=args.rate,
            rate_source=args.rate_source,
            days_per_month=args.days_per_month,
            days_per_week=args.days_per_week,
            focus=args.focus,
            low_confidence_dims=args.low_confidence_dims,
        )
        markdown = format_single_markdown(result)

    print(markdown)
    if args.json_out:
        with open(args.json_out, "w", encoding="utf-8") as handle:
            json.dump(result, handle, indent=2)
        print(f"JSON written to: {args.json_out}", file=sys.stderr)


if __name__ == "__main__":
    main()
