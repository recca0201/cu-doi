# Brainstorming Examples

Worked examples showing the workflow checklist applied to real decisions across all three AI-DLC phases. Outcomes are illustrative — your DR will land somewhere different based on your context.

The checklist for reference (defined in `SKILL.md → Workflow Checklist`):

1. Discovery — initial scoping → 2. Offer visual support (wireframe and/or prototype) → 3. Discovery — deep questioning → 4. Research → 5. Anti-clustering check → 6. Analysis → 7. Prototype render & review *(only if the prototype tier was accepted)* → 8. Recommendation → 9. Approval of recommendation → 10. Write the DR → 11. Self-review → 12. User review of the written DR → 13. Transition

Steps 10–13 are procedurally identical across examples (write, self-review, user review of the document, transition). They're collapsed into a single "DR & handoff" line per example below. Step 7 is a no-op for examples that don't use the prototype tier.

---

## Example 1: Business Decision (Foundation Phase) — Pricing Model

**User**: "Should we use freemium or subscription-only pricing for our SaaS product?"

**Type**: Business | **Phase**: Foundation

1. **Discovery — initial scoping**: Read the user's request — early-stage SaaS pricing. No Foundation docs assumed. Identify target market and CAC assumptions as the highest-leverage unknowns.
2. **Offer visual support**: Skip both tiers. The upcoming questions (target market, CAC, conversion expectations) are textual — pure conceptual A/B/C choices. Nothing the user would understand better by seeing it.
3. **Discovery — deep questioning**: Ask one at a time about target market, CAC assumptions, competition, conversion expectations.
4. **Research**: Freemium conversion rates (2–5% typical), SaaS pricing models, support burden implications.
5. **Anti-clustering check**: Push past freemium vs paid-only — also consider usage-based, free-trial-only, and "do nothing / launch with paid waitlist." Force the alternatives into different corners of the build/buy/simple/conventional space.
6. **Analysis**: Freemium vs subscription-only vs free-trial-only vs hybrid. Challenge assumptions about free user support cost and brand positioning while writing cons.
7. **Prototype render & review**: N/A — the prototype tier wasn't accepted, so this step is skipped.
8. **Recommendation**: Lead with the chosen pricing model and the one or two reasons it tipped. Name the strongest con in the same breath. Note reversibility (medium — switching to paywall later risks backlash) and a success signal (free→paid conversion ≥ 3% within 6 months).
9. **Approval of recommendation**: Invite pushback ("does this match your read?"). Wait for explicit alignment before writing. If the user surfaces a constraint about brand positioning that wasn't named earlier, return to Analysis.
10–13. **DR & handoff**: Write `aidlc-docs/brainstorming/0001-freemium-pricing.md` using **full template** (business decision with cross-phase implications). Self-review for the *Describing Without Deciding* anti-pattern. User reviews the written DR for fidelity to what was agreed; after approval, transition to the Foundation product overview doc.

---

## Example 2: Technical Decision (Foundation Phase) — Architecture Pattern

**User**: "Should we use microservices or monolith for our e-commerce platform?"

**Type**: Technical | **Phase**: Foundation

1. **Discovery — initial scoping**: Read the user's request and any existing Foundation docs (system-architecture, codebase-summary). Identify team size, expected scale, and operational tolerance as the highest-leverage unknowns.
2. **Offer visual support**: Offer the **wireframe tier**. Architecture diagrams (monolith vs microservices vs modular monolith vs serverless) are easier to compare side-by-side than to read about — that's structural/diagram content, not look-and-feel, so wireframe is the right tier — present it via the step-2 `AskUserQuestion` (wireframe as the recommended option).
3. **Discovery — deep questioning**: One question at a time on team size, expected scale, deployment-complexity tolerance, current operational maturity.
4. **Research**: Monolith-first patterns, microservices migration paths, team-size implications, operational overhead, recent post-mortems on premature decomposition.
5. **Anti-clustering check**: Don't just compare monolith vs microservices — include modular monolith, serverless functions, and "defer the architecture decision until we have a real user." Cover build/buy and simple/powerful axes.
6. **Analysis**: Monolith-first vs microservices vs modular monolith vs serverless. Apply YAGNI hard — microservices for a 3-person team is almost always over-engineering. Lead with weaknesses of the recommended option.
7. **Prototype render & review**: N/A — the prototype tier wasn't accepted, so this step is skipped.
8. **Recommendation**: Lead with the chosen architecture and the one or two reasons it won (likely team size + operational maturity). Name the strongest con honestly. Note reversibility (medium — splitting a modular monolith is straightforward; consolidating microservices is painful) and a success signal (deploy-time, on-call burden trends over 6 months).
9. **Approval of recommendation**: Invite pushback. If the user reveals a near-term scaling event that changes the operational-maturity picture, return to Analysis. Otherwise wait for explicit alignment before writing.
10–13. **DR & handoff**: Write `aidlc-docs/brainstorming/0002-modular-monolith.md` using **full template** (architectural decision affecting all subsequent phases). User reviews the written DR; after approval, transition to the Foundation `system-architecture.md` doc.

