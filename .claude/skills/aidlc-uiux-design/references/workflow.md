# UX Design Workflow

Step-by-step process for creating HTML UI handoff artifacts during Construction phase.

## Prerequisites

Load foundation docs and inception artifacts before starting:

**Foundation (Brown-field)**:
- `aidlc-docs/foundation/uiux-guideline.md` - Design system reference
- `aidlc-docs/foundation/project-overview-pdr.md` - User personas

**Inception / Spec**:
- `aidlc-docs/specs/{unit}/requirements.md` - Spec-driven requirements (preferred when present)
- `aidlc-docs/story-artifacts/{id}_{feature-name}_user_stories.md` - User stories with acceptance criteria
- Any unit-decomposition artifact available for the feature - use it when present
- Any NFR artifact available for the product or feature - use it when present

If one of the optional requirement artifacts is missing, continue with the best available spec-local requirements, story artifacts, and user prompt context.

## Step 1: Analyze Requirements

Extract design-relevant information:
- User personas and goals
- User stories and acceptance criteria
- Functional requirements
- Non-functional requirements (performance, accessibility)
- Existing design system constraints

## Step 2: Design Wireframes

Create screen layouts for key pages:
- Start with low-fidelity (structure only)
- Show component placement
- Indicate content hierarchy
- Note responsive behavior
- ASCII art or Mermaid sufficient for simple layouts

## Step 3: Specify Components

Reference design system components:
- List components used from design system
- Document child components or internal structure when the component is non-trivial
- Document states (default, hover, active, disabled, error)
- Specify variants (size, color, style)
- Map important tokens to exact component parts, not just high-level categories
- Note any custom components needed

**If Figma `figma-spec.md` is in context:** Read relevant component entries line-by-line and preserve visual intent. Copy radii, fills, typography, padding, and gaps when they map to real tokens or implementation-critical styling. Treat dimensions (`w×h`) as Figma references for proportions, layout hierarchy, target viewport, and minimum viable space; do not prescribe fixed component sizes unless a non-resizable control is explicitly required. Convert sizing into responsive guidance using design-system components, flex/grid structure, min/max constraints, scroll containment, and breakpoint behavior. If `figma-spec.md` does not cover a value, fall back to `uiux-guideline.md`.

## Step 4: Document Interactions

Describe interactive behaviors:
- Click/tap actions and results
- Hover states and tooltips
- Animations and transitions
- Loading states
- Error feedback

## Step 5: Define Accessibility

Ensure WCAG 2.1 AA compliance:
- Keyboard navigation flow
- Screen reader labels and ARIA
- Focus management
- Color contrast (4.5:1 minimum)
- Touch targets (44x44px minimum)

## Step 6: Responsive Design

Specify breakpoint behaviors:
- Mobile (< 768px): Layout and interactions
- Tablet (768px - 1024px): Layout adjustments
- Desktop (> 1024px): Full layout

## Output

Generate HTML artifacts using `references/html-artifacts.md`. Construction/developer handoff writes `aidlc-docs/specs/{spec}/mockup.html`; PO/designer/stakeholder review writes a visual prototype under `aidlc-docs/design-artifacts/prototype/{feature}/`.

When a design image exists, browser Visual QA is part of creating the HTML artifact. Follow `references/html-artifacts.md`; missing capture/comparison evidence is `pending:main-agent`, not complete.

## Validation

Before marking complete:
- [ ] Wireframes show key screens
- [ ] Entry paths and screen structure are documented when needed
- [ ] Components match design system
- [ ] Token usage is mapped to exact component parts
- [ ] Complex components include child structure and behavior notes
- [ ] Accessibility requirements defined
- [ ] Responsive behavior specified
- [ ] Interactions documented
- [ ] HTML artifacts with design images have browser capture/comparison evidence or a documented `pending:main-agent` handoff
