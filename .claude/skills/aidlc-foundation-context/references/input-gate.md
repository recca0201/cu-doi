# Input Gate — Resolve Before You Write

Foundation documents are consumed downstream as settled fact. Inception pulls personas straight out of the product overview, specs inherit the stack from system-architecture, UI work treats uiux-guideline as the single source of truth, and nobody re-checks any of it. So a guessed value here does not stay a guess — it propagates into stories, specs, and code wearing the authority of documentation.

That asymmetry is the whole reason this gate exists. A question costs the user one turn. An invented persona costs a rewrite of every artifact derived from it.

The gate is **not** a questionnaire. It is a filter: harvest what already exists, identify what each requested document genuinely cannot invent, and ask only about what is left.

## Three markings, used everywhere

Every fact that lands in a foundation document carries one of these — in the Shared Facts Brief, in the document itself, and in a subagent's structured return:

| Marking | Means | Source |
|---|---|---|
| **Observed** | Read from the codebase, configs, or repo files | repomix output, config files, existing docs |
| **Confirmed** | The user stated or chose it | their request, or an answer to a gate question |
| **Assumed** | You chose it because the user explicitly deferred | "you decide", "just assume and go" |

The point of marking is that a reader — human or the next AI-DLC phase — can tell which lines are load-bearing. An unmarked assumption is indistinguishable from a decision, which is exactly the failure this skill is trying to avoid.

## Step 1 — Harvest before asking

Asking for something the repo already states wastes the user's turn and makes the gate feel like bureaucracy. Check these first, cheapest to most expensive:

| Source | Answers |
|---|---|
| The user's own request | vision, users, stack intent, scope, constraints — read it closely before treating anything as unknown |
| `README.md`, `CONTRIBUTING.md`, `docs/` | purpose, setup, conventions, sometimes personas |
| `package.json` / `pyproject.toml` / `go.mod` / etc. | name, stack, dependencies, scripts |
| Existing `{docs-root}/foundation/*.md` | anything a prior run already established — update rather than re-ask |
| `{docs-root}/story-artifacts/`, `{docs-root}/specs/` | personas, scope decisions, accepted constraints |
| `{docs-root}/brainstorming/` Decision Records | settled direction on stack, scope, or design — a decision, not a suggestion |
| repomix output (brownfield) | tree, configs, dependencies, existing conventions |

Reuse names and terms exactly as these sources write them. Inventing a second name for something that already has one creates the same drift as inventing the fact.

## Step 2 — Check each requested document against its input floor

The floor is what a document cannot honestly assert without input. Greenfield and brownfield differ sharply, because code answers factual questions but never intent.

| Document | Greenfield floor (must be Confirmed) | Brownfield (most is Observed — ask only for) |
|---|---|---|
| **project-overview-pdr.md** | product purpose/vision; who the users are and what each wants; the business objective and how success is judged; what is in and out of MVP scope | the same list — code shows *what exists*, never *why it matters or for whom* |
| **system-architecture.md** | target stack and the reason for it; deployment/hosting model; external systems and integrations; scale/availability/security expectations | deployment target and integration intent where no infra config exists; the NFR bar; the *why* behind a stack choice that looks accidental |
| **codebase-summary.md** | intended top-level structure; dependency set; package manager and the dev/build/test commands | nothing — this doc is fully observable. Questions here are a smell; read the repo instead |
| **code-standards.md** | language and framework; lint/format/test tooling; commit and branch convention | nothing, *unless* the codebase is genuinely inconsistent and no linter/formatter config arbitrates — then the user picks which existing style is the standard |
| **uiux-guideline.md** | whether there is a UI at all; where the design system comes from (existing brand kit, a named system like MDS, design tokens, or nothing yet); brand palette and typography; target platforms and breakpoints; accessibility bar | brand intent behind detected tokens; the accessibility bar; whether the detected system is the intended one or legacy |

`uiux-guideline.md` deserves specific caution. It is 450–650 lines declaring itself the single source of truth for colour, type, spacing, and components. Generated with no design input, essentially all of it is fabricated while presenting as authoritative — the highest-damage invention this skill can make. If there is no design input and no detected system, say so and ask; if the project has no UI, propose skipping the document rather than inventing a design system for it.

## Step 3 — Decide what actually deserves a question

An unknown becomes a question when a wrong value would change the *substance* of a document — its personas, scope, stack, deployment shape, design system, or conventions. That is the test.

