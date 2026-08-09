# Lean Design Document Guidance

Use this guidance for Phase 2 `design.md` when the team wants a short,
decision-dense design instead of the full standard document. It defines the
document shape only; write project-specific content from the approved
requirements, codebase analysis, UI handoff context, and research.

**Why lean**: `design.md` has two readers — a human approver who should absorb
it in one sitting, and the Phase 4 implementation agent that needs decisions,
not prose. Length that doesn't change what either reader does is cost, not
rigor. The most common design failure is not a missing section; it is a design
that ignores the existing codebase. So this template spends its space on
grounding: what already exists, what is reused, what is genuinely new, and why.

**When to use**: most single-unit features. Prefer `standard` when the unit
introduces new architecture, spans multiple services/modules, or needs deep
NFR treatment (security, performance, compliance) that deserves its own
sections.

## Template Structure

```markdown
# Design: {Feature Name}

## Summary
[2–3 short sentences: what is being built, the chosen approach, and which existing
module/layer it lands in. Reference acceptance criteria IDs; do not restate
requirements.]

## Decisions & Open Questions

**Decisions**

| Decision | Choice | Why |
| --- | --- | --- |
[One row per settled decision. Keep the rationale to one line.]

**Open questions**
[Unresolved API, data-contract, copy, Figma, or design-system questions that
implementation must not treat as settled. Use one line each; never resolve one
with a silent guess. Write `None` if there are genuinely none, but a hidden
assumption is not `None`.]

## Architecture
[One Mermaid diagram placing the feature inside the existing system. Use real
module/component names from the codebase and mark which nodes are new vs
existing. Prefer a sequence diagram for integration or request flows. Follow
with 2–4 concise bullets on how the new parts attach to the current architecture.]

## Codebase Alignment
[One row for every element the design introduces or touches. This table is the
core of the document — an element without a verified path means codebase
analysis is not finished.]

| Element | Action | Current path | Follows / Reuses (verified path) |
| --- | --- | --- | --- |
| InvoiceExportService | new | `N/A` | patterned on `src/services/ReportExportService.ts` |
| useInvoiceFilters | modify | `src/hooks/useInvoiceFilters.ts` | extends `src/hooks/useOrderFilters.ts` |
| ExportButton | reuse | `src/components/common/ExportButton.tsx` | as-is |
| retry queue | new | `N/A` | no precedent in codebase |

## Contracts & Data Changes
[Only NEW or CHANGED interfaces, endpoints, schemas, events, props, and data
model changes (tables, fields, migrations). Signature plus 1–2 sentences of
behavior each. Skip anything unchanged.

Tag every entry `new` or `changed` (e.g. a trailing `// new` / `// changed` on
the declaration). For a `changed` element, show only the fields that are added
or altered — mark each `// added` or `// changed` — instead of repeating the
whole existing shape, so the reader sees the delta, not a diff to compute. This
extends the Codebase Alignment Action column (new/modify/reuse) down to field
granularity.]

## UI Design Specification _(only when mockup.html exists or was generated)_

> UI handoff: [mockup.html](./mockup.html)
> Source of truth for visual structure, interaction states, accessibility
> markup, and token/mapping metadata.

[Only the UI constraints implementation will directly reference: key states,
non-obvious interactions, breakpoint changes, implementation-critical tokens.
Cite `mockup.html` instead of duplicating it.]

## Edge Cases & Failure Handling
[Only failure modes and edge states NOT already covered by the reused patterns
in Codebase Alignment; 1 line each. For UI work: empty, loading, validation,
and error states the user will see.]

## Testing Strategy
[3–6 bullets: what proves this works, at which level (unit/integration/E2E),
using the existing test setup — name it. Map coverage to acceptance criteria.]
```

## Rules

- Ground every element: each `modify` or `reuse` row must cite its current file. Each `new` row must cite the verified file/pattern it follows, or explicitly state no precedent exists. When changed behavior follows another pattern, cite that precedent too. If you cannot name the relevant file, stop and read the code before designing further.
- Reuse over rebuild: when similar logic already exists, extend or wrap it. Duplicating existing logic requires a note in the relevant Codebase Alignment row explaining why reuse was rejected.
- Cross-check the Architecture and Contracts sections against `aidlc-docs/foundation/system-architecture.md` and `code-standards.md` (and `uiux-guideline.md` for UI work). When current code and foundation docs disagree, the code wins — note the drift inline where it matters (a Codebase Alignment row or Architecture), or under Open questions if it leaves something unresolved.
- Reference requirements, don't restate them: cite acceptance criteria IDs. Before finalizing, confirm every acceptance criterion maps to at least one design element.
- Readable shape: prose paragraphs are 1–3 sentences; requirement/criterion IDs live in a table column or as a trailing tag on a one-line bullet — sentence text stays free of inline ID parentheticals.
- Describe contracts, not code — the full rule lives in `references/phase-2-design.md § Design Document Creation` ("What `design.md` is"); code fences are for contracts (interfaces, schemas, diagrams), not bodies.
- Make the delta visible: tag each Contracts & Data Changes entry `new` or `changed`, and for a changed element show only the added/altered fields (marked `// added` / `// changed`), not the full unchanged shape — the reader should see what changed without diffing against the current code.
- Keep the section headings above; use a brief `N/A` when a section genuinely does not apply. Include `## UI Design Specification` only when `mockup.html` exists or was generated, and keep it a lean extract that cites `mockup.html`.
- Defer implementation detail to Phase 3 `tasks.md`: no file-by-file edit steps, private helper lists, implementation checklists, or exhaustive test case tables. Avoid implementation tasks, approval text, and next-step boilerplate.
