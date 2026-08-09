# Quick-Spec Task Execution

Read this completely after the user approves `spec.md` and before editing implementation files. Resolve the requested task scope and execution approach, then read only the matching approach playbook.

## Pre-Flight Spec Check

Before executing anything, scan the approved spec once against reality:

- Do the file paths and line ranges still match the code? (Especially on resume — the codebase may have moved since the spec was written.)
- Do any tasks contradict each other, or contradict the Design section?
- Is anything unclear enough that you would have to guess mid-task?

Raise any blocking mismatch before implementation. If the execution approach is also unspecified, combine the mismatch and approach questions into one structured-question call. If the approach is explicit, ask only about the mismatch; do not make the user re-confirm their execution choice.

## Resolve Scope and Execution Approach

Treat scope and execution approach as separate decisions:

- `Implement all tasks` means every unchecked task in `spec.md`, in spec order.
- A task number, range, or section limits execution to that requested scope.
- Scope wording such as `all tasks` does not imply inline or subagent execution.

Apply this precedence before the first implementation edit:

1. **Explicit inline instruction** — wording such as `inline`, `in this session`, `active session`, or `do not spawn implementation subagents` selects inline execution. Do not ask another approach question.
2. **Explicit subagent instruction** — wording such as `use subagents`, `subagent-driven`, or `delegate implementation` selects subagent-driven execution. Do not ask another approach question.
3. **No approach specified** — ask once with the structured question tool and mark the recommendation `(Recommended)`. If that tool is unavailable, ask one concise plain-text question. Do not edit implementation files until the user chooses.

Derive the recommendation from the approved task graph:

- **Inline (this session)** — you execute the tasks yourself, in order. Recommend when tasks share files or form a tight sequential chain — the typical quick-spec, since it is single-area by definition. Lowest overhead, fastest for small task counts.
- **Subagent-driven (this session coordinates)** — spawn one fresh **`ai-orchestration-engineer`** implementer subagent per task, one at a time in sequence; verify, integrate, and update its checkbox before spawning the next. Recommend when tasks are individually meaty or the session context is heavily loaded — the win is isolation, not parallelism.

Explicit prompt wording always wins over the recommendation, injected context, or workspace configuration. If subagent execution was selected but subagent spawning is unavailable, stop and ask whether to continue inline; never change approaches silently.

After resolving the approach, update the spec's status from `Approved` to `In Progress` — both the frontmatter `status:` field (what the CLI reads) and the body `**Status:**` line, plus the frontmatter `updated:` date — and read and follow the matching playbook:

- Inline → `references/inline-execution.md`
- Subagent-driven → `references/subagent-execution.md`

## Shared Rules (both approaches)

**The spec is the ledger.** `spec.md`'s checkboxes are the single durable record of progress — they survive session restarts and context compaction, which your conversation memory does not. A ticked checkbox means that one task was implemented and passed its own verification; only the status field says the spec is done — the Completion steps below can still find blockers after every box is ticked. Check current state before starting and after any resume; never redo a task already marked `- [x]`:

```bash
python3 .claude/skills/aidlc-quick-spec/scripts/quick_spec_cli.py status FEATURE_SLUG
python3 .claude/skills/aidlc-quick-spec/scripts/quick_spec_cli.py progress FEATURE_SLUG
python3 .claude/skills/aidlc-quick-spec/scripts/quick_spec_cli.py complete FEATURE_SLUG TASK_NUM
```

**Verification gates the checkbox.** Run each task's verification command and get the expected result before marking it complete. If verification fails, fix the issue first. Lint and build are always required after the implementation is done; tests run when the project has tests for the area being changed — do not invent test commands for a codebase that doesn't test that area.

**Stop when blocked — never guess.** Stop and ask the user when you hit a missing dependency, a verification that fails repeatedly, an instruction you don't understand, or code that doesn't match what the spec claims. Bad work is worse than no work; a wrong guess costs more to unwind than the question costs to ask.

**Scope is fixed at the gate.** If completing a task requires touching a file not in the spec's File Structure, or the spec turns out to be wrong, that is a spec change: return to the Step 8 gate in SKILL.md, update the spec, say what changed, and (for scope changes, not minor wording) get re-approval before continuing.

## Completion

When every checkbox is done:

1. Run the project's lint and build one final time (plus the relevant test suite if the area has one).
2. Run `aidlc-code-review` **only if any of the following is true**: the change touched more than 3 files, introduced a new pattern not already present in the area, added a new dependency, or the user asked for a review. Otherwise skip it — quick-spec's surface area is small enough that verification plus the user's read of the spec catch what matters.
3. If the final lint/build or the review finds blockers, the spec stays `In Progress` — leave the checkboxes ticked (each task did pass its own verification); the unresolved findings, not the boxes, are the remaining work. Fix per the active approach — inline fixes directly; subagent-driven spawns one fixer subagent with the complete findings list — then re-run the affected verification and, when the review raised the blockers, the review.
4. Update the spec's status from `In Progress` to `Complete` — both the frontmatter `status:` field and the body `**Status:**` line, plus the frontmatter `updated:` date — only when lint/build and any run review are clean.
5. Report completion with verification evidence: per-task verification results (command + outcome), final lint/build results, review outcome when run, and any concerns raised along the way. Evidence, not adjectives.

## Resuming an In-Progress Quick-Spec

If a `spec.md` already exists at `{aidlc-docs-root}/specs/{feature}/`, its status field is the state machine — read it and re-enter the workflow at the matching point:

- **Draft** — never passed the gate: re-read the spec, ask the user whether they want revisions, then get approval at the Step 8 gate.
- **Approved** — approved but never started: run the Pre-Flight Spec Check, then resolve scope and execution approach above.
- **In Progress** — run the Pre-Flight Spec Check (reality may have drifted since the last session), honor the requested scope, and continue from the first unchecked task in that scope. Reuse an approach already selected in the active conversation or retained handoff context. On a fresh session where the approach is unknown and the prompt does not specify one, ask once. Do not restart from Step 1 or re-ask between tasks. If every checkbox is already ticked, the Completion steps are the remaining work — re-enter Completion (final lint/build, conditional review, status update); do not redo tasks and do not report the spec as done on the checkboxes alone.
- **Complete** — nothing to execute; say so and ask what the user actually wants (a follow-up change is a new quick-spec, not a reopened one).

If the status field and the checkboxes disagree (say, `Draft` with half the tasks checked), trust the checkboxes for progress, tell the user about the mismatch, and fix the status field.

If separate `requirements.md` / `design.md` / `tasks.md` exist instead of `spec.md`, recommend `aidlc-spec-driven`. If the user explicitly wants quick-spec, return to the consolidation rule in `SKILL.md` before execution; do not treat `tasks.md` as a quick-spec document.
