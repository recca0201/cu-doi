"""Tests for estimate_time.py — BCP -> effort/duration conversion.

Run from the repo root:
    python3 -m pytest .claude/skills/aidlc-estimation/scripts/test_estimate_time.py -v
"""

import json
import subprocess
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent))

from estimate_time import (  # noqa: E402
    BANDS,
    ORG_DEFAULT_RATE,
    estimate_one,
    estimate_rollup,
    format_rollup_markdown,
    format_single_markdown,
)

SCRIPT = Path(__file__).parent / "estimate_time.py"


class TestEffortMath:
    def test_rate_denominator(self):
        """170 BCP at the org rate is exactly one man-month / 20 person-days."""
        result = estimate_one(bcp=170, level="spec", parallel_fte=1)
        assert result["effort"]["man_months"] == 1.0
        assert result["effort"]["person_days"] == 20.0

    def test_worked_example_57_bcp(self):
        """The proposal's worked example: 57 BCP, 2 parallel FTE."""
        result = estimate_one(
            bcp=57, level="spec", parallel_fte=2, team_size=3,
            rate_source="team-calibrated",
        )
        assert result["effort"]["man_months"] == 0.34
        assert result["effort"]["person_days"] == 6.7
        assert result["duration"]["working_days"] == 3.4
        assert result["duration"]["weeks"] == 0.7

    def test_custom_days_per_month(self):
        result = estimate_one(
            bcp=170, level="spec", parallel_fte=1, days_per_month=22
        )
        assert result["effort"]["person_days"] == 22.0

    def test_focus_factor_stretches_duration_not_effort(self):
        full = estimate_one(bcp=170, level="spec", parallel_fte=1, focus=1.0)
        half = estimate_one(bcp=170, level="spec", parallel_fte=1, focus=0.5)
        assert half["effort"]["person_days"] == full["effort"]["person_days"]
        assert half["duration"]["working_days"] == pytest.approx(
            full["duration"]["working_days"] * 2
        )

    def test_parallel_fte_divides_duration(self):
        one = estimate_one(bcp=170, level="spec", parallel_fte=1)
        two = estimate_one(bcp=170, level="spec", parallel_fte=2)
        assert two["duration"]["working_days"] == pytest.approx(
            one["duration"]["working_days"] / 2
        )


class TestRangeBands:
    def test_band_by_level_with_calibrated_rate(self):
        for level, band_index in (("spec", 0), ("unit", 1), ("story", 2)):
            result = estimate_one(
                bcp=100, level=level, parallel_fte=1,
                rate_source="team-calibrated",
            )
            assert result["range"]["band"] == BANDS[band_index]["label"]

    def test_org_default_rate_widens_one_level(self):
        result = estimate_one(
            bcp=100, level="spec", parallel_fte=1, rate_source="org-default"
        )
        assert result["range"]["band"] == BANDS[1]["label"]

    def test_low_confidence_widens_one_level(self):
        result = estimate_one(
            bcp=100, level="spec", parallel_fte=1,
            rate_source="team-calibrated", low_confidence_dims=3,
        )
        assert result["range"]["band"] == BANDS[1]["label"]

    def test_both_widenings_stack(self):
        result = estimate_one(
            bcp=100, level="spec", parallel_fte=1,
            rate_source="org-default", low_confidence_dims=4,
        )
        assert result["range"]["band"] == BANDS[2]["label"]

    def test_widening_clamps_at_widest_band(self):
        result = estimate_one(
            bcp=100, level="story", parallel_fte=1,
            rate_source="org-default", low_confidence_dims=5,
        )
        assert result["range"]["band"] == BANDS[3]["label"]

    def test_two_low_confidence_dims_do_not_widen(self):
        result = estimate_one(
            bcp=100, level="spec", parallel_fte=1,
            rate_source="team-calibrated", low_confidence_dims=2,
        )
        assert result["range"]["band"] == BANDS[0]["label"]

    def test_optimistic_below_likely_below_pessimistic(self):
        result = estimate_one(bcp=100, level="unit", parallel_fte=2)
        rng = result["range"]
        assert (
            rng["optimistic"]["duration_working_days"]
            < rng["likely"]["duration_working_days"]
            < rng["pessimistic"]["duration_working_days"]
        )


class TestValidation:
    @pytest.mark.parametrize(
        "kwargs",
        [
            {"bcp": 0, "level": "spec", "parallel_fte": 1},
            {"bcp": -5, "level": "spec", "parallel_fte": 1},
            {"bcp": 10, "level": "epic", "parallel_fte": 1},
            {"bcp": 10, "level": "spec", "parallel_fte": 0},
            {"bcp": 10, "level": "spec", "parallel_fte": 1, "focus": 0},
            {"bcp": 10, "level": "spec", "parallel_fte": 1, "focus": 1.5},
            {"bcp": 10, "level": "spec", "parallel_fte": 1, "rate": 0},
            {"bcp": 10, "level": "spec", "parallel_fte": 1, "rate_source": "guess"},
        ],
    )
    def test_invalid_inputs_exit(self, kwargs):
        with pytest.raises(SystemExit):
            estimate_one(**kwargs)

    def test_parallel_fte_cannot_exceed_team_size(self):
        with pytest.raises(SystemExit):
            estimate_one(bcp=10, level="spec", parallel_fte=5, team_size=3)


