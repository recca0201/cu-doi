# Implementation Mockup

Create this artifact for developers and AI code-generation agents during Construction handoff.

## Output

Save exactly one HTML file:

```text
aidlc-docs/specs/{spec}/mockup.html
```

Do not create additional HTML files for this artifact. Put notes, state examples, and MDS mapping inside `mockup.html`.

## Purpose

The implementation mockup is a minimum viable structural blueprint, not a polished stakeholder prototype. It should make the intended component hierarchy, states, interactions, and design-system mapping obvious enough to generate real code from it without restating requirements or source prose.

The HTML is the spec. Prefer visible, semantic HTML over prose. Add notes only for provenance, uncertainty, MDS mapping, open questions, Visual QA, and implementation-critical decisions that are not obvious from the markup.

## Generation steps

1. Confirm artifact mode is `mockup` and, when Figma images exist, a Visual Extraction Decision has been recorded by the current or parent workflow.
2. Run the design-image gate in `references/html-artifacts.md`.
3. Run the state/component consolidation pass in `references/html-artifacts.md`.
4. Start from `assets/mockup-template.html` unless an existing project mockup provides a stronger local pattern.
5. Replace template placeholders with feature-specific content and remove unused sections rather than leaving placeholder text.
6. Summarize the target screens/states as compact sections in one `mockup.html`.
7. Use semantic HTML for layout and component structure.
8. If MDS is in scope, apply the shared MDS traceability contract to mapped elements.
9. Apply the compactness budget below for bottom metadata placement, collapsed support sections, and base-plus-delta state rendering.
10. Run the Browser visual QA policy in `references/html-artifacts.md` when a design image exists. If browser tooling cannot run in a subagent, return that reference's `visual_qa: "pending:main-agent"` handoff.

## Template

Use `assets/mockup-template.html` as the default starting point for new implementation mockups. The template includes:

- A mockup shell that follows the compactness budget below.
- One base screen layout with tabbed state panels so reviewers do not scroll through every variant.
- Compact delta panels for loading, empty, error, selected, validation, and other near-duplicate states.
- Shared CSS variables and reusable classes for cards, forms, tables, chips, buttons, notes, and responsive behavior.
- Collapsed support sections for implementation notes and optional component maps.
- Minimal same-page JavaScript for state tabs only.

When using the template, adapt structure to the real feature. Delete example components that do not apply, add distinct screens only when the layout or component tree changes materially, and ensure no `{{PLACEHOLDER}}` tokens remain in the final `mockup.html`.

Delete optional sections when they add no implementation value:

- Remove unused state tabs and their panels.
- Remove Component Map when no shared design-system mapping is in scope.
- Remove Implementation Notes when there are no open questions, gaps, or non-obvious implementation decisions.
- Remove delta panels that only repeat obvious copy or status changes.
- Remove placeholder rows, fields, buttons, and sample components that are not part of the feature.

## Compactness budget

Use this budget to keep implementation mockups readable:

- Render one full base layout per distinct component tree or navigation step.
- Target a header under roughly `80px` where practical; pre-screen content should be title, compact chips, and tabs only.
- Keep the main UI visible near the first viewport; move explanatory text below the UI or into collapsed notes.
- Put similar states in tabs, not stacked full-page sections.
- In each non-base tab, show only the changed region or a concise delta list unless the state requires a materially different layout.
- Keep source metadata visible by default near the bottom. Collapse secondary Visual Extraction Decision details, Implementation Notes, and Component Map with `<details>` only when they are supporting material, and include a visible arrow/chevron in every collapsed summary.
- Keep MDS mapping focused on implementation-critical components. Prefer a short component map over exhaustive rows for every repeated input, table cell, icon, or checkbox.
- Prefer matrices for label/visibility rules, header variants, permissions, or component variants instead of repeated visual markup.
- Prefer under roughly 1000 lines for normal mockups and up to roughly 1400 lines for complicated screens or dense multi-state flows. If trending beyond 1400 lines, stop adding full markup and convert repeated areas to deltas, matrices, or collapsed notes.

## Template structure expectations

