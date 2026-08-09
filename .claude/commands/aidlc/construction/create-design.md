---
description: Create comprehensive design document from approved requirements
argument-hint: [requirements] [--design-template standard|lean|custom]
---

# /aidlc.construction.create-design

**Purpose**: Create comprehensive design document from approved requirements

**Phase 2 Agent**: ai-orchestration-engineer
**Primary Skill**: aidlc-spec-driven
**Conditional Figma Agent**: dedicated Figma source read subagent
**Conditional Figma Skill**: figma-design
**Conditional UI/UX Agent**: ai-design-orchestrator
**Conditional UI/UX Skill**: aidlc-uiux-design
**Design Review Agent**: ai-solutions-architect

## Input

<requirements>$ARGUMENTS</requirements>

Optional `--design-template standard|lean|custom` selects the Phase 2 guidance template (`lean` produces a short, decision-dense design grounded in a codebase-alignment table). If omitted, pass no template value so `aidlc-spec-driven` can read workspace config before defaults.

## Role

You are the main command runner — the "main session" in `aidlc-spec-driven/references/phase-2-design.md § Execution Contexts`. You orchestrate the subagents and own every gate. The contracts you enforce are defined once in the skill references — cite them, do not restate them:

- `aidlc-spec-driven/references/phase-2-uiux-handoff.md` — supported Figma URLs, `mockup_status` vocabulary, Figma Source Read Contract, UI Handoff JSON Contract, browser QA quality checks
- `aidlc-spec-driven/references/phase-2-design.md` — Phase 2 workflow, Architecture Review Gate contract, approval loop

Do not perform Figma extraction, mockup generation, or design drafting inline — each has a dedicated subagent below. Exception: question triage and review-directed fixes to `design.md` (steps 6-7).

## Process

1. **Resolve the target spec.** Prefer an explicit `aidlc-docs/specs/{spec-name}/requirements.md`; otherwise infer `{spec-name}` or ask one clarification question. Extract `--design-template ...` only when explicitly present — treat it as workflow config, not requirements text, and never pass a default when the flag is omitted.
2. **Preflight (in this session).** Read the target `requirements.md` plus the provided requirements argument. Detect Figma URLs, then determine `mockup_status` deterministically — do not hand-compare mockup metadata:
   ```bash
   python3 .claude/skills/aidlc-spec-driven/scripts/spec_workflow.py mockup-status {spec-name} [--figma-url URL]
   ```
   If the script reports the URL is unsupported (e.g. board/FigJam), handle it per the handoff reference. Whenever a Figma URL or `mockup.html` is present, read `aidlc-spec-driven/references/phase-2-uiux-handoff.md` in full before going further. Preflight is orchestration-only — no foundation docs or codebase analysis here; that grounding belongs to the design subagent (step 5).
3. **UI handoff pipeline** — only when `mockup_status` is `needs-refresh` or `needs-generation`. A `pre-existing-fresh`, `pre-existing`, or `not-applicable` result needs no extraction; spawning Figma subagents for a fresh mockup wastes a full subagent run:
   1. Spawn the dedicated Figma source read subagent (invokes `figma-design`) per the Figma Source Read Contract.
   2. Spawn `ai-design-orchestrator` (invokes `aidlc-uiux-design`) with spec name, requirements context, Figma URL, and the Figma handoff JSON; require the UI Handoff JSON Contract.
   3. If the handoff fails, retry per the reference; continue without `mockup.html` only with explicit user approval (`mockup_status: unavailable`).
4. **Browser QA gate (this session, before Phase 2 design).** Resolve per the handoff reference's quality checks: if a design image exists and `visual_qa` is pending, missing, or claimed without per-state capture/comparison evidence, complete it using `aidlc-uiux-design/references/html-artifacts.md` with built-in browser tooling or MCP/Chrome DevTools. If browser tooling is unavailable, document `skipped:no-browser-tool` with the required fields.
5. **Spawn the Phase 2 design subagent**: `ai-orchestration-engineer`, invoking `aidlc-spec-driven` per its Execution Contexts — it reads `references/phase-2-design.md` completely, produces `design.md`, and returns a summary separating **blocking** open questions (answer would materially change the design) from non-blocking ones; it must not run the architect gate or ask the user. Pass: requirements context, explicit `--design-template` only when provided, `mockup_status`, mockup path, browser QA status/evidence or skip reason, and any handoff failure context. If `mockup.html` exists, the subagent links to it from `design.md` instead of duplicating it. Always spawn — even if this session already gathered context, pass it as brief pointers in the prompt; never draft `design.md` inline.
6. **Triage returned questions (this session).** If the subagent returned blocking questions, ask the user via AskUserQuestion, update `design.md`, and remove resolved items from `## Open Questions` — resolving known blockers first saves an architect review cycle. Non-blocking items stay in `## Open Questions` for the approver.
7. **Architecture Review Gate (this session).** Spawn `ai-solutions-architect` per `phase-2-design.md § Architecture Review Gate`: review-only, foundation docs as critical review input, structured JSON verdict as defined there. Handle the result here: on `needs-fixes`, fix `design.md` in this session (documentation-only, within approved requirements) and re-run the review; on `needs-clarification` or open questions, use AskUserQuestion (one call when supported, genuine blockers only), update `design.md`, and re-run the review. Loop until `pass` or only non-blocking notes remain.
8. **User approval.** Present the design with a concise summary of the architect outcome and any non-blocking residual risks, following the Phase 2 approval loop. If user feedback causes material `design.md` changes, repeat step 7 before moving to Phase 3.
