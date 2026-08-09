---
name: aidlc-requirements-engineering
description: Transform business needs into testable user stories for the AI-DLC Inception phase. Use this skill whenever someone asks to create user stories, write requirements, define acceptance criteria, capture a feature specification, kick off feature planning, build a product backlog, break down epics, write a BRD, or describe what a feature should do, even if they never say "user story" and even if the request is informal like "what should the login feature do?" or "list out what the dashboard needs". Use it for both greenfield planning and brownfield backlog cleanup. The skill clarifies ambiguity first, reuses foundation context, splits multi-goal requests into independently valuable stories, flags scope conflicts, and writes artifacts to aidlc-docs/story-artifacts/ using shared default, checklist, Given/When/Then table, or configured custom story-block formats.
argument-hint: "[requirements|BRD|Jira|ADO|feature description] [--template default|checklist|given-when-then-table|custom] [--docs-root path]"
version: 1.6.0
license: MIT
---

# AIDLC Requirements Engineering

Transform business needs into testable user stories with acceptance criteria for the AI-DLC Inception phase.

## Docs Root

Artifact paths below live under `{aidlc-docs-root}`. The scaffold script resolves it automatically; when reading context files yourself, use the same precedence:

1. Explicit `--docs-root` argument
2. `aidlcDocsPath` in `.mtv-aidlc/extension-config.json`
3. `aidlc-docs/` at the repo root

## Workflow

### 1. Gather existing context

Stories that ignore existing product context create rework: personas drift, scope conflicts surface late, and settled decisions get re-litigated. Start with the user's request and any provided BRD, Jira/ADO item, markdown artifact, screenshot, draft, or notes, then load only the sources that could affect the decisions ahead:

| Source | Load when | Extract |
| --- | --- | --- |
| User-provided material | Always | Requested output, feature intent, known actors, candidate scope, explicit constraints |
| `{aidlc-docs-root}/foundation/project-overview-pdr.md` | Present and relevant | Personas, business goals, product scope, objectives |
| `{aidlc-docs-root}/foundation/system-architecture.md` | Technical constraints, integrations, or NFRs may affect stories | Stack constraints, integration points, limits, reliability/security expectations |
| `{aidlc-docs-root}/foundation/codebase-summary.md` | Brownfield or existing-module requests | Existing modules, boundaries, current product shape |
| `{aidlc-docs-root}/foundation/uiux-guideline.md` | UI, workflow, accessibility, or interaction requirements | UX patterns, flow conventions, components |
| `{aidlc-docs-root}/foundation/code-standards.md` | Conventions affect wording, naming, reuse, or downstream traceability | Requirement wording conventions, naming expectations, reuse constraints |
| `{aidlc-docs-root}/story-artifacts/` and `{aidlc-docs-root}/specs/` | Related work may already exist | Prior stories, scope decisions, accepted constraints, reusable terminology |
| `{aidlc-docs-root}/brainstorming/` | A Decision Record may have settled direction, scope, or prioritization for this feature (or one was handed off by `aidlc-brainstorm`) | Decision and scope boundary — prior decisions stories must align with, not suggestions |
| Targeted docs/code | Brownfield behavior or touchpoints are unclear | Existing behavior, affected areas, public contracts, constraints not captured in docs |

Reuse foundation persona names exactly as written and never invent prior decisions. If expected context is missing, partial, or stale, proceed from user input and note the gap in the artifact rather than hiding the uncertainty.

### 2. Clarify before generating

This is the step that most determines artifact quality: a requirement guessed instead of confirmed produces a confident-looking artifact that is wrong at its core. Read `references/elicitation-guide.md` and apply its Pre-Generation Decision Gate. Three rules are absolute:

- **Never guess the core of the requirement** — expected output, actor, acceptance criteria, and scope are never assumable. If any is unclear, ask; when in doubt whether something is unclear, ask. "Make reasonable assumptions" from the user does not override this.
- **In one response, either clarify or generate — never both.** A generated artifact anchors the discussion and buries open questions inside it, so users react to the draft instead of deciding what it should have been.
- **Generate only from a confirmed understanding.** After clarification answers arrive — or when proceeding with stated low-stakes assumptions — confirm the consolidated requirement with the user per the guide's "Confirm the Requirement Before Generating" step. Only a fully specified request that needed no clarification and no assumptions skips this confirmation.

If unresolved decisions remain, ask following the guide's question format, then stop — no scaffolding, saving, or story generation in that response.

### 3. Decompose into story candidates

- Split multiple user-visible outcomes into separate stories. Never split by technical layer (frontend vs backend) — layer-split stories cannot ship value independently.
- If the input is an existing BRD, backlog export, or Jira/ADO ticket set, follow `references/brownfield-import.md` for mapping source items to stories, preserving ticket IDs, and deduplicating against existing artifacts.
- Flag obvious scope conflicts with the PDR before generating, so the user decides scope rather than discovering the conflict in review.

