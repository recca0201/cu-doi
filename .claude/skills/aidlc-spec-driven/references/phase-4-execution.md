# Phase 4: Task Execution

**Goal**: Execute coding tasks from approved plan

> **⚠️ CRITICAL: Read this COMPLETE file before taking ANY action. Do not skim or read partially. Understanding all constraints and workflows is mandatory before proceeding.**

## Execution Rules

**Roles and the two execution approaches**:
- **Subagent-driven (default)** — the approach unless step 2 resolves otherwise. The active session acts as coordinator: it spawns one `ai-orchestration-engineer` implementer subagent per task group, one at a time in sequence, verifies returns, runs the verification gates, and owns `tasks.md`. The coordinator does not write implementation code. `references/phase-4-subagent-execution.md` owns the coordination playbook.
- **Inline (opt-in)** — selected by explicit user wording or workspace config (see step 2). The active session executes code changes itself, runs verification, and fixes blockers.

**Git ownership**: Phase 4 produces verified worktree changes and never stages, commits, amends, switches branches, rewrites history, or runs reset/restore/checkout/revert/clean operations. Implementers, fixers, and reviewers also must not edit `tasks.md`. Committing is a separate action performed only after an explicit user request outside this workflow.

1. **Pre-Execution Requirements**

   Read the spec files in full before executing any task — code written from a partial read of the specs is how implementations drift from what was approved, and the drift only surfaces at review or in production:
     - `aidlc-docs/specs/{spec-name}/requirements.md` - Ground truth for what to implement
     - `aidlc-docs/specs/{spec-name}/design.md` - Ground truth for how to implement; for UI tasks read the `§ UI Design Specification` section carefully — design tokens, color variables, spacing, typography defined there must be used exactly in code
     - `aidlc-docs/specs/{spec-name}/tasks.md` - Ground truth for implementation sequence
     - **If `aidlc-docs/specs/{spec-name}/mockup.html` exists**, read it before executing any UI-related task. It contains the authoritative component structure, design token identifiers, interaction states, accessibility markup, and Magenta MDS mappings that the design extract in `design.md` may summarize at a higher level. When code must reference a specific token, component variant, or interaction state, use the values in `mockup.html` as the source of truth rather than inferring them from `design.md` alone.
   - **SHOULD** also read the foundation docs for implementation context when available:
     - `aidlc-docs/foundation/code-standards.md`
     - `aidlc-docs/foundation/codebase-summary.md`
     - `aidlc-docs/foundation/uiux-guideline.md`
   - If foundation docs are missing, continue with the approved spec documents and current codebase state, and mention the missing foundation context in the execution report when it affects confidence.

2. **Resolve Execution Approach (subagent-driven by default)**

   Resolve in this order — the first match wins, then stop:

   1. **Explicit prompt wording.** `inline`, `in this session`, `active session`, or `do not spawn implementation subagents` selects inline. `subagent`, `use implementer subagents`, `delegate implementation`, or equivalent wording selects subagent-driven. Explicit prompt wording always wins over config.
   2. **Workspace config, resolved by the script:**

      ```bash
      python3 .claude/skills/aidlc-spec-driven/scripts/spec_workflow.py execution-approach
      ```

      Prints the resolved `approach` and its `source` as JSON. Always run it — the injected `Task Execution Approach` context line is only a preview and is absent in spawned sessions or after compaction. If the script is unavailable, read `taskExecution.approach` from `.mtv-aidlc/extension-config.json` directly (walk upward from cwd).
   3. **Default: subagent-driven.** Only when step 2 found no usable config value.

   - Do not ask the user to confirm the approach in either direction.
   - Announce the resolved approach and source in one line inside the loaded-references statement — "Executing inline (config)" or "Executing group-wise via implementer subagents (default) — say 'inline' to switch" — then start; it is not a question. Re-run the script after compaction or resume.
   - Before the first spawn, read `references/phase-4-subagent-execution.md` completely — it owns the implementation unit (the Phase 3 task group), implementer prompt contract, scope checking, and return handling. The verification, review, and completion sections below apply to both approaches; in subagent mode the coordinator owns all of those gates.
   - Forced fallbacks to inline, always announced, never silent: delegation is unavailable, including when the current harness or parent contract disallows nested delegation. Exception: if the user explicitly demanded subagent execution and it cannot be honored, stop and ask rather than silently changing approach (a config- or default-selected `subagent` falls back with an announcement; it does not stop).

