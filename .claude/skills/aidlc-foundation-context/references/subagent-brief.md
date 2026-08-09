# Shared Brief, Dispatch Prompt & Return Schema

Everything the orchestrator needs to hand off a document to a subagent and get back something it can reconcile. Three parts: the **Shared Facts Brief** (built once), the **dispatch prompt** (one per document), and the **structured return** (one per subagent).

---

## 1. Shared Facts Brief

Built **once** by the orchestrator — after the input gate (Step 1.5) has resolved the missing inputs — and embedded inline in every dispatch prompt. It is the single source of shared truth so no subagent re-derives facts or invents them. Keep it distilled — a summary, not raw repomix. When a subagent needs the *full* tree or *full* configs, it reads the saved repomix output file (brownfield) or the actual repo.

Every fact carries its provenance: **[Observed]** read from code, **[Confirmed]** stated or chosen by the user, **[Assumed]** the user deferred and the orchestrator chose. Subagents rely on these markings to know what to hedge in the document, so a fact with no marking is a defect in the brief.

```markdown
# Shared Facts Brief — {Project Name}

## Project
- Name: {name}
- One-liner: {what it is}
- Type: brownfield | greenfield
- Output dir: {resolved docs root}/foundation/
- Repomix output (brownfield): {path to saved file, e.g. .aidlc-tmp/repomix-output.md} | N/A greenfield

## Business context (seeds product-overview; informs others)
- Vision: {1–2 sentences} **[Confirmed | Assumed]**
- Primary users / personas: {names + one-line goal each} **[Confirmed | Assumed]**
- Business objective: {the point of the product} **[Confirmed | Assumed]**
- Scope boundary: {in MVP / explicitly out} **[Confirmed | Assumed]**

## Tech stack
- Language(s): {e.g. TypeScript 5.x} | Framework(s): {e.g. Next.js 14} **[Observed | Confirmed | Assumed]**
- State / data: {e.g. Redux Toolkit, SQLAlchemy} **[…]**
- Key libraries: {short list with versions} **[…]**
- Deployment / hosting: {target} **[…]**   ·   NFR bar: {scale, availability, security expectations} **[…]**

## Structure & configs
- Directory tree (high-level): {top-level dirs + one-line purpose each; full tree lives in codebase-summary} **[Observed | Confirmed | Assumed]**
- Config files present: {list — package.json, tsconfig.json, .eslintrc, pyproject.toml, …} **[…]**
- Scripts / commands: {dev, build, test, …} **[…]**

## Design signal
- Has UI: yes | no **[Observed | Confirmed]**
- Design system source: {detected or named system, e.g. MTI Design System / Tailwind / brand kit} | None yet **[Observed | Confirmed | Assumed]**
- Palette & typography: {tokens or brand values} **[…]**   ·   Platforms / breakpoints: {…} **[…]**   ·   A11y bar: {e.g. WCAG 2.1 AA} **[…]**
- If backend-only and uiux is requested: flag to orchestrator — uiux may be N/A

## Open inputs (unresolved after the input gate — do NOT fill these in)
- {input}: {which document it affects, and why it stayed open}
- (none)

## Run scope (which docs exist THIS run — only cross-ref these)
- [ ] project-overview-pdr.md
- [ ] system-architecture.md
- [ ] codebase-summary.md
- [ ] code-standards.md
- [ ] uiux-guideline.md

## Cross-reference map (link targets by owner; see cross-reference-patterns.md for anchors)
- Business vision  → project-overview-pdr.md#product-vision
- Tech stack WHY   → system-architecture.md#technology-stack
- Directory tree / configs → codebase-summary.md#directory-structure , #configuration-files
- Code conventions → code-standards.md
- Design system    → uiux-guideline.md#design-system
```

---

## 2. Dispatch prompt template

One per requested document, all spawned **in the same turn** for concurrency. Fill the `{...}` slots. Use `agentType` from the table in `orchestration-workflow.md`.

A subagent inherits none of the orchestrator's context — not the phase, not which document it owns, not which skill governs it. Everything it needs to route correctly has to be stated in the prompt. The three lines that do the most work are the **skill to invoke**, the **phase and purpose**, and **what is out of scope for this document**: without them a capable agent will still produce something reasonable-looking, just not a foundation document — a product-owner agent drifts toward user stories, a design agent toward mockups.

