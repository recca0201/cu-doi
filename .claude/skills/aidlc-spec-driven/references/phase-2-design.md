# Phase 2: Design Document Creation

**Goal**: Create a design grounded in the approved requirements, at the depth the selected design template prescribes

> **⚠️ CRITICAL: Read this COMPLETE file before taking ANY action. Do not skim or read partially. Understanding all constraints and workflows is mandatory before proceeding.**
>
> **🚫 PLANNING ONLY: This phase produces DOCUMENTATION (design.md). Do NOT write, modify, or execute any actual implementation code. Coding begins in Phase 4.**

## Execution Contexts

This phase runs in one of two contexts. Identify yours before acting — several steps below belong to only one of them.

- **Main session** — the skill was invoked directly, or you are the command runner for `/aidlc.construction.create-design`. You own prerequisites, UI handoff orchestration, the Architecture Review Gate (step 7), and the Approval Loop (step 8). Draft `design.md` inline only when no orchestrating command declares a Phase 2 design agent; otherwise delegation is mandatory, regardless of how much context you already hold.
- **Spawned Phase 2 design subagent** — a parent session spawned you to produce the design. You own steps 1–6: produce `design.md` with its self-checks, then return a concise summary marking which open questions are **blocking** (answer would materially change the design). Do **not** attempt steps 7–8 — subagents cannot spawn subagents or ask the user; the parent owns the architect review and approval. Return early and honestly rather than claiming gates ran.

## Process

1. **Prerequisites**

   Read these inputs in full before designing. A design grounded in a skimmed requirements file drifts from approved scope, and the approver has no reliable way to notice until implementation breaks:
   - `aidlc-docs/specs/{spec-name}/requirements.md` — the ground truth for design decisions
   - Foundation docs from `aidlc-docs/foundation/` when available:
     - `system-architecture.md` - Existing architecture patterns
     - `codebase-summary.md` - Current implementation details
     - `code-standards.md` - Coding conventions and implementation patterns
     - `uiux-guideline.md` - UI/UX design patterns. Required reading — not optional context — when the approved requirements are primarily frontend, user-flow, interaction, layout, or presentation work: dashboards, forms, pages, component libraries, navigation flows, and any feature where UI behavior is a major part of the scope
   - If foundation docs are missing, continue with the approved requirements plus actual codebase analysis and note the missing foundation context in the design narrative if it materially affects decisions.
   - **UI handoff context**: Check for `aidlc-docs/specs/{spec-name}/mockup.html` and scan requirements/user context for supported Figma URLs (design/file/proto links). If either exists, read `references/phase-2-uiux-handoff.md` — it owns the supported-URL pattern, the `mockup_status` vocabulary, the deterministic `mockup-status` script check, and the handoff contracts — and follow it before drafting `design.md`.

2. **Codebase Analysis (CRITICAL)**

   The most common design failure is not a missing section — it is a design that ignores the existing codebase. Before creating the design:
   - Use Glob/Grep to identify relevant files, modules, and similar existing implementations, and read the code that relates to the feature requirements
   - Understand current architecture, patterns, conventions, integration points, and dependencies; document findings in the conversation thread
   - For frontend-heavy work, inspect existing screens, shared components, styling tokens, form patterns, routing structure, state/data-fetching patterns, and accessibility conventions before proposing new UI structure
   - Base design decisions on actual codebase structure, not assumptions; align with existing patterns and identify the files/modules that need modification or integration
   - If actual codebase patterns conflict with foundation docs, treat the current code as the source of truth and note the discrepancy in the design when it materially affects decisions.

3. **UI Handoff Integration**

   If `mockup.html` exists or a supported Figma URL is present, read `references/phase-2-uiux-handoff.md` and follow it. That reference owns the Path A/Path B handoff rules, metadata contract, subagent JSON contract, and UI handoff quality checks.

   Phase 2 design consumes the UI handoff. It must not create `mockup.html` or invoke `figma-design` directly. If Figma extraction fails, retry through the dedicated Figma source read subagent; do not use `Explore` for that step. If UI handoff fails, retry through `ai-design-orchestrator` / `aidlc-uiux-design`, or proceed only when the user explicitly approves continuing without `mockup.html`.

   If neither `mockup.html` nor a supported Figma URL exists, skip this step and proceed to research/context building.

