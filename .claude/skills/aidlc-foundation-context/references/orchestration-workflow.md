# Foundation Analysis Orchestration

Generate multiple foundation documents by acting as an **orchestrator**: resolve missing inputs with the user once, gather shared facts once, dispatch one specialized subagent per document in parallel, then review and reconcile their output into a coherent, non-duplicated set.

This is the path for **2+ documents** (including the full set of five). For a single document, skip orchestration and generate it inline — the coordination overhead isn't worth it for one doc.

## Why orchestrate with subagents

The old approach generated all five docs sequentially in one context. That works, but it has three costs this design removes:

- **Wasted analysis** — each doc re-derives the same facts (tech stack, directory tree, configs). Here the orchestrator runs `repomix` **once** and every subagent draws from the same brief.
- **Context pressure** — five long documents competing for one window. Here each subagent gets a clean context focused on a single doc, so it can go deeper.
- **Late, per-doc duplication checks** — validating each doc in isolation misses overlap *between* docs. Here the orchestrator's reconcile pass is a dedicated cross-doc step, which is where the "one home per fact" rule is actually enforced.

The thing that makes parallel generation safe is that cross-references are just markdown links to **predictable anchors** — the templates fix the section headings, so a subagent can link to `codebase-summary.md#directory-structure` without waiting for that doc to exist. Informational dependencies (architecture needs the vision; codebase needs the stack) are satisfied by the **shared brief**, not by reading sibling docs. So the docs decouple and run at once.

## The orchestration loop

### Step 1 — Scope

- Determine which of the five documents are requested (all five, or a subset).
- Determine **brownfield vs greenfield**: is there an existing codebase to analyze, or is this a new/empty project?
- Resolve the output directory (docs-root rule in SKILL.md) and record the resolved path in the brief.

### Step 1.5 — Clarify missing inputs (before the brief exists)

The orchestrator is the only participant that can talk to the user, so this is the one place clarification can happen. Subagents run in parallel with no interactive channel — whatever is unresolved when they start gets invented by five agents independently, in five incompatible ways.

Run the input gate in `references/input-gate.md` for the **union** of the requested documents:

- Harvest first (request, README, configs, existing foundation docs, prior artifacts, repomix for brownfield) — never ask what is already written down.
- Compare what you have against each requested document's input floor.
- Ask the user about the material gaps, batched by blast radius (product intent → technical shape → design), with grounded options and a defer choice. Keep asking until each floor input is answered or explicitly deferred.
- For greenfield multi-document runs, play the consolidated answers back for confirmation before dispatching. Five documents built on a misread answer is the most expensive mistake available here, and the playback is the last free moment to catch it.

Brownfield runs often clear this step with a single round about product intent, since repomix answers the factual questions. Greenfield runs will not — accept that a real conversation happens here, because the alternative is five documents of fiction.

### Step 2 — Build the shared brief (once)

This is the orchestrator's real job: **arrange the information** so subagents don't each rediscover it. Construct one Shared Facts Brief following `references/subagent-brief.md`, marking every fact **Observed** / **Confirmed** / **Assumed**.

- **Brownfield**: run `repomix` **one time**, save its output to a working file (e.g. `.aidlc-tmp/repomix-output.md`), and distill the facts into the brief (stack, directory tree, configs, scripts, design-system signal) as *Observed*. Point subagents at that saved file so none of them re-run repomix.
- **Greenfield**: there is nothing to scan, so the brief is built from Step 1.5 — the user's confirmed stack, structure, and design intent, recorded as *Confirmed*, plus anything they explicitly deferred, recorded as *Assumed* with the value you chose. Recording them centrally is what keeps the architecture and codebase subagents consistent. Do not fill a gap here that Step 1.5 left open: put it in the brief's **Open inputs** list so the owning subagent flags it instead of quietly inventing a value.

