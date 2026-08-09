# Sync AIDLC Task Plans

Workflow for syncing `aidlc-docs/specs/.../tasks.md` implementation checklists to Jira subtasks under the correct AIDLC user story tickets.

**Reference files:** `references/query-languages.md`, `references/ticket-writing-guide.md`

---

## Step 1: Resolve the AIDLC context

Ask the user for the `tasks.md` path if they did not provide it.

Then locate the sibling `requirements.md` in the same spec directory. Treat `requirements.md` as the source of truth for story-level Jira links. If `requirements.md` is not linked to Jira yet, pause the subtask sync and link or sync the stories first.

Use the native command:

```bash
node <skill-path>/scripts/sync-aidlc.mjs sync-task-plan <tasks.md>
node <skill-path>/scripts/sync-aidlc.mjs sync-task-plan <tasks.md> --apply
```

The first form previews the mapping and the second applies it.

## Step 2: Build the story map

Read the `requirements.md` user story sections and extract:

- `US-*` identifier
- User story heading or summary
- Jira key from `**Related Jira**` or sync-only `Related Jira` references

Create a table for yourself:

| US | Jira key | Summary |
|----|----------|---------|
| US-1 | SCRUM-10 | Add Toolbar Button to Specs TreeView |

If any referenced `US-*` in `tasks.md` does not have a Jira key, stop and ask the user whether to link the story first.

## Step 3: Parse `tasks.md`

For each top-level checklist item under `## Implementation Checklist`, extract:

- Task number from the checkbox line
- Task summary from the checkbox text
- `Reference:` line
- Supporting bullets such as files, implementation notes, and test steps
- Completion state from `[ ]` or `[x]`

Treat each top-level checklist item as one Jira subtask candidate.

## Step 4: Expand each task to all referenced parent stories

Each Jira subtask can have only one parent, but one checklist task can sync to multiple parent stories.

Use this rule order:

1. If the `Reference:` line mentions one `US-*`, sync one subtask to that story.
2. If it mentions multiple `US-*` values, sync one subtask per referenced story.
3. Keep the full referenced `US-*` set in each subtask description, and include the current parent story as separate stable metadata.

This is the default behavior for multi-US tasks. Do not collapse a multi-US task down to a single parent story.

## Step 5: Present the planned mapping

Before creating or editing subtasks, show the user a concise plan:

| Task | Referenced stories | Parent Jira key | Action |
|------|--------------------|-----------------|--------|
| 3. Implement command handler for refine spec shortcut | US-2, US-3, US-6, US-7 | SCRUM-11 | create/update subtask |
| 3. Implement command handler for refine spec shortcut | US-2, US-3, US-6, US-7 | SCRUM-12 | create/update subtask |
| 3. Implement command handler for refine spec shortcut | US-2, US-3, US-6, US-7 | SCRUM-15 | create/update subtask |
| 3. Implement command handler for refine spec shortcut | US-2, US-3, US-6, US-7 | SCRUM-16 | create/update subtask |

Because this is a mutating operation, get confirmation before proceeding.

## Step 6: Make the sync idempotent

Do not create blind duplicates.

Before creating a subtask, search beneath each chosen parent for an existing issue using the task summary together with stable source metadata in the description:

- Exact task summary under the current parent story
- Description markers such as:
  - `AIDLC Task ID: 1`
  - `Source file: apps/mtv-aidlc-vscode/aidlc-docs/specs/create-spec-shortcut/tasks.md`
  - `Referenced US: US-2, US-3, US-6, US-7`
  - `Parent Jira story: SCRUM-15`

Prefer searching by parent plus one of those markers. If you find a matching subtask under a given parent, update it instead of creating a new one there.

## Step 7: Create or update the subtasks

Create or edit one Jira subtask per parent story with:

- Summary from the checklist item text
- Description built from the `Reference:` line, supporting bullets, and stable source metadata only
- Stable source metadata for reruns
- Parent set to the mapped user story Jira key for that specific copy

When the project uses a custom subtask issue type, discover it first with:

```bash
node <skill-path>/scripts/jira.mjs issue-types <PROJECT_KEY>
```

Then create or edit with the appropriate issue type and parent.

## Step 8: Handle completion state carefully

If the checklist item is `[x]`, propose a status transition for each matching subtask. Do not guess the transition ID.

Always list transitions first:

```bash
node <skill-path>/scripts/jira.mjs transitions <ISSUE_KEY>
```

Then confirm the intended move with the user before transitioning.

## Step 9: Report results

Summarize which subtasks were created, updated, skipped, or blocked, and include the parent story key for each.

Call out any unresolved cases clearly:

- Missing Jira link for one or more referenced `US-*`
- Existing duplicate subtasks that require cleanup

The important outcome is traceable execution work under the right user story, not just a batch of new Jira tickets.