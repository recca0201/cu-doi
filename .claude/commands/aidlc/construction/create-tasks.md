---
description: Create actionable task checklist for implementation from approved design
argument-hint: [design] [--task-template test-first|implement-with-tests|tests-later|custom]
---

# /aidlc.construction.create-tasks

**Purpose**: Create actionable task checklist for implementation from approved design

**Phase 3 Agent**: ai-orchestration-engineer
**Primary Skill**: aidlc-spec-driven

## Input

<design>$ARGUMENTS</design>

Optional `--task-template test-first|implement-with-tests|tests-later|custom` selects the Phase 3 task guidance template. If omitted, pass no template value so `aidlc-spec-driven` can read workspace config before defaults.

## Role

You are the main command runner — the "main session" in `aidlc-spec-driven/SKILL.md § Execution Contexts`. You orchestrate the Phase 3 planning subagent and own every gate. The contracts you enforce are defined once in the skill — cite them, do not restate them:

- `aidlc-spec-driven/references/phase-3-tasks.md` — Phase 3 workflow, task format and content rules, `## Next Steps` scaffold, approval loop
- `aidlc-spec-driven/SKILL.md § Template Resolution Contract` — task-template precedence

Do not draft or edit `tasks.md` inline for initial planning — that belongs to the Phase 3 subagent. Exception: question triage and validation-directed mechanical fixes (steps 4-5).

## Process

1. **Resolve the target spec (in this session).** Prefer an explicit `aidlc-docs/specs/{spec-name}/design.md`; otherwise infer `{spec-name}` or ask one clarification question (run `list` if the spec name is unknown). Extract `--task-template ...` only when explicitly present — treat it as workflow config, not design text, and never pass a default when the flag is omitted.
2. **Preflight (in this session).** Deterministic phase check — do not hand-inspect the spec folder:
   ```bash
   python3 .claude/skills/aidlc-spec-driven/scripts/spec_workflow.py status {spec-name}
   ```
   - Phase 1 or 2 (`requirements.md` or `design.md` missing) → stop and direct the user to `/aidlc.construction.refine-requirements` or `/aidlc.construction.create-design` — a plan built without an approved design gets redone.
   - Phase 4 (`tasks.md` already exists) → resume path: follow `SKILL.md § Modifying Approved Documents`; confirm whether the user wants to update the plan or move to `/aidlc.construction.execute-task`, and when updating, preserve completed `- [x]` items.
   - Phase 3 → continue. Preflight is orchestration-only — no foundation or codebase reads here; that grounding belongs to the planning subagent (step 3).
3. **Spawn the Phase 3 planning subagent**: `ai-orchestration-engineer`, invoking `aidlc-spec-driven` per its Execution Contexts — it reads `references/phase-3-tasks.md` completely plus the selected task-template guidance, produces `tasks.md` with its self-checks (including the `validate` self-check), and returns a concise summary separating **blocking** open questions (answer would materially change the plan) from non-blocking ones; it must not ask the user or run the approval loop. Pass: spec name, design and requirements paths, explicit `--task-template` only when provided, and any resume context from step 2. Always spawn — even if this session already gathered context, pass it as brief pointers in the prompt; never draft `tasks.md` inline.
4. **Validation gate (in this session).** Deterministic structure and coverage check — do not hand-verify acceptance-criteria coverage:
   ```bash
   python3 .claude/skills/aidlc-spec-driven/scripts/spec_workflow.py validate {spec-name}
   ```
   On `valid: false`: fix mechanical failures (frontmatter, missing `Reference:` lines, `## Next Steps` placement, numbering depth) in this session and re-run; when `uncovered-criteria` reveals missing planning work, re-spawn the Phase 3 subagent with the validation JSON instead of inventing tasks inline. Loop until `valid: true`.
5. **Triage returned questions (in this session).** If the subagent returned blocking questions, ask the user via AskUserQuestion (one call when supported), update `tasks.md`, and re-run step 4 if the edits changed structure or coverage. Non-blocking items stay visible for the approver.
6. **User approval.** Ask, per the Phase 3 approval loop: "Do the tasks look good?" Present a task-group overview, the validation result, and any non-blocking open questions. On requested changes: revise, re-run step 4, and ask again — loop until explicit approval. If gaps trace back to design or requirements, offer to return to that phase rather than patching the plan. Stop once approved — implementation starts with `/aidlc.construction.execute-task`, not here.
