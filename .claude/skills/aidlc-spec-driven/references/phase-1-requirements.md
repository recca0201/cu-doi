# Phase 1: Requirements Clarification

**Goal**: Generate requirements using the local requirements wrapper and selected shared user-story block, run Product Owner review, then iterate until user approval

> **⚠️ CRITICAL: Read this COMPLETE file before taking ANY action. Do not skim or read partially. Understanding all constraints and workflows is mandatory before proceeding.**
>
> **🚫 PLANNING ONLY: This phase produces DOCUMENTATION (requirements.md). Do NOT write, modify, or execute any actual implementation code. Coding begins in Phase 4.**

## Process

**Step-by-step workflow:**

1. **Read user's feature request** and understand the context
2. **Read the foundation docs in full** for context (personas, constraints, patterns) when they exist — requirements written from a skimmed foundation contradict established personas and constraints in ways the user only catches later
  - If foundation docs are missing from `aidlc-docs/foundation/`, continue using the user request as the primary source of truth and explicitly note that foundation context was unavailable.
3. **Analyze the codebase** when the feature touches existing behavior or files
4. **Identify unclear or ambiguous points** by checking every artifact-shaping decision in "Identify Unclear or Ambiguous Points" below
5. **Ask clarification questions** using AskUserQuestion tool (if needed)
6. **Resolve the user-story block** by passing explicit prompt/CLI selection to `init --template`; when no explicit selection exists, omit the flag so `spec_workflow.py` reads config and falls back
7. **Generate initial requirements** by placing the selected story block inside the requirements document wrapper
8. **Run the Product Owner review gate** before asking the user to approve the requirements
9. **Iterate with user** until approved

**Focus**: Writing requirements only. Codebase analysis is read-only requirements grounding. Do NOT edit code, draft implementation, or turn Phase 1 into detailed design.

## Analyze the Codebase

Before writing requirements, do enough read-only investigation to write them accurately:

- Find relevant files
- Read the files or docs that shape the requested behavior
- Identify existing patterns, terminology, constraints, and integration points
- Use findings to ask better clarification questions and write accurate requirements

## Identify Unclear or Ambiguous Points (CRITICAL)

Treat an item as unclear when any unresolved decision could change the saved requirements artifact, story split, acceptance criteria, implementation, or testing. Ask before running `init`, scaffolding, saving, or generating `requirements.md`; do not generate requirements and append questions in the same response. A request to "make reasonable assumptions" does not bypass unresolved artifact-shaping decisions.

**ALWAYS clarify before generating when any of these are unclear:**

- **Actor/persona**: target user, role, permission level, or foundation persona that receives the value
- **Acceptance or success criteria**: observable behavior, business outcome, or quality bar that proves the requirement is done
- **Scope boundaries**: what is in scope, out of scope, or a separate feature/story group
- **Constraints and touchpoints**: non-negotiable constraints, technical choices, implementation-affecting options, integrations, prior artifacts, existing product/code areas, or external systems
- **UX and workflow behavior**: entry points, screens, commands, triggers, user journeys, feedback messages, accessibility expectations, and interruption rules
- **Timing and limits**: frequency, cooldowns, quiet hours, thresholds, quotas, retries, timeouts, and performance targets
- **Configuration and control**: defaults, settings, enable/disable behavior, opt-out behavior, permissions, and admin controls
- **Data and compliance**: privacy, telemetry, storage, retention, auditability, consent, external services, and sensitive-data boundaries
- **Failure and verification**: fallback behavior, recoverability, negative paths, edge cases, and how the behavior will be tested

**Question format:**

- Use AskUserQuestion when available.
- Ask one decision at a time by default, then stop and wait for the answer.
- Use 2-4 concrete options when the choices are known, marking the recommended option with `(Recommended)`.
- Ask open-ended questions only when useful options cannot be known from context.
- Group questions only when the decisions are tightly related or depend on the same answer.

**Examples:**
- "Add authentication" → Clarify: OAuth/JWT? Social login? Password policy?
- "Make it faster" → Clarify: Which part? Target metrics? Trade-offs?
- "Add export" → Clarify: Format (CSV/PDF/Excel)? Data scope? Schedule?

## Constraints

**File Creation:**
- MUST create `aidlc-docs/specs/{spec-name}/requirements.md` if not exists
- MUST output to correct spec directory

**Pre-Generation Clarification:**
- MUST confirm with user BEFORE creating requirements if anything is unclear (see "Identify Unclear or Ambiguous Points")
- MUST ask before running `init`, scaffolding, saving, or generating `requirements.md` if any artifact-shaping decision is unresolved
- MUST stop after asking clarification; do not scaffold, save, or generate requirements in the same response
- SHOULD use AskUserQuestion tool for clarification
- For binary or multi-way technical decisions (auth method, data format, API style): present 2-4 options with a recommended default — this reduces cognitive load for the user
- For open-ended context questions (target user, business goal, key constraint): ask conversationally; don't force options where they don't naturally fit
- SHOULD ask one decision at a time by default
- CAN ask multiple related questions in a single AskUserQuestion call only when the decisions are tightly related or dependent on the same answer

