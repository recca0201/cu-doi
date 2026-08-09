---
name: aidlc-vibe
description: Quick implementation and debugging workflow for AI-DLC projects — bug fixes, errors, test failures, small features, and refactoring touching 1-3 related files with no new infrastructure. Trigger on "fix this bug", "getting an error", "test is failing", or simple feature requests. Enforces root-cause-before-fix for bugs, writes a regression test, auto-verifies with lint & build, offers user-confirmed tests/run. NOT for complex features, new dependencies, or when a written spec is wanted — use aidlc-quick-spec (written record) or aidlc-spec-driven (full process) instead.
---

# AIDLC Vibe

Quick, verified implementation for simple changes — bug fixes, small features, and refactoring that don't need the full AI-DLC process. One session, no spec documents, but never at the cost of discipline: bugs get root-cause diagnosis, features get a plan, everything gets verified.

## Workflow Overview

```
Step 1: Load foundation context (selective)
Step 2: Scout the code
Step 3: Route by task type — silently, from the request itself
   ├─ FIX path   (bug, error, test failure, unexpected behavior)
   └─ BUILD path (simple feature, refactor)
Step 4: Automatic verification (lint & build)
Step 5: Optional verification (tests & run — user decides)
```

### Step 1: Load Foundation Context (Selective)

Foundation docs live in `aidlc-docs/foundation/`. Read only what the task needs — this skill exists for speed, and reading all five documents for a one-line backend fix is wasted time:

| File | Read when |
|------|-----------|
| `code-standards.md` | Always — conventions the change must follow |
| `codebase-summary.md` | Always — where things live |
| `system-architecture.md` | Change touches component boundaries, services, or data flow |
| `uiux-guideline.md` | Change touches UI |
| `project-overview-pdr.md` | Business intent of the request is unclear |

If a file doesn't exist, continue without it — don't block on missing foundation docs.

### Step 2: Scout the Code

Understand the affected area BEFORE forming any plan or hypothesis:

Before editing, inspect current changes in the affected files (`git status --short` plus targeted diffs). Preserve pre-existing user work; never restore or rewrite unrelated changes.

1. **Locate** — Glob/Grep for the relevant functionality; identify the files involved
2. **Read** — current implementation, patterns, dependencies, imports
3. **Check history** — `git log --oneline -15 -- <affected files>`: a recent commit is the #1 suspect for a new bug, and history shows which patterns are current
4. **Find related tests** — they document expected behavior, and they're where a regression test will live

### Step 3: Route by Task Type

Route silently based on the request — never ask the user which path to take:

- *bug, error, broken, fails, crash, wrong, doesn't work, unexpected* → **FIX path**
- *add, create, implement, refactor, rename, extract* → **BUILD path**
- Re-route freely mid-task: a feature request that uncovers broken existing behavior switches to FIX; a "bug" that's really a missing feature switches to BUILD.

## FIX Path: Root Cause Before Any Fix

Symptom patches create new bugs and mask real ones. The iron rule: **no fix without a diagnosed root cause.**

For anything beyond a trivial lint/type/syntax error, read [references/debugging.md](references/debugging.md) before proposing a fix. If the symptom matches a known category (test failure, type errors, logs, CI, UI), also check [references/symptom-playbooks.md](references/symptom-playbooks.md).

### F1. Capture the failure

Before touching anything, record:
- **Exact symptom** — error message / failing assertion / wrong behavior, copied verbatim (never paraphrased)
- **Repro command** — the minimal command or steps that trigger it
- **Expected vs actual** — one sentence each

Run the original repro once when safe and record fresh output. This capture is the baseline: F5 re-runs this same repro and compares output. It is distinct from the new regression test written in F4.

### F2. Diagnose

Find the root cause — a specific line, missing check, race, or wrong assumption — with file:line evidence.

- **Trivial fast-path:** for lint/type/syntax errors with an obvious cause, abbreviated diagnosis is fine (read error → locate → confirm). F1 capture is still required.
- **Everything else:** follow the root-cause gate, hypothesis discipline, and backward tracing in `references/debugging.md`.
- Never fix where the error *appears* until you've traced why it happens there.

### F3. Fix minimally

One hypothesis, one change, at the source. No bundled refactoring, no "while I'm here" improvements. A single-variable change is easy to reason about and easy to revert if the hypothesis was wrong.

### F4. Write a regression test (do not run the new test yet)

If the project has a test harness, write a new test that exercises the exact captured failure — designed to fail without the fix and pass with it. Don't run this newly written test in this step; running it is user-confirmed in Step 5. If there is no test harness, skip and say so in the final report.

### F5. Prove the fix