class TestRollup:
    UNITS = [
        {"name": "unit-1", "bcp": 24, "level": "unit"},
        {"name": "unit-2", "bcp": 57, "level": "unit"},
        {"name": "unit-3", "bcp": 36, "level": "unit"},
    ]
    DEFAULTS = {
        "parallel_fte": 2,
        "team_size": 3,
        "rate": ORG_DEFAULT_RATE,
        "rate_source": "team-calibrated",
        "days_per_month": 20,
        "days_per_week": 5,
        "focus": 1.0,
    }

    def test_totals(self):
        rollup = estimate_rollup(self.UNITS, self.DEFAULTS)
        totals = rollup["totals"]
        assert totals["total_bcp"] == 117
        assert totals["effort_man_months"] == pytest.approx(
            sum(u["effort"]["man_months"] for u in rollup["units"])
        )
        assert totals["sequential_duration_working_days"] == pytest.approx(
            sum(u["duration"]["working_days"] for u in rollup["units"])
        )
        assert totals["parallel_floor_working_days"] == max(
            u["duration"]["working_days"] for u in rollup["units"]
        )

    def test_per_unit_override_beats_defaults(self):
        units = [dict(self.UNITS[0], parallel_fte=1)] + self.UNITS[1:]
        rollup = estimate_rollup(units, self.DEFAULTS)
        assert rollup["units"][0]["inputs"]["parallel_fte"] == 1
        assert rollup["units"][1]["inputs"]["parallel_fte"] == 2

    def test_empty_units_exit(self):
        with pytest.raises(SystemExit):
            estimate_rollup([], self.DEFAULTS)

    def test_unit_missing_bcp_exit(self):
        with pytest.raises(SystemExit):
            estimate_rollup([{"name": "broken"}], self.DEFAULTS)


class TestMarkdown:
    def test_single_contains_required_fields(self):
        result = estimate_one(
            bcp=57, level="spec", parallel_fte=2, team_size=3,
            rate_source="team-calibrated",
        )
        md = format_single_markdown(result)
        assert "## Time Estimate" in md
        assert "170 BCP per man-month (team-calibrated)" in md
        assert "Optimistic" in md and "Likely" in md and "Pessimistic" in md
        assert "**Assumptions:**" in md
        assert "Effective parallel FTE: 2 of team size 3" in md

    def test_org_default_assumption_is_visible(self):
        result = estimate_one(
            bcp=24, level="story", parallel_fte=1, rate_source="org-default"
        )
        md = format_single_markdown(result)
        assert "org-default" in md
        assert "Range widened" in md

    def test_rollup_has_unit_rows_and_totals(self):
        rollup = estimate_rollup(TestRollup.UNITS, TestRollup.DEFAULTS)
        md = format_rollup_markdown(rollup)
        for unit in TestRollup.UNITS:
            assert unit["name"] in md
        assert "Sequential duration" in md
        assert "Parallel floor" in md
        assert "aidlc-units-roadmap" in md


class TestCLI:
    def test_single_artifact_cli(self, tmp_path):
        json_out = tmp_path / "time.json"
        proc = subprocess.run(
            [
                sys.executable, str(SCRIPT),
                "--bcp", "57", "--level", "spec",
                "--parallel-fte", "2", "--team-size", "3",
                "--rate-source", "team-calibrated",
                "--json-out", str(json_out),
            ],
            capture_output=True, text=True,
        )
        assert proc.returncode == 0, proc.stderr
        assert "## Time Estimate" in proc.stdout
        payload = json.loads(json_out.read_text())
        assert payload["effort"]["person_days"] == 6.7

    def test_units_json_cli(self, tmp_path):
        units_file = tmp_path / "units.json"
        units_file.write_text(json.dumps({"units": TestRollup.UNITS}))
        proc = subprocess.run(
            [
                sys.executable, str(SCRIPT),
                "--units-json", str(units_file),
                "--parallel-fte", "2",
                "--rate-source", "team-calibrated",
            ],
            capture_output=True, text=True,
        )
        assert proc.returncode == 0, proc.stderr
        assert "## Time Rollup" in proc.stdout

    def test_missing_required_args_fails(self):
        proc = subprocess.run(
            [sys.executable, str(SCRIPT), "--bcp", "57"],
            capture_output=True, text=True,
        )
        assert proc.returncode != 0