3. **Task Execution Process**
   - Resolve the exact task scope before editing: requested task number(s), unit slug, affected requirements, and whether the work is FE-heavy UI, UI, backend, integration, or documentation-only
   - If a task has sub-tasks, execute them first
   - Execute tasks as requested by user (single or multiple)
   - Avoid unrelated cleanup while executing the task; preserve any existing user or parallel-agent changes outside the requested scope
   - Verify implementation against task requirements
   - Capture the diff scope to use for review: explicit git range if provided, otherwise current staged/unstaged changes related to the task
   - Route implementation by the resolved approach: subagent-driven (default) spawns one `ai-orchestration-engineer` implementer subagent per task group in sequence as defined in `references/phase-4-subagent-execution.md`, and the coordinator writes no implementation code; inline (opt-in) keeps implementation in the active execution session

   **FE-heavy UI classification**:
   Treat a task as FE-heavy UI when it creates or changes visible screens, layouts, complex components, routes, dialogs/drawers, responsive behavior, interaction states, or design-system styling. If a task touches only non-visual data wiring but indirectly affects UI state, classify it as UI and run the relevant state checks.

   **Frontend/UI task protocol (required for FE-heavy UI tasks)**:
   The checklist below binds whoever writes the UI code — the active session in inline mode, the implementer subagent in subagent-driven mode (embed these obligations in the implementer prompt per the playbook). The visual verification gates in step 4 stay coordinator-owned in both modes.
   - Before coding, read the UI source of truth in this order when available: `mockup.html`, `design.md § UI Design Specification`, and `uiux-guideline.md`. `mockup.html` is the source of truth; a missing value is a handoff gap (next bullet), not a reason to re-read the Figma extraction. Preview/child-frame images may serve as a visual baseline when present.
   - If requirements or design reference a supported Figma URL but `mockup.html` is missing for a FE-heavy task, stop and ask whether to run the UI handoff first or continue with explicitly limited visual confidence; do not hand-infer the design from memory
   - Identify the project design system from foundation docs and nearby code. If Magenta/MDS is in scope, invoke `magenta-mds` before implementing UI and use confirmed component props/tokens instead of invented variants or raw values
   - Write a short implementation checklist before editing: target layout structure, component mapping, token mapping, responsive breakpoints, and required empty/loading/error/disabled/focus/hover states
   - Prefer existing design-system components and project layout primitives over custom div-only structures unless the spec explicitly requires a custom composition
   - Preserve visual hierarchy from the approved design source: spacing rhythm, typography scale, alignment, grouping, width constraints, and primary/secondary action placement
   - Do not mark FE-heavy tasks complete based only on lint/tests/build; rendered UI must be inspected or the missing browser/design baseline must be explicitly reported