Treat `assets/mockup-template.html` as the source of truth for the single-file shell. Do not maintain a second HTML skeleton in this guide; if the structure changes, update the template first and keep this section as expectations only.

- Keep one self-contained `mockup.html` with embedded CSS and minimal same-page JavaScript.
- Follow the compactness budget for UI ordering, support-section placement, and collapse behavior.
- Keep structure changes in the template rather than copying a skeleton into this guide.

## Embedded MDS map

When MDS is in scope, include a visible or clearly commented table inside `mockup.html`:

```html
<section class="implementation-notes" aria-labelledby="mds-map-title">
  <h2 id="mds-map-title">MDS Component Map</h2>
  <table>
    <thead>
      <tr><th>HTML Element</th><th>MDS Component</th><th>Props</th><th>Confidence</th><th>Notes</th></tr>
    </thead>
    <tbody>
      <tr>
        <td><code>.primary-action</code></td>
        <td><code>Button</code></td>
        <td><code>variant="fill" color="primary" size="lg"</code></td>
        <td>confirmed</td>
        <td>Static button; convert to MDS Button in React.</td>
      </tr>
    </tbody>
  </table>
</section>
```

## Mockup style rules

- Keep visuals simple and readable.
- Prefer clear layout boxes, state sections, and annotations over pixel-perfect reproduction.
- Focus on implementation-critical information only; avoid prose summaries, requirements restatement, exhaustive mappings, and repeated context.
- Keep all CSS and JS embedded in `mockup.html`.
- Use same-page anchors or sections for multiple states instead of multiple files.
- Use modals, panels, tabs, and validation states in-place to show interaction structure.
- Do not create `README.md` unless the user explicitly asks for one.
- Keep repeated state markup lean. Create one base screen or component pattern, then show state deltas for loading, empty, error, selected, disabled, expanded, validation, and confirmation variants.
- Do not duplicate an entire screen when only copy, status, selected row, helper text, button disabled state, validation message, or modal severity changes.
- For dense Figma boards, include a short "Merged States" note listing near-duplicate frames that were represented by the same base markup.
- Prefer compact variant matrices for repeated components over many individually rendered copies.
- For 3+ states, use tabs or an equivalent non-scrolling state switcher. Avoid stacking all states vertically.
- Apply the compactness budget above for support-section placement and collapse behavior.

## Validation checklist

- [ ] Saved as exactly `aidlc-docs/specs/{spec}/mockup.html`
- [ ] No extra HTML files created
- [ ] Started from `assets/mockup-template.html` or documented why a local project pattern was more appropriate
- [ ] No `{{PLACEHOLDER}}` tokens remain in the final HTML
- [ ] Mockup shell follows the compactness budget: compact header, primary UI first, bottom Source Metadata visible by default, and collapsed support sections with visible arrow/chevron indicators
- [ ] Optional sections, tabs, rows, fields, and placeholder components that do not apply were removed
- [ ] For 3+ states, states are navigated through tabs or equivalent non-scrolling controls instead of stacked full sections
- [ ] Only one full base layout is rendered for similar states; minor variants are deltas or changed-region examples
- [ ] Large notes, rule matrices, and component maps are collapsed by default unless they are the primary artifact content
- [ ] Design image was read, or user-approved text/spec-only fallback is documented inside `mockup.html`
- [ ] Implementation Notes exists only when there are open questions, gaps, or non-obvious implementation decisions
- [ ] Similar states/components are consolidated into base markup plus concise state deltas
- [ ] Near-duplicate Figma frames are listed in notes only when the merge is not obvious from the visible UI
- [ ] MDS traceability attributes exist when MDS is in scope
- [ ] MDS Component Map is embedded inside `mockup.html` only when MDS or another shared design system is in scope
- [ ] Props/variants/tokens match `magenta-mds` references or are marked `candidate`/`unavailable`
- [ ] Browser Visual QA follows `references/html-artifacts.md`
- [ ] If browser QA could not run in the current context, the output returns the `visual_qa: "pending:main-agent"` handoff from `references/html-artifacts.md`
