---
name: aidlc-code-review
description: AIDLC Construction code review gate — validates task/unit implementation against AIDLC spec artifacts (requirements.md, design.md, tasks.md, and mockup.html for UI handoff when present), project standards, verification evidence, and changed-code failure modes. Use after Phase 4 implementation and verification but before marking any AIDLC task or unit complete, after all tasks in a unit are implemented, or when asked to "review aidlc task/unit", "validate implementation", "check construction output", or "code review for construction". Prefer this skill over generic code review whenever work is tied to `aidlc-docs/specs/*`.
---

# AIDLC Code Review

Validates construction output against the unit's spec artifacts and the project's own coding standards. Combines spec compliance, code quality, and adversarial review — all grounded in AIDLC artifacts rather than generic best practices.

## When to Run

| Trigger | Mode |
|---------|------|
| After `execute-task` implements and verifies a task, before checkbox completion | Per-task review |
| After all implementation tasks in a unit are verified, before unit completion | Full unit review |
| User says "review task X" / "check unit Y" | On-demand |
| Before marking a unit complete | Final gate |

---

## Review Subagent Contract

When running as a delegated review subagent from `/aidlc.construction.execute-task` or `/aidlc.construction.code-review`:

- Load this skill only before reviewing
- Review only the provided unit/task scope and the task-relevant diff
- Do not modify implementation code
- Do not update `tasks.md` checkboxes
- Return findings, verdict, reviewed files, excluded unrelated changes, verification evidence, and ready-to-proceed decision to the parent session that requested the review (the Phase 4 coordinator, or the inline implementation session)

---

## Step 0: Locate AIDLC Context

Before reviewing, identify the unit and scope being reviewed.

**Resolution order** — try each in sequence, stop when resolved:

1. **From conversation context** — unit slug or task ID mentioned in the current session
2. **From arguments** — user passed a unit slug or task number directly
3. **Ask the user** — if neither of the above works, ask:

   > "Which unit and scope should I review?"
   > - Unit slug (e.g., `user-authentication`) — required
   > - Scope: single task (which task number?) or full unit?
   > - Optional: git range (BASE_SHA..HEAD_SHA) if known

   Do not proceed without at least the unit slug.

Load these artifacts for the unit:

```
aidlc-docs/specs/{unit-slug}/
├── requirements.md   ← acceptance criteria ground truth
├── design.md         ← API contracts, data models, architecture; includes § UI Design Specification with feature-specific design tokens when applicable
├── tasks.md          ← task checklist with per-task acceptance criteria
└── mockup.html       ← authoritative HTML UI handoff for UI tasks, when present
```

Load project standards:

```
aidlc-docs/foundation/
├── code-standards.md      ← coding conventions, patterns, naming
├── system-architecture.md ← architectural patterns and component map
├── codebase-summary.md    ← tech stack and project structure
└── uiux-guideline.md      ← global component patterns, design tokens, accessibility (load only if unit has UI/frontend changes)
```

When the unit touches UI components, screens, layouts, styling, or interaction patterns, load `uiux-guideline.md` (global baseline), read `mockup.html` if present, and read the `§ UI Design Specification` section in `design.md` (feature-level tokens). For FE-heavy UI reviews, also inspect preview/child-frame images, design screenshots, and review-handoff visual QA evidence when provided. `mockup.html` is the UI source of truth. Skip UI context for purely backend/service units and note the omission.

If `aidlc-docs/foundation/` is missing, skip Stage 2 standards check and note it in the report.

## Review Scope Hygiene

Before grading anything, establish what changed and what is in scope. AIDLC review should protect the user's current worktree rather than sweeping in unrelated edits.

- Prefer an explicit git range from the user or command context (`BASE_SHA..HEAD_SHA`)
- If no range is provided, inspect staged and unstaged changes and include only files relevant to the requested task/unit
- If unrelated changes are present, list them as excluded rather than reviewing or modifying them
- Do not mark a task complete based on a review that did not cover its implementation diff
- Cite evidence from actual files with `file:line`; use diff lines only to understand what changed

---

## Three-Stage Pipeline

```
Step 0: Resolve scope (ask user if unclear)
    ↓
Stage 1: AIDLC Spec Compliance
    ↓ PASS / accepted WARN
Stage 2: Code Quality  (vs foundation/code-standards.md)
    ↓ PASS
Stage 3: Adversarial Review  (scope-gated)
```