Re-run the **original** repro from F1 and compare output before/after. This does not include the newly written F4 regression test, which remains user-confirmed in Step 5. If the original repro cannot be repeated without an optional application run, record that limitation rather than implying proof. "Should be fixed now" is not verification — fresh output is.

### Escape hatch: 3 failed fixes = wrong approach

Count fix attempts honestly. After the 2nd failure, do not apply a blind third patch: return to F2 and require new evidence for a contained root cause. If the proper fix now requires architecture or broader scope, escalate immediately. After a third evidence-backed attempt fails, STOP — this is no longer a simple bug:

- The architecture or pattern itself is likely the problem
- Summarize the symptom, the attempts, and what each revealed; recommend `aidlc-quick-spec` or `aidlc-spec-driven`
- Never attempt fix #4 inside this skill — see `references/debugging.md` §9

## BUILD Path: Plan, Then Implement

### B1. Plan

From the Step 2 scouting, create a short plan — files to touch, specific changes, edge cases. Keep it in the conversation (3-5 bullets) or TodoWrite. **Never** write the plan to a file (no plan.md) — if the change deserves a planning document, it belongs in `aidlc-quick-spec`.

### B2. Implement

- Match surrounding code: style, naming, patterns from foundation docs
- Only what's necessary — no extra features, no drive-by refactoring, comments only where logic isn't self-evident
- If scope grows mid-implementation (5+ files, new dependency, cross-module), stop and escalate rather than pushing through. A fourth file that is only a related test or small configuration update does not by itself require escalation.

## Step 4: Automatic Verification (Lint & Build)

Always run after implementation, both paths:

1. **Lint** — fix style or syntax issues introduced by or directly related to the change
2. **Build** — ensure compilation succeeds

Fix in-scope failures immediately and re-run. Report unrelated pre-existing failures without modifying them. Proceed to Step 5 only when both pass, or when a documented pre-existing failure prevents a clean result without being caused by this change.

## Step 5: Optional Verification (Tests & Run)

Use `AskUserQuestion` when available to let the user choose additional verification. If it is unavailable, ask one concise plain-text question:

1. Run unit tests — on the FIX path this runs the F4 regression test; offer it first
2. Run/start the application (smoke test — clean startup, not full functional testing)
3. Both
4. Skip

On failures in any chosen step, fix only failures caused by or directly related to the change, then re-run. Report unrelated pre-existing failures. If the user skips on the FIX path, the final report must state plainly: **"regression test written at `<path>` but not yet run"** — never imply an unrun test passed.

## Verification Commands

| Stack | Lint | Build | Test | Start |
|-------|------|-------|------|-------|
| Node/TS | `npm run lint` | `npm run build` | `npm test` | `npm start` |
| .NET | `dotnet format --verify-no-changes` | `dotnet build` | `dotnet test` | `dotnet run` |
| Flutter | `flutter analyze` | `flutter build <target>` | `flutter test` | `flutter run` |

Check `package.json` / `Makefile` / project docs when standard commands don't exist. Substitute `yarn`/`bun`/`pnpm` equivalents as the lockfile indicates.

## Red Flags — Stop and Follow the Process

| Thought | Reality |
|---------|---------|
| "I can see the problem, let me fix it" | Seeing a symptom ≠ understanding the root cause. Diagnose first. |
| "Quick fix now, investigate later" | Later never comes. The first fix sets the pattern. |
| "It's probably X" | "Probably" is a guess. Confirm with evidence, then fix. |
| "Just try changing X and see" | Random fixes waste time and create new bugs. |
| "One more blind attempt" (after 2 failures) | Re-diagnose first. Attempt 3 requires new evidence and contained scope; otherwise escalate. |
| "Issue is simple, skip the process" | Simple bugs have root causes too — the trivial fast-path IS the process for them. |
| "Emergency, no time for process" | Systematic diagnosis is faster than guess-and-check thrashing. |

## Know When to Escalate

- Needs a written record but still single-area, ~1-5 files → `aidlc-quick-spec` (one `spec.md`, one approval gate)
- 5+ files, cross-module, new dependency, architectural discussion → `aidlc-spec-driven`
- 3 failed fix attempts → stop, summarize findings, discuss with the user (FIX escape hatch)

When escalating mid-task, carry your findings forward — scout results, diagnosis, attempted fixes. They're the most valuable output of the session so far; don't make the next workflow rediscover them.

## References

| File | Read when |
|------|-----------|
| `references/debugging.md` | FIX path, any non-trivial bug — root-cause gate, hypothesis discipline, backward tracing, regression test contract, prevention check, 3-strike rule |
| `references/symptom-playbooks.md` | Symptom matches a category: test failures, type errors, log-reported errors, CI failures, UI bugs |