4. **Research & Context Building**
   - **MUST** identify areas needing research based on feature requirements
   - **MUST** conduct research and build context in conversation thread
   - **SHOULD NOT** create separate research files
   - **MUST** summarize key findings that inform design
   - **Research focus areas** (check what's relevant to this feature):
     - **Codebase patterns first**: Use Grep/Glob to find analogous implementations — internal patterns take precedence over external approaches
       - **Frontend patterns**: For frontend work, identify reusable layout primitives, design-system components, motion patterns, responsive breakpoints, form validation patterns, and accessibility approaches already used in the codebase or documented in `uiux-guideline.md`
     - **External APIs/SDKs**: Auth requirements, rate limits, error codes, SDK versions when integrating third-party services
     - **Security**: Existing auth middleware, data validation patterns, secrets management conventions
     - **New dependencies**: When a new library is needed, briefly compare 2-3 candidates against the existing stack
     - **Performance**: Existing caching patterns, query optimization, known bottlenecks in the area
   - **SHOULD** cite sources and include relevant links in conversation
   - **MAY** ask user for input on specific technical decisions during design process

5. **Design Document Creation**
   - **What `design.md` is**: the artifact a human approves and `ai-solutions-architect` reviews. Implementation detail makes it unreviewable and goes stale when Phase 4 deviates, so describe contracts, not code:
     1. Start the component/contract section with a tree view of new and changed files in architectural reading order. Mark each file `[NEW]` or `[CHANGED]`. For `[NEW]` files, cite the verified precedent path or state `No precedent`. For `[CHANGED]` files, cite any precedent used for the new behavior. Use real code paths, not assumptions, and do not use the tree as implementation sequencing.
     2. Present each contract as a minimal interface, function signature, schema, or endpoint.
     3. Follow each contract with 1–2 concise sentences describing its behavior.
     4. Code fences contain contracts only. Do not include class or function bodies, constructors, private helpers, default values, implementation steps, or lengthy comments.
   - **Readable and lean (MUST)**: write the whole document for quick human review. Use clear headings, short sentences and paragraphs, and bullets or tables when they are easier to scan than prose. State each fact once. Keep only approval-relevant decisions and contract-level detail; omit implementation code, step-by-step logic, and long explanations.
   - **MUST** run or read selected design-template guidance before drafting. Add `--design-template ...` only when the prompt explicitly selects a design template; otherwise omit the flag so the script reads config and falls back:
     ```bash
     python3 .claude/skills/aidlc-spec-driven/scripts/spec_workflow.py design-template {spec-name} [--design-template ...]
     ```
   - Template resolution follows SKILL.md: explicit prompt/CLI selection → workspace-root `.mtv-aidlc/extension-config.json` found by walking upward → built-in `standard`.
   - The script owns config fallback, custom template loading, and stdout guidance.
   - The script-owned metadata preamble in stdout is authoritative for frontmatter. With `{spec-name}`, it derives `source_artifacts` from the current spec folder's `requirements.md`; emit that frontmatter as the first bytes of `design.md`.
   - **MUST NOT** paste `design-template` output directly into `design.md`; it is instructional guidance only.
   - **MUST** create `aidlc-docs/specs/{spec-name}/design.md` if it doesn't exist
   - **MUST** incorporate research findings directly into design
   - **MUST** use the section structure defined by the selected design-template guidance (`standard` → `references/design-blocks/standard.md`, `lean` → `references/design-blocks/lean.md`, `custom` → the configured file). The selected guidance owns the required headings; do not invent a different document shape. Regardless of template, the design must still cover: overview/summary, architecture, components/contracts, data changes, error handling, and testing — at the depth the selected template prescribes.
   - **MUST** keep the selected template's section headings even for frontend work; do not replace them with a separate UX-only document
   - **For frontend-heavy requirements, MUST capture UI implementation intent inside the selected template's sections:**
     - **Architecture section**: identify the relevant UI layers, routing boundaries, data-loading strategy, and where presentation logic should live
     - **Component/contract section**: define the high-level screen or page hierarchy, major component responsibilities, user flow, state transitions, and key props/interfaces between UI pieces; point to `mockup.html` for detailed visual structure, states, and MDS mapping when that file exists
     - **Error-handling section**: describe empty, loading, validation, and failure states visible to the user
     - **Testing section**: include frontend-oriented coverage such as component tests, interaction tests, and responsive or end-to-end verification when appropriate
   - **For frontend-heavy requirements, SHOULD also call out:**
     - Responsive behavior across the target screen sizes from requirements or `uiux-guideline.md`
   - **When step 3 produced UI handoff content** (from `mockup.html` or generated via `aidlc-uiux-design`), populate `## UI Design Specification` with a reference link to `mockup.html` and a concise extract (proportional to scope) covering only the UI constraints that implementation will directly reference. Do not copy the full handoff and do not restate visible HTML structure, component trees, accessibility details, or token inventories. Preserve canonical token identifiers from `mockup.html` only for extracted colors, spacing, typography, radius/shadow, or breakpoint tokens that the implementation must apply directly. In the component/contract section, cite values by reference to `mockup.html` rather than duplicating them.
   - If `mockup.html` indicates a shared design system is in scope, `## UI Design Specification` MAY include a concise dependency extract for implementation-critical components, wrappers, tokens, or icons. Magenta MDS is optional and should only appear when the UI handoff actually indicates it.
   - **Identifier sanity check**: before finalizing, scan all Mermaid diagrams, GraphQL SDL, TypeScript examples, protobuf/rpc names, DTO fields, and file paths for obvious implementation-breaking typos, spaces inside identifiers, inconsistent casing, and misspellings. Examples to catch: `createBaciseTariff` vs `createBasicTariff`, `reefer MonitoringCost` vs `reeferMonitoringCost`. If an identifier is intentionally uncertain, mark it as an open question instead of presenting it as final.
   - **UI ambiguity carry-forward**: if `mockup.html` contains copy discrepancies, candidate/unavailable design-system mappings, missing preview images, or incomplete Figma extraction, carry those items into the design's decisions/open-questions section(s) (`## Open Questions` / `## Design Decisions` in standard, `## Decisions & Open Questions` in lean) or the UI extract so implementation does not treat them as resolved.
   - **SHOULD** include diagrams or visual representations (use Mermaid)
   - **MUST** ensure design addresses all requirements from requirements.md
   - **SHOULD** highlight design decisions and their rationales
   - **Final self-check (proportionality)**: before finalizing, scan for any full function/component/test bodies and replace each with its contract + intent (per "What `design.md` is" above), or defer the step to Phase 3 `tasks.md`.

6. **Document Format**
   Use the selected design-template guidance for the document shape. The default `standard` guidance lives in `references/design-blocks/standard.md`; the `lean` guidance lives in `references/design-blocks/lean.md` (short, decision-dense documents built around a codebase-alignment table — still includes an architecture Mermaid diagram); custom guidance is loaded through `.mtv-aidlc/extension-config.json` `designDocument.customTemplatePath`.

   Template choice follows the resolution contract in SKILL.md (explicit selection → config → `standard`); do not switch templates on your own judgment.

   Regardless of template, the final `design.md` **MUST** remain project-specific and grounded in approved requirements, codebase analysis, UI handoff context, and research. It **MUST NOT** include generic template instructions, placeholder-only sections, or copied guidance text that does not apply to the feature.

7. **Architecture Review Gate** _(main session only — see Execution Contexts)_

   The JSON contract below is the canonical definition of the architect review result; commands such as `/aidlc.construction.create-design` cite it rather than redefining it.
   - Before the first review run, resolve any blocking questions the design subagent returned (AskUserQuestion, then update `design.md`) — reviewing a design with known-open blockers wastes the cycle.
   - **MUST** spawn a dedicated `ai-solutions-architect` subagent after `design.md` is created or materially updated, before asking the user to approve the design.
   - The architect review subagent is review-only: it reads artifacts and returns findings/questions; it must not edit `design.md`, `requirements.md`, `mockup.html`, tasks, or implementation code.
   - Pass the review subagent:
     - Project root and spec name
     - `aidlc-docs/specs/{spec-name}/requirements.md`
     - `aidlc-docs/specs/{spec-name}/design.md`
     - Available foundation docs from `aidlc-docs/foundation/`
     - `mockup.html` path and `mockup_status` when present
     - Figma/UI handoff limitations, unresolved questions, and assumptions already known
   - **Foundation Context is critical**: the review subagent must carefully read relevant architecture and implementation foundation docs before judging `design.md`, especially:
     - `system-architecture.md` for architecture patterns, ADRs, and integration constraints
     - `codebase-summary.md` for actual modules, dependencies, and ownership boundaries
     - `code-standards.md` for conventions and implementation patterns
     - `uiux-guideline.md` for frontend, user-flow, interaction, layout, or presentation work
   - If any expected foundation doc is missing, stale, or insufficient, the review subagent must include that limitation in `non_blocking_notes` or `blocking_findings` depending on risk. Missing foundation context must not be silently ignored.
   - Require the subagent to return a structured result:
     ```json
     {
       "verdict": "pass | needs-fixes | needs-clarification",
       "blocking_findings": ["missing or incorrect design issue"],
       "missing_or_weak_requirements_coverage": ["requirement id or behavior gap"],
       "architecture_risks": ["integration, boundary, dependency, or pattern risk"],
       "nfr_gaps": ["security, performance, scalability, reliability, observability, or compliance gap"],
       "ui_handoff_gaps": ["mockup, Figma, MDS, visual QA, or responsive traceability gap"],
       "recommended_fixes": ["specific documentation changes for design.md"],
       "clarification_questions": ["question that needs user input before design can be reliable"],
       "non_blocking_notes": ["residual risks or suggestions"]
     }
     ```
   - Review focus:
     - Requirements coverage and traceability
     - Careful alignment with Foundation Context: system architecture, codebase summary, code standards, UI/UX guidelines, and existing codebase patterns
     - Component/API/data-model completeness
     - Integration boundaries and cross-module effects
     - Error handling, security, performance, observability, reliability, and testability
     - UI handoff traceability when `mockup.html` or Figma is present
     - Implementation-breaking ambiguity, invented identifiers, or hidden assumptions
   - If the architect returns `needs-fixes`, update `design.md` in the main session using the findings, staying within approved requirements and Phase 2 documentation-only scope, then re-run the architect review.
   - If the architect returns `needs-clarification` or any clarification questions, use the `AskUserQuestion` tool to ask the question list before proceeding. Ask only genuine blockers or decision points, preferably in one call when the tool supports multiple questions. After the user answers, update `design.md` and re-run the architect review.
   - Continue the review/fix/clarify loop until the architect returns `pass` or only non-blocking notes remain. Carry non-blocking notes into the design's decisions/open-questions section(s) or the user handoff summary as appropriate.

8. **Approval Loop** _(main session only — see Execution Contexts)_
   - **MUST** ask user: "Does the design look good? If so, we can move on to the implementation plan."
   - **MUST** revise `design.md` when the user requests changes, then ask for explicit approval again.
   - **MUST NOT** proceed to implementation plan until receiving clear approval (e.g., "yes", "approved", "looks good")
   - **MUST** repeat the feedback-revision-approval cycle until explicit approval is received.
   - **MUST** offer to return to requirements clarification if gaps identified during design

9. **Exit Criteria**
   - User explicitly approves design with clear approval statement
   - All requirements from requirements.md addressed
   - Design decisions documented with rationales
   - Testing strategy defined
   - Available foundation docs referenced and followed when present
   - Research findings incorporated into design
   - Codebase analysis completed and reflected in design
   - For frontend-heavy work, UI/UX guidance is reflected in component structure, interaction flow, and responsive behavior
   - When `mockup.html` was present (Path A): `design.md` links to it and contains only a lean implementation-facing extract rather than a duplicate UI handoff
   - When no valid matching `mockup.html` but a supported Figma URL was present (Path B): UI handoff preflight ran, `mockup.html` was produced with valid handoff metadata or the user explicitly approved continuing without it, and `design.md` contains only the necessary extract or documented failure context
   - When Path B produced `mockup.html`: the file satisfies the handoff metadata contract and `design.md` explicitly notes whether it came from generic Figma source read + `aidlc-uiux-design`, partial-artifact fallback, screenshot fallback, or unavailable Figma context
   - When a shared design system is in scope: `design.md` carries forward only the implementation-critical design-system dependencies from `mockup.html`
   - `design.md` does not substantially duplicate `mockup.html`; detailed visual structure, accessibility markup, and comprehensive design-system mapping remain in the HTML handoff
   - All code-like identifiers in diagrams/code blocks were sanity-checked for typos, spaces inside identifiers, casing drift, and consistency across GraphQL, TypeScript, DTO, rpc, and file-path examples
   - UI/UX handoff quality checked: provenance status is accurate, preview image paths are present when images exist, state delta matrix exists for board-style Figma sources, design-system mapping confidence is preserved, and copy/design asset discrepancies are carried forward
   - Unresolved UI/UX, API, protobuf, copy, and design-system ambiguities appear in the design's open-questions section instead of being hidden in implementation examples
   - `ai-solutions-architect` reviewed `design.md` after creation/update and returned `verdict: pass`, or all blocking findings were fixed and clarification questions were answered before user approval

10. **Next Steps Section**
   - Ensure `design.md` ends with the following section **before** asking for user approval — it is part of the document the user approves, and appending it afterwards would silently modify an artifact the architect already reviewed:
     ```markdown
     ## Next Steps

     Once this design is approved, proceed to Phase 3: Implementation Planning.

     **What to do next:**
     1. Use the slash command: `/aidlc.construction.create-tasks`
     2. The agent will automatically read `references/phase-3-tasks.md` for detailed workflow instructions
     3. Foundation docs will be referenced for implementation patterns

     This will create `tasks.md` with actionable task checklist for code implementation.
     ```
