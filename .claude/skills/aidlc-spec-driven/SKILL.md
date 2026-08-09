---
name: aidlc-spec-driven
description: >-
  Specification-driven development workflow for AI-DLC projects. Use this skill
  whenever the user is planning or executing work through `aidlc-docs/specs/*`:
  creating/refining requirements, running Construction Phase 2 design, creating
  implementation tasks, executing tasks from `tasks.md`, continuing an approved
  spec, or marking spec tasks complete. Do not use for simple bug fixes or small
  1-2 file changes; prefer `aidlc-vibe`. Do not use for medium-sized single-area
  features where one `spec.md` plus one approval gate would be enough; prefer
  `aidlc-quick-spec` (which lives at the same `aidlc-docs/specs/{feature}/` path
  and can be upgraded in place to this skill if scope grows).
metadata:
  argument-hint: "[spec-name|feature request|task number] [--template default|checklist|given-when-then-table|custom] [--design-template standard|lean|custom] [--task-template test-first|implement-with-tests|tests-later|custom]"
---

# AI-DLC Spec-Driven Development

Specification-driven workflow for structured feature development using AI-DLC methodology.

## Core Principles

- **User establishes ground-truths** - Wait for explicit approval ("yes", "approved", "looks good") before any phase transition
- **Natural guidance** - Guide through the process; don't announce workflow steps
- **Feature naming** - Use kebab-case (e.g., `user-authentication`)
- **Planning vs Execution separation** - Phases 1-3 are PLANNING ONLY. Do NOT write, modify, or execute any actual code until Phase 4.
- **Clarify before generating** - Resolve artifact-shaping ambiguities first, then generate rather than stalling for more input (per-phase detail in the phase reference)
- **Phase 4 discipline** - Subagent-driven by default: spawn one `ai-orchestration-engineer` implementer subagent per task group in sequence, with the coordinator scope-checking every return and writing no implementation code. Switch to inline execution (the active session implements, verifies, and owns `tasks.md`) only when the user explicitly asks for it or the workspace config selects it (`taskExecution.approach: "inline"` in `.mtv-aidlc/extension-config.json`, resolved via the script's `execution-approach` command). Mark checkboxes complete only after verification and, for code changes, a passing delegated `aidlc-code-review`. `references/phase-4-execution.md` and `references/phase-4-subagent-execution.md` own the protocol.

## Workflow Overview

**4-Phase Process** with approval gates: Requirements → Design → Tasks → Execution. Phases run sequentially — complete earlier phases before proceeding to later ones.

`aidlc-docs/` paths throughout this skill and its references mean the configured docs root: `aidlcDocsPath` from `.mtv-aidlc/extension-config.json` when set, otherwise `aidlc-docs/` at the workspace root. The workflow script resolves this automatically (override with `--docs-root`).

Foundation docs (`aidlc-docs/foundation/`: project-overview-pdr.md, system-architecture.md, codebase-summary.md, code-standards.md, uiux-guideline.md) are auto-referenced when available. If some or all are missing, continue with the user request, spec documents, and codebase context, and explicitly note that foundation context was unavailable rather than blocking the workflow.

Output: `aidlc-docs/specs/SPEC_NAME/`

## Workflow Script

`scripts/spec_workflow.py` commands:
- `init SPEC_NAME [--template default|checklist|given-when-then-table|custom]` - Create spec directory and scaffold requirements.md using the local requirements wrapper plus the selected or configured story block
- `status SPEC_NAME` - Check phase and status
- `list` - List all specs
- `design-template [SPEC_NAME] [--design-template standard|lean|custom]` - Print selected or configured Phase 2 design-template guidance to stdout (pass SPEC_NAME so the metadata preamble derives `source_artifacts`); use as drafting guidance, not final `design.md` content
- `tasks-template [SPEC_NAME] [--task-template test-first|implement-with-tests|tests-later|custom]` - Print selected or configured Phase 3 task-template guidance to stdout (pass SPEC_NAME so the metadata preamble derives `source_artifacts`); use as drafting guidance, not final `tasks.md` content
- `mockup-status SPEC_NAME [--figma-url URL]` - Print Phase 2 `mockup_status` as JSON, determined deterministically from `mockup.html` handoff metadata vs the Figma URL (vocabulary defined in `references/phase-2-uiux-handoff.md`); run this before deciding whether any Figma/UI handoff work is needed
- `execution-approach` - Print the resolved Phase 4 execution approach and its source as JSON (`taskExecution.approach` from config, else `inline`); run when no explicit prompt wording selects an approach
- `validate SPEC_NAME` - Deterministically check `tasks.md` structure as JSON (frontmatter first, checkbox/`Reference:` format, ≤2 hierarchy levels, acceptance-criteria coverage vs `requirements.md`, `## Next Steps` last); the Phase 3 gate to run before asking for plan approval — exit 0 when valid
- `complete SPEC_NAME TASK_NUM` - Mark a task checkbox done in `tasks.md`; the preferred completion mechanism, used only after Phase 4 verification and required delegated code review pass
- `progress SPEC_NAME` - Check completion %

## Mandatory Reference Loading

Do not treat this `SKILL.md` as enough detail to execute a phase. It is only the router. Before taking any phase-specific action, identify the active phase and read the matching reference file completely:

| Phase | Trigger | Required complete reference read |
| --- | --- | --- |
| Phase 1 | Create/refine `requirements.md`, run `init`, clarify requirements | `references/phase-1-requirements.md` |
| Phase 2 | Create/refine `design.md`, run create-design, discuss design approval | `references/phase-2-design.md` |
| Phase 3 | Create/refine `tasks.md`, run create-tasks, plan implementation | `references/phase-3-tasks.md` |
| Phase 4 | Execute task checkboxes, mark tasks complete, verify implementation | `references/phase-4-execution.md` (+ `references/phase-4-subagent-execution.md` before the first spawn when subagent-driven execution is selected) |

Reference loading rules — the phase references contain constraints that are deliberately not repeated here, so acting from this file's summaries alone means silently skipping rules:

- Read the full current-phase reference before editing artifacts, answering phase-process questions, spawning phase subagents, or executing phase work. Re-read it after context compaction, a long interruption, or any handoff/resume where you cannot confirm it is still loaded.
- Load the companion references named by the current phase reference; for Phase 4 this includes the spec/UI artifacts and, before delegated execution, `phase-4-subagent-execution.md`.
- Before substantial phase work, state in one sentence which phase reference and companion guidance were loaded; do not paste the reference content.

## Execution Contexts

The skill can run as the main session or as a phase subagent spawned by a command runner (for example, the Phase 2 design subagent in `/aidlc.construction.create-design`, or the Phase 3 planning subagent in `/aidlc.construction.create-tasks`). When spawned to produce a single phase artifact: produce the artifact with its self-checks, then return a concise summary with open questions — the parent session owns review gates and user approval. Phase references mark the steps that are main-session-only (see `references/phase-2-design.md § Execution Contexts`). If the current harness or parent contract disallows nested delegation or user interaction, keep those responsibilities in the parent; a spawned Phase 4 session announces the constraint and falls back to inline execution unless the user explicitly required subagents.

## Template Resolution Contract

Use one precedence rule for every template family:

1. Explicit user selection from CLI args or plain prompt wording
2. `.mtv-aidlc/extension-config.json` at the workspace root
3. Built-in default

Explicit prompt wording counts as selection. For example, "use checklist requirements" means pass `--template checklist`; "use the custom task template" means pass `--task-template custom`; "use standard design" means pass `--design-template standard`; "use lean design" or "keep the design lean/concise" means pass `--design-template lean`. If an explicit selection is unsupported, stop and ask the user for one supported value.

The script owns config/default resolution and custom template loading. When no explicit selection exists, call the script without the template flag so it can find `.mtv-aidlc/extension-config.json` by walking upward from the current app/project path, then fall back if no usable config exists.

| Family | Explicit flag | Config key | Supported values | Default |
| --- | --- | --- | --- | --- |
| Requirements story block | `--template` | `userStory.template` / `userStory.customTemplatePath` | `default`, `checklist`, `given-when-then-table`, `custom` | `default` |
| Design guidance | `--design-template` | `designDocument.template` / `designDocument.customTemplatePath` | `standard`, `lean`, `custom` | `standard` |
| Task guidance | `--task-template` | `implementationTask.template` / `implementationTask.customTemplatePath` | `test-first`, `implement-with-tests`, `tests-later`, `custom` | `test-first` |

Custom requirements templates must be story-block Markdown only, not a full `requirements.md`. Custom design and task templates must be guidance/block Markdown only, not full generated documents.

`customTemplatePath` is read only when that family's `template` is `"custom"` — a path configured alongside a built-in template name is ignored.

The Phase 4 execution approach follows the same precedence with config key `taskExecution.approach` (supported values `inline`, `subagent`; default `subagent`). Explicit prompt wording ("inline", "use implementer subagents") selects it; otherwise run the script's `execution-approach` command — the injected `Task Execution Approach` context line is only a preview and can be absent. `references/phase-4-execution.md` owns the resolution steps.

Example config:

```json
{
  "aidlcDocsPath": "apps/my-app/aidlc-docs",
  "userStory": {
    "template": "given-when-then-table"
  },
  "designDocument": {
    "template": "custom",
    "customTemplatePath": ".mtv-aidlc/templates/design/standard.md"
  },
  "implementationTask": {
    "template": "implement-with-tests"
  }
}
```

## Resuming an In-Progress Spec

When a user returns to continue an existing feature, first run `list` if the spec name is unknown, then detect the current phase before taking any action:

```bash
python3 .claude/skills/aidlc-spec-driven/scripts/spec_workflow.py status SPEC_NAME
```

Quick detection (if script unavailable):
- Only `spec.md` exists (no `requirements.md`) → this is an `aidlc-quick-spec` document, not a spec-driven feature. Either continue with `aidlc-quick-spec`, or upgrade in place by splitting `spec.md` into `requirements.md` / `design.md` / `tasks.md` (see `aidlc-quick-spec` SKILL.md "Upgrading In Place")
- No `requirements.md` → Phase 1
- No `design.md` → Phase 2
- No `tasks.md` → Phase 3
- All three exist → Phase 4 (scan for uncompleted `- [ ]` checkboxes in tasks.md)

Read the full reference file for the current phase and proceed from there. Do not restart from Phase 1 if documents already exist. When the user approves moving to a new phase, read that next phase reference before doing any work in it.

## Modifying Approved Documents

When a later phase reveals gaps requiring updates to a previously approved document:

- **Minor clarification** (adding a missing edge case, correcting wording): Update inline, mention the change to the user, no re-approval needed
- **Scope change** (new requirement, architectural adjustment): Show the user exactly what changed and ask for re-approval before proceeding
- **Major rework** (requirements contradict design, fundamental assumption wrong): Return to that phase fully and re-run the approval loop

Never silently modify an approved document for a scope change.

## Troubleshooting

When a phase stalls (requirements loops, research gaps, design complexity, ambiguous approval), see `references/troubleshooting.md`.
