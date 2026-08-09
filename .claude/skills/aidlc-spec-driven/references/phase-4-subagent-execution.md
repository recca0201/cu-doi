# Phase 4: Subagent-Driven Execution

Read this playbook completely after `references/phase-4-execution.md` routes implementation through delegated task-group execution. The shared Phase 4 rules still apply: approved-artifact reads, coordinator-owned verification, the final review gate, and checkbox completion remain in `phase-4-execution.md`.

Act as the coordinator. Spawn one fresh `ai-orchestration-engineer` implementer subagent per task group, one at a time in sequence; scope-check and verify every return before spawning the next. Do not write implementation code yourself. If delegation is unavailable, announce the direct-execution fallback; if the user explicitly required delegation, stop and ask instead.

Execute continuously. Do not pause between clean groups to ask whether to continue. Pause only for a blocking contradiction, missing context that cannot be recovered locally, a scope change requiring approval, or completion of the requested scope.

## Pre-Flight Review

Before the first spawn, scan all requested task groups once for:

- contradictions between `tasks.md`, `requirements.md`, and `design.md`
- task groups that require incompatible interfaces or execution order
- references to files, functions, or contracts that plainly do not exist
- work that materially exceeds the declared `Files:` entries

If the scan finds blocking conflicts, present them as one batched question with the conflicting artifact text and stop before implementation. If it is clean, proceed without commentary. Implementation-time discoveries still use the blocker and scope-change rules below.

## Implementation Unit

The Phase 3 task group is the default handoff unit. Its sub-tasks share files and interfaces and should land as one coherent increment. Include all unchecked sub-tasks in the group, in order.

Adjust the unit only when:

- the user narrows the requested scope to one or more sub-tasks
- a resumed group has completed sub-tasks, in which case include only unchecked work
- a flat plan has no groups, in which case batch consecutive tasks that share files or a design section
- a group is too large for one focused context, in which case split only at sub-task boundaries

Never spawn implementation subagents in parallel. Complete implementation, scope checks, validation, and any correction loop for one group before spawning the next.

## Model Selection

Always select a model explicitly when the harness supports per-spawn selection. Explicit user selection wins. Do not hard-code vendor-specific model names in this skill; resolve the required capability against the models available in the current harness.

| Observable work | Capability |
| --- | --- |
| Fully specified mechanical change, isolated scope, one or two files | Economical implementation capability |
| Multi-file implementation, integration, debugging, or prose-based task text | General implementation capability |
| Architectural judgment, security-sensitive behavior, schema migration, concurrency, or broad system impact | Highest available reasoning capability |

Use general capability as the floor for implementers working from prose rather than exact implementation text. Use the highest available reasoning capability for the final broad review.

Pass the resolved model identifier in the spawn tool call. If explicit selection is unavailable, report that the inherited model was used; do not claim that the workflow selected it.

## Per-Group Loop

For each pending group, in plan order:

1. Capture the worktree baseline, allowed files, and pre-existing changes the group must preserve.
2. Select the implementation model from the observable work.
3. Spawn the group's fresh `ai-orchestration-engineer` implementer subagent with the prompt contract below.
4. Resolve its status before continuing.
5. Compare the worktree with the baseline and allowed-file union.
6. Re-run the group's validation commands yourself.
7. Resolve scope or validation failures through one correction subagent when needed.
8. Record the group as coordinator-validated, then continue.

## Implementer Prompt

Use a fresh or isolated subagent context when the harness supports it. Make every implementer prompt self-contained regardless of inherited context; include the contract below and omit session history or prior-group play-by-play. Point the implementer at the ground-truth documents rather than paraphrasing them.

