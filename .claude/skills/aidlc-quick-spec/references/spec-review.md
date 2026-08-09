# Quick-Spec Review Checklists

Instructions for the two review subagents spawned in Workflow Step 7 of `aidlc-quick-spec`. Each reviewer reads this file, the spec under review, and the codebase files the spec claims to touch — then returns a verdict.

## Shared Ground Rules (both reviewers)

- You are reviewing a **quick-spec**: one `spec.md`, one approval gate, ~1–5 files in a single area of code. Judge it against that bar, not against a full `aidlc-spec-driven` requirements/design/tasks set. Proportionality is a feature: a small fix deserves a small spec.
- Verify claims against reality. If the spec says `src/hooks/useAuth.ts:31-45`, open the file and check. A review that only reads the spec is not a review.
- Return exactly one of:
  - **PASS** — optionally with non-blocking suggestions clearly marked as such
  - **FINDINGS** — a numbered list; for each: what is wrong, where (section / trace ID / task number), and why it matters. Concrete enough that the author can fix it without asking you anything.
- Do not rewrite the spec yourself. Do not expand scope ("you should also handle…") unless the omission breaks a stated requirement.
- **Upgrade triggers are blocking findings.** If the work crosses modules, needs new infrastructure or dependencies (beyond one obvious, justified one), or the Design section is compressing a real architectural discussion — say so explicitly. The right outcome is upgrading to `aidlc-spec-driven`, not a bigger quick-spec.

## Product-Owner Review (`ai-assistant-product-owner`)

Scope: **Goal** and **Requirements** sections — the business side.

1. **Goal fidelity** — does the Goal sentence match what the user actually asked for? No silent scope additions or drops.
2. **Requirement coverage** — is every behavior the user asked for represented by at least one criterion? List anything the user said that has no trace ID.
3. **Testability** — is each criterion independently verifiable? "Works correctly" and "handles errors gracefully" are not testable; "rejects passwords under 8 chars and shows `error.password.tooShort`" is.
4. **Trace IDs** — shallowest clear depth (`1`, `1.1`, `1.1.1`), stable, no checkbox markers in Requirements.
5. **Edge cases the user implied** — logout/cleanup, failure paths, permission boundaries — but only where the user's request or the touched code makes them real. Do not invent product surface.
6. **Ambiguity** — could any criterion be read two ways that would produce different implementations? Flag it; the author must resolve it with the user, not guess.

## Solutions-Architect Review (`ai-solutions-architect`)

Scope: **Design**, **File Structure**, and **Tasks** sections — the technical side.

1. **Design soundness** — is the described solution technically coherent, and does it actually satisfy the Requirements? Point at any criterion the design cannot deliver.
2. **Pattern fit** — does the design follow the existing patterns in the area being changed? A deviation needs a recorded reason; an unrecorded deviation is a finding.
3. **Refactoring discipline** — cuts both ways. If the design builds on top of code it touches that is visibly broken or tangled in a way that affects this change, the missing targeted improvement is a finding. If the design includes refactoring of code this change does not need to touch, that unrelated scope is also a finding.
4. **Path accuracy** — every *Modify* path exists; every *Create* path has an existing parent directory; line ranges point at the code the task describes.
5. **Requirements → Tasks coverage** — every task has an `Implements:` line naming requirement IDs, and the mapping is accurate in both directions: every criterion is claimed by at least one task, no task claims a criterion it does not actually deliver, and no task implements behavior no criterion asked for.
6. **Interface consistency** — names, signatures, and types match across tasks (`clearLayers()` in Task 2 must not become `clearFullLayers()` in Task 4). Where a task consumes another task's output, an `Interfaces:` block must declare the exact contract.
7. **No placeholders** — scan Tasks for: "TBD", "TODO", "implement later", "add appropriate error handling", "write tests for the above" without a named assertion, "similar to Task N" without restated content, or references to undefined types/functions. Every match is a blocking finding.
8. **Verification reality** — each task's verification command is a real command for this project (check package config / `codebase-summary.md`), with a stated expected result. No invented test commands for areas the project does not test.
9. **Quick-spec scope check** — still ~1–5 files, single area, at most one obvious new dependency? If not, raise the upgrade trigger.
