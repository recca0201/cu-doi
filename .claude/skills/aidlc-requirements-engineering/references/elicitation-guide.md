# Requirements Elicitation Guide

Clarify before generating. In any single response, either ask or generate — never both. A request to "make reasonable assumptions" does not bypass unresolved artifact-shaping decisions: guessed scope, actors, or acceptance behavior produce an artifact the user has to un-write instead of one they can react to.

## Pre-Generation Decision Gate

Walk the decision categories below for the request. The gate has a hard floor and a judgment zone:

**Never assume — categories 1-4.** Expected output, actor/persona, acceptance or success criteria, and scope boundaries define what the requirement *is*. If any of them is unclear, ask — a guessed version of these is not a draft, it is a different requirement, and once written it anchors the user to a shape they never chose. No instruction to "make reasonable assumptions" overrides this floor.

**Materiality test — categories 5-10.** Sort each open question:

- **Ask first** when a wrong guess would change the story split, the acceptance behavior, or what gets built and tested — anything the user would likely reject and rewrite.
- **Generate with stated assumptions** only when the answer merely tunes details inside a story. Record each assumption visibly in the artifact and in the review handoff so the user can correct it cheaply.
- **When in doubt, ask.** A question costs the user one turn; a wrong artifact costs a full generate-review-rewrite cycle. The tiebreaker always favors asking.

The test is the point of the gate: clarification protects the expensive decisions, stated assumptions keep momentum on the genuinely cheap ones — they are never a way to avoid a conversation the user needs to have.

Decision categories:

1. **Expected artifact/output**: story artifact, BRD conversion, backlog cleanup, Jira/ADO-ready stories, or another explicit output.
2. **Actor/persona**: the user, role, or foundation persona that receives the value.
3. **Acceptance or success criteria**: observable behavior, business outcome, or quality bar that proves the story is done.
4. **Scope boundaries**: what is in scope and what is explicitly out of scope for this artifact.
5. **Constraints and touchpoints**: non-negotiable constraints, integrations, foundation context, prior artifacts, or existing product/code areas.
6. **UX and workflow behavior**: entry points, screens, triggers, user journey, feedback messages, accessibility, interruption rules.
7. **Timing and limits**: frequency, cooldowns, quiet hours, thresholds, quotas, retries, timeouts, performance targets.
8. **Configuration and control**: defaults, workspace/user settings, enable/disable, opt-out, permissions, admin controls.
9. **Data and compliance**: privacy, telemetry, storage, retention, auditability, consent, external services, sensitive-data boundaries.
10. **Failure and verification**: fallback behavior, recoverability, negative paths, edge cases.

One rule has no materiality exception: never hide an unresolved decision behind generic configurable wording. If a draft criterion says the system uses "a configured threshold" or acts at "appropriate moments", then either the user explicitly chose configurability as the requirement, or the value is an open decision that must be asked. Generic wording that papers over a decision misleads implementation and fails the review gate.

**Decision check.** Before deciding to generate, walk the ten categories once more and confirm each one is either resolved from the request and gathered context, a stated low-stakes assumption (categories 5-10 only), or not applicable to this feature. Anything still open means the answer is "clarify", not "generate". Doing this check explicitly is what prevents the common failure where generation starts because the request *feels* complete rather than *is* complete.

**Requests that typically fail the gate:**

- "Add authentication" → OAuth/JWT? Social login? 2FA?
- "Make it faster" → Which part? Target metrics?
- "Add export" → CSV/PDF/Excel? Scheduled or on-demand? Which permissions? What happens on failure?
- "Add notifications" → Which channel? Which trigger event? How often? Opt-out?
- "Improve search" → What's slow or wrong today? Fuzzy matching?

## Confirm the Requirement Before Generating

If any clarification round happened, or any assumptions remain, play back the consolidated understanding before scaffolding: actor, intended outcome, what is in and out of scope, the key acceptance decisions, and every remaining assumption — then ask the user to confirm or adjust (confirm marked `(Recommended)`). Generation starts only from a confirmed understanding.

This playback exists because users answer clarification questions one at a time; the confirmation is the first moment they see the whole picture and can catch cross-question mistakes while fixing them is still free — before an artifact exists.

Skip the playback only when the request arrived fully specified — the decision check passed with nothing clarified and nothing assumed. In that case generate directly; confirming what the user just said verbatim wastes their turn.

## Scope Challenge

Run this before detailed elicitation when the request is broad, multi-goal, or likely to create a large story set:

1. **What already exists?** Check gathered context and known product capabilities for reusable personas, workflows, constraints, or related stories.
2. **What is the minimum story set?** Identify the smallest set of user-visible outcomes that delivers the core goal.
3. **Should this be decomposed?** If the request spans independent outcomes or multiple product areas, propose separate story groups or artifacts.

If the scope question is strategic rather than factual, offer 2-3 approaches with trade-offs and a recommendation before asking the user to choose.

## Question Format

Ask one decision at a time by default; group up to four questions only when they are tightly related or depend on the same answer. An unrelated batch forces the user to context-switch mid-answer, and the answers get shallower.

- Use `AskUserQuestion` when the tool is available; otherwise ask the same question in plain text and stop for the answer.
- Offer 2-4 specific options when the choices are known, and mark the recommended one with `(Recommended)`.
- Ground options in gathered context and product patterns rather than asking abstract questions.

**Example:**

```
Question: "Which authentication method?"
Options: "OAuth 2.0 (Recommended)", "JWT", "Session-based", "Other"
```

## Question Categories

**Purpose**: Why now? What outcome proves this matters?
**Scope**: What's included/excluded? Boundaries? Integrations?
**Success criteria**: What observable behavior or quality bar proves done?
**Users**: Who (use foundation personas)? Goals? Pain points? Roles?
**Functional**: What actions? What happens when? Success/failure scenarios?
**NFR**: How many users? Performance targets? Security? Availability?
**Technical**: Which tech/library/framework? Constraints from gathered context?
**UX**: User flow? Interaction patterns? Visual design? Accessibility?