4. **Verification (MANDATORY)**

   **MUST** create a verification checklist with the available plan/todo mechanism (`TodoWrite` in Claude Code) **before the first code edit (inline) or first spawn (subagent-driven)**. If skipped, create it before running verification — do not produce a results table in isolation:

   ```
   - [ ] Run linter
   - [ ] Run unit tests
   - [ ] Run build
   - [ ] Run application and verify feature
   - [ ] (UI tasks only) Cross-check rendered output against `mockup.html`
   - [ ] (Frontend UI tasks only) Compare actual browser UI against the design image or screenshots
   - [ ] (FE-heavy UI tasks only) Verify design-system component/token mapping and responsive layout at mobile and desktop viewports
   ```

   **Verification sequence (execute in order; steps e–g apply only to UI work)**:

   a. **Linter** → Fix issues → Mark complete
   b. **Unit Tests** → Fix failures → Mark complete
   c. **Build** → Fix errors → Mark complete
   d. **Runtime** → Test feature, fix issues → Mark complete
   e. **UI handoff cross-check** (only when `mockup.html` exists and the task touches UI) → Confirm rendered components, design tokens, interaction states, and empty/loading/error states match `mockup.html` → Fix mismatches → Mark complete
   f. **Frontend visual check** (only when the task implements or changes visible UI) → Run the app in a browser when possible and compare the actual screen against the approved UI design image, Figma export, or provided screenshot → Fix material mismatches → Mark complete
   g. **FE-heavy UI quality gate** (only for FE-heavy UI tasks) → Verify design-system component/token mapping, layout structure, spacing, typography, interaction states, and responsive behavior at mobile and desktop viewports → Fix material mismatches → Mark complete

   **Finding commands**: Check `codebase-summary.md` for project-specific commands (lint, test, build, run scripts)

   **Critical rules**:
   - **MUST** complete every applicable step, or explicitly skip it with a reason, before marking a task complete
   - **MUST** fix every in-scope blocking issue found during verification; report unrelated failures without modifying out-of-scope work
   - **MUST** keep the verification checklist current with the available plan/todo mechanism

   **Subagent-driven mode**: this verification sequence is coordinator-owned. Implementer subagents run their tasks' targeted validation commands during their run, but those runs gate group progression only — the coordinator re-runs validation on each return and runs this full sequence at the executed-scope boundary. A subagent's claim that verification passed is not evidence; the coordinator's run is.

   **Adapting verification to your project type:**
   - No test framework configured: skip Unit Tests, note the gap, and recommend adding tests as a follow-up coding task
   - No build step: skip Build; if TypeScript, run `tsc --noEmit` for type-checking instead
   - Library or CLI (no runnable UI): replace Runtime step with a functional smoke test or integration test
   - Always run at minimum: Linter + whatever tests already exist

   Include any skipped steps and the reason in your completion report to the user.

   **Frontend visual verification fallback:**
   - If an approved UI design image, Figma export, or screenshot exists, use it as the visual baseline and compare it with the running browser UI after implementation.
   - If no design image is available, ask the user to provide the design image/screenshot before claiming visual alignment.
   - If browser automation or local app launch is available, capture the implemented UI screenshot and compare it with the design baseline image.
   - If the browser cannot be run automatically, ask the user to run/capture the implemented UI and provide two screenshots: the design/reference screenshot and the implemented UI screenshot.
   - If the user cannot provide screenshots, complete only the code/spec verification and clearly report that visual UI comparison was not performed.

   **FE-heavy UI evidence required in completion report and review handoff:**
   - UI source files/artifacts read (`mockup.html`, `design.md § UI Design Specification`, `uiux-guideline.md`, and any design screenshots/preview images used as a visual baseline)
   - Design-system decision and component/token mapping used; include whether `magenta-mds` informed the implementation when Magenta/MDS is in scope
   - Viewports checked, at minimum mobile and desktop when browser verification is possible
   - Visual comparison result, screenshot paths if captured/provided, or explicit reason comparison could not run
   - Remaining visual gaps or assumptions; do not claim Figma/design alignment when comparison was skipped

