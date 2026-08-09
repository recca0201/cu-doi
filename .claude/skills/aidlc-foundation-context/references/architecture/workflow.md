# System Architecture Workflow

**Output**: `aidlc-docs/foundation/system-architecture.md`
**Agent**: ai-solutions-architect
**Target Length**: 450-650 lines (guideline, not a cap)

## Inputs this document cannot invent

This document's value is the WHY, and a fabricated WHY is worse than no document — it manufactures a rationale nobody agreed to, and later decisions get justified against it. Floor by project type in `references/input-gate.md`; brownfield mostly needs deployment target, integration intent, and the NFR bar, since code rarely states any of the three.

The C4 diagrams make this sharper than it looks: a Container diagram needs real containers, a System Context diagram real external actors. Drawing plausible ones is how invented architecture enters a project, because the diagram is then read as the agreed design.

Inline: ask before writing. Dispatched: use the brief's Confirmed values, hedge Assumed ones in place, report gaps in `unresolved_inputs`.

## When dispatched as a subagent

If you received a **Shared Facts Brief**, follow your dispatch prompt's rules (contract in `references/subagent-brief.md`): use the brief's facts without re-running repomix, ask the user nothing, cross-reference anything outside your ownership, self-validate (below), write the file, and return the structured summary.

## Focus

**Purpose**: Technical decisions and their WHY

### Include

- C4 Model diagrams (System Context, Container, Component levels) using mermaid
- Architecture patterns & deployment model
- Technology stack with detailed rationale
- Component hierarchy & data flow (high-level)
- Infrastructure architecture (hosting, CDN, pipeline)

### Exclude

- ❌ Detailed directory tree (10-20 lines max)
- ❌ Full configuration files
- ❌ Component implementation examples
- ❌ Setup steps

## Process

1. Identify architecture patterns and deployment model
2. Create C4 diagrams (System Context, Container, Component) using mermaid-diagramming skill
3. Document technology stack with detailed rationale
4. Map component architecture and data flow
5. Document infrastructure architecture

## Required Sections

1. Architecture Overview & Pattern
2. C4 Model Diagrams
   - Level 1: System Context Diagram (users, external systems)
   - Level 2: Container Diagram (apps, APIs, databases, tech choices)
   - Level 3: Component Diagram (services, modules, dependencies)
3. Technology Stack (detailed with rationale)
4. Application Architecture (high-level)
5. Infrastructure Architecture
6. Assumptions & Open Inputs (omit only when nothing was assumed or left open)

## Constraints

- Use C4 Model for architecture visualization (3 levels only, no Code level)
- Diagram only containers, actors, and integrations that are Observed or Confirmed — an unconfirmed element is marked as such in the diagram legend or left out and noted in section 6
- Use mermaid syntax for all diagrams (reference mermaid-diagramming skill)
- Directory tree: high-level only (10-20 lines max)
- No full config files, component examples, or setup steps
- Focus on WHY, not HOW

## Post-generation validation (Todo Tool)

Add Todo: "Validate: system-architecture.md" then confirm:
- Required Sections present (incl. 3 C4 diagrams)
- 450-650 lines (or longer when justified)
- No duplication: directory tree/configs/setup steps belong in codebase-summary
- No invented rationale, integration, or NFR target — assumptions marked and listed
- Content concise (tight bullets, minimal repetition)