The brief also carries the **cross-reference map** (which anchors each doc should link to) and the **run scope** (which docs exist this run, so nobody links to a doc that isn't being generated).

### Step 3 — Dispatch subagents in parallel

Spawn one subagent per requested document **in a single turn** so they run concurrently. Use the specialized AI-DLC agent each document is aligned with:

| Document | Subagent (`agentType`) | Purpose to state in the prompt | Out of scope for that subagent |
|---|---|---|---|
| project-overview-pdr.md | `ai-assistant-product-owner` | business vision, personas, product scope | user stories, acceptance criteria, technical detail |
| system-architecture.md | `ai-solutions-architect` | architecture decisions and their WHY | full directory tree, full configs, setup steps |
| codebase-summary.md | `ai-solutions-architect` | structure, dependencies, configs, setup (WHAT/WHERE) | architecture rationale, coding patterns, UI examples |
| code-standards.md | `ai-solutions-architect` | how to write code in *this* project, named for its real stack | full configs, UI examples, architecture decisions |
| uiux-guideline.md | `ai-design-orchestrator` | the project-wide design system other docs link to | spec mockups, `mockup.html`, prototypes |

The last two columns matter more than they look. Each of these agents has its own habitual output — the product owner reaches for user stories, the design orchestrator for HTML mockups — and those are the right outputs in Inception and Construction, just not here. Naming the phase, the purpose, and the exclusions is what keeps a capable agent from producing something good and wrong.

Each dispatch prompt (template in `references/subagent-brief.md`) tells the subagent to **invoke the `aidlc-foundation-context` skill itself — that skill by name, not an adjacent one** — and hands it:
- the **phase (Foundation), its document's purpose, and what is out of scope** for it (columns above),
- the Shared Facts Brief (inline), with facts marked Observed / Confirmed / Assumed,
- the instruction to **ask the user nothing and invent nothing** — it has no interactive channel, so any gap the brief left open goes into `unresolved_inputs` in its return rather than being filled with a plausible value,
- the instruction to follow the skill's **single-document (inline) path** for its type — generating one doc, so the skill routes it inline and it does **not** spawn further subagents,
- the paths to **its** `workflow.md` + `template.md` to read and follow,
- its **ownership boundary** — what it owns vs. what it must cross-reference instead of restating,
- the exact cross-reference anchors to emit,
- the instruction to **not re-run repomix** (read the saved output if it needs the full tree/configs),
- the instruction to **self-validate** (template, length, exclusions) and write its file, then
- return the **structured summary** (schema in `references/subagent-brief.md`) so the orchestrator can reconcile cheaply.

Subagents write distinct files, so parallel writes to `aidlc-docs/foundation/` don't conflict — no worktree isolation needed.

### Step 4 — Review and reconcile

When the subagents return, the orchestrator makes the set coherent. Use the structured summaries first (cheap), then spot-read the actual files for anything flagged.

**Duplication matrix** — confirm each fact lives in exactly one home, per the Information Ownership table in `references/cross-reference-patterns.md`.

**Cross-references** — every `see [Doc](./doc.md#anchor)` link resolves to a real file (in this run's scope) and a real section anchor.

**Consistency** — stack names/versions, persona names, and product naming match across docs.

**Assumptions and open inputs** — collect `assumptions_or_gaps` and `unresolved_inputs` from every return and report the union to the user in one place, naming which document each affects. Scattered across five documents these are invisible; listed together they're a short, actionable review list. If an unresolved input turns out to be load-bearing, ask the user now and patch the affected document rather than shipping the set with a hole in it.

**Fix** — for small overlaps or broken links, edit the file directly. For a document that badly ignored its boundary, re-dispatch just that one subagent with a corrective note. Then clean up the working repomix file.

## Document relationships

```
project-overview-pdr.md   → references system-architecture.md, uiux-guideline.md
system-architecture.md    → references codebase-summary.md
codebase-summary.md       → source of truth for configs (no upward refs)
code-standards.md         → references codebase-summary.md
uiux-guideline.md         → source of truth for design (no upward refs)
```

These are **reference** relationships, not generation-order dependencies — with the shared brief, all requested docs generate at once.

## Next steps after foundation analysis

1. Review the generated documents for accuracy.
2. Confirm the duplication matrix and cross-references (Step 4).
3. Run `/aidlc.foundation.foundation-report` to consolidate findings.
4. Proceed with implementation using the foundation docs as reference.
