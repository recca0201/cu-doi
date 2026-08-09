---
name: aidlc-uiux-design
description: >
  Produces implementation-facing HTML UI handoff artifacts for AI-DLC work: lightweight implementation mockups at `aidlc-docs/specs/{spec}/mockup.html` and full visual prototypes at `aidlc-docs/design-artifacts/prototype/{feature}/`. Use this skill when the user asks for UX/UI specifications, screen layouts, interaction states, component mapping, HTML prototypes/mockups, Figma-backed UI handoff, or when Construction Phase 2 needs a UI handoff before `design.md`. In the Construction create-design flow, this skill consumes Figma handoff JSON from a dedicated Figma source read subagent and focuses on compact HTML generation; outside that separated flow, it can coordinate `figma-design` extraction. It requires reading preview images so visual states, board layouts, and per-frame differences are captured without bloating HTML; similar screens, states, and component variants should be merged into reusable structures with concise state annotations. If Magenta/MDS is detected, invoke `magenta-mds` and make static HTML artifacts MDS-aware with canonical component names, valid token references, and explicit confidence notes. Do not use for purely backend/API specs or casual visual feedback that does not need a reusable UI artifact.
version: 2.0.0
license: MIT
---

# AIDLC UI/UX Design

Create implementation-facing HTML UI handoff artifacts with component mapping, visible states, accessibility structure, full visual prototypes, and lightweight implementation mockups.

## Purpose

Generate static HTML artifacts that align with requirements, respect the active design system, document interactions through visible markup, and support review or implementation handoff.

**Used By**: AI Design Orchestrator (Inception story-level exploration and Construction unit-level UI handoff)

## Workflow

### 1. Load Context

Read foundation and design inputs using this discovery order. Prefer the first existing artifact in each category rather than assuming every path exists.

**Foundation (brown-field)**:
- `aidlc-docs/foundation/uiux-guideline.md` - design system
- `aidlc-docs/foundation/project-overview-pdr.md` - personas

**Feature requirements and context**:
- `aidlc-docs/specs/{unit}/requirements.md` - preferred when the unit already has a spec folder
- `aidlc-docs/story-artifacts/{id}_{feature-name}_user_stories.md` - story-level requirements when no spec-local requirements exist
- Any user-provided requirement file or prompt context that clearly defines the target UI

**Optional supporting artifacts**:
- Any repo NFR artifact that exists for the feature or product
- Any unit-decomposition artifact that exists for the feature

If optional artifacts are missing, continue and note the missing context in the generated HTML handoff metadata rather than blocking.

**Figma link discovery (required check)**:
- Scan `requirements.md`, linked story artifacts, and user-provided context for supported Figma URLs before drafting.
- When a relevant Figma URL is present in the Construction create-design flow, first look for an upstream Figma handoff JSON from the dedicated Figma source read subagent. Prefer that handoff over rerunning extraction.
- If no upstream Figma handoff is provided and the task is explicitly a Construction create-design handoff, return a blocking handoff error asking the parent session to run the dedicated Figma source read subagent first. Do not use `Explore` for that step.
- Outside the separated Construction create-design flow, follow `references/figma-handoff.md` and invoke `figma-design` before writing HTML. This keeps Figma extraction rules in one place and avoids hand-authoring Figma-derived values.

**Magenta design system detection (required check)**:
- Scan `uiux-guideline.md`, requirements, related artifacts, and nearby codebase context for Magenta indicators such as `Magenta`, `MDS`, `@ocean-network-express/magenta`, `@ocean-network-express/magenta-react`, or `@ocean-network-express/magenta-react-icons`.
- If Magenta is detected as the applicable design system, invoke the `magenta-mds` skill before finalizing the HTML artifact.
- Use `references/handoff-contract.md` for precedence between Figma visual values and Magenta implementation names.

**If foundation files don't exist (green-field or early-stage project)**:
- Skip `uiux-guideline.md` — proceed without a design system constraint, and note in the HTML handoff metadata that a design system hasn't been defined yet
- Skip `project-overview-pdr.md` — infer personas from the user stories themselves
- Do not block or fail; just note the missing context at the top of the output spec

**Figma Integration (when a Figma URL is present)**:
- If an upstream Figma handoff JSON is provided, treat its `figma_spec_md_path`, `figma_spec_json_path`, `design_image_source`, `preview_image_paths`, `child_image_paths`, `visual_scope`, `observed_state_count`, `child_image_decision`, `merged_state_candidates`, and `limitations` as the Figma source contract.
- Do not rerun `figma-design` when the upstream handoff is complete and matches the requested Figma URL/file/node. Rerun only when the handoff is stale, missing required artifacts, explicitly partial, or the user asks to refresh extraction.
- Follow `references/figma-handoff.md` for URL support, artifact states, retries, source metadata, image reading, and fallback behavior.
- Treat Figma extraction as a protected handoff that follows `figma-design`'s Extraction Reliability Contract: pick blocking-with-long-timeout or `--detach` + poll `--status` based on your harness (see `references/figma-handoff.md` for the run modes and retry ladder). Never start a second extraction for the same target, hand-roll a script from `figma_client.py`, kill the terminal early, or continue as if Figma is unavailable just because extraction is slow, the terminal returned early, or an artifact has not appeared yet. Only a `FAILED` status or a concrete credential/permission/network/API error is failure.
- Do not use WebFetch or browser-open for Figma URLs.
- Do not report missing credentials based on file search; run the `figma-design` script and use its actual error output.

