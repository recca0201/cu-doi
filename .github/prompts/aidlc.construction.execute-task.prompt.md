---
description: Execute individual coding tasks from approved implementation plan
---

---
description: Execute individual coding tasks from approved implementation plan
argument-hint: [task]
---

# /aidlc.construction.execute-task

**Purpose**: Execute individual coding tasks from approved implementation plan

**Active Agent**: ai-orchestration-engineer
**Primary Skill**: aidlc-spec-driven
**Review Agent**: ai-orchestration-engineer
**Review Skill**: aidlc-code-review

## Input

<task>$ARGUMENTS</task>

**Process**:

1. Invoke skill `aidlc-spec-driven` (Phase 4 - Execution) before implementing.
2. Before implementation, read the complete `aidlc-spec-driven/references/phase-4-execution.md`, required spec/foundation/UI artifacts, and—when subagent-driven execution is selected—the complete `phase-4-subagent-execution.md`.
3. Resolve execution scope before editing:
   - Unit/spec slug and `aidlc-docs/specs/{unit}/` path
   - Requested task number/range
   - Task type: FE-heavy UI, UI, backend, integration, or documentation-only
   - Required spec and foundation artifacts
4. Resolve the approach without asking (subagent-driven by default) — first match wins:
   - Explicit `inline`, `in this session`, or `do not spawn implementation subagents` wording selects inline execution; explicit `subagent`, `use implementer subagents`, or `delegate implementation` wording selects subagent-driven execution. Wording always wins over config.
   - Otherwise run `python3 .claude/skills/aidlc-spec-driven/scripts/spec_workflow.py execution-approach` and follow its JSON `approach` (the injected `Task Execution Approach` line is only a preview and may be absent).
   - A config `inline` value executes inline in the active session; missing or unusable config defaults to subagent-driven.
   - When subagent-driven is selected, announce it and spawn one `ai-orchestration-engineer` implementer subagent per Phase 3 task group, one at a time in sequence.
   - If subagent-driven is selected but delegation is unavailable, announce the inline fallback. If the user explicitly required subagents, stop and ask instead; the separate review gate still applies.
5. For FE-heavy UI work:
   - Read `mockup.html`, available `uiux-guideline.md`, and referenced Figma artifacts.
   - Identify the design system and use `magenta-mds` when applicable.
   - Define layout, component/token mapping, breakpoints, and required states from the approved source.
   - Put these obligations in subagent prompts; visual verification remains coordinator-owned.
6. Execute only the requested scope and preserve unrelated changes:
   - Subagent-driven (default): pre-flight once, then per group capture the baseline, select an explicit model, spawn the implementer with full group context, scope-check and re-run validation, and resolve scope or validation failures before continuing. The coordinator writes no implementation code and spawns no per-group reviewer.
   - Inline (opt-in): implement in the active session.
7. Create a verification checklist and run Phase 4 verification, including UI gates when applicable:
   - Lint, tests, build/type-check, and runtime/smoke
   - Design-system component/token alignment and rendered layout fidelity
   - Desktop/mobile responsiveness and specified empty/loading/error/disabled/focus/hover states
   - Browser comparison evidence; if capture is unavailable, request screenshots or record an explicit skip reason
8. Capture the broad-review handoff:
   - Project root, spec path, and executed task range
   - Git range/worktree mode, changed files, and excluded unrelated changes
   - Verification evidence and applicable UI/mockup evidence
   - In subagent mode: model selection, per-group spawn outcomes, scope checks, and coordinator validation
9. After code changes pass full verification, spawn a fresh `ai-orchestration-engineer` subagent with an explicit model for broad `aidlc-code-review`. If delegation is unavailable, hand evidence to a parent or leave the scope `verified-pending-review` and unchecked.
10. The broad reviewer loads `aidlc-code-review`, reviews only, and does not modify code or `tasks.md`.
11. Resolve blocking findings per the selected approach—one fixer with the complete findings list in subagent mode—then rerun affected verification and broad review.
12. If execution pauses after a coordinator-validated subset, run full verification and broad review for that subset when possible; otherwise leave it `verified-pending-review` and unchecked.
13. Update `tasks.md` only after verification and broad review have no blockers. Documentation-only/no-code work may skip review explicitly; skipping review for code leaves checkboxes unchecked.