5. **Post-Verification Broad Code Review (REQUIRED FOR CODE CHANGES)**

   In subagent-driven execution, coordinator scope checks and re-run validation gate each task group before the next begins; no per-group review subagent is spawned. After implementation and full verification pass, spawn a fresh review agent and invoke `aidlc-code-review` over the complete executed scope. This broad gate checks cross-group contracts, integration, and overall alignment with the approved AIDLC artifacts. Inline execution uses this broad gate as its required review. Keep implementation and review responsibilities separate: reviewers review only.

   **Review cadence:**
   - Subagent-driven task group: coordinator scope checks and re-run validation before the next group; no separate review agent
   - Executed scope after full verification: one fresh broad review over the complete task number/range
   - Full-phase or full-unit review: one fresh broad review with the complete scope
   - Documentation-only or no-code tasks: code review can be skipped and noted explicitly

   **Purpose:**
   - Validate implementation against `requirements.md`, `design.md`, `tasks.md`, and `mockup.html` (when it exists)
   - Check alignment with available foundation docs and code standards
   - Catch adversarial or contract-level issues before the task is considered done

   **Dedicated review agent handoff:**

   Running reviews in a separate session prevents the implementer from grading their own work and keeps review-only file reads out of the implementation context. Pass this handoff block to the review subagent:

   - Project root
   - Spec name (the same slug is called "unit" in Inception artifacts)
   - `aidlc-docs/specs/{spec-name}/` path
   - Scope: task number/range, full phase, or full unit
   - Git range (`BASE_SHA..HEAD_SHA`) or current staged/unstaged worktree mode
   - Changed files in scope
   - Excluded unrelated changes and reason
   - Verification evidence: lint, tests, build/type-check, runtime/smoke, UI cross-check when applicable
   - Whether UI files changed and whether `mockup.html` exists
   - For FE-heavy UI tasks: the FE-heavy UI evidence listed in step 4 — the same items required in the completion report
   - In subagent-driven mode: per-group spawn outcomes, model-selection evidence, and coordinator scope-check and validation evidence

   **Review delegation:**

   Use the current harness's subagent mechanism to spawn a fresh review-only agent with the handoff context above. When named subagent types are supported, use `ai-orchestration-engineer`. When model selection is supported, select from the review's scope, complexity, and risk. Instruct the agent to load `aidlc-code-review` only and not modify code or `tasks.md`.

   **If skipped:**
   - State why it was skipped in the completion report
   - Do not imply that review passed when it was not run
   - If the current session cannot delegate review, return the implementation and verification evidence to a parent session that can run the gate; if no review session is available, leave the scope verified-pending-review and do not update checkboxes

   **If review finds blockers:**
   - Critical Stage 2 findings and accepted Critical Stage 3 findings block task completion
   - Accepted Medium Stage 3 findings should be fixed before unit completion; defer only with explicit user approval
   - Fix ownership follows the approach: inline mode, the active session fixes directly; subagent-driven mode, spawn **one** fixer subagent with the complete findings list (per-finding fixers each rebuild context and cost more)
   - Every fixer reruns covering validation and returns the evidence
   - After fixes, re-run impacted verification commands and re-run the broad review before updating checkboxes

6. **Completion Protocol**
   - **MUST** complete all post-execution verification steps first
   - **MUST** complete `aidlc-code-review` for code-changing tasks before marking the task complete; documentation-only/no-code tasks may skip it explicitly
   - If the user explicitly skips review for code changes, honor the skip but report the scope as implemented and verified, not Phase 4 complete; do not update its checkboxes
   - Resolve every verification checklist item as passed or explicitly skipped with a reason
   - Update task checkboxes in tasks.md only after verification passes and the broad code review has no blocking findings, or after review is explicitly skipped for documentation-only/no-code tasks
   - Mark tasks complete with the workflow script (it validates the task number exists and reports if it was already done); fall back to the Edit tool (`- [ ]` → `- [x]`) if the script is unavailable:
     ```bash
     python3 .claude/skills/aidlc-spec-driven/scripts/spec_workflow.py complete {spec-name} {task-number}
     ```
   - Report completion status including verification results, broad review outcome, and excluded pre-existing changes

7. **Task Recommendations**
   - If user doesn't specify tasks, review task list
   - Recommend next logical tasks to execute
   - Execute based on user's preference

8. **Handling Questions**
   - User may ask about tasks without wanting execution
   - Provide information without starting tasks
   - Example: "What's the next task?" → Inform, don't execute

## Common Scenarios

**Scenario: Full-unit code review (all tasks complete)**
```
User: "Run the full-unit code review" (all tasks done)
→ Recognize scope is full-unit — do NOT run review inline
→ Spawn a fresh review-only subagent using the current harness
→ Provide the handoff context above with scope "full unit"
→ Instruct the subagent to load aidlc-code-review only
→ The review agent reviews only and must not modify code or tasks.md
→ Report to user that review has been delegated and what to expect
```