**Ask:**
- Anything on the floor above that harvesting did not answer.
- Anything where two plausible answers would produce materially different documents (e.g. "internal tool for 20 people" vs "public SaaS" rewrites architecture, NFRs, and scope alike).

**Don't ask:**
- Facts the repo, README, or an existing artifact already states.
- Detail that only tunes wording inside a section the user will read anyway.
- Anything you can determine by reading a file. Read the file.
- Preferences that a stated convention already settles (a `.eslintrc` decides formatting; don't poll the user on semicolons).

Never launder an unresolved decision into vague prose. "A suitable database", "appropriate spacing scale", "industry-standard accessibility" — each is an open decision wearing a costume, and it misleads everyone downstream. Either the user chose flexibility deliberately, or the value is a question.

## Step 4 — How to ask

Use `AskUserQuestion` when available; otherwise ask the same thing in plain text and stop for the answer.

Batch by **blast radius**, so the answers with the widest effect arrive first:

1. **Product intent** — vision, users, objective, MVP boundary. Shapes all five documents.
2. **Technical shape** — stack, deployment, integrations, NFR bar. Shapes architecture, codebase, standards.
3. **Design** — UI or not, design system source, palette/type, platforms, a11y bar. Shapes uiux.

Group up to four tightly-related questions per call (the tool's maximum); keep unrelated topics in separate rounds so answers stay considered rather than rushed.

Every question should:
- **Offer concrete, grounded options** built from what you harvested — not abstract prompts. Options the user can recognise get answered; open-ended ones get skipped.
- **Mark one `(Recommended)`** when the harvested signals support a default, and say why in the option description.
- **Include a defer option** — "You decide, note it as an assumption" — so the user can hand back any decision they don't care about without abandoning the run.

**Grounded (good):**
```
Q: "Who is this dashboard primarily for?"
- "Engineering managers tracking team adoption (Recommended — your request mentions team metrics)"
- "Individual developers checking their own usage"
- "IT admins managing licences and seats"
- "You decide — note it as an assumption"
```

**Ungrounded (bad):** `"Who are the personas?"` — this hands the analytical work back to the user, which is the opposite of the job.

## Step 5 — Keep asking until each input resolves

There is no round ceiling. A floor input stays open until one of two things happens:

- The user **answers** it → mark **Confirmed**.
- The user **explicitly defers** it ("you decide", "just assume and go", picks the defer option) → mark **Assumed** and move on immediately.

Deferral is a real answer, and it applies to the scope the user gave it. "Just assume the tech details" defers the technical batch; it does not silently license inventing personas and a brand palette too. When a user defers broadly and early, proceed — but keep the assumption list visible so they can correct cheaply.

What keeps this from becoming an interrogation is Steps 1–3, not a counter: harvest first, and only material unknowns qualify. If you find yourself on a fourth round, check whether the remaining questions are actually load-bearing or whether you are polling for preferences.

## Step 6 — Play back before generating a multi-document set

When any clarification happened and two or more documents are being generated, replay the consolidated picture once before writing: product intent, users, stack and deployment, design source, scope boundary, and every remaining assumption. Ask the user to confirm or adjust.

Users answer questions one at a time; the playback is the first moment they see the whole picture, and it is the last moment a cross-question mistake is free to fix. After five documents exist, the same correction costs a full regeneration.

Skip the playback only when nothing was clarified and nothing was assumed — replaying what the user just said verbatim wastes their turn.

## Step 7 — Record what was assumed

Assumptions live where the reader will hit them, not in chat:

- **In the document** — an `## Assumptions & Open Inputs` section listing each Assumed value, what it affects, and what it would take to confirm. Inline the marking too where it matters (`**Assumed:** PostgreSQL — no infra config present`).
- **In a subagent's structured return** — `assumptions_or_gaps` plus `unresolved_inputs` for anything the brief never supplied.
- **In the orchestrator's reconcile summary** — surface the union of assumptions to the user at the end, so the set's soft spots are visible in one place.

A foundation set with five clearly-marked assumptions is far more useful than one that reads as fully settled and quietly isn't.

## Two traps worth naming

- **`Planned` is not a marking for a guess.** It reads as *decided, to be built later* — exactly the wrong impression for something you invented. Greenfield sections describe Planned work only when the user agreed to it; otherwise **Assumed**.
- **Asking and generating in the same response defeats the point.** The draft anchors the discussion, so the user reacts to what you wrote instead of deciding what it should have been. Ask, stop, then generate.
