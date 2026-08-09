# Product Overview Workflow

**Output**: `aidlc-docs/foundation/project-overview-pdr.md`
**Agent**: ai-assistant-product-owner
**Target Length**: 250-350 lines (guideline, not a cap)

## Inputs this document cannot invent

Pure intent: nothing in a codebase reveals *why* a product exists or *who* it is for, so this is the one document whose input floor is identical on greenfield and brownfield (floor and question format in `references/input-gate.md`).

Invented personas are the most expensive fabrication in the AI-DLC chain — Inception reuses these names verbatim, so a made-up "Sarah, the Operations Lead" propagates into stories, acceptance criteria, and eventually code, and nobody re-questions her.

Inline: ask before writing. Dispatched: use the brief's Confirmed values, hedge Assumed ones in place, report gaps in `unresolved_inputs`.

## When dispatched as a subagent

If you received a **Shared Facts Brief**, follow your dispatch prompt's rules (contract in `references/subagent-brief.md`): use the brief's facts without re-running repomix, ask the user nothing, cross-reference anything outside your ownership, self-validate (below), write the file, and return the structured summary.

## Focus

**Purpose**: Business vision, user needs, business scope

### Include

- Product vision statement (what, why, vision)
- Target audience (2-3 personas with goals/pain points)
- Business objectives
- Product scope (MVP features in/out)
- Content strategy (key messages, tone)

### Exclude

- ❌ Technical implementation details
- ❌ Code or configuration examples

## Process

1. Analyze business domain and product vision
2. Document key features and MVP scope
3. Identify target audience and user personas
4. Extract Product Development Requirements
5. Define content strategy and key messages

## Required Sections

1. Product Vision (what, why, vision statement)
2. Target Audience & User Personas (2-3 personas)
3. Business Objectives
4. Product Scope (MVP features, out of scope)
5. Content Strategy (key messages, tone of voice)
6. Assumptions & Open Inputs (omit only when nothing was assumed or left open)

## Constraints

- Focus on business value and user needs
- No technical implementation details
- Every persona, objective, and scope line traces to something the user said or an existing artifact — anything you chose yourself is marked **Assumed** and listed in section 6

## Post-generation validation (Todo Tool)

Add Todo: "Validate: project-overview-pdr.md" then confirm:
- Required Sections present
- 250-350 lines (or longer when justified)
- No technical details duplicated from other docs
- No invented persona, objective, or scope claim — assumptions marked and listed
- Content concise (no filler)
