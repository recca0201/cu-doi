# Prototype Tier — Delegated High-Fidelity Design Prototypes

> **MANDATORY:** If the prototype tier is selected, read this whole file before acting on it — every time. The flow has exact mechanics (parallel subagents, file assembly, the render-before-recommend gate) that are easy to get wrong from memory. Don't shortcut it from the SKILL.md summary.

Brainstorming has three visual fidelity tiers. This file covers the highest — the **Prototype tier**, where a dedicated `ai-design-orchestrator` subagent builds design-system-faithful UI options instead of the main agent hand-authoring wireframes. The first two tiers (terminal text, inline wireframes) live in [visual-companion.md](../visual-companion.md).

**No server.** Unlike the wireframe tier (which uses the companion server for live-reload and click events), the prototype tier needs none of that — the user only *looks*. The subagent writes a self-contained HTML file to disk; the main agent opens that file directly and asks for review in the terminal. Don't start or touch the companion server for this tier.

## Why this tier exists

The inline wireframe tier renders grey `mock-*` blocks — deliberately crude, "focus on layout not pixel-perfect" (see [visual-companion.md → Design Tips](../visual-companion.md)). That is the right fidelity for *structural* questions ("sidebar-left or top-nav?"). It is the **wrong** fidelity when the decision genuinely hinges on look-and-feel, and it actively misleads when the project has a real design system: a grey wireframe of a design-system screen looks nothing like what would ship, so the user is comparing fictions.

The Prototype tier closes that gap by delegating to the design specialist — `ai-design-orchestrator`, which runs `aidlc-uiux-design` (and design-system-specific skills such as `magenta-mds` when the relevant system is detected) and whose canonical output *is* a visual prototype. The main agent stays focused on framing and deciding; the subagent renders.

## When to use the Prototype tier

Two conditions, AND'd, then one judgment:

1. **The decision hinges on look-and-feel** — visual hierarchy, real spacing/typography, component styling, brand feel — not just structure or flow. A question *about* a UI topic is not automatically a prototype question. "Which nav pattern?" is structural (wireframe). "Does direction A or B feel right for our product, rendered the way it'd actually ship?" is look-and-feel (prototype).
2. **A design system is the primary trigger.** Detected during Setup (see below). When a design system is present, faithful rendering is exactly what wireframes can't give — this is the strongest case for the tier.

**No-design-system case:** the tier is still *offerable* for a genuine look-and-feel decision (the subagent produces high-fidelity styled screens from inferred conventions), but it is **not the default** — wireframe stays the norm green-field. Only escalate when fidelity would actually change the answer.

**Fidelity is static by design.** The subagent produces DS-faithful *design-direction* screens as an HTML file for visual comparison only — the user opens the file, looks, and reacts in the terminal; the screens are not clickable or wired into working flows. If a decision truly needs a clickable interactive prototype, that is out of scope for this tier — say so and handle it outside the brainstorm.

## Design-system detection (run in Setup)

Detect *any* design system — don't special-case one vendor. Add to the brainstorm Setup step, before the first question, in order of signal strength:

- **Documented system:** `aidlc-docs/foundation/uiux-guideline.md` exists, or the request/foundation docs name a design system the project follows.
- **Dependency/import signal:** a design-system package appears in `package.json` or imports — e.g. a third-party library (MUI, Ant Design, Chakra, Mantine, Bootstrap, Tailwind+a component kit, etc.) or a company/internal system (e.g. Magenta/MDS via `@ocean-network-express/magenta-react`). These are illustrative, not exhaustive — treat any consistent component/token system as a hit.
- **Codebase convention:** a local component library or token set the UI consistently builds on, even without a formal guideline doc.

Record *which* system was found (or "none"). The presence of a system is the primary gate for whether the Prototype offer is the default escalation for an upcoming look-and-feel question; the specific system tells the subagent which design-system skill to invoke (e.g. `magenta-mds` for Magenta) or, for others, to render from the documented tokens/components directly.

## Offering the Prototype tier

The prototype tier is offered as the **"Full prototype"** option of the step-2 `AskUserQuestion` (see SKILL.md → Visual Companion → *How to offer*). It is not a separate prose message — the blocking tool call is the offer, and it enforces the wait for the user's selection. If the user picks wireframe or text-only instead, don't escalate to a subagent; never silently spawn one.