A Stage 1 failure stops the pipeline — there's no point checking code quality when the requirements aren't met. A Stage 1 WARN can proceed only when the review clearly identifies the extra scope and the user or task context accepts it.

---

## Stage 1 — AIDLC Spec Compliance

**Question**: Does the implementation match what was specified in the AIDLC artifacts?

### What to check

| Source | What to verify |
|--------|----------------|
| `requirements.md` | All acceptance criteria are implemented |
| `design.md` | API contracts, data models, component interfaces match |
| `design.md § UI Design Specification` | Feature-specific design tokens, spacing, typography, and component specs defined in this section are applied in code — no hardcoded values where a token was defined (only for UI tasks) |
| `mockup.html` | Authoritative UI structure, component variants, interaction states, responsive behavior, accessibility markup, and Figma/MDS mappings are followed (only for UI tasks when present) |
| Figma handoff/images | Rendered structure, hierarchy, spacing, typography, and state coverage match the approved visual source, or deviations are documented with an accepted reason (only for FE-heavy UI tasks when available) |
| `tasks.md` | Each task in the current scope has its acceptance criteria fulfilled |
| `requirements.md` | No unjustified out-of-scope additions |

For **per-task review**: focus only on the task being reviewed (its row in tasks.md).

For **full unit review**: check all tasks and the complete requirements.md.

### Verdict

| Verdict | Meaning | Next step |
|---------|---------|-----------|
| **PASS** | All requirements met, no unjustified extras | Proceed to Stage 2 |
| **FAIL** | Requirements missing or incorrectly implemented | Stop, list failures, implementer fixes, re-review |
| **WARN** | Extra scope not in spec, may be valid | Flag for user decision |

### Output format

```markdown
## Stage 1 — Spec Compliance

| # | Requirement | Source | Status | Evidence |
|---|-------------|--------|--------|----------|
| 1 | [from requirements.md / tasks.md] | requirements.md:L12 | PASS | file:line |
| 2 | [acceptance criterion] | design.md:L34 | MISSING | — |

**Verdict**: PASS / FAIL (N missing) / WARN (N extras)
```

---

## Stage 2 — Code Quality

**Ground truth**: `foundation/code-standards.md` and `foundation/system-architecture.md`.

Review against the **project's own standards**, not generic best practices. If something isn't covered by the foundation docs, apply common sense and note the gap.

### Review areas

- **Conventions**: naming, formatting, file organization — from code-standards.md
- **Architecture fit**: patterns and component structure — from system-architecture.md
- **Error handling**: follows the project's established error handling style
- **Type safety**: consistent with the project's typing approach
- **Test coverage**: follows project's testing patterns
- **Verification evidence**: linter, tests, build/type-check, runtime or smoke verification were run or explicitly skipped with reasons
- **Unit integration**: clean contracts with other units, no coupling to internals
- **UI/UX alignment** *(only when unit has UI/frontend changes)*: verify design tokens, color variables, spacing values, typography, component variants, and interaction states match `mockup.html` when present, the `§ UI Design Specification` in `design.md` (feature-level), and `uiux-guideline.md` (global baseline); flag hardcoded values where a token was defined; skip and note if unit is backend-only
- **FE-heavy visual quality** *(only for visible screen/layout/component changes)*: verify rendered structure, responsive layout, visual hierarchy, state coverage, and browser/design comparison evidence. Flag completion attempts that rely only on lint/tests/build without visual inspection or an explicit skip reason
- **Design-system adherence** *(when a design system is in scope)*: verify canonical components, valid props/variants, token-backed spacing/colors/radii, and no custom replacements where an approved component exists. For Magenta/MDS, check against `mockup.html` mappings and `magenta-mds`-confirmed components/tokens rather than invented props

### Issue categories

| Category | Description | Action |
|----------|-------------|--------|
| **Critical** | Bug, data loss, broken contract with another unit, security flaw | Fix before proceeding |
| **Important** | Architecture violation, missing error path, test gap, wrong pattern | Fix before next unit |
| **Minor** | Style deviation, naming inconsistency, optimization opportunity | Track, fix when convenient |

### Output format