**Design image input (screenshot, mockup PNG, Figma export)**:
- Treat as a visual reference for layout and proportions only
- Do not try to extract tokens from images; use them during HTML artifact creation and validation

### 2. Follow Design Process

See `references/workflow.md` for 7-step process: Analyze requirements → Map screen structure and entry paths → Design wireframes → Specify components → Document interactions → Define accessibility → Specify responsive behavior

### 3. Apply Design Patterns

Load `references/design-patterns.md` for: User flow patterns, wireframe layouts, component usage, interaction patterns, responsive patterns

### 4. Ensure Accessibility

Follow `references/accessibility.md` for WCAG 2.1 AA: Color contrast (4.5:1), keyboard navigation, touch targets (44x44px), screen reader support, focus indicators

### 5. Select HTML UI Handoff Mode

Use `references/html-artifacts.md` to choose the artifact type before writing HTML. For Construction/developer handoff, generate `aidlc-docs/specs/{spec}/mockup.html`. For PO/designer/stakeholder review, generate `aidlc-docs/design-artifacts/prototype/{feature}/`.

For `mockup.html`, let the HTML carry the layout, hierarchy, states, interactions, and accessibility structure.

**When Magenta MDS is detected and actually used by the target project or feature**:
- Add implementation-facing MDS traceability for tokens, components, and icons based on `magenta-mds`
- Prefer canonical MDS names over generic descriptions
- If a clean mapping cannot be confirmed, document the nearest supported composition and mark the uncertain part as unconfirmed

**When Magenta MDS is not in scope**:
- Do not force MDS traceability into the artifact
- If another shared design system is clearly in use, reference that system's canonical names instead
- If no shared design system is in scope, keep the implementation guidance generic and library-agnostic

Use `references/handoff-contract.md` for output paths, lean metadata, Magenta/Figma precedence, and the subagent handoff response contract.

### 6. Verify Visual Coverage Against Figma Images (required when Figma images are available)

Before drafting or finalizing the HTML artifact, read the preview image from the upstream Figma handoff JSON, the `**Preview:**` line in `figma-spec.md`, or from the Figma output directory. Use this as a visual coverage gate, not as a token source. The point is to catch whether the Figma node is a single screen, a board of many states, or a component set where child-frame images are needed.

Record a **Visual Extraction Decision** before continuing: preview path, visual classification, approximate visible screen/state count, decision (`run`, `skip`, or `ask-user`), and reason. If the upstream handoff already includes child images, read and use those images. If the preview shows a board, multiple visible states, component variants, or is too dense/unclear and no child images were provided, request an updated dedicated Figma source read handoff or rerun extraction only when this skill is operating outside the separated create-design flow. If images are missing or unreadable, document that limitation in the artifact metadata instead of implying visual review was completed.

### 7. Create HTML Artifacts

Generate an HTML artifact when the user asks for one, the flow is hard to validate in text, stakeholder review is mentioned, the spec has 3+ screens, or Figma extraction was unavailable/partial and a visual substitute is useful. Use `references/html-artifacts.md` to choose `prototype`, `mockup`, or `both` before writing HTML.

Use `prototype` for PO/designer/stakeholder visual review and save to `aidlc-docs/design-artifacts/prototype/{feature}/`. Use `mockup` for developer handoff or Construction code generation and save exactly one file to `aidlc-docs/specs/{spec}/mockup.html`. Use `both` only when both audiences are explicitly requested.

Before writing HTML, run the design-image gate in `references/html-artifacts.md`. If no usable design image exists, ask the user for one; if running inside a subagent, return `needs_design_image` to the main agent. Continue without an image only when the user explicitly approves a text/spec-only artifact.

Before writing HTML, also run the state/component consolidation pass in `references/html-artifacts.md`. This keeps multi-state Figma boards from becoming huge repetitive files: group similar states, extract repeated components into shared CSS/classes or a single semantic pattern, and show only meaningful visual or behavioral differences.

For implementation mockups, start from `assets/mockup-template.html` unless an existing project mockup is clearly the better local pattern. Replace placeholders, remove irrelevant sections, and keep the final `mockup.html` single-file, concise, and free of template tokens.

