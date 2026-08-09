# Phase 3: Implementation Planning

**Goal**: Create actionable task checklist for code implementation

> **⚠️ CRITICAL: Read this COMPLETE file before taking ANY action. Do not skim or read partially. Understanding all constraints and workflows is mandatory before proceeding.**
>
> **🚫 PLANNING ONLY: This phase produces DOCUMENTATION (tasks.md). Do NOT write, modify, or execute any actual implementation code. Coding begins in Phase 4.**

## Process

1. **Prerequisites**

   Read the spec files in full before planning — tasks derived from a partial read miss acceptance criteria, and the gap becomes unimplemented behavior:
   - `aidlc-docs/specs/{spec-name}/requirements.md` - Establishes ground truth for what to implement
   - `aidlc-docs/specs/{spec-name}/design.md` - Establishes ground truth for how to implement
   - **If `aidlc-docs/specs/{spec-name}/mockup.html` exists**, read it in full — it contains component-level UI details, interaction patterns, design tokens, states, and Magenta MDS mappings that are more granular than what `design.md` summarizes. Use it to ensure UI tasks reference the correct components, states, and tokens rather than relying solely on the design extract.

   If the user indicates design changes or new requirements while planning, return to that phase instead of patching the plan — `SKILL.md § Modifying Approved Documents` defines how; a task plan built on a shifting design gets redone.

   Also read the foundation docs from `aidlc-docs/foundation/` when available:
   - `code-standards.md` - Implementation patterns and conventions
   - `codebase-summary.md` - File structure and current implementation
   - `uiux-guideline.md` - UI component, layout, interaction, and accessibility expectations; read it whenever the approved requirements or design are primarily frontend, screen, component, navigation, or interaction oriented — plans that skip it collapse UI features into generic backend tasks

   If foundation docs are missing, continue from the approved requirements and design; do not block task planning on absent foundation context.

2. **Task List Creation**

   Run or read the selected task-template guidance before drafting — it defines the item-level shape the plan must follow. Add `--task-template ...` only when the prompt explicitly selects a task template; otherwise omit the flag so the script resolves config and defaults (per `SKILL.md § Template Resolution Contract`):
     ```bash
     python3 .claude/skills/aidlc-spec-driven/scripts/spec_workflow.py tasks-template {spec-name} [--task-template ...]
     ```
   - The script owns config fallback, custom template loading, and stdout guidance.
   - The script-owned metadata preamble in stdout is authoritative for frontmatter. With `{spec-name}`, it derives `source_artifacts` from the current spec folder's `requirements.md` and `design.md`; emit that frontmatter as the first bytes of `tasks.md`.
   - Do not paste `tasks-template` output directly into `tasks.md` — it is instructional guidance, and pasting it ships template boilerplate as the plan.
   - Create `aidlc-docs/specs/{spec-name}/tasks.md` with real project-specific tasks from the approved `requirements.md` and `design.md`, following the selected task-template guidance for item-level sequencing and fields while still satisfying the rules in this file.
   - Convert the feature design into a series of prompts for a code-generation LLM using this instruction:

     > Convert the feature design into a series of prompts for a code-generation LLM that will implement each step incrementally with appropriate testing. Prioritize best practices, incremental progress, and early validation, ensuring no big jumps in complexity at any stage. Make sure that each prompt builds on the previous prompts, and ends with wiring things together. There should be no hanging or orphaned code that isn't integrated into a previous step. Focus ONLY on tasks that involve writing, modifying, or testing code.

3. **Task Format**

   Format tasks as numbered checkbox items with a maximum of 2 hierarchy levels, numbering sub-tasks with decimal notation (1.1, 1.2, 2.1). Prefer simple structure over deep hierarchy — Phase 4 executes tasks one number at a time, so flat, discrete items resume cleanly. Use numbered `###` group headings when grouping improves readability, sequencing, or execution handoff; group titles do not need checkboxes, and short or naturally flat plans do not need groups at all.

   Every checkbox item carries a `Reference:` line citing granular criteria, not just user stories — e.g. `Reference: US-1 AC-2.3`. Use the story and criterion IDs exactly as the requirements document defines them (unit-prefixed schemes such as `US-CSA-05 AC-CSA-05.2.1` are equally valid). Phase 4 execution and code review trace implementation back through these IDs, so an item without them cannot be verified against requirements.

   These structural rules (frontmatter first, checkbox and `Reference:` format, ≤2 hierarchy levels, criteria coverage, `## Next Steps` last) are checked deterministically:

   ```bash
   python3 .claude/skills/aidlc-spec-driven/scripts/spec_workflow.py validate {spec-name}
   ```

   Run it as a self-check before finishing instead of hand-verifying, and fix reported errors before asking for approval. The gate applies to plans created or updated in this phase — never retroactively to legacy artifacts.