**Initial Generation:**
- SHOULD read the foundation docs from `aidlc-docs/foundation/` when available (in full, per step 2):
  - `project-overview-pdr.md` - Product vision, target audience
  - `system-architecture.md` - Technical constraints
  - `uiux-guideline.md` - UX patterns and standards
- IF foundation docs are missing, MUST continue with the user's stated constraints and call out any resulting assumptions briefly.
- MUST generate initial requirements after clarification (do NOT ask sequential questions during generation)
- SHOULD consider edge cases, UX, technical constraints, success criteria

**Template Selection:**
- Template resolution follows `SKILL.md § Template Resolution Contract`: pass explicit prompt wording as `--template`, otherwise omit the flag so the script owns config/default resolution
- Supported templates:
  - `default`: `../_aidlc-shared/user-story-blocks/default.md`
  - `checklist`: `../_aidlc-shared/user-story-blocks/checklist.md`
  - `given-when-then-table`: `../_aidlc-shared/user-story-blocks/given-when-then-table.md`
  - `custom`: `userStory.customTemplatePath` from `.mtv-aidlc/extension-config.json`
- If the user provides an invalid template, ask them to choose one supported template and stop
- MUST load `references/requirements-document-wrapper.md` and only the selected built-in story-block reference or configured custom story-block file
- MUST treat custom templates as story-block Markdown only, not a full `requirements.md` wrapper
- MUST use the selected acceptance-criteria format consistently across all stories in `requirements.md`
- MUST preserve stable criterion IDs because Phase 2 and Phase 3 cite requirements by story and criterion ID

**Document Format:**
- MUST include clear introduction summarizing the feature
- MUST include user stories in the format: "As a [role], I want [feature], so that [benefit]"
- MUST include traceable acceptance criteria using the selected template:
  - `default`: hierarchical EARS-Lite criteria such as `1.1 WHEN ... THEN system SHALL ...`
  - `checklist`: checklist items with bold stable IDs such as `- [ ] **1.1** ...`
  - `given-when-then-table`: table rows with stable `No.` IDs such as `1.1`
- See `../_aidlc-shared/user-story-blocks/{template}.md` for built-in story-block formats, or the configured custom template path for custom format and examples
- MUST use `references/requirements-document-wrapper.md` for the surrounding `requirements.md` document shape
- MUST append "Next Steps" section at end of document (see below)

**Approval Loop:**
- MUST run the Product Owner review gate before asking: "Do the requirements look good? If so, we can move on to the design."
- MUST ask: "Do the requirements look good? If so, we can move on to the design."
- MUST make modifications if user requests changes
- MUST rerun the Product Owner review gate before asking for approval again when user-requested changes alter scope, story splits, personas, acceptance behavior, criteria, or constraints; typo-only or formatting-only fixes do not need another review
- MUST NOT proceed until explicit approval ("yes", "approved", "looks good")
- SHOULD proactively identify remaining ambiguities or unclear points
- MUST use AskUserQuestion tool if clarification needed during iteration
- Watch for: vague requirements, missing edge cases, unclear criteria, conflicts, feasibility concerns

**Product Owner Review Gate:**
- MUST run after the first complete `requirements.md` draft is saved and before asking for user approval to move to Phase 2
- Spawn a dedicated `ai-assistant-product-owner` subagent in Spec Requirements Review Mode when subagent tooling is available
- Give the subagent a review-only handoff with: project root, spec name, `requirements.md` path, original user request/source material, selected requirements template, gathered foundation/context files, assumptions or missing-context notes, and this Phase 1 reference plus the selected story-block guidance
- The subagent must return exactly one verdict: `PASS`, `FIX_BEFORE_USER_REVIEW`, or `NEEDS_USER_DECISION`
- Require blocking findings, advisory findings, coverage notes, and suggested minimal edits
- The review subagent must not edit files, regenerate `requirements.md`, or invoke `aidlc-spec-driven`; the parent skill owns all requirements edits
- If the verdict is `PASS`, continue to the approval loop and ask the user whether the requirements look good
- If the verdict is `FIX_BEFORE_USER_REVIEW`, apply only clear in-scope fixes to `requirements.md`, preserve stable story and criterion IDs where possible, then rerun the Product Owner review once before asking for user approval
- After the one rerun, do not loop; if the review still blocks, surface the remaining verdict and findings instead of asking for general approval
- If the verdict is `NEEDS_USER_DECISION`, ask the user before changing scope, defaults, personas, acceptance behavior, privacy/data decisions, or story splits
- If subagent tooling is unavailable, say delegated Product Owner review was skipped, run the same review checklist inline, apply the same verdict handling, and do not claim subagent review occurred

**Exit Criteria:**
- User explicitly approves requirements
- Product Owner review gate passed, or a remaining blocking/user-decision finding was surfaced instead of moving to Phase 2
- All requirements use the selected shared user-story block format consistently
- Edge cases considered
- Success criteria defined

**Next Steps Section:**
- MUST preserve the `## Next Steps` section from `references/requirements-document-wrapper.md`
