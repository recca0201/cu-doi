# Time Estimation — BCP to Effort & Duration

Detailed workflow for the optional time-estimation phase (Steps 10-12) that runs
**after** a BCP total is finalized in Step 9. Read this file before producing any
effort or duration numbers.

## Table of Contents

- [The Three-Layer Model](#the-three-layer-model)
- [Capacity Profile in team-info.md](#capacity-profile-in-team-infomd)
- [Step 10: Load Capacity](#step-10-load-capacity)
- [Step 11: Compute and Present](#step-11-compute-and-present)
- [Step 12: Save (Report Only)](#step-12-save-report-only)
- [Multi-Unit Rollup](#multi-unit-rollup)
- [Parallelism Heuristics](#parallelism-heuristics)
- [Worked Examples](#worked-examples)
- [Recalibration Guidance](#recalibration-guidance)

## The Three-Layer Model

Keep these three quantities separate — collapsing them is the most common
estimation mistake:

| Layer | Question | Unit | Source |
|-------|----------|------|--------|
| **Complexity** | How hard is the work? | BCP | Steps 1-9 (finalized total) |
| **Effort** | How much work is it? | man-months / person-days | BCP ÷ delivery rate |
| **Duration** | How long on the calendar? | working days / weeks, as a range | Effort ÷ (parallel FTE × focus) |

Two teams facing the same 57 BCP finish in very different calendar times — BCP
measures complexity objectively; **team capacity** is what turns it into time.

**Time derives only from finalized BCP.** Never estimate time before the BCP
total is final: a time number without a complexity basis is a guess, and a time
number from a draft BCP silently inherits every unresolved dimension. If the
user asks for time and no BCP exists yet, run the estimation workflow
(Steps 1-9) first.

### The formulas

```
Effort (man-months)     = Total BCP ÷ Delivery_Rate          # rate in BCP/man-month
Effort (person-days)    = Effort (mm) × Working_Days_per_Month
Duration (working days) = Effort (pd) ÷ (Effective_Parallel_FTE × Focus_Factor)
Duration (weeks)        = Duration (wd) ÷ Working_Days_per_Week
```

**Org default delivery rate: 170 BCP per man-month.** Use it when the team has
no measured rate of its own. Precedence (highest wins):

1. Explicit value in the user's prompt ("our team does 200 BCP/mm")
2. `team-info.md` → Delivery Capacity section (team-calibrated)
3. Org default: 170 BCP/mm

**Why focus factor defaults to 1.0:** the 170 standard is derived from
*delivered* work, so it already absorbs typical overhead (meetings, context
switching, code review). Applying a focus factor on top would double-count that
overhead. Lower it only for known deviations the rate can't see — e.g. a team
spending 50% of its time on production support sets 0.5.

### Range, not point estimates

A single time number is false precision. Always present
**Optimistic / Likely / Pessimistic**, using the same accuracy bands the skill
already declares per artifact level (Step 5):

| Level | Accuracy | Range multipliers |
|-------|----------|-------------------|
| Spec | ±10-15% | × 0.87 / × 1.15 |
| Unit | ±20-30% | × 0.75 / × 1.30 |
| User Story | ±30-40% | × 0.65 / × 1.40 |
| (widened beyond story) | ±40-50% | × 0.60 / × 1.50 |

The band **widens one level** for each of these (stacking, clamped at widest):

- Delivery rate is the **org default** (no team-calibrated data) — an assumed
  rate deserves a wider band than a measured one.
- **≥3 BCP dimensions have Low confidence** — time inherits the complexity
  estimate's uncertainty.

`estimate_time.py` applies these rules automatically and records the widening
reasons in the output assumptions.

## Capacity Profile in team-info.md

Capacity lives in `{aidlc-docs-root}/foundation/team-info.md` — the same file
unit decomposition already creates for team size. One source of truth; do not
create a separate capacity file.

```markdown
# Team Information

## Team Size
**Developers in the team**: 4

## Delivery Capacity
**Delivery rate**: 170 BCP per man-month
**Rate source**: org-default          <!-- org-default | team-calibrated -->
**Working days per month**: 20
**Working days per week**: 5
**Focus factor**: 1.0
**Holidays / non-working dates**: (optional, e.g. 2026-09-02)
```

Field meanings:

- **Delivery rate** — BCP delivered per man-month. The one number that converts
  complexity to effort.
- **Rate source** — `team-calibrated` when measured from the team's own
  delivered work; `org-default` when using the 170 standard. Controls range
  widening.
- **Working days per month / week** — converts man-months to days and weeks.
- **Focus factor** — fraction of capacity actually available; keep 1.0 unless
  the team has a known structural deviation (support duty, split allocation).
- **Holidays** — noted for the human scheduling on a calendar; the script
  reports working days/weeks and does not map to calendar dates (that is the
  roadmap's job).

## Step 10: Load Capacity

Read `{aidlc-docs-root}/foundation/team-info.md` and resolve capacity in two
parts:

**1. Team size** — take it from `team-info.md`; if missing, ask the user
(required — duration is impossible without it).

**2. Delivery rate** — resolve by precedence:

- **Rate given in the user's prompt** → use it directly, no question.
- **`Rate source: team-calibrated` in team-info.md** → use it, ask nothing.
- **No team-calibrated rate anywhere** — file missing, Delivery Capacity
  section missing, or the section still says `org-default` → **ask the user
  once**, with the org default as the pre-selected/default option
  (AskUserQuestion when interactive):

  > Does your team have a measured delivery rate (BCP per man-month)?
  > - **Use org default: 170 BCP/man-month** (default — pick this if you
  >   don't know)
  > - Enter our team's measured rate

  The point of asking is to harvest better data when it exists — the user may
  know a rate the file doesn't. If they provide one, use it, set
  `Rate source: team-calibrated`, and write it back to `team-info.md`. If they
  don't know, don't answer, or the run is non-interactive with no
  prompt-provided rate → use the org default 170 (rate source `org-default`,
  range widens one level). **Never block on this question** — the org default
  is always the safe fallback.

Everything else (20 days/mm, 5 days/week, focus 1.0) defaults silently. When
`team-info.md` or its Delivery Capacity section is missing, offer to create or
update it so future runs have the data — the same persistence pattern unit
decomposition uses for team size.

**File complete with a team-calibrated rate** → ask nothing about capacity.
The only per-run judgment left is Effective_Parallel_FTE (Step 11), because it
depends on the artifact, not the team.

Three useful properties of this flow:

- **Effort never blocks.** `Effort = BCP ÷ rate` needs no user input at all —
  you can always state effort immediately, even with zero team info. Only
  duration needs team size.
- **The rate question repeats only while uncalibrated.** Re-asking when the
  recorded source is still `org-default` is intentional — each ask is a chance
  to capture a real measured rate. Once the rate is team-calibrated, the
  question disappears permanently.
- **All other answers persist to `team-info.md`** and are never asked again.

## Step 11: Compute and Present

Never compute effort/duration by hand — use the script so the arithmetic is
reproducible across runs:

```bash
python3 .claude/skills/aidlc-estimation/scripts/estimate_time.py \
  --bcp 57 --level spec \
  --parallel-fte 2 --team-size 3 \
  --rate 170 --rate-source team-calibrated \
  --json-out <workspace>/time-estimate.json
```

Pass `--low-confidence-dims N` with the count of Low-confidence dimensions from
the finalized BCP assessment so the range widens correctly.

Before running it, determine **Effective_Parallel_FTE** (see
[Parallelism Heuristics](#parallelism-heuristics)) and **confirm it with the
user** — it is the one input that is a judgment call about the work itself, and
getting it wrong scales the duration linearly.

Present the script's markdown output to the user with every assumption visible:
rate + source, days per month/week, focus factor, parallel FTE, and any range
widening. The user must be able to challenge any input before Step 12.

## Step 12: Save (Report Only)

After the user confirms:

1. **Append the `## Time Estimate` section** (the script's markdown output) to
   the BCP estimation report saved in Step 9.
2. **Do not touch artifact frontmatter.** Time estimates live only in the
   report — `estimation_bcp`/`estimation_report` remain the only estimation
   fields on artifacts. (Time depends on team capacity, which changes; BCP does
   not. Stamping volatile numbers on artifacts creates stale data.)
3. **Multi-unit runs** additionally include the rollup table in the
   consolidated batch report (next section).
4. **Suggest the roadmap step.** When a multi-unit rollup was produced (or an
   existing product roadmap covers the estimated units), offer in one line to
   update the roadmap — e.g. *"Durations are ready; want me to update the
   product roadmap (`aidlc-units-roadmap`) so the Gantt uses them?"* The
   rollup exists to feed the roadmap, so this handoff should be offered, not
   left for the user to discover. For a single spec with no roadmap in play,
   skip the suggestion.

## Multi-Unit Rollup

When estimating multiple units (typically after a batch BCP estimate of a
units-decomposition file), produce one rollup the roadmap can consume:

1. Build a units JSON from the finalized per-unit BCP totals:

```json
{
  "units": [
    {"name": "unit-1-auth", "bcp": 24, "level": "unit", "parallel_fte": 2},
    {"name": "unit-2-profile", "bcp": 57, "level": "unit", "parallel_fte": 2},
    {"name": "unit-3-badges", "bcp": 36, "level": "unit", "parallel_fte": 1}
  ]
}
```

2. Run the script in batch mode:

```bash
python3 .claude/skills/aidlc-estimation/scripts/estimate_time.py \
  --units-json <workspace>/units.json \
  --parallel-fte 2 --team-size 3 --rate 170 --rate-source team-calibrated \
  --json-out <workspace>/time-rollup.json
```

3. Include the markdown output as a section in the consolidated batch
   estimation report. **Do not save it as a separate standalone file** — the
   sources of truth are the per-unit BCP values (on the artifacts) and the
   capacity profile (`team-info.md`); a persistent derived file would go stale
   the moment any unit's BCP is re-estimated. When the roadmap needs
   durations, it re-derives them from those same inputs with the script
   (deterministic — same inputs, same numbers).

The rollup reports:

- Per-unit effort, likely duration, and duration range
- **Sequential total** (units one after another — the conservative ceiling)
- **Parallel floor** (longest single unit — the theoretical best case)

It deliberately does **not** schedule dependencies or draw a Gantt: that is
`aidlc-units-roadmap`'s job, and it recomputes the same duration numbers from
per-unit BCP + capacity when building the schedule. The boundary keeps the two
skills DRY — estimation owns the numbers and their sources of truth, roadmap
owns the schedule.

## Parallelism Heuristics

Effective_Parallel_FTE = how many people can *actually* work the artifact
concurrently. It is capped by the work's decomposability, not the headcount —
a 6-person team cannot parallelize a single-track task 6 ways.

Default heuristic: `min(team size, independent task tracks)`, then confirm with
the user.

To judge independent task tracks:

- **Spec with tasks.md** — count top-level task groups that do not depend on
  each other's outputs (e.g. "backend API" and "frontend form" tracks = 2;
  a strictly sequential migration checklist = 1).
- **Spec with design.md only** — count independently buildable components
  (separate services, UI vs API, isolated modules).
- **Unit / story** — usually 1-2; units are by definition single-team cohesive
  slices, and most stories are single-track.

When in doubt, prefer the **lower** parallelism — overestimating parallelism
produces optimistic durations that miss, which is the expensive direction to be
wrong in. State the chosen value as an assumption either way.

## Worked Examples

### Single spec

`validation-quality-engine` spec, finalized at **57 BCP**, team of 3, tasks.md
shows 2 independent tracks, team-calibrated rate 170:

```
Effort   = 57 ÷ 170              = 0.34 mm  ≈ 6.7 person-days
Duration = 6.7 ÷ (2 × 1.0)       = 3.4 working days ≈ 0.7 weeks
Range    (spec ±10-15%)          : 5.8–7.7 pd → 2.9–3.9 wd
```

### Same spec, no team data

Same 57 BCP but no `team-info.md` and no rate history — org default applies:

```
Effort   = 57 ÷ 170 = 0.34 mm ≈ 6.7 person-days     (unchanged — effort never blocks)
Range    widens one level to ±20-30%: 5.0–8.7 pd
Output states: "Delivery rate 170 BCP/man-month (org-default)" + widening reason
```

### Multi-unit rollup

Three units at 24 / 57 / 36 BCP (117 total), 2 parallel FTE, calibrated rate:

```
Effort total       = 117 ÷ 170 = 0.69 mm ≈ 13.8 person-days
Sequential total   = 1.4 + 3.4 + 2.1 ≈ 6.9 working days ≈ 1.4 weeks
Parallel floor     = 3.4 working days (unit-2, the longest)
```

Real calendar dates come from the roadmap after dependency scheduling.

## Recalibration Guidance

The 170 BCP/mm standard is a starting point, not a law. Challenge it when
actuals drift:

1. After a unit ships, compare its finalized BCP against actual person-days
   spent: `observed rate = BCP ÷ (actual person-days ÷ days-per-month)`.
2. One data point is noise. After **3+ completed units**, if the observed rate
   consistently deviates from the recorded rate by more than ~20%, update the
   Delivery Capacity section: new rate, `Rate source: team-calibrated`.
3. Estimates immediately tighten — a calibrated rate drops the automatic range
   widening.

Do not tune the rate from a single fast or slow unit, and never tune it to make
a particular estimate look better.
