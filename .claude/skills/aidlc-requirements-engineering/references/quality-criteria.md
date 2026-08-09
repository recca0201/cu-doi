# User Story Quality Criteria

## INVEST Principles

**Independent**: Developed separately, no hard dependencies
**Negotiable**: Details flexible until Construction phase
**Valuable**: Delivers measurable user/business value
**Estimable**: Enough detail to estimate effort
**Small**: 1-5 days in Construction (can split further)
**Testable**: Specific, measurable acceptance criteria in the selected shared story-block format

## Perspective and Detail Defaults

Write stories from the business and user point of view by default: who receives value, what capability or outcome they need, and why it matters. Stories are the contract with the user, and users approve outcomes, not implementations.

- Prefer business-readable capability language over technical implementation language.
- Name frameworks, database tables, APIs, services, or internal jobs only when the user explicitly asks or the term is a confirmed business-facing concept.
- Prescribe UI detail (layouts, components, colors, control placement) only when explicitly requested, confirmed as a product constraint, or required to make observable acceptance behavior testable.
- Keep technical constraints as constraints or acceptance criteria when they affect user-visible behavior, reliability, security, compliance, or testing — phrased in outcome terms where possible.

## Acceptance Criteria

Use the selected shared story block from `../_aidlc-shared/user-story-blocks/` consistently. Every criterion needs a concrete context, trigger, and expected result: prefer `WHEN page loads THEN system SHALL respond <200ms (p95)` over "system should be fast".

Concrete values matter because acceptance criteria drive implementation and tests. Defaults, triggers, thresholds, and failure behaviors belong in the criteria when they affect either. If a value is unknown, that is an unresolved decision — apply the gate in `references/elicitation-guide.md` rather than writing generic wording around it.

Preserve stable criterion IDs (`1.1`, `2.3`) during revisions: design and tasks documents cite them (e.g., `per AC-2.3`), so renumbering breaks downstream traceability.

## Scenario Dimensions

Use these dimensions as a completeness check when acceptance criteria feel thin or the feature is stateful, risky, or user-facing. Include only dimensions that materially apply:

| Dimension | Check for |
|-----------|-----------|
| User types | Admins, guests, new users, restricted users, bots, or foundation personas with different permissions |
| Input extremes | Empty, null, long, malformed, duplicate, unsupported, or special-character input |
| Timing | Concurrent actions, retries, timeouts, stale state, delayed sync, or interrupted flows |
| Scale | Zero items, one item, many items, pagination, rate limits, or large files |
| State transitions | First use, draft state, partial completion, resume, cancellation, or recovery |
| Environment | Mobile, offline, low bandwidth, accessibility, timezone, locale, or browser/device constraints |
| Error cascades | Downstream service failure, partial write, missing data, and graceful degradation |
| Authorization | Role mismatch, expired session, shared access, permission downgrade, or forbidden action |
| Data integrity | Duplicate records, stale data, validation, auditability, and consistency after updates |
| Integration | API contract drift, webhook replay, third-party outage, sync conflict, or version mismatch |
| Compliance | Retention, privacy, audit logs, consent, restricted data, or legal approval |
| Business logic | Limits, thresholds, pricing, quotas, eligibility, escalation, and exception handling |

## Splitting Large Stories

A story is too big if it would take more than 5 days to implement. Split along **user-visible value lines**, not technical layers.

**Rule:** Each split story must be independently deployable and deliver standalone value.

**Example — "Onboarding flow" is too big:**
- ❌ Split by layer: "Backend for onboarding", "Frontend for onboarding"
- ✅ Split by user action: "User can create an account", "User can set up first project", "User can invite team members"

**How to identify the split points:**
1. List the distinct user goals inside the story
2. Ask: "Could we ship this one part without the others and still deliver value?"
3. If yes → separate story; if no → keep as acceptance criteria within one story

**After splitting**, check that each child story still passes INVEST — especially that it's estimable and independently testable.

## Common Pitfalls

| Avoid | Instead |
|-------|---------|
| "System should be fast" | "WHEN page loads THEN SHALL respond <200ms (p95)" |
| Vague bullets without IDs | Concrete criteria with traceable IDs such as `1.1` or `2.1` |
| Generic configurable wording for an undecided value | Ask for the value or confirm configurability (see elicitation guide) |
| Technical implementation as the story goal | Business/user outcome, technical detail only as a confirmed constraint |
| Detailed UI layout as acceptance criteria | Observable user behavior unless exact UI detail was requested or confirmed |
| Creating new personas | Reuse personas from gathered context exactly as named |
| Ignoring architecture constraints | Reference system-architecture.md constraints in criteria they affect |

## Quality Checklist

Use before handing the saved draft to the Product Owner review gate.

**Structure**:
- [ ] Artifact includes `## Overview`, no leftover scaffold placeholders, and no spec-driven wrapper text (`# Requirements:`, `**Unit**:`, `## Next Steps`)
- [ ] "As a [persona], I want [goal], so that [benefit]" format with personas from gathered context
- [ ] Priority set; optional Business Value only where prioritization needs explanation
- [ ] Dependencies concrete: `None`, or named story IDs/prerequisites when sequencing matters
- [ ] Multi-goal requests split into separate user-visible stories
- [ ] Stories written from the business/user perspective per the defaults above

**Acceptance Criteria**:
- [ ] Selected story-block format used consistently, stable criterion IDs preserved
- [ ] Atomic, testable, with concrete values for triggers, defaults, thresholds, and failure behaviors that affect implementation or testing
- [ ] No unresolved decision hidden behind generic configurable wording
- [ ] Edge cases, negative paths, and recovery behavior covered; scenario dimensions considered for stateful, risky, or user-facing stories
- [ ] Constraints from system-architecture.md and components from uiux-guideline.md referenced where applicable

**INVEST**:
- [ ] Independent, Negotiable, Valuable, Estimable, Small, Testable

**Context**:
- [ ] Existing context gathered before generation; personas reused, constraints incorporated, scope aligned with the PDR
- [ ] Expected output, actor, acceptance criteria, and scope were confirmed by the user or explicit in the request — never assumed
- [ ] Remaining assumptions are low-stakes detail only, stated visibly in the artifact, and were included in the pre-generation confirmation
