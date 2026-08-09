---
name: aidlc-quick-spec
description: >-
  Use when a user requests a quick, small, or lightweight spec for a medium
  single-area change, or references an existing quick-spec `spec.md` to approve,
  execute, resume, or update. Best for roughly 1-5 files, no architectural
  rework, and one approval gate. Prefer `aidlc-vibe` for tiny changes needing no
  record and `aidlc-spec-driven` for cross-module work or new infrastructure,
  unless the user explicitly chooses quick-spec.
---

# AI-DLC Quick Spec

Single-document, single-approval-gate workflow for medium-sized AI-DLC features. Sits between `aidlc-vibe` (no doc, no gate) and `aidlc-spec-driven` (three docs, three gates).

## Choose the Workflow Tier

Classify the work before creating or resuming artifacts. Use the boundary table to avoid forcing a small task into unnecessary ceremony or compressing a complex task into one document.

| Signal                          | aidlc-vibe        | **aidlc-quick-spec**                  | aidlc-spec-driven                |
|---------------------------------|-------------------|---------------------------------------|----------------------------------|
| File count                      | 1–3               | **1–5, single area of code**          | 5+ or cross-module               |
| Written artifact                | None              | **One `spec.md`**                     | requirements + design + tasks    |
| Approval gates                  | None              | **One** (before execution)            | Three                            |
| New patterns / new dependencies | No                | **Maybe one, if obvious**             | Yes — design.md justifies them   |
| Foundation context loaded       | Yes               | **Yes**                               | Yes                              |
| Mandatory `aidlc-code-review`   | No                | **Conditional**                       | Yes                              |
| Tasks live in                   | TodoWrite         | **Checkboxed inside `spec.md`**       | Separate `tasks.md`              |
| Multi-session friendly          | No                | **Yes** (resume from `spec.md`)       | Yes                              |

If a spec already exists with separate `requirements.md` / `design.md` / `tasks.md`, recommend continuing with `aidlc-spec-driven`. Do not reinterpret those files as quick-spec unless the user explicitly asks to consolidate them into one `spec.md`.

The boundary table guides recommendations; it is not a hard gate. If the user explicitly requests quick-spec, honor that choice even when the work is larger, cross-module, or introduces infrastructure. Warn once about the lost phase-by-phase review and recommend `aidlc-spec-driven`, then continue quick-spec unless the user accepts the switch. Never change workflows silently.

If you are unsure between vibe and quick-spec, the deciding question is: **"Will anyone ever read this document again?"** If no, use vibe. If yes, use quick-spec.

If you are unsure between quick-spec and spec-driven, the deciding question is: **"Would a single approval gate over one document genuinely be enough, or does the user need to sign off separately on what to build, how to build it, and the task breakdown?"** If a single gate is enough, use quick-spec.

## Quick-Spec CLI

Use `scripts/quick_spec_cli.py` to scaffold the spec (the execution-time checkbox commands are documented in `references/task-execution.md`):

```bash
python3 .claude/skills/aidlc-quick-spec/scripts/quick_spec_cli.py init FEATURE_SLUG
```

The CLI resolves the AI-DLC docs root in this order:

1. explicit `--docs-root`
2. `.mtv-aidlc/extension-config.json` `aidlcDocsPath`
3. `aidlc-docs`

Do not manually copy `assets/spec-template.md`; run `init`, then replace scaffold placeholders with real spec content.

## Workflow

Eight steps to an approved spec, then execution. Steps 1–6 shape and write the spec, Step 7 is subagent review, Step 8 is the single user approval gate. **After approval, read `references/task-execution.md` and follow it** — task execution and code review live there, not here.

### Step 1: Load Foundation Context

Resolve the AI-DLC docs root using the same precedence as the CLI, then read foundation docs from `{aidlc-docs-root}/foundation/` if they exist:

- `project-overview-pdr.md`
- `system-architecture.md`
- `codebase-summary.md`
- `code-standards.md`
- `uiux-guideline.md`

If some or all are missing, continue with the user's request and codebase context, and note in the spec that foundation context was unavailable. Do not block the workflow on missing foundation.

### Step 2: Analyze the Codebase

Before shaping the spec, do enough investigation to write it accurately:

- Find relevant files with Glob/Grep
- Read the files the change will touch
- Identify the existing patterns the change should follow
- Identify the actual file paths and line ranges that will be modified

This step is what separates quick-spec from vibe. Vibe can wave at "the login form"; quick-spec needs to write `apps/web/src/components/LoginForm.tsx:42-78` in the spec, because the spec is a real document someone may read in the future.

### Step 3: Understand the Requirements

Before designing anything, decide whether the requirements can be written without guessing. Use foundation context and codebase analysis to find anything unclear or ambiguous that would change the spec content or execution plan. The spec should not guess at behavior the user has not confirmed.

