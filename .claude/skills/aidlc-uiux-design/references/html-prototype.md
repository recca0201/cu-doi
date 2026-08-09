# Full Visual Prototype

Create this artifact for UI/UX designers, POs, and stakeholders who need to review the visual flow.

## Output

Save to:

```text
aidlc-docs/design-artifacts/prototype/{feature}/
```

Include:

- `index.html`
- Additional screen HTML files when the flow needs them
- `README.md`
- Optional QA screenshots if browser visual QA ran

Multi-screen flows may use one HTML file per top-level screen. Link screens with plain `<a href>` tags, not JavaScript routing.

## Generation steps

1. Run the design-image gate in `references/html-artifacts.md`.
2. Run the state/component consolidation pass in `references/html-artifacts.md`.
3. Identify every distinct screen needed for stakeholder walkthrough and merge minor state variants into the closest screen.
4. Use design images for visual hierarchy, spacing, proportions, and meaningful state differences.
5. Create static HTML/CSS/JS with enough visual fidelity for review.
6. If MDS is in scope, apply the shared MDS rules and traceability contract.
7. Run the Browser visual QA policy in `references/html-artifacts.md` when a design image exists. If browser tooling cannot run in a subagent, return that reference's `visual_qa: "pending:main-agent"` handoff rather than marking QA complete.
8. Document design source, navigation, MDS map, merged states, and QA notes in `README.md`.

## Visual fidelity rules

- Favor realistic content, spacing, typography, and state presentation.
- Represent loading, empty, error, selected, disabled, and confirmation states when they matter to review.
- Use mobile-first responsive CSS with desktop expansion rules.
- Keep the prototype static; do not add API calls, framework routing, or build tooling.
- Keep top-level prototype pages for distinct journey steps or layouts, not every Figma state frame.
- Show minor states through toggles, tabs, accordions, inline variant strips, or concise annotated regions within the same page.
- Reuse shared component CSS and markup patterns for repeated cards, rows, forms, dialogs, and navigation.
- If stakeholder review needs side-by-side comparison, render only the changed region side by side rather than duplicating the whole page.

## MDS Component Map in README

When MDS is in scope, include this section in `README.md`:

```markdown
## MDS Component Map

| HTML Element | Intended MDS Component | Props / Variant | Confidence | Notes |
|--------------|------------------------|-----------------|------------|-------|
| `.primary-action` | `Button` | `variant="fill" color="primary" size="lg"` | confirmed | Anchor only for static navigation |
| `.filter-dialog` | `Dialog` | `maxWidth="md"` | confirmed | Static modal behavior |
| `.status-chip` | `Tag` | `color="green" variant="light" size="md"` | confirmed | Success status |
```

## README contents

`README.md` should include:

- What the prototype covers
- How to open and navigate it
- Design image or Figma preview paths reviewed
- Any text/spec-only approval if no image was available
- Merged states and the source frames represented by each page or component variant
- MDS Component Map when MDS is in scope
- Browser visual QA summary only when capture/comparison evidence exists
- Known visual gaps or assumptions

## Validation checklist

- [ ] Saved under `aidlc-docs/design-artifacts/prototype/{feature}/`
- [ ] Design image was read, or user-approved text/spec-only fallback is documented
- [ ] Multi-screen links work with plain anchors
- [ ] Similar states/components are consolidated; page count reflects distinct flows, not minor variants
- [ ] README lists merged states when Figma/source images had near-duplicate frames
- [ ] README documents navigation and source images
- [ ] MDS traceability attributes exist when MDS is in scope
- [ ] README includes MDS Component Map when MDS is in scope
- [ ] Browser visual QA follows `references/html-artifacts.md`; when a design image exists, missing capture/comparison evidence is treated as `pending:main-agent`
- [ ] Visual gaps were fixed or documented