---

## Example 3: Product Decision (Inception Phase) — MVP Prioritization

**User**: "Should we prioritize onboarding flow or analytics dashboard for MVP?"

**Type**: Hybrid | **Phase**: Inception

1. **Discovery — initial scoping**: Read the user's request and any prior product DRs. Identify activation goals, time-to-value, and MVP scope constraints as the highest-leverage unknowns.
2. **Offer visual support**: Offer the **wireframe tier**. Comparing feature-priority cards or rough user-flow options is genuinely easier seen than described, and the crux here is prioritization/structure rather than pixel-level look-and-feel — present it via the step-2 `AskUserQuestion` (wireframe as the recommended option).
3. **Discovery — deep questioning**: One question at a time on activation goals, must-have metrics, time to value, demo deadline (if any).
4. **Research**: Activation best practices, MVP prioritization frameworks (MoSCoW, RICE), dependency analysis between onboarding and analytics.
5. **Anti-clustering check**: Don't just compare onboarding vs analytics — include "neither, ship core feature only," "minimal version of both," and a third feature that might dominate both.
6. **Analysis**: Onboarding-first vs analytics-first vs minimal-both vs core-feature-only. Force the prioritization — challenge "both are critical" mentality. Consider what breaks if analytics ships without onboarding vs the reverse.
7. **Prototype render & review**: N/A — the prototype tier wasn't accepted, so this step is skipped.
8. **Recommendation**: Lead with the chosen priority and tie it directly to the activation goal the user named. Name the strongest con. Note reversibility (high — feature order can be re-sequenced) and a success signal (activation rate, time-to-first-value within 30 days).
9. **Approval of recommendation**: Invite pushback. Wait for explicit alignment before writing — feature-order DRs are cheap to flip in conversation but expensive to re-write.
10–13. **DR & handoff**: Write `aidlc-docs/brainstorming/0003-mvp-prioritization.md` using **lite template** (clear winner with simple trade-off). User reviews the written DR; after approval, transition to `aidlc-requirements-engineering` for user stories.

---

## Example 4: Technical Decision (Construction Phase) — Authentication

**User**: "What's the best way to implement user authentication for the login-unit?"

**Type**: Technical | **Phase**: Construction | **Unit**: login-unit

1. **Discovery — initial scoping**: Read the unit's spec, the existing auth-related code, and any prior auth DRs. Identify SSO needs and compliance constraints as the highest-leverage unknowns.
2. **Offer visual support**: Offer the **wireframe tier**. The upcoming questions involve OAuth sequence comparisons and option-comparison cards across 4 auth approaches — both genuinely easier to see than to read, and both structural/diagram content rather than look-and-feel — present it via the step-2 `AskUserQuestion` (wireframe as the recommended option); the tool call blocks for the answer.
3. **Discovery — deep questioning**: One question at a time on security requirements, SSO needs, user flows, compliance. Use the browser for OAuth sequence comparison; terminal for textual scope questions.
4. **Research**: Auth libraries (better-auth, passport, auth0), JWT vs sessions, passkey support, current security advisories.
5. **Anti-clustering check**: Push past JWT-variants — consider sessions, hosted auth providers, passkeys, and "use the platform's built-in auth." Cover build/buy explicitly.
6. **Analysis**: JWT+sessions vs hosted (Auth0/Clerk) vs better-auth vs passkey-only. Push back on over-engineering (passkeys now? social login scope?) while writing cons.
7. **Prototype render & review**: N/A — the prototype tier wasn't accepted, so this step is skipped.
8. **Recommendation**: Lead with the chosen library and token format and the one or two reasons it won (likely cost-at-scale + lock-in trade-off). Name the strongest con. Note reversibility (low for token format, high for library choice) and a success signal (zero auth-related incidents in first 30 days).
9. **Approval of recommendation**: Invite pushback. If the user surfaces a compliance requirement that rules out self-hosting, return to Analysis. Otherwise wait for explicit alignment before writing.
10–13. **DR & handoff**: Write `aidlc-docs/brainstorming/0004-auth-implementation.md` using **lite template** (isolated Construction decision). User reviews the written DR; after approval, transition back to `aidlc-spec-driven` to create the unit's design doc.

