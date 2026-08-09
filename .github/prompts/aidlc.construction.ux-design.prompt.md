---
description: Create HTML UI handoff artifacts with user flows, component mapping, visual prototypes, and implementation mockups
---

---
description: Create HTML UI handoff artifacts, visual prototypes, and implementation mockups
argument-hint: [feature]
---

# /aidlc.construction.ux-design

**Purpose**: Create HTML UI handoff artifacts with user flows, component mapping, visual prototypes, and implementation mockups

**Conditional Figma Reader**: dedicated Figma source read subagent
**Conditional Figma Skill**: figma-design
**Agent**: ai-design-orchestrator
**Skill**: aidlc-uiux-design

## Input

<feature>$ARGUMENTS</feature>

**Process**:

1. Resolve UI handoff context from `$ARGUMENTS` without assuming a spec path:
   - If an explicit `aidlc-docs/specs/{spec}/requirements.md` or spec folder is provided, use it and prefer `aidlc-docs/specs/{spec}/mockup.html` for implementation mockup output.
   - If a story artifact, requirements file, screenshot, Figma URL, feature name, or free-form prompt is provided, use that as the source context and let `aidlc-uiux-design` choose `mockup`, `prototype`, or both from the requested audience.
   - Select `mockup` for developer handoff, code generation, Construction specs, MDS mapping, or implementation reference.
   - Select `prototype` for PO/designer/stakeholder review, visual walkthrough, clickable/static prototype, or visual validation.
   - Select `both` only when both audiences are explicitly requested.
   - If the requested audience/artifact type is unclear, ask one clarification question before spawning subagents: "Do you want an implementation mockup, a visual prototype for review, or both?"
   - Scan all provided context for supported Figma URLs matching `https?://(www\.)?figma\.com/(design|file|proto)/\S+`.
2. If a supported Figma URL exists and the requested HTML artifact should be Figma-backed, spawn a dedicated Figma source read subagent first — **UX Figma Source Read**:
   - Use a subagent execution path for the Figma read. Do not use `Explore` for this step.
   - Invoke skill `figma-design`.
   - Follow the Figma Source Read contract in `aidlc-spec-driven/references/phase-2-uiux-handoff.md`.
   - Return Figma handoff JSON for downstream HTML generation.
3. Spawn subagent `ai-design-orchestrator` — **Construction Process - UX Design**:
   - Invoke skill `aidlc-uiux-design`.
   - Pass the original feature/context, resolved artifact target when known, supported Figma URL when present, and Figma handoff JSON when produced.
   - If this is a Construction spec mockup, require `aidlc-docs/specs/{spec}/mockup.html`; if it is a prototype, require `aidlc-docs/design-artifacts/prototype/{feature}/`; if both are requested, require both outputs.
   - Follow `aidlc-uiux-design/references/handoff-contract.md` for output contract and browser Visual QA behavior.
4. Resolve the browser QA gate before marking UX design complete:
   - If a design image exists and UI handoff returns `visual_qa: "pending:main-agent"`, omits Visual QA, or claims completion without per-state browser capture/comparison evidence, complete it using `aidlc-uiux-design/references/html-artifacts.md`.
   - Open the generated HTML with built-in browser tooling or MCP/Chrome DevTools, capture each relevant state tab at the primary design viewport, compare against the original design image, and update the HTML/CSS to close visible gaps.
   - If browser tooling is unavailable, document `skipped:no-browser-tool` with attempted tool, reason, design image source, primary design viewport, and unvalidated tab/state list.