```markdown
## Stage 2 — Code Quality

### Strengths
- [what's done well — be specific with file:line]

### Issues

#### Critical
- `file:line` — What's wrong — Why it matters — How to fix

#### Important
- `file:line` — What's wrong — Why it matters — How to fix

#### Minor
- `file:line` — Suggestion
```

---

## Stage 3 — Adversarial Review

Failure-mode analysis that actively tries to break the implementation. See `references/adversarial-review.md` for the full protocol.

### Scope gate

**Skip** when ALL of these are true:
- Files changed ≤ 2 AND lines changed ≤ 30
- No security-sensitive files (auth, crypto, env, SQL, input parsing)
- No new external dependencies added

When skipped, note: `Adversarial: skipped (below threshold)` in output.

**NEVER skip when**:
- New API routes or external integrations added
- Auth or permissions logic changed
- Database schema modified
- Cross-unit contract (shared interface, shared DB table) changed
- Environment variables added or changed
- `package.json`, lockfile, dependency manifest, or generated client/schema changed

### AIDLC-specific attack angles

Beyond the standard adversarial checklist, also consider:

- **Unit coupling assumptions**: Does this unit assume another unit's API is stable at a specific version? What breaks if that contract changes?
- **Integration point validation**: Are inputs from other units validated, or trusted blindly?
- **Error propagation across boundaries**: If this unit throws, does the calling unit handle it correctly?
- **FE-heavy UI failure modes**: Does the UI collapse at mobile widths, hide primary actions, omit required empty/loading/error states, rely on hardcoded design values where tokens exist, or diverge from the Figma/design structure enough to mislead users?

**Full adversarial protocol**: `references/adversarial-review.md`

---

## Getting the Diff

### Per-task review

```bash
# Best: explicit range supplied by user or execute-task context
git diff --stat BASE_SHA..HEAD_SHA
git diff BASE_SHA..HEAD_SHA
```

If the team doesn't commit per-task, use pending changes and scope manually to the task:

```bash
git status --short
git diff --cached
git diff
```

Review only the task-relevant files. If unrelated staged or unstaged files exist, call them out as excluded.

### Full unit review

```bash
# Prefer the unit branch merge-base with the target branch, or an explicit unit-start SHA from the user
git merge-base HEAD main
git diff BASE_SHA..HEAD
```

If the repository uses a different base branch, replace `main` with the actual target branch.

---

## Review Output Template

```markdown
# AIDLC Code Review — {unit-slug} [{task-id | "unit-complete"}]

**Unit**: {unit-slug}
**Scope**: Task {task-id} / Full unit
**Diff**: {BASE_SHA}..{HEAD_SHA}
**Reviewed files**: {files}
**Excluded changes**: {none | files and reason}
**Verification evidence**: {commands/results or skipped steps with reasons}

---

## Stage 1 — Spec Compliance
[table]
**Verdict**: PASS / FAIL / WARN

---

## Stage 2 — Code Quality

### Strengths
- ...

### Issues
#### Critical
- ...
#### Important
- ...
#### Minor
- ...

---

## Stage 3 — Adversarial Review
[full adversarial output OR "Skipped (below threshold: N files, N lines)"]

---

## Assessment

| Stage | Result |
|-------|--------|
| Stage 1 — Spec Compliance | PASS / FAIL |
| Stage 2 — Code Quality | PASS / N critical, N important, N minor |
| Stage 3 — Adversarial | PASS / N accepted, N rejected, N deferred / Skipped |

**Ready to proceed?**
- Yes → continue to next task or next unit
- No — fix Critical or spec-compliance failures first → list what needs fixing
- With fixes → Important issues noted, can continue only when deferral is explicit and tracked
```

---

## Integration with Construction Workflow

This skill fits inside Step 4 (Execute Tasks) as a pre-completion quality gate:

```
Step 3: Create Tasks  →  Step 4: Implement + Verify Task N  →  Code Review  →  Mark Task N Complete  →  Execute Task N+1
                                                           ↓
                                                    (all tasks done)
                                                    Full Unit Review
                                                           ↓
                                                    Next unit or workflow complete
```

**Per-task cadence** (recommended):
- Review after each task → catch issues early → fix before compounding

**Per-unit cadence** (minimum):
- Review after all tasks in a unit → quality gate before moving on

---

## Reference Files

- `references/adversarial-review.md` — Stage 3 adversarial review protocol, scope gate logic, subagent prompt template