4. **Task Content and Sequencing**

   Each task must be actionable by a coding agent without additional clarification:
   - A clear objective involving writing, modifying, or testing specific code — scoped to concrete coding activities ("Implement X function", not "Support X feature")
   - The files or components to be created or modified
   - Additional implementation information as sub-bullets, without repeating detail already covered in the design document
   - Appropriate testing for the implemented functionality

   Sequence the plan as a series of discrete, manageable steps where each builds incrementally on the previous ones: validate core functionality early, leave no hanging or orphaned code, and end with wiring everything together. Assume all context documents (requirements, design, and `mockup.html` when present) remain available during implementation. Cover every aspect of the design that can be implemented through code — `validate` reports any acceptance criteria no task references.

   **For frontend-heavy work**, preserve the design's UI intent rather than collapsing it into generic backend or data tasks. Translate the approved design into explicit UI tasks covering the relevant mix of:
   - Screen, route, or container creation
   - Reusable component implementation or extension
   - State management or data-fetching integration
   - Styling or design-system wiring
   - Empty, loading, validation, and error-state handling
   - Accessibility or keyboard interaction work when called for by the design
   - Frontend tests that validate the intended user flow

   Sequence these so shared UI primitives and data seams land before screen assembly, then interaction states, then integration and verification.

5. **Excluded Task Types**

   Exclude non-coding tasks — every item must be completable by writing, modifying, or testing code:
   - User acceptance testing or user feedback gathering
   - Deployment to production or staging environments
   - Performance metrics gathering or analysis
   - Running application to test end-to-end flows (can write automated tests instead)
   - User training or documentation creation
   - Business process changes or organizational changes
   - Marketing or communication activities

6. **Document Format**

   Use this document wrapper for `tasks.md`. Apply the selected task-block shape inside `## Implementation Checklist`.

   ```markdown
   # Tasks: {Feature Name}

   ## Implementation Checklist

   ### 1. Data model and API setup

   - [ ] 1.1 Create core data models
     - Reference: US-1 AC-1.1, US-1 AC-1.2
     - Files: `models/feature.ts`, `models/feature.test.ts`
     - Implement interfaces and types
     - Tests:
       - Test file: `models/feature.test.ts`
       - Test cases: valid model construction; invalid field handling
     - Validate with `npm test models/feature.test.ts`

   - [ ] 1.2 Create POST /api/feature endpoint
     - Reference: US-1 AC-2.1
     - Files: `api/routes/feature.ts`, `api/routes/feature.test.ts`
     - Implement request validation and persistence
     - Tests:
       - Test file: `api/routes/feature.test.ts`
       - Test cases: valid create request; validation failure
     - Validate with `npm test api/routes/feature.test.ts`
   ```

7. **Next Steps Section**

   Ensure `tasks.md` ends with the following section **before** asking for user approval — it is part of the document the user approves, and appending it afterwards would silently modify an approved artifact. The `validate` self-check (step 3) confirms this section exists and is last.

   ```markdown
   ## Next Steps

   Once this task plan is approved, proceed to Phase 4: Task Execution.

   **What to do next:**
   1. Use the slash command: `/aidlc.construction.execute-task [task-number]`
   2. The agent will automatically read:
      - `requirements.md` - Feature requirements
      - `design.md` - Design decisions
      - `tasks.md` - This task list
      - `mockup.html` - HTML UI handoff (if present, read before any UI task)
      - `references/phase-4-execution.md` - Execution workflow instructions
      - Foundation docs for implementation patterns
   3. Tasks will be marked complete with checkboxes after execution

   **Example**: To execute task 1.1, use `/aidlc.construction.execute-task 1.1`
   ```

8. **Approval Loop**

   Ask the user: "Do the tasks look good?" Revise on any feedback and ask again after every iteration — the workflow is complete only after a clear approval statement (e.g., "yes", "approved", "looks good"). If planning reveals gaps in requirements or design, offer to return to that phase rather than patching the plan. Stop once the task document is approved.

   When running as a spawned subagent, skip this loop and return the concise summary instead — the parent session owns validation gates and user approval (see `SKILL.md § Execution Contexts`).

9. **Exit Criteria**

   The phase is done when:
   - User explicitly approves tasks with clear approval statement
   - `validate {spec-name}` reports `valid: true` — structure correct and all parseable acceptance criteria covered by tasks
   - Tasks are incremental, manageable, and build on each other
   - Each task is actionable by a coding agent without clarification
   - Foundation docs referenced for implementation patterns
   - No non-coding tasks included in plan
   - For frontend-heavy work, the plan includes concrete UI implementation tasks derived from the approved design (and `mockup.html` when present) rather than only generic integration work

## Phase Boundary

This phase ends when `tasks.md` is approved. Do not implement here — tell the user the plan is ready and hand off to Phase 4 (`references/phase-4-execution.md`); all planning artifacts (requirements, design) remain available during execution.
