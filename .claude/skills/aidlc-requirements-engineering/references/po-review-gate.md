# Product Owner Review Gate

Run this gate after the first complete draft is saved and before asking the user for feedback. Its purpose is to catch story-quality defects with fresh product-owner eyes before the user spends review effort — while keeping every file edit in the parent session, so artifact ownership stays in one place.

## Handoff package

Spawn a dedicated `ai-assistant-product-owner` subagent in Story Artifact Review Mode and give it:

- Project root and the saved artifact path
- The original user request and any source material
- The selected template
- The gathered context files (foundation docs, prior artifacts, Decision Records)
- Assumptions made and known context gaps
- The quality criteria loaded from `references/quality-criteria.md`

## Review contract

The subagent is review-only: it must not edit files, regenerate the artifact, or invoke `aidlc-requirements-engineering`. It returns exactly one verdict — `PASS`, `FIX_BEFORE_USER_REVIEW`, or `NEEDS_USER_DECISION` — with blocking findings, advisory findings, coverage notes, and suggested minimal edits. The return format and review checklist live in the agent definition (`../../agents/ai-assistant-product-owner.md`); do not restate or override them in the handoff.

## Verdict handling

| Verdict | Parent action |
| --- | --- |
| `PASS` | Present the reviewed artifact path and ask the user for feedback. |
| `FIX_BEFORE_USER_REVIEW` | Apply only clear, in-scope fixes to the saved artifact, preserving stable story and criterion IDs where possible, then rerun the review once. |
| `NEEDS_USER_DECISION` | Ask the user before changing scope, defaults, personas, acceptance behavior, or story splits. |

After the one rerun, do not loop. If the review still blocks, surface the remaining verdict and findings instead of asking for general feedback — a review that blocks twice means the open issues are the user's to decide, not the skill's to keep polishing.

## When subagent tooling is unavailable

Say explicitly that delegated Product Owner review was skipped, run the same review checklist inline, and apply the same verdict handling. Never claim subagent review occurred when it did not — the user relies on this gate as an independent quality signal.
