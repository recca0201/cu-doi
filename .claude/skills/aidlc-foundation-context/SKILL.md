---
name: aidlc-foundation-context
description: Use this skill whenever you need to generate, update, or review AI-DLC foundation documentation — even if the user just says "document this project", "analyze this codebase", "help me understand the project structure", or "set up foundation docs". Covers all five foundation documents: product overview (business vision, personas), system architecture (C4 diagrams, tech rationale), codebase summary (directory structure, config summaries, setup), code standards (conventions, patterns), and UI/UX guideline (design system). Clarifies missing inputs with the user before generating instead of inventing them — especially on greenfield projects where there is no codebase to observe. Trigger on requests to run any aidlc.foundation.* command, start a new project (greenfield), document an existing codebase (brownfield), or generate any subset of the five foundation documents.
---

# AI-DLC Foundation Context

Generate focused, non-duplicated foundation documentation for AI-DLC projects. Five documents, each owning a distinct slice of knowledge — everything else cross-references.

**Output directory**: `aidlc-docs/foundation/`. Here and throughout this skill's references, `aidlc-docs/` means the configured docs root: `aidlcDocsPath` from `.mtv-aidlc/extension-config.json` when set, otherwise `aidlc-docs/` at the workspace root. Resolve it once; in orchestration, record the resolved path in the Shared Facts Brief.

## Foundation Documents

| Document | Owns |
|---|---|
| project-overview-pdr.md | Business vision, personas, product scope |
| system-architecture.md | Architecture decisions and WHY |
| codebase-summary.md | Directory structure, configs, setup steps |
| code-standards.md | Code conventions and patterns |
| uiux-guideline.md | Design system (single source of truth) |

Per-document length targets live in each `references/{type}/workflow.md`.

## Core rules

- **One home per fact**: each piece of information lives in exactly one document; all others link to it with `For X, see [Doc](./doc.md#section)`.
- **Length targets are guidance, not caps**: the lower number is a soft floor for thoroughness; going over the upper number is fine when the content earns it. Prefer completeness and clarity over hitting a ceiling — never pad or truncate just to hit a number.
- **Validate before finishing**: each document is validated for template, length, no-duplication, and concision. In orchestration each subagent self-validates its own doc; the orchestrator then validates *across* docs (duplication + cross-references).
- **Greenfield vs brownfield**: for existing projects, use `repomix` to analyze the codebase. For new/empty projects there is nothing to scan — the missing facts come from the user through the input gate below, not from invention.
- **Never invent a fact the document presents as decided**: mark every fact **Observed** (read from code), **Confirmed** (the user said it), or **Assumed** (the user deferred and you chose). An unmarked guess is indistinguishable from a decision.

## Step 0 — Resolve inputs before writing anything

Foundation documents are consumed downstream as settled fact: Inception pulls personas from the product overview, specs inherit the stack from system-architecture, UI work treats uiux-guideline as the single source of truth — and nobody re-checks them. A guessed value doesn't stay a guess; it propagates into stories, specs, and code wearing the authority of documentation. A question costs one turn, so the trade is never close.

Read `references/input-gate.md` and run it before generating anything:

1. **Harvest** what already exists — the user's request, README, configs, existing foundation docs, prior story-artifacts and Decision Records. Never ask for something already written down.
2. **Check each requested document against its input floor** — the facts that document cannot honestly assert without input (per-document table, greenfield vs brownfield, in the gate).
3. **Ask** (`AskUserQuestion`) about every material unknown, with concrete grounded options and a defer choice. Keep going until each floor input is either answered or explicitly deferred by the user — there is no round cap, and clarifying and generating never share a response.
4. **Record** assumptions visibly: an `## Assumptions & Open Inputs` section in the document, and `unresolved_inputs` in a subagent's return.

Greenfield is where this matters most — with no codebase, nearly everything the five documents assert would otherwise be invented. Brownfield usually needs only intent-level questions, since code answers structure, stack, and conventions on its own; asking there what repomix already shows is friction, not diligence.

**Who asks**: whoever is talking to the user. Inline single-document runs ask directly. In orchestration the **orchestrator** asks once for the whole run before dispatch (Step 1.5 in `references/orchestration-workflow.md`); **subagents never ask** — they use the brief's Confirmed/Assumed values and report leftovers in `unresolved_inputs`. If this skill is invoked inside a subagent that was spawned before any clarification happened, don't invent the gaps — generate what the inputs support and return the open ones.

## Choose the path by how many documents are requested

- **One document** → generate it inline (below). Orchestration overhead isn't worth it for a single doc.
- **Two or more documents** (including all five) → **orchestrate with subagents** (below). This is the default for "document this project" / full foundation requests.

## Single document (inline)

Run the input gate for that one document first (its floor row in `references/input-gate.md`), then load only what's needed, generate, and validate:

- **Product Overview** → references/product-overview/{workflow.md, template.md}
- **System Architecture** → references/architecture/{workflow.md, template.md}
- **Codebase Summary** → references/codebase/{workflow.md, template.md}
- **Code Standards** → references/standards/{workflow.md, template.md}
- **UI/UX Guideline** → references/uiux/{workflow.md, template.md}

## Multiple documents (orchestrated with subagents)

Act as an **orchestrator**: gather shared facts once, dispatch one specialized subagent per document in parallel, then review and reconcile. This is faster (no repeated analysis), keeps each doc in a clean focused context, and makes non-duplication a dedicated cross-doc step instead of a per-doc afterthought.

1. **Read `references/orchestration-workflow.md`** — the full loop (scope → clarify → shared brief → parallel dispatch → reconcile).
2. **Run the input gate** for the union of requested documents (Step 0) — one consolidated clarification round for the whole run, before the brief exists.
3. Build one **Shared Facts Brief** so subagents don't each re-run repomix (`references/subagent-brief.md`), with every fact marked Observed / Confirmed / Assumed.
4. Dispatch one subagent per requested doc **in the same turn**, using the aligned AI-DLC agent (product → `ai-assistant-product-owner`; architecture/codebase/standards → `ai-solutions-architect`; uiux → `ai-design-orchestrator`), following the dispatch contract in `references/subagent-brief.md`: invoke this same skill, phase = Foundation, the document's purpose and exclusions, its workflow + template, single-document inline path (no fan-out), ask nothing of the user. Phase and purpose need saying because these agents have habitual outputs from other phases — the product owner reaches for user stories, the design orchestrator for mockups.
5. **Reconcile** their structured returns against the duplication matrix and cross-reference map (`references/cross-reference-patterns.md`); fix or re-dispatch as needed, and surface the set's assumptions and any `unresolved_inputs` to the user.

## Reference files

- `references/input-gate.md` — the input gate: harvest sources, per-document input floors, question format, assumption recording
- `references/orchestration-workflow.md` — the orchestrator loop (scope → clarify → shared brief → parallel dispatch → reconcile)
- `references/subagent-brief.md` — Shared Facts Brief, dispatch-prompt template, and structured-return schema
- `references/cross-reference-patterns.md` — information ownership table, predetermined anchors, and cross-link examples
- `references/{type}/workflow.md` — process and required sections per document
- `references/{type}/template.md` — document template per document
