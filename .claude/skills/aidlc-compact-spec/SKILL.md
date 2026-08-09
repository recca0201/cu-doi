---
name: aidlc-compact-spec
description: >-
  Compact implemented, completed, outdated, or noisy AI-DLC specs into durable
  project memory. Use when the user asks to compact a spec, archive old specs,
  reduce too many specs, preserve useful implemented-spec knowledge, detect
  stale spec claims against current code, or prepare foundation update
  candidates from specs. Trigger from `/aidlc-compact-spec` prompts and from
  MTV AI-DLC Compact Spec shortcuts. Dry-run by default; apply only after
  explicit approval.
metadata:
  argument-hint: "[aidlc-docs/specs/<spec-slug>|path/to/spec.md] [--focus \"...\"] [--apply] [--no-foundation-candidates]"
---

# AI-DLC Compact Spec

Compact one old or completed spec into reviewable memory, then archive the raw spec after approved apply.

## Authority

Use this source-of-truth order:

1. Current code, tests, and accepted current specs
2. Foundation docs and Decision Records
3. Existing memory cards
4. Archived specs and old planning notes

Memory is derived context, not truth. If memory and current source disagree, current source wins.

## Inputs

Supported prompt shape:

```text
/aidlc-compact-spec aidlc-docs/specs/<spec-slug>
/aidlc-compact-spec aidlc-docs/specs/<spec-slug>/spec.md --focus "implementation decisions"
/aidlc-compact-spec aidlc-docs/specs/<spec-slug> --apply
```

Default behavior is dry-run. Do not modify memory, foundation docs, or archive location unless `--apply` is present or the user explicitly approves applying after reviewing the dry-run.

## Memory Structure

Use this flat MVP structure:

```text
aidlc-docs/memory/
├── README.md
├── index.md
├── spec-memory.md
├── foundation-candidates.md
└── compact-reports/
```

Do not create nested category folders in the first MVP.

## Workflow

### 1. Resolve and preflight

- Resolve the target to one active spec folder under `aidlc-docs/specs/`.
- Reject targets already under `aidlc-docs/specs/_archive/`.
- Read available spec files: `requirements.md`, `design.md`, `tasks.md`, `spec.md`, `test-cases.md`, `uiux_spec.md`, and directly related mockups or notes only when referenced.
- If no compactable markdown exists, stop and report that the target is not a spec.
- If applying and `aidlc-docs/specs/_archive/<spec-slug>/` already exists, stop before writing memory.

### 2. Extract durable facts

Keep only information likely to help future work:

- Product or user behavior that still matters.
- Architecture decisions, implementation patterns, and rejected alternatives.
- Source file ownership, module boundaries, public commands, or workflow contracts.
- Important task outcomes, known limitations, follow-up risks, and validation behavior.
- Business scope boundaries that help future user story or business checks.

Do not keep full requirements tables, full design sections, obvious boilerplate, temporary task notes, or duplicate text already owned by foundation docs.

### 3. Validate freshness

Validate extracted facts against current implementation before calling them current:

- Extract source references from backticked paths, markdown links, `src/`, `scripts/`, `resources/`, `package.json`, `README.md`, `INSTALLATION.md`, and command names like `mtv-aidlc.compactSpec`.
- For each path, check whether it exists. If missing, search by basename or key symbol with `rg`.
- Use git as a freshness signal:
  - `git log -n 1 -- <referenced-source-path>`
  - `git log -n 1 -- aidlc-docs/specs/<spec-slug>`
- Search newer specs, DRs, and existing memory for overlap or supersession.
- Treat git dates as signals only. Do not use them as final proof that behavior is current.

### 4. Classify

Classify each candidate:

| Classification | Meaning | Output |
|---|---|---|
| Keep verified | Supported by current code, tests, current spec, or accepted DR. | Memory card |
| Keep historical | Useful context but no longer current. | Memory card with `Historical` |
| Needs review | Plausible but weak evidence, missing source, conflict, or recent source change. | Compact report only by default |
| Foundation candidate | Durable project context may belong in foundation docs. | `foundation-candidates.md` |
| Drop | Duplicate, too detailed, obsolete without future value, or boilerplate. | Summary count only |

When a spec is out of date because newer specs or current code supersede it, do not silently preserve stale claims as verified. Mark them `Historical` or `Needs Review` and cite the newer source.

### 5. Report

Always produce a compact report in the response. If writing files is appropriate, write:

```text
aidlc-docs/memory/compact-reports/<spec-slug>-YYYY-MM-DD.md
```

The report must include:

- Target spec path
- Dry-run or applied status
- Source paths found, existing, missing, and searched replacements
- Existing memory conflicts or stale memory warnings
- Candidate memory cards
- Foundation candidates
- Archive action that will happen on apply
- Explicit recommendation: apply, revise, keep active, or reject compaction

### 6. Apply

Only apply after explicit approval.

Apply order:

1. Create `aidlc-docs/memory/` and `compact-reports/` if needed.
2. Ensure `README.md` explains memory is derived and lower authority than code, tests, foundation, DRs, and active specs.
3. Append approved cards to `spec-memory.md`.
4. Update `index.md` with spec slug, freshness, original path, archive path, and report path.
5. Append foundation candidates to `foundation-candidates.md`.
6. Write the applied compact report.
7. Move the original spec folder to `aidlc-docs/specs/_archive/<spec-slug>/`.

Move rules:

- Preserve the original spec folder contents exactly.
- Create `_archive/` if missing.
- Never overwrite an existing archive destination.
- Never delete the archived spec.
- Dry-run never moves the spec.

## Memory Card Format

```md
## <short memory title>

Status: Verified | Historical | Needs Review
Confidence: High | Medium | Low
Source spec: aidlc-docs/specs/<spec-slug>
Source evidence:
- <current source path, current spec, DR, or archived spec path>
Last Verified: YYYY-MM-DD

Summary:
<2-5 concise bullets or one short paragraph>

Use when:
- <specific future workflow>

Guardrail:
<what must be rechecked before relying on this memory>
```

Avoid writing `Needs Review` cards during apply unless the user explicitly asks to preserve them. Prefer keeping uncertain items in the report.

## Foundation Handoff

Do not edit foundation docs directly as part of Compact Spec.

When a durable insight belongs in foundation context:

1. Write it to `aidlc-docs/memory/foundation-candidates.md`.
2. Tell the user to run `aidlc-foundation-context` or `/aidlc.foundation.foundation-context` for the actual foundation update.
3. Include target doc suggestions such as `codebase-summary.md`, `system-architecture.md`, `code-standards.md`, `project-overview-pdr.md`, or `uiux-guideline.md`.

## Completion Behavior

If run from a VS Code shortcut, treat the prompt path as the selected spec. The extension is only a launcher; this skill owns all analysis, file edits, archive movement, and foundation handoff.