For implementation mockups, follow `references/html-implementation-mockup.md` for state tabs, compact base-plus-delta rendering, bottom metadata placement, and collapsed-section affordances. Avoid restating those mockup-specific layout rules here so the skill stays lean.

HTML artifacts are static by default: plain HTML/CSS/JS, no build step, and no React runtime. If Magenta MDS is in scope, use `magenta-mds` and include MDS traceability with `data-mds-component`, `data-mds-props`, and `data-mds-confidence`. Use real MDS React components only when the user explicitly asks for React code or a React prototype.

### 8. Verify Visual Values Against Figma (required when Figma artifacts are available)

When Figma artifacts are available from the dedicated Figma source read subagent or from local extraction, compare the generated HTML artifact against `figma-spec.md` and preview images. Correct mismatches in explicit Figma colors, typography, spacing, radii, and visible state differences. If corrections were needed, document them briefly in the artifact metadata or README.

### 9. Visual Validation with Browser Tooling

After writing the HTML artifact, run the Browser visual QA policy in `references/html-artifacts.md` when a usable design reference exists. This is a completion gate, not optional polish. If browser tooling cannot run in a subagent, return the main-agent handoff shape from that reference rather than marking Visual QA complete.

## Validation

Before marking complete:

**Source gate**:
- [ ] Artifact mode is selected (`prototype`, `mockup`, `both`, or `none`).
- [ ] A usable design image was read, or user-approved text/spec-only fallback is documented; subagent flows return `needs_design_image` instead of unsupported HTML.
- [ ] Construction create-design consumes upstream Figma handoff JSON before HTML drafting; outside that separated flow, `figma-design` follows `references/figma-handoff.md` before fallback.
- [ ] Figma artifacts used by the HTML are complete enough for the claim made: `figma-spec.md` / `figma-spec.json` paths, source metadata, preview paths, Visual Extraction Decision, and limitations are recorded.

**HTML compactness gate**:
- [ ] Key screens/states, interactions, responsive behavior, and semantic structure are visible in HTML.
- [ ] Similar screens, states, and component variants are consolidated; 3+ states use tabs or equivalent non-scrolling navigation, with one full base layout and delta panels for minor variants.
- [ ] Mockup-specific layout rules from `references/html-implementation-mockup.md` are satisfied, including compact header, bottom source metadata, and clear collapsed-section affordances.
- [ ] Final HTML has valid structure, no unresolved `{{PLACEHOLDER}}` tokens, no duplicated requirements, and no broken tables.

**Design-system gate**:
- [ ] Shared design-system components/tokens are mapped only where useful for implementation; no fake token names are invented.
- [ ] If Magenta MDS is in scope, `magenta-mds` informed the mapping and meaningful mapped elements include `data-mds-component`, `data-mds-props`, and `data-mds-confidence`.
- [ ] Mapping confidence uses `confirmed`, `candidate`, or `unavailable`; raw colors/alpha values remain raw values rather than fake tokens.

**Browser QA gate**:
- [ ] When a design image exists, generated local HTML was opened with built-in browser tooling, browser automation, or `chrome-devtools`.
- [ ] Browser Visual QA follows `references/html-artifacts.md`, including tab/state capture at the primary design viewport when applicable.
- [ ] If a subagent omitted browser QA or claimed completion without capture/comparison evidence, the main agent treated it as `pending:main-agent` and ran or documented the QA gate.
- [ ] Visual QA evidence is added only when browser validation actually ran; otherwise return the documented `visual_qa: "pending:main-agent"` handoff.

**Output contract gate**:
- [ ] `mockup` output is exactly `aidlc-docs/specs/{spec}/mockup.html`; `prototype` output is under `aidlc-docs/design-artifacts/prototype/{feature}/`.
- [ ] `mockup.html` satisfies the lean metadata and handoff response contract in `references/handoff-contract.md`.
- [ ] Copy discrepancies, missing images, uncertain mappings, design assets, and open questions are documented only when relevant.

## References

**Detailed guides** (load as needed):
- `references/workflow.md` - 7-step design process
- `references/figma-handoff.md` - Figma URL, extraction, artifact-state, and fallback contract
- `references/handoff-contract.md` - output paths, lean metadata, precedence rules, and handoff response contract
- `references/design-patterns.md` - Common UI/UX patterns and layouts
- `references/accessibility.md` - WCAG 2.1 AA guidelines and checklist
- `references/html-artifacts.md` - HTML artifact mode router, design-image gate, MDS traceability, and browser QA policy
- `references/html-prototype.md` - Full visual prototype generation for PO/designer/stakeholder review
- `references/html-implementation-mockup.md` - Single-file implementation mockup generation for developer handoff and code generation

## Integration

**Command**: `/aidlc-uiux-design`
**Agent**: ai-design-orchestrator
**Workflow**: Inception workflow (when stories need UX clarification) and Construction workflow (after requirements, before tasks)
