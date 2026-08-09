# HTML Artifact Router

Use this reference before creating any HTML prototype or implementation mockup.

## Choose artifact type

| User intent | Artifact type | Output |
|-------------|---------------|--------|
| PO review, designer review, stakeholder walkthrough, visual prototype, clickable prototype, Figma visual validation | `prototype` | `aidlc-docs/design-artifacts/prototype/{feature}/` |
| Developer handoff, code generation, Construction spec, MDS mapping, implementation reference | `mockup` | `aidlc-docs/specs/{spec}/mockup.html` |
| Both audiences explicitly requested | `both` | Generate both outputs |

Default to `mockup` during Construction implementation handoff. Default to `prototype` for PO/designer/stakeholder review. Do not generate both unless both audiences are clearly named or the user explicitly asks for both.

## Design image gate

Run this gate before writing HTML. HTML created without a visual source tends to become generic; the gate prevents unsupported visual guessing.

Look for usable design images in this order:

- Figma preview or child-frame images from `temp/figma_*/`, especially paths referenced by `figma-spec.md`.
- Images referenced in `mockup.html`, prototype README, or other handoff notes.
- PNG/JPG/WebP/SVG mockups near `aidlc-docs/specs/{spec}/` or `aidlc-docs/design-artifacts/`.
- User-provided attachments, screenshots, Figma exports, or prompt context.

When a usable image exists, read it before writing HTML. If multiple state images exist, read the images that correspond to screens or states represented by the artifact.

If no usable design image exists:

- Ask the user for a screenshot, Figma export, or Figma URL before generating HTML.
- If running inside a subagent, return `html_status: "needs_design_image"` to the main agent with a short reason.
- Continue without an image only when the user explicitly approves a text/spec-only artifact. Record this as `design_image_source: "user-approved-text-only"` and do not claim visual comparison.

## Shared static HTML rules

- Use plain HTML/CSS/JS by default.
- Do not import React, Vue, or `@ocean-network-express/magenta-react` unless the user explicitly asks for a React prototype or production code.
- Use semantic landmarks, labels, keyboard-friendly controls, and responsive CSS.
- Keep JavaScript local and minimal: modal open/close, tabs, accordions, validation hints, and dismissible notifications are enough.
- Do not add API calls, server logic, build pipelines, or framework routing.

## State and component consolidation pass

Run this pass after reading design images and before writing HTML. The goal is to preserve implementation meaning without turning every Figma frame or state variant into duplicated markup.

1. Inventory screens, states, and repeated components from the requirements, Figma `figma-spec.md`, preview images, and child-frame images.
2. Choose a base structure for each repeated screen family, for example list view, detail view, wizard step, table page, modal, or form.
3. Merge states that share the same layout and components. Represent them as tabs, concise `data-state` examples, state chips, comments, or an adjacent delta note instead of copying the full screen.
4. Extract repeated components into one semantic pattern with shared classes and CSS variables. Reuse that pattern for cards, form rows, table rows, dialogs, side panels, and action bars.
5. Keep separate full sections only when the layout, information architecture, or implementation behavior materially changes.
6. Keep the primary UI before support material. Use the artifact-specific guide for support-section placement and collapse defaults.
7. Remove optional tabs, notes, maps, placeholder rows, and sample components when they do not add implementation value.
8. Record skipped near-duplicate states only when the merge is not obvious from the visible UI.

Use this decision rule: if a reader can implement the state by changing props, content, visibility, validation message, selected row, or status styling, do not duplicate the entire layout. If they would need a different component tree or navigation structure, create a separate section or page.

Prefer these compact patterns:

- One screen section with an inline "State Variants" block for loading, empty, error, disabled, selected, expanded, or confirmation variants.
- One tabbed state section with a full default/base state and delta-only tabs for minor variants.
- One component example plus a small variant matrix for repeated buttons, tags, cards, rows, or input states.
- One modal/panel shell with alternate body examples when only copy, severity, or action labels change.
- Shared CSS custom properties and utility classes instead of repeated inline styles.
- Artifact-specific support sections for metadata, extraction notes, implementation notes, component maps, and long business-rule matrices.

Avoid these bloating patterns:

- Full duplicated screen markup for every hover, selected, validation, loading, or empty state.
- Vertically stacked full-screen sections for 3+ states when the states can fit in tabs or delta panels.
- One HTML page per Figma child frame when the child frames are component variants rather than top-level screens.
- Repeating the same card, table, form, or navigation markup only to change labels or status colors.
- Long prose tables that restate every requirement already visible in the HTML.
- Support sections that exist only because the template included them.