```
You are generating ONE AI-DLC foundation document: {document filename}.

- AI-DLC phase: **Foundation** (not Inception, not Construction)
- Purpose: {this document's job in one line — e.g. "architecture decisions and their WHY"}
- Out of scope for you: {what this document explicitly does not produce — e.g. "user stories,
  spec mockups, implementation tasks"}

FIRST, invoke the `aidlc-foundation-context` skill (Skill tool) and follow it. Use that skill,
not a differently-named one that sounds adjacent — `aidlc-requirements-engineering` produces
Inception user stories and `aidlc-uiux-design` produces Construction HTML mockups; neither
produces a foundation document. If you find yourself writing stories, tasks, or a mockup,
you have routed to the wrong skill.

You are generating a SINGLE document, so the skill routes you to its
**single document (inline)** path — do NOT spawn further subagents. The skill's
workflow + template for your document type are the spec you must follow:
- Workflow:  .claude/skills/aidlc-foundation-context/references/{type}/workflow.md
- Template:  .claude/skills/aidlc-foundation-context/references/{type}/template.md

## Shared Facts Brief (authoritative — do NOT re-derive these facts)
{paste the Shared Facts Brief here}

## Your ownership boundary
You OWN: {this doc's owned facts — e.g. "tech stack rationale + C4 diagrams"}.
For anything you do NOT own, do NOT restate it — cross-reference instead using the
links in the brief's cross-reference map (format: `see [Doc](./doc.md#anchor)`).
Only link to documents listed in the brief's Run scope.

## Rules
- Do NOT ask the user anything — you have no interactive channel. The orchestrator already ran
  the input gate; the brief is what came back from it.
- Do NOT invent a value for anything in the brief's **Open inputs**, and do not upgrade an
  **[Assumed]** fact into a stated decision. Write the document from what the brief supports,
  hedge Assumed values in place (e.g. "**Assumed:** PostgreSQL — no infra config present"),
  list them in an `## Assumptions & Open Inputs` section, and report them in your return.
  A confident-sounding guess here is read downstream as a decision, which is the one failure
  this pipeline is built to prevent.
- Do NOT run repomix. All shared facts are in the brief; if you need the full directory
  tree or full config contents, read {repomix output path} (brownfield) or the repo directly.
- When you name specific file paths in examples, use paths consistent with the brief's
  directory tree — don't invent a divergent sub-path (e.g. if the tree says `lib/github/`
  and `tests/e2e/`, don't write `lib/github-api/` or a top-level `e2e/`). codebase-summary
  owns the structure; every other doc's example paths should match it so a reader can follow them.
- Respect the workflow's Include/Exclude lists — excluded content belongs to another doc; link to it.
- {greenfield only} The project has no code yet — mark observed-style sections as **Planned**,
  derived from the brief's Confirmed stack/structure. "Planned" describes something the user
  agreed to build; it is not a label for something you decided on their behalf — that is **Assumed**.
- Self-validate before returning: template sections present, length near the guideline range,
  exclusions respected, cross-links (not duplication) used, every Assumed value marked and listed.

## Output
- Write the document to: {output dir from the brief}/{document filename}
- Then return the structured summary below as your final message (raw JSON, nothing else).

{paste the return schema}
```

---

## 3. Structured return schema

The subagent's final message. Lets the orchestrator reconcile from summaries first and only spot-read files for flagged issues.

```json
{
  "document": "system-architecture.md",
  "path": "aidlc-docs/foundation/system-architecture.md",
  "line_count": 512,
  "sections_emitted": ["Architecture Overview", "C4 Diagrams", "Technology Stack", "Application Architecture", "Infrastructure"],
  "facts_owned": ["tech stack rationale", "C4 model diagrams"],
  "cross_refs_emitted": ["codebase-summary.md#directory-structure", "uiux-guideline.md#component-library"],
  "self_validation": { "template_match": true, "length_ok": true, "exclusions_respected": true, "assumptions_marked": true },
  "assumptions_or_gaps": "Assumed PostgreSQL from SQLAlchemy usage; no infra config found in repo.",
  "unresolved_inputs": [
    { "input": "target deployment platform", "affects": "Infrastructure Architecture section", "written_as": "left open — section notes the decision is pending" }
  ]
}
```

`unresolved_inputs` is the pressure valve that makes "don't invent" survivable: a subagent that hits a genuine gap has somewhere to put it other than the document. Return `[]` when the brief covered everything.

The orchestrator reads every return, checks the duplication matrix and that each `cross_refs_emitted` target is in scope and points at a real anchor, then fixes or re-dispatches as needed, and surfaces the union of `assumptions_or_gaps` + `unresolved_inputs` to the user (Step 4 of `orchestration-workflow.md`).