If anything spec-shaping is unclear, ask before moving on. Ask one focused question at a time, starting with the unknown most likely to change scope, behavior, constraints, files, or task order. Use the structured question tool for finite choices, offer 2-4 concrete options, and mark the recommended option with `(Recommended)`; use free text only for genuinely open answers.

Keep questions concrete and spec-shaping:

- "Should this apply only to the admin page, or also to the public profile page?"
- "When validation fails, should the form block submit or wait for the server response?"

Ask only what is needed to write testable requirements and accurate tasks. If the user already provided enough detail, continue.

### Step 4: Design the Solution

With requirements understood, work out the technical design — the solution, not a menu of approaches. Quick-spec changes live inside an existing codebase, so the design is mostly discovered, not invented: follow the patterns Step 2 found in the area being changed.

- State how the change works technically: which existing pattern/hook/module it extends, what data flows where, what state or storage changes, how errors surface
- Follow existing patterns in the area. Deviating from them is a design decision that needs a reason recorded in the spec
- Where the code being touched has problems that affect this work — a tangled function, unclear boundaries in the exact area being changed — include the targeted improvement as part of the design, the way a good developer improves code they're working in. Record it as a design decision with its reason
- Do not propose unrelated refactoring; stay focused on what serves the current goal
- If a design decision is unclear or genuinely needs the user's confirmation (e.g., "extend `useAuth` vs. add a small storage helper" changes the file structure), ask — same one-question-at-a-time, structured-choice style as Step 3, with your recommendation marked. Do not silently pick when the user would reasonably care
- Then **present the design** to the user conversationally: a short summary of the solution and any decisions confirmed along the way. Present it and continue into Step 5 without waiting for acknowledgment — it is a sanity check the user can interrupt, not a formal gate; the single approval gate is Step 8, on the written spec

If the design exceeds the normal boundary, apply the scope rule above: recommend the upgrade and explain the risk. If the user keeps quick-spec, continue with one document and make the Design and Tasks complete enough for the larger scope.

### Step 5: Plan the Implementation

Turn the design into an execution plan a skilled engineer with zero context for this codebase could follow. Two parts, in order:

**File structure first.** Map which files will be created or modified and what each is responsible for — this is where decomposition gets locked in. Each file has one clear responsibility; in existing codebases, follow the established structure rather than restructuring.

**Then bite-sized tasks.** Each task is the smallest unit with its own verification, sized at 2–5 minutes of real work per step:

- Exact file paths with line ranges for modifications (`src/hooks/useAuth.ts:31-45`), exact paths for creations
- Each task declares which requirement IDs it implements (`Implements: 1.1, 2.1`). This closes the traceability loop: a criterion no task claims is a coverage gap, and a task claiming no criterion is scope creep — both should be caught before review, not by it
- When later tasks consume what earlier tasks produce, add an `Interfaces:` block naming the exact functions, parameters, and return types — the engineer executing Task 4 may not re-read Task 2
- Every task ends with a verification step: the exact command and its expected result. Use the project's real lint/build/test commands (from `codebase-summary.md` or package config); write test steps only where the project actually tests that area
- Fold setup, config, and scaffolding into the task whose deliverable needs them; split only where the user could meaningfully reject one task while approving its neighbor

### Step 6: Write `spec.md`

Scaffold `{aidlc-docs-root}/specs/{feature-kebab-case}/spec.md`:

```bash
python3 .claude/skills/aidlc-quick-spec/scripts/quick_spec_cli.py init FEATURE_SLUG
```

Then replace every scaffold placeholder with the real content produced by Steps 3–5: Goal, Requirements, Design, File Structure, and Tasks. The CLI renders the template from `assets/spec-template.md`, adds quick-spec metadata frontmatter, and does not overwrite an existing `spec.md`.

Naming: feature directory uses kebab-case (`user-profile-edit`, not `User Profile Edit`).

Before handing the spec to review, do a quick inline scan for the placeholder patterns listed in *No Placeholders* below and fix every match — do not spend reviewer time on mechanical misses.

### Step 7: Spec Review by Subagents

Fresh eyes catch what the author cannot. Spawn two review subagents **in parallel**, each with a scoped mandate:

- **`ai-assistant-product-owner`** — reviews the business side: Goal and Requirements (testability, coverage of the user's ask, trace IDs, missing edge cases the user mentioned)
- **`ai-solutions-architect`** — reviews the technical side: Design, File Structure, and Tasks (pattern fit with the analyzed codebase, path accuracy, task completeness against requirements, no-placeholder compliance, quick-spec scope check)

Each subagent prompt must be self-contained: point it at `references/spec-review.md` for its role's checklist, the spec file path, and the key files from Step 2 it needs to verify claims against. Ask each to return **PASS** or a concrete findings list (what is wrong, where, why it matters).

Then:

- Fix findings inline in `spec.md`; if a reviewer raises an upgrade trigger, recommend the upgrade, but continue when the user has explicitly chosen quick-spec
- Re-spawn a reviewer only if its findings forced substantive changes (scope, design, or task restructuring — not wording), and at most one re-review round per reviewer. Two rounds without convergence means the spec has a real problem to raise with the user, not a polishing problem

If subagent spawning is unavailable in the current session, run both checklists from `references/spec-review.md` yourself as an explicit self-review pass, and say so.

### Step 8: User Review Gate

With subagent review passed, **stop** and ask the user to review the written spec:

> "Spec written to `{path}` and reviewed ({reviewed-by}). Please review — say 'approved' or tell me what to change before I start implementation."

Fill `{reviewed-by}` with what Step 7 actually did — "product-owner + solutions-architect subagents" when they ran, or "self-review, subagents were unavailable" on the fallback path. Say what happened, not what usually happens.

Wait for explicit approval ("yes", "approved", "looks good") before doing any implementation work. This is the load-bearing process decision of the skill: do not proceed while the spec is still being debated — fixing a written spec costs more than re-running the conversation.

If the user requests changes, apply them, re-run the affected reviewer from Step 7 only for substantive changes, and return to this gate.

On approval, update the spec's status from `Draft` to `Approved` in both places it lives — the frontmatter `status:` field (what the CLI and other AIDLC tooling read) and the body `**Status:**` line (what humans read) — and bump the frontmatter `updated:` date. A spec stuck at `Draft` after everyone approved it misleads whoever checks later.

### After Approval: Execute

Read `references/task-execution.md` completely before editing implementation files. It resolves an explicit inline or subagent instruction without another question, asks once when the approach is unspecified, routes to the matching playbook, and covers pre-flight checks, verification, conditional `aidlc-code-review`, and resume behavior.

## Spec Document Structure

Use `scripts/quick_spec_cli.py init` as the scaffold entrypoint. It renders `assets/spec-template.md` as the single source for the exact `spec.md` skeleton. The five sections, with their purpose:

- **Goal** — one sentence. What this feature does for the user (or system) and why now.
- **Requirements** — traceable acceptance criteria grouped only by relevant categories. Each item is independently testable, uses the shallowest clear trace ID depth (`1`, `1.1`, or `1.1.1`), and avoids paragraphs of prose. Keep IDs stable during revisions; no checkbox markers here — checkboxes are reserved for Tasks.
- **Design** — the technical solution from Step 4: how it works, which existing patterns it follows, and any decisions confirmed with the user (with the one-line reason).
- **File Structure** — exact paths to be created or modified, with one-line responsibilities. This is where decomposition gets locked in.
- **Tasks** — bite-sized checkboxed steps from Step 5. Each task is 2–5 minutes of real work, traces to requirement IDs via its `Implements:` line, has a clear verification step, declares its `Interfaces:` when other tasks depend on it, and contains the actual content the engineer needs (no placeholders).

### No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" without naming the specific behavior or assertion
- "Similar to Task N" without restating the concrete action — the engineer may be reading tasks out of order
- Vague steps that do not identify the concrete file, behavior, or implementation target
- References to types, functions, or methods not defined in any task

Code snippets are optional. Include a snippet only when prose would leave room for materially different implementations: exact contracts, new public shapes, non-obvious branching logic, validation rules, integration keys, data transforms, error mappings, surgical replacements, or test assertions.

If a task can't be written without a placeholder, the spec isn't ready — investigate further (Step 2) or ask a focused question (Step 3/4), then come back.

## Upgrading In Place to `aidlc-spec-driven`

The reason quick-spec lives at `{aidlc-docs-root}/specs/{feature}/` is so a spec that grows mid-flight does not need to be moved or renamed. The upgrade is a file split:

1. From `spec.md`'s **Requirements** section, create `requirements.md` (expand trace ID depth only if useful).
2. From `spec.md`'s **Design** + **File Structure** sections, create `design.md`.
3. From `spec.md`'s **Tasks** section, create `tasks.md` (preserve the checkbox state).
4. Delete `spec.md`, or archive it as `spec-original.md` for traceability.
5. Hand off to `aidlc-spec-driven`; it detects the existing files and resumes at the appropriate phase.

This upgrade is the explicit escape hatch — taking it is not a failure of the skill, it is the skill working as designed.

## Critical Rules

1. **One approval gate.** After the spec passes subagent review, stop and wait for explicit user approval. Do not write code first and ask later.
2. **One document; user owns the scope choice.** Keep Goal, Requirements, Design, File Structure, and Tasks in `spec.md`. When scope exceeds the recommended boundary, recommend `aidlc-spec-driven` but do not force the switch; an explicit quick-spec choice wins.
3. **Design is a solution, not a menu.** Follow existing codebase patterns; confirm unclear decisions with the user; record the reasoning.
4. **Subagent review before user review.** The user's approval time is the most expensive resource in the loop — spend reviewer subagents first so the user reviews a clean spec.
5. **No placeholders in tasks.** A task with `// TODO: handle errors` is a plan failure — fix it before requesting review or approval.