---

## Example 5: Design-Direction Decision (Construction Phase) — Dashboard Look-and-Feel

**User**: "Which visual direction for the analytics dashboard — dense data-grid, card-based summary, or hybrid? It's about look-and-feel for the investor demo. We're on React + Magenta MDS."

**Type**: Product/Design | **Phase**: Construction | **Design system**: Magenta/MDS detected *(illustrative — the Prototype tier fires for any detected design system; substitute MUI, Ant Design, an in-house system, etc., and the flow is identical)*

1. **Discovery — initial scoping**: Read the request and Foundation docs. In Setup, design-system detection fires — `uiux-guideline.md` exists and Magenta indicators are present. The crux is explicitly look-and-feel, not data or structure.
2. **Offer visual support**: Present the step-2 `AskUserQuestion` with **Full prototype** as the recommended first option. Because the decision hinges on look-and-feel *and* a design system is present, grey wireframes would misrepresent the options — this is the prototype tier's primary trigger. The option labels name the design system and are honest that prototype spins up a slower, token-heavier subagent; the tool call blocks until the user selects.
3. **Discovery — deep questioning**: One question at a time on audience (non-technical investors), the must-show KPIs, and density tolerance — terminal, since these answers are sentences.
4. **Research**: Dashboard density patterns, KPI-card conventions, what reads as "polished" to non-technical audiences.
5. **Anti-clustering check**: Push past the three given directions — also consider "single-hero-metric" and "defer styling, use default MDS layout." The main agent frames the final 2–4 directions; the subagent renders them.
6. **Analysis**: For each direction, pros/cons against the investor-demo goal and MDS fidelity. Frame the final 2–4 directions to render — this is the brief, not the decision.
7. **Prototype render & review** *(the gate — the user said yes to seeing it, so this happens before any recommendation)*: after reading [prototype-tier.md](prototype-tier.md) in full, first **`AskUserQuestion` (multi-select): which directions to render — A / B / C / All?** (each is a separate subagent — the cost gate). Then spawn `ai-design-orchestrator` for the selected directions — one per direction, in parallel — each writing an MDS-faithful static screen as `direction-*.html` under `aidlc-docs/design-artifacts/prototype/{dr-slug}/`. No server: the main agent assembles a single `index.html` review file and opens it for the user (built-in browser tool, else hands over the `file://` path). The user looks and reacts **in the terminal**; layout/styling tweaks continue the same designer session and the file is regenerated for reload. Do not advance until the user has actually seen and reacted to the options.
8. **Recommendation**: Lead with the chosen direction, tie it to the look-and-feel framing and the demo deadline. Name the strongest con (e.g. card-based summary hides detail power users want). Reversibility (high — visual direction can be re-skinned) and a success signal (positive demo feedback, time-to-comprehension).
9. **Approval of recommendation**: Invite pushback.
10–13. **DR & handoff**: Write `aidlc-docs/brainstorming/NNNN-dashboard-direction.md` using **lite template**, referencing the persisted prototype path. User reviews the written DR; after approval, transition back to `aidlc-spec-driven` for the unit design doc, which now has a real prototype to build from.

---

## What these examples illustrate (and what they don't)

**They illustrate**: the *shape* of a complete brainstorm — how each step gets a one-line answer for a real prompt, where the Visual Companion fits, what reversibility/success-signal sentences look like.

**They don't illustrate**: the actual back-and-forth dialogue, the brutal-honesty pushback, or the full DR text. Those live in the actual DR files (`aidlc-docs/brainstorming/`) once you start producing them. Read 2–3 real DRs alongside these examples to see both the procedure and the depth.
