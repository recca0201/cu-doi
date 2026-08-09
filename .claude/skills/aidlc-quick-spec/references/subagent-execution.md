# Subagent-Driven Execution

Use this playbook only after `references/task-execution.md` selects subagent-driven execution through explicit user wording or the one-time handoff. Delegation covers only the approved task scope.

Act as coordinator: spawn a fresh implementer per task, verify each return, and update the ledger. Do not write implementation code yourself. Apply the shared rules throughout. If spawning is unavailable, stop and ask whether to switch to inline; never switch silently.

Execute continuously; Step 8 approved the spec and the handoff selected the approach. Do not pause between tasks or post progress summaries. Pause only for a shared blocker, a scope break, or completion. After compaction or resume, trust the spec checkboxes and `git diff` over recollection.

## Implementer Role

Spawn every implementer as **`ai-orchestration-engineer`** when the harness supports named agent types. Otherwise state that role and its implementation contract explicitly in the prompt instead of inventing an unsupported agent-type argument.

Step 5 makes each task self-contained with exact paths, `Implements:`, `Interfaces:`, verification, and no placeholders. Pass that task text verbatim.

## One Implementer at a Time

Spawn one **`ai-orchestration-engineer`** implementer subagent per task, one at a time in sequence; never spawn implementation subagents in parallel. Quick-spec tasks commonly share files or consume earlier `Interfaces:`, so each task must land and be verified before the next prompt quotes the resulting code. The benefit is isolated context, not concurrency.

For each unchecked task, in spec order (Step 5 already encoded the dependency order):

1. Record the baseline: `git status --short`, `git diff --stat`, and the exact staged and unstaged diffs for every pre-existing dirty file. Name those changes in the implementer prompt so they are preserved rather than silently absorbed or overwritten.
2. Pick the model, compose the implementer prompt below, then spawn the subagent.
3. Fully resolve the return — checks, then checkbox — before spawning the next subagent. An unresolved concern compounds into every task built on top of it.

## Pick the Model When Supported

When supported, select the model explicitly from task complexity. Otherwise use the available subagent without inventing arguments; model selection must not block execution.

- Task text contains the complete code to write → transcription plus verification → cheapest tier
- Task described in prose within a well-specified single area → mid tier
- Task needs integration judgment across the spec's files → session model

Prefer sufficient capability for prose or integration-heavy tasks; repair turns cost more than a suitable first pass.

## Implementer Prompt

Use a fresh or isolated context when supported. Make the prompt self-contained regardless of inherited context and omit session history or prior-task play-by-play:

```
SPAWN CONFIGURATION
subagent_type: ai-orchestration-engineer
model: [MODEL — REQUIRED: choose per "Pick the Model When Supported" above;
        omitting it silently inherits the session model]

PROMPT
Implement Task N of an approved quick-spec.

You are executing ONE task as a scoped implementer. Do not load the
aidlc-quick-spec or aidlc-spec-driven skills, do not spawn review subagents,
and do not edit spec.md — the coordinator owns the spec's checkboxes and the
review gate.
This prompt contains your full requirements.

## Context
[2–4 sentences: the spec's Goal and Design summary — where this task fits.]
[If this task consumes another task's output: the exact Interfaces (signatures,
types) as they now exist on disk.]

## Existing Work to Preserve
[Pre-existing dirty files and their exact staged or unstaged changes that this
task must preserve, or `None`.]

## Your Task (requirements — follow verbatim)
[Task N's full text from spec.md: Implements, Files, Interfaces, all steps.]

## Constraints
- Touch only the files in your Files list. Do not fix, refactor, or "improve"
  code outside your task, even if you notice problems — report them instead.
- Follow the existing patterns in the code you touch.
- Preserve every pre-existing change listed above exactly; do not absorb,
  extend, overwrite, or revert it.
- Run the task's verification command yourself and capture the result.
- Leave changes uncommitted; do not stage or commit.

## If Anything Is Unclear

Stop and return `NEEDS_CONTEXT` before coding when:

- The task requires an architectural decision with multiple valid approaches.
- Required code or context remains unclear after focused investigation.
- You are uncertain that the proposed approach matches the approved spec.
- Continued file exploration is not producing clarity.

Return `BLOCKED` mid-task when implementation requires unplanned restructuring,
scope expansion, or files outside the task's `Files:` list.

Report the specific question or mismatch, what you tried, and what you need.
Stop and report rather than guess.

## Before Reporting: Self-Review
Check completeness, nothing extra built (YAGNI), scope, names, existing
patterns, and verification. Fix in-scope findings before reporting.

## Report Back (under 15 lines)
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Files changed
- Verification: exact command + result
- Concerns, if any (for BLOCKED/NEEDS_CONTEXT: the specific question or
  mismatch, what you tried, what you need)
```

## Handle Each Return

Treat every report as unverified. Before checking off a task: **scope** — compare the worktree with the baseline and `Files:` list, resolving any scope creep; **verification** — rerun the task's command yourself.

- **DONE** — checks clean → tick the checkbox, then spawn the next task's implementer.
- **DONE_WITH_CONCERNS** — resolve correctness or scope concerns through a fixer subagent or the Step 8 gate if the spec is wrong; carry observations into the completion report.
- **NEEDS_CONTEXT** — answer in the same agent when supported; otherwise add context and spawn again. Never proceed past its question.
- **BLOCKED** — change the context, model capability, or task split before spawning again; use the Step 8 gate if the spec is wrong. Never repeat an unchanged failed prompt.

Fixer subagents receive the task contract, findings, allowed files, and verification. If completion-time `aidlc-code-review` finds blockers, spawn one fixer with the complete list; the spec stays `In Progress` until the shared Completion steps pass clean.

## What Quick-Spec Deliberately Skips

Quick-spec skips per-task reviewers, separate ledgers, and report files. Spec checkboxes track progress; baseline and coordinator verification gate each task; conditional `aidlc-code-review` handles completion review. If per-task reviews become necessary, recommend full `aidlc-spec-driven` while honoring the user's workflow choice.