## The subagent contract

Spawn `ai-design-orchestrator` (Agent tool, `subagent_type: ai-design-orchestrator`). No server is involved — the subagent writes HTML files to disk and the main agent opens them.

**Render the directions in parallel — one subagent per direction.** Render only the directions the user selected in the step-2a `AskUserQuestion` cost gate (see the interaction loop). The selected directions are independent, so don't render them sequentially in one agent. In a single message, spawn one `ai-design-orchestrator` per selected direction concurrently; each renders just its own option to its own HTML file. To keep them composable, give every subagent the **same shell spec**: identical page width/viewport, the same section/heading structure, and the design-system context. This parallel fan-out is for the *first* render and for "add a variant"; in-place *iterations* on one direction continue that direction's single session (see the interaction loop).

**Pass to the subagent:**

- **The decision question** being visualized, in one sentence.
- **The 2–4 design directions to render** — the main agent frames these from its anti-clustering + analysis work, shaped by the discovery answers. The subagent renders directions; it does not invent the option set or make the decision.
- **Design-system context:** the detection result (which system, or none), path to `uiux-guideline.md` if present, the relevant design-system skill to invoke if one applies (e.g. `magenta-mds` for Magenta; otherwise render from the documented tokens/components), and any relevant Foundation docs (`project-overview-pdr.md` for personas).
- **Output path:** each subagent writes its direction to a distinct file under `aidlc-docs/design-artifacts/prototype/{dr-slug}/` — e.g. `direction-a.html`.
- **Self-containment requirement:** each direction's file must be a full document (`<!DOCTYPE html>` / `<html>`) with inline CSS/JS so it opens standalone in any browser — no external local stylesheets, no server dependency. Images use remote URLs / data-URIs, or local image files placed in the same `{dr-slug}/` dir and referenced relatively. All subagents share the **same shell spec** (identical width/viewport, section/heading structure, design-system context) so the directions read consistently.

**Each subagent produces and returns:**

- Its direction's full-fidelity HTML file under `aidlc-docs/design-artifacts/prototype/{dr-slug}/`.
- A short handoff note: which DS components/tokens were used, confidence level, and any gaps or assumptions (e.g. "no design system found — used inferred conventions").

**The main agent then assembles the review file** under `aidlc-docs/design-artifacts/prototype/{dr-slug}/` (e.g. `index.html`): a single self-contained HTML page that shows the directions **side-by-side or as labeled sections** (each clearly labeled A/B/C or named, so the user can refer to them by name), built by inlining the returned fragments. This one file is what the user opens to review. (If a single combined page is impractical — e.g. very large screens — instead link to each `direction-*.html` from a small index page; one file to open either way.)

## The interaction loop — how the brainstorm question drives the prototype

A brainstorm is a conversation that narrows. The prototype is not a one-shot render dropped in front of the user — it is the **rendered form of the visual question**, and it updates as the conversation converges. The discovery questions and the user's reactions both run through the main agent in the terminal (the prototype is for viewing, per *When to use*).

**1. Discovery shapes the first render.** The textual sub-questions run first, in the terminal, one at a time via `AskUserQuestion` ("Who's the audience?", "Which KPIs must show?", "Density tolerance?"). Their answers become the brief the subagent renders from — don't render before you've asked what would change what gets rendered.

**2a. Confirm which directions to render (cost gate).** Rendering is the expensive part — one subagent per direction — so before spawning anything, **use `AskUserQuestion` (multi-select) to let the user pick which of the framed directions to render**: a specific one, several, or all. List each framed direction as an option plus an explicit **"All of them"** option. Briefly note the cost ("each is a separate design subagent") so the choice is informed. This is a blocking tool call, so it also paces the flow. Render only what the user selects.

**2b. Render the visual question, then open the file.** Spawn the `ai-design-orchestrator` subagents for the **selected** directions — **one per direction, in parallel** (see *The subagent contract → Render the directions in parallel*) — then assemble the single review file (e.g. `aidlc-docs/design-artifacts/prototype/{dr-slug}/index.html`). Once it's on disk, **open it for the user automatically** rather than making them hunt for the path:

