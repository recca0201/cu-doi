# Inline Execution

Use this playbook only after `references/task-execution.md` resolves the approach to inline through explicit user wording or the one-time handoff. Execute the approved tasks yourself, in this session, in order; do not spawn implementation subagents. Apply the shared ledger, verification, stop-when-blocked, and scope rules throughout.

## Before the First Edit

Re-read the approved spec critically, as the engineer about to do the work rather than the author who wrote it. If you have concerns — an approach you now doubt, a step that seems wrong against the real code — raise them with the user **before** starting, not after three tasks are built on the shaky one. If the Pre-Flight Spec Check already ran and came back clean, a quick skim is enough.

## Per-Task Loop

For each unchecked task, in spec order:

1. Read the full task — every step, the `Implements:` line, the `Interfaces:` block if present.
2. Follow the steps exactly as written. The spec was reviewed and approved at this granularity; silently "improving" a step mid-flight bypasses both review gates. If a step is genuinely wrong, that's the scope rule — stop and go back to the gate.
3. Run the task's verification command and confirm the expected result. Fix failures before moving on.
4. Check off the task's step checkboxes (`- [x]`) as they land — or tick the whole task at once with the CLI `complete FEATURE_SLUG TASK_NUM` — and record the verification outcome for the completion report.

## Execution Tempo

Execute continuously — do not pause between tasks to ask "should I continue?" or post progress summaries. The user approved the whole spec; the approval covers all of its tasks. The only reasons to stop mid-run are the shared stop-when-blocked conditions, a scope break, or all tasks complete.

Narrate lightly: one short line per completed task ("Task 2 done — lint clean, 6/6 tests passing"). The checkboxes and the completion report carry the record; play-by-play commentary between edits is noise.

## Watch Your Own Drift

Inline execution has a failure mode subagents don't: accumulated context makes it tempting to batch ahead, skip a verification "because the last three passed," or fold two tasks together. The bite-sized task structure is what makes the spec reviewable and resumable — honor one task, one verification, one checkbox even when you can see the end from here. If a task turns out bigger than its 2–5 minute intent, that is spec feedback worth mentioning at completion, not a license to freestyle.