```text
SPAWN CONFIGURATION
subagent_type: ai-orchestration-engineer
model: [MODEL — REQUIRED: choose per "Model Selection" above; omitting it
        silently inherits the session model, which may be more expensive than
        this task requires]

PROMPT
Implement task group {G} — "{group title}" — of the approved spec `{spec-name}`.

Work from: {project-root}

You are executing ONE group of related tasks as a scoped implementer. Do not
load the aidlc-spec-driven skill, do not spawn review subagents, and do not
edit tasks.md — the coordinator owns the checkboxes and the review gate.

## Ground Truth (read before coding)
- {docs-root}/specs/{spec-name}/requirements.md — the criteria this group
  cites: {union of Reference IDs from the sub-tasks}
- {docs-root}/specs/{spec-name}/design.md — read: {relevant section(s)}
- [UI groups] {docs-root}/specs/{spec-name}/mockup.html — authoritative design
  tokens, component structure, interaction states
- [when available] {docs-root}/foundation/code-standards.md and
  codebase-summary.md — follow their conventions
[If this group consumes a prior group's output: the exact interfaces
(signatures, types, paths) as they now exist on disk.]

## Your Tasks (from tasks.md — follow verbatim, in order)
[Full text of every unchecked sub-task in the group: {G}.1, {G}.2, … —
each with its Reference, Files, steps, Tests, Validate with]

## Constraints
- Execute the sub-tasks in the listed order. Run each sub-task's validation
  command as you complete it and record the result before moving to the next.
- Touch only files in your sub-tasks' Files lists. Do not fix, refactor, or
  "improve" code outside this group, even if you notice problems — report
  them instead.
- Follow the existing patterns in the code you touch.
[FE-heavy UI groups add:]
- mockup.html is the source of truth for tokens, component variants, and
  interaction states; do not infer them from design.md alone.
- Use confirmed design-system components/props; implement all specified
  empty/loading/error/disabled/focus/hover states. Visual/browser
  verification is done by the coordinator — do not claim visual alignment.

## If Anything Is Unclear

Stop and return `NEEDS_CONTEXT` before coding when:

- The task requires an architectural decision with multiple valid approaches.
- Required code or context remains unclear after focused investigation.
- You are uncertain that the proposed approach matches the approved design.
- Continued file exploration is not producing clarity.

Return `BLOCKED` mid-group when implementation requires unplanned restructuring,
scope expansion, or files outside the task's `Files:` list.

Report the specific question or mismatch, what you tried, what you need, and
which sub-tasks are already done. Stop and report rather than guess.

## Before Reporting: Self-Review
Check with fresh eyes: every sub-task fully implemented, nothing extra built
(YAGNI), names accurate, existing patterns followed, every validation actually
run. Fix what you find, then report.

## Report Back (short — a few header lines + 1–2 lines per sub-task)
- Overall status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Per sub-task: {G}.n — status; validation command + result
- Files changed
- Concerns, if any (for BLOCKED/NEEDS_CONTEXT: the sub-task, the specific
  question or mismatch, what you tried, what you need)
```

For FE-heavy UI groups, the implementer prompt must include `mockup.html` and the applicable UI/design-system sources, required component and token mappings, responsive breakpoints, interaction states, and the visual checks that remain coordinator-owned.

## Handle Implementer Status

Treat every report as an unverified claim.

- **DONE** — run scope and validation checks, then continue.
- **DONE_WITH_CONCERNS** — resolve correctness and scope concerns before continuing; carry non-blocking observations into the final review handoff and report.
- **NEEDS_CONTEXT** — provide the missing context and continue the same agent when supported; otherwise spawn again with the added context and the same capability.
- **BLOCKED** — classify the cause before spawning again:
  1. context gap → add context and use the same capability
  2. insufficient reasoning → select higher capability
  3. oversized group → split at a sub-task boundary
  4. incorrect approved artifact → stop at the specification-change gate

Never send the same failed prompt unchanged. Never fix implementation code in the coordinator context.

## Scope and Validation Checks

- **Scope** — compare the worktree to the baseline and allowed-file union. Preserve pre-existing hunks exactly and list untouched dirty files as excluded unrelated changes.
- **Validation** — re-run every group validation command. The implementer's reported result is context, not evidence.

Resolve scope breaks as follows:

| Case | Resolution |
| --- | --- |
| Unnecessary extra change | Spawn a scoped correction subagent. Never restore or reset a pre-dirty file. |
| Necessary minor supporting file | Add it to the task's `Files:` list as a minor clarification and mention it to the user. |
| Necessary material expansion | Stop, show the exact scope change, and request approval. |
| Approved artifact contradicts the codebase | Stop with BLOCKED status and use the specification-change gate. |

## Per-Group Review Behavior

Do not spawn a review subagent after each group. As in quick-spec execution, coordinator scope checks and re-run validation gate progression. Resolve failures through one scoped correction subagent and re-run the affected checks before continuing. The mandatory broad review remains at the executed-scope boundary.

## Scope Boundary

When every requested group is coordinator-validated, or execution must pause after a validated subset:

1. Run the full step-4 verification sequence over the resolved subset yourself — lint, tests, build/type-check, runtime/smoke, and applicable UI verification. This is the same MANDATORY gate as inline mode (`phase-4-execution.md` § 4); the coordinator runs it, not the implementer.
2. Spawn a fresh broad reviewer over the whole executed scope to check cross-group contracts, integration, and overall approved-artifact coverage.
3. Resolve final findings with one fixer carrying the complete list, then re-run affected verification and broad review.
4. Update `tasks.md` only after full verification and the broad review have no blockers.
5. Report per-group status, baseline and scope evidence, model-selection evidence, validation, broad review, and excluded changes.

If a validated subset cannot reach the broad review gate, leave its checkboxes unchecked and report it as `verified-pending-review`.