- If a built-in browser tool is available (the harness's open-browser/navigate action, or an MCP browser/Chrome DevTools tool), use it to open the file (`file://…/index.html`) yourself.
- Otherwise, give the user the file path in the terminal and ask them to open it.

Either way, in the terminal: confirm it's open (or give the path), summarize what's on screen, and ask for their reaction **in words** — *"I've opened the prototype — three directions: A dense grid, B card-summary, C hybrid. Which reads as most polished, and what would you change?"* End the turn and wait. On re-renders (step 4), regenerate the file and tell the user to reload it (or re-open it with the browser tool).

**3. The user reacts in the terminal.** They name a direction and/or describe changes ("B's layout, but make burn the hero card and try a darker header"). There is no click data to read — their typed message is the whole signal. Merge it with what you know and decide what the prototype needs next.

**4. Update by edit size** — this is how the prototype changes in response:

| User's reaction | What happens to the prototype |
|---|---|
| Trivial copy/label/caption/reorder | Main agent edits the review HTML file **inline** — no subagent |
| Layout / component / token / styling change on a direction | **Continue that direction's `ai-design-orchestrator` session** with the feedback — it re-renders its `direction-*.html`; re-assemble the review file |
| "Add a 4th variant" | **Spawn one new `ai-design-orchestrator`** for the new direction (same shell spec as the others), in parallel with any other new renders; re-assemble |
| A new sub-decision surfaces (e.g. now choosing *density within the chosen direction*) | Main agent reframes the question (its job), then renders the new sub-question's directions (parallel fan-out again) |
| "That's the one." | Resolve → recommendation → DR |

**Iterating a direction: continue its session, don't re-spawn it.** When the user's feedback changes an *existing* direction, continue that direction's `ai-design-orchestrator` session (in Claude Code, `SendMessage` to its agent id) rather than spawning fresh — it already knows the system and what it just rendered, so iterations are cheaper *and* stay coherent. Spawning a *new* subagent is for a *new* direction (the "add a 4th variant" case), not for re-touching an existing one. Only re-spawn an existing direction if its session can't be continued; then pass the full prior context.

**5. Converge.** Repeat 3–4 until the user settles. Then resume the normal brainstorm loop: lead with the recommendation, get alignment, write the DR. The DR references the persisted prototype path (`aidlc-docs/design-artifacts/prototype/{dr-slug}/`) so the decision is reviewable later and can feed Construction. The HTML files stay on disk as the artifact — nothing to tear down.

One prototype set per decision. If a hidden second decision surfaces, re-decompose (the standard SKILL.md rule) — don't pile a second decision's screens into the same prototype.

### Worked trace

```
Q1 terminal:  "Audience for the dashboard?"   → non-technical investors
Q2 terminal:  "Must-show KPIs?"               → MRR, growth, burn
Q3 terminal:  "Density tolerance?"            → low — keep it clean
   → these answers become the designer's brief

AskUserQuestion (cost gate): "Which directions should I render? A / B / C / All
   — each is a separate design subagent." → user picks "All"
(blocks for the answer)

RENDER (step 7, the gate — must happen before any recommendation):
   spawn 3 ai-design-orchestrator IN PARALLEL, one per selected direction (same shell spec)
   → direction-a.html, direction-b.html, direction-c.html  (in {dr-slug}/)
   main agent assembles the review file → {dr-slug}/index.html
Main: opens index.html with the built-in browser tool (no tool → give the file path)
Main: "Opened the prototype: A dense grid, B card-summary, C hybrid.
       Which reads most polished for the demo, and what would you change?"
(end turn, wait)

User: "B's layout is right, but make burn the hero card and try a darker header."
   → change to existing direction B → CONTINUE B's designer session
Designer-B: updates direction-b.html (burn promoted, dark header variant)
Main: re-assembles index.html; "Updated — burn is now the hero, darker header.
       Reload index.html and take another look. Closer?"
(end turn, wait)

User: "That's the one."
   → resolve → recommendation → DR refs design-artifacts/prototype/{dr-slug}/
```

## Failure handling

State the blocker and fall back; never silently skip:

- **Subagent fails or returns nothing usable** → tell the user, fall back to the inline wireframe tier for that question.
- **No built-in browser tool to auto-open** → give the user the `file://…/index.html` path and ask them to open it; don't treat this as a failure.
- **No design system detected and the user expected one** → say so; the prototype will use inferred conventions, flagged in the handoff note.