## Shared MDS rules

When Magenta MDS is detected, invoke/use `magenta-mds` before writing HTML.

- Use confirmed MDS component names, props, variants, sizes, colors, icons, and `--mag-*` tokens.
- Do not invent MDS tokens, props, variants, or icon names.
- Mark each mapping as `confirmed`, `candidate`, or `unavailable`.
- Static class names such as `.mds-button` and `.mds-dialog` are prototype-only readability helpers, not production MDS CSS APIs.

Use traceability attributes on meaningful mapped elements:

```html
<!-- MDS: Button variant="fill" color="primary" size="lg" confidence="confirmed" -->
<a
  class="mds-button mds-button--primary primary-action"
  data-mds-component="Button"
  data-mds-props='{"variant":"fill","color":"primary","size":"lg"}'
  data-mds-confidence="confirmed"
>
  Continue
</a>
```

Use these attributes consistently:

- `data-mds-component`: canonical component or composition, for example `Button`, `Input`, `Dialog`, `Tag`, `Table`, or `Dialog + Button`.
- `data-mds-props`: compact JSON object with implementation-relevant props.
- `data-mds-confidence`: `confirmed`, `candidate`, or `unavailable`.

## Browser visual QA policy

Run browser visual QA after HTML generation when a design image exists. Treat this as a completion gate for HTML artifacts: open the local HTML with browser tooling, capture it, compare it with the original design image, and update the HTML/CSS to close visible gaps before claiming completion.

Use available tooling in this order; do not substitute a text-only review for this step:

- Built-in browser preview, browser automation, or an already-active browser tool if available.
- `chrome-devtools` skill or MCP/browser automation otherwise.

For `mockup.html`, default the primary design viewport to `1280px`. Override this only when the original design image or Figma source clearly uses a different target width. Do not require separate mobile/tablet/desktop captures unless the user explicitly asks for responsive validation.

If the artifact uses tabs, segmented controls, accordions-as-state-switchers, or any equivalent state switcher, click through and capture each implementation-relevant tab/state at the primary design viewport. Each state capture must be compared against the original design image or matching child-frame export so the validation evidence covers the actual state being reviewed.

After each capture pass, view/read the generated screenshot again alongside the original design image or matching child-frame export before judging the result. Compare layout, spacing, alignment, typography, colors, component sizing, and visible states. Update the HTML/CSS to match the original design as closely as practical for a static implementation handoff, then re-capture affected tab states when changes are made.

For `prototype`, responsive visual QA may be useful when explicitly requested. For `mockup`, visual QA is still required when a design image exists, but prioritize implementation clarity over pixel-perfect polish and keep validation focused on the primary design viewport.

Do not claim Visual QA is complete just because the HTML file was written or self-reviewed. Completion requires opening the generated HTML in a browser, capturing every implementation-relevant state tab, comparing those captures against the original design image, and applying fixes for visible gaps. If a subagent omits Visual QA, reports `completed` without per-state capture/comparison evidence, or returns an ambiguous QA status while a design image exists, the main agent must treat QA as `pending:main-agent` and run this browser comparison before downstream design work. If no browser tool can run in the current agent context, return the main-agent handoff below.

## Main-agent visual QA handoff

If this work is running inside a subagent and browser tooling is unavailable, unreliable, or cannot open the generated HTML, return control to the main agent instead of marking QA complete or silently skipping it.

Use this handoff shape:

```json
{
  "visual_qa": "pending:main-agent",
  "visual_qa_reason": "browser tooling unavailable in subagent",
  "html_artifact_type": "prototype | mockup",
  "prototype_path": "path or none",
  "mockup_path": "path or none",
  "design_image_source": "path",
  "attempted_browser_tool": "built-in browser | chrome-devtools | unavailable | other",
  "primary_design_viewport": "1280px or explicit design image width",
  "tab_state_list": ["default", "validation-error", "empty"]
}
```

The main agent should then open the artifact with available browser tooling or `chrome-devtools`, capture each implementation-relevant tab/state at the primary design viewport, compare the captures against the original design image, fix HTML/CSS gaps, re-capture when needed, and update the prototype README or `mockup.html` metadata with Visual QA evidence.

## Route to detailed guide

- For `prototype`, follow `references/html-prototype.md`.
- For `mockup`, follow `references/html-implementation-mockup.md`.
- For `both`, generate the prototype first for visual review, then derive the implementation mockup from the approved structure and MDS map.