### 4. Scaffold the artifact

After the requirement is confirmed (step 2), run:

```bash
python3 .claude/skills/aidlc-requirements-engineering/scripts/story_artifact.py scaffold "{feature-name}" [--template {template}] [--source {input-file}]...
```

The script resolves the docs root and template (explicit flag → workspace config → default), stamps compliant frontmatter including `intent` and `source_artifacts`, chooses the next 3-digit artifact ID, and prints the saved path plus a `Resolved template:` line. Pass the user's `--template` value through unchanged and one `--source` per input document the stories derive from. If the script warns about a fallback, tell the user which template was actually used.

The scaffold is structure only. Every placeholder must be replaced with real story content before the artifact is presented for review.

### 5. Generate stories inside the scaffold

Read `references/quality-criteria.md` first, then the story-block reference for the template the script reported (`../_aidlc-shared/user-story-blocks/{template}.md`, or the configured custom file) so acceptance criteria follow that format's structure and numbering exactly. While writing:

- Use the selected format consistently across all stories; do not mix templates unless the user explicitly asks for a hybrid.
- Write from the business/user perspective; include technical terms, implementation details, or UI prescriptions only when explicitly requested or required to express observable behavior or a confirmed constraint.
- Include Priority (High/Medium/Low); add optional `Business Value` when prioritization needs justification, and `Related ADO` / `Related Jira` IDs when importing from or syncing to a ticket system.
- Keep `## Overview`; remove `## Dependency Notes` unless sequencing adds real value.

### 6. Save, then run the Product Owner review gate

Save the first complete draft to `{aidlc-docs-root}/story-artifacts/` before presenting anything — review must target the real file the user will iterate in, not chat output.

Then run the review gate described in `references/po-review-gate.md`: hand the saved artifact to a review-only `ai-assistant-product-owner` subagent, which returns exactly one verdict — `PASS`, `FIX_BEFORE_USER_REVIEW`, or `NEEDS_USER_DECISION`. The reference defines the handoff package, verdict handling, the single-rerun limit, and the inline fallback when subagent tooling is unavailable. Do not ask the user for feedback until the gate passes or a decision they own is surfaced.

### 7. Iterate in the saved file

Share the artifact path and ask for feedback. Revise only the stories or sections the user mentions — regenerating everything discards review effort and breaks stable criterion IDs, which design and tasks cite (e.g., `per AC-2.3`). If a new ambiguity surfaces, ask before changing scope. Explicit approval is what turns the saved draft into the approved story artifact; stop iterating when the user approves or signals they are done.

## Template Selection

| Template | Story block | Use when |
| --- | --- | --- |
| `default` | `../_aidlc-shared/user-story-blocks/default.md` | Formal AI-DLC artifacts need hierarchical EARS-Lite acceptance criteria and downstream traceability. |
| `checklist` | `../_aidlc-shared/user-story-blocks/checklist.md` | Stakeholders need checkable acceptance criteria grouped by category for backlog review. |
| `given-when-then-table` | `../_aidlc-shared/user-story-blocks/given-when-then-table.md` | QA, business analysts, or UI teams need acceptance criteria as a Given/When/Then table. |
| `custom` | `userStory.customTemplatePath` in `.mtv-aidlc/extension-config.json` | The workspace has a team-owned Markdown story-block template (story-block only, not a full artifact wrapper). |

Resolution is the script's job: explicit `--template` wins, then workspace config, then `default` (with a printed warning on any fallback). If the user asks for a template outside this table, ask them to choose a supported one and stop.

## Output

- Directory: `{aidlc-docs-root}/story-artifacts/`
- Filename: `{id}_{feature-name}_user_stories.md` — kebab-case slug, 3-digit sequential ID (e.g., `001_authentication_user_stories.md`)
- Document structure: short context note when expected context was missing or inconsistent, then `## Overview`, `## User stories`, and `## Dependency Notes` only when sequence matters

## References

- `references/elicitation-guide.md` - Pre-Generation Decision Gate, materiality test, question format
- `references/quality-criteria.md` - INVEST, perspective defaults, scenario dimensions, quality checklist
- `references/brownfield-import.md` - Normalizing BRDs, backlogs, and Jira/ADO tickets into story artifacts
- `references/po-review-gate.md` - Product Owner review gate protocol and verdict handling
- `references/story-artifact-wrapper.md` - Artifact wrapper consumed by the scaffold script
- `scripts/story_artifact.py` - Scaffold script (docs-root + template resolution, frontmatter, IDs)
- `../../agents/ai-assistant-product-owner.md` - Review-only Product Owner subagent definition
- `../_aidlc-shared/user-story-blocks/` - Shared story-block formats (default, checklist, given-when-then-table)
