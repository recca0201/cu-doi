# UI/UX Guideline Workflow

**Output**: `aidlc-docs/foundation/uiux-guideline.md`
**Agent**: ai-design-orchestrator
**Target Length**: 450-650 lines (guideline, not a cap)

## Inputs this document cannot invent

The riskiest document in the set: 450–650 lines declaring itself the single source of truth for colour, typography, spacing, and components, linked from every other document. Generated without design input, essentially all of it is invented while reading as authoritative — and UI code then gets built against a palette nobody chose. Floor in `references/input-gate.md`.

If a design system is named (MTI Design System, Magenta/MDS, a Tailwind preset, an existing kit), **read it rather than describing it** — restating a real system from memory produces plausible-but-wrong token names, which is harder to catch than an obvious gap.

Two honest outcomes when design input is missing: ask the user, or — if the project has no UI, or design genuinely hasn't started — propose skipping this document and say why, rather than shipping a fabricated design system. Dispatched: use the brief's Confirmed design signal and report gaps in `unresolved_inputs`.

## When dispatched as a subagent

If you received a **Shared Facts Brief**, follow your dispatch prompt's rules (contract in `references/subagent-brief.md`): use the brief's facts and design signal without re-running repomix, ask the user nothing, self-validate (below), write the file, and return the structured summary. If the brief flags the project as backend-only with no design system, tell the orchestrator this doc may be N/A rather than inventing one.

## Focus

**Purpose**: Complete design system (SINGLE SOURCE OF TRUTH)

### Include

- Design philosophy & principles
- Design system (colors, typography, spacing) - DETAILED
- Layout system (grid, breakpoints, spacing scale)
- Component library (buttons, cards, forms) WITH CODE EXAMPLES
- Responsive design patterns
- Accessibility guidelines (WCAG 2.1 AA)
- Animation & interactions

### Exclude

- Nothing - this is comprehensive and authoritative

### Note

Other documents reference this for all design information.
This is the single source of truth for:
- Color palette and values
- Typography specifications
- Component code examples
- Design tokens
- Spacing and layout system

## Process

1. Document design philosophy
2. Extract complete design system
3. Inventory UI components
4. Document responsive patterns
5. Document accessibility guidelines
6. Document animations/interactions

## Required Sections

1. Design Philosophy
2. Design System (colors, typography, spacing) - DETAILED
3. Layout System
4. Component Library (WITH CODE EXAMPLES)
5. Responsive Design Patterns
6. Accessibility Guidelines
7. Animation & Interactions
8. Assumptions & Open Inputs (omit only when nothing was assumed or left open)

## Constraints

- Single source of truth for design
- Be comprehensive - other docs reference this
- Comprehensive means *complete about what was given*, never *filled in to look complete* — token values, component variants, and a11y targets are Observed or Confirmed, or explicitly marked **Assumed**

## Post-generation validation (Todo Tool)

Add Todo: "Validate: uiux-guideline.md" then confirm:
- Required Sections present
- 450-650 lines (or longer when justified)
- Single source of truth (other docs link here)
- No invented palette, type scale, or token names — assumptions marked and listed
- Content concise (dense, no filler)
