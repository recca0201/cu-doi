---
name: atlassian-rest
description: >
  Interact with Atlassian Jira and Confluence using REST APIs — no MCP server needed.
  Use this skill whenever the user mentions Jira, Confluence, Atlassian, tickets, issues,
  sprints, backlogs, epics, stories, or any project management task that involves
  creating/editing/searching/transitioning Jira issues, writing or reading Confluence pages,
  generating status reports, triaging bugs, converting specs to backlogs, capturing tasks
  from meeting notes, searching company knowledge, syncing local BMAD documents with Jira
  or Confluence, syncing local AIDLC documents such as requirements.md and tasks.md,
  pushing docs to Jira, pulling from Jira, linking documents to tickets,
  downloading Confluence spaces to local markdown, or converting between Confluence storage
  format and markdown. Also trigger when the user says things like "move that ticket to done",
  "what's the status of PROJ-123", "create a bug for X", "search our wiki for Y",
  "file a ticket", "check for duplicates", "write a status update",
  "break this spec into stories", "sync this doc", "push to jira", "pull from jira",
  "sync to confluence", "link this to jira", "sync my epics",
  "sync tasks.md", "sync implementation checklist", "sync task plan to jira",
  "create subtasks from tasks.md", or "map aidlc tasks to user stories",
  "download confluence pages", "sync confluence space", "convert confluence to markdown",
  or "pull docs from confluence". If there is even a chance the user wants to interact
  with Jira or Confluence, use this skill.
---

# Atlassian REST API Skill

Portable Jira & Confluence integration via REST APIs. Works in any agent environment with Node.js 18+ — zero dependencies, no MCP server required.

## First-Use Setup

`<skill-path>` throughout this document refers to the directory where this skill is installed. Resolve it from the skill invocation context (e.g., the path shown by `claude plugin list` or the skill's directory in `.claude/plugins/`).

Before any operation, verify the user has credentials configured. Run:

```bash
node <skill-path>/scripts/setup.mjs
```

If it fails, guide the user through the setup — the script prints step-by-step instructions.

### Credentials — .env File (Recommended)

The scripts automatically load a `.env` file so credentials never need to be exported in the terminal. Search order (first found wins):

1. `<cwd>/.env`
2. `<skill-root>/.env`
3. `<git-root>/.env`

**Quick start:**
```bash
cp <skill-path>/.env.example .env   # copy template to project root
# then edit .env and fill in your values
```

The `.env` file is gitignored by the skill's `.gitignore`. The root `.gitignore` already excludes `.env` and `.env.*` as well.

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `ATLASSIAN_API_TOKEN` | API token | *(generated at Atlassian)* |
| `ATLASSIAN_EMAIL` | Account email | `user@company.com` |
| `ATLASSIAN_DOMAIN` | Atlassian site domain | `company.atlassian.net` |

**`.env` format** (no quotes needed, comments allowed):
```
ATLASSIAN_EMAIL=you@example.com
ATLASSIAN_DOMAIN=yourcompany.atlassian.net
ATLASSIAN_API_TOKEN=your-api-token-here
```

Shell-exported variables always take precedence over `.env` values.

---

## How to Use This Skill

When the user asks you to do something with Jira or Confluence, follow these principles:

1. **Resolve ambiguity first.** If the user says "create a ticket" but hasn't specified a project, run `node <skill-path>/scripts/jira.mjs projects` to list available projects, then ask which one. Same for issue types — run `node <skill-path>/scripts/jira.mjs issue-types <projectKey>` if unsure.

2. **Confirm before mutating.** Before creating issues, transitioning tickets, or publishing Confluence pages, show the user what you're about to do and get confirmation. Read operations (search, get, list) don't need confirmation.

3. **Never delete.** This skill does not support delete operations (issues, pages, attachments, boards, projects, accounts, etc.). If the user asks to delete something, direct them to the Atlassian web UI. This restriction is intentional and must not be bypassed.

4. **Compose operations naturally.** Many user requests require multiple script calls. For example, "assign PROJ-123 to Sarah" requires: (a) `lookup-user "Sarah"` to get the account ID, then (b) `edit PROJ-123 --assignee <accountId>`.

5. **Prefer the document sync script that matches the artifact family.** Use `sync.mjs` for BMAD-style artifacts. Use `sync-aidlc.mjs` for AIDLC-style artifacts such as `aidlc-docs/story-artifacts/`, `aidlc-docs/specs/requirements.md`, and related AIDLC markdown structures. For `tasks.md`, treat the file as child execution work beneath already-linked AIDLC user stories: use `sync-aidlc.mjs` to establish the story links from `requirements.md`, then orchestrate subtask creation/update with `jira.mjs` under the correct parent story. Only use `jira.mjs create` for ad-hoc issues not backed by a local document.

6. **Use workflows for complex tasks.** If the user's request matches one of the workflows below, read the corresponding file and follow its step-by-step process.

7. **Read reference docs when needed.** Before writing JQL/CQL queries, consult `references/query-languages.md`. Before creating tickets, consult `references/ticket-writing-guide.md`. The reference docs exist to help you produce high-quality output — use them.

### Passing Long Content to Scripts

For descriptions, comments, or page bodies longer than ~200 characters or containing special
characters (backticks, quotes, `$`, newlines), **write the content to a temp file** and use the
file-based flag:

| Inline Flag | File Flag | Commands |
|-------------|-----------|----------|
| `--description "text"` | `--description-file /tmp/desc.md` | jira create, jira edit |
| `<body>` (positional) | `--body-file /tmp/body.md` | jira comment, confluence comment |
| `--body "text"` | `--body-file /tmp/body.md` | confluence create-page, update-page |
| `--comment "text"` | `--comment-file /tmp/comment.md` | jira worklog |

Write **plain markdown** to the file — scripts handle conversion to ADF (Jira) or storage format (Confluence) automatically. Prefer file-based input to avoid shell escaping issues.

### ⚠️ How to Write Temp Files (Agent-Specific — CRITICAL)

**NEVER use shell heredoc, multi-line `printf`, or `node -e "..."` with template literals to write temp files.** These methods corrupt content in AI agent terminal environments — special characters (`|`, `—`, backticks, `$`), multi-line strings, and markdown tables all get mangled.

**Correct two-step approach:**

1. Use the `create_file` tool to write the content directly to `/tmp/<name>.md`
2. Then pass the file path to the script via `--description-file`, `--body-file`, or `--comment-file`

**Step 1 — use the `create_file` tool (this is a tool call, NOT a shell command):**
```
File path:  /tmp/story-desc.md
Content:    ## Goal

            The description with | tables | and — dashes and `backticks`...
```

> ⚠️ **ADF Paragraph Collapse** — In the file content, separate key-value metadata lines with blank lines or use a markdown table. Single newlines between `**Key:** Value` lines collapse into one run-on paragraph in Jira. See `references/ticket-writing-guide.md` for the full rule and examples.

**Step 2 — run in terminal:**
```bash
node jira.mjs create --project PROJ --type Story --summary "Title" --description-file /tmp/story-desc.md
```

This applies to ALL long content: Jira descriptions, Confluence page bodies, comments, and worklogs.

---

## Jira Operations

Script: `node <skill-path>/scripts/jira.mjs <command> [args]`

### Search Issues
```bash
jira.mjs search 'project = PROJ AND status = "In Progress"' --max 20
```

### Get Issue Details
```bash
jira.mjs get PROJ-123
jira.mjs get PROJ-123 --fields summary,status,assignee
```

### Create Issue
```bash
jira.mjs create --project PROJ --type Task --summary "Implement feature X" \
  --description "Details here" --priority High --assignee <accountId> \
  --labels "backend,urgent" --components "API,Auth"
jira.mjs create --project PROJ --type Story --summary "User login" --parent PROJ-100
# For long descriptions, use a file:
jira.mjs create --project PROJ --type Task --summary "Feature X" \
  --description-file /tmp/desc.md --priority High
```
When creating child stories under an Epic, include `--priority Medium` unless the user specifies a different priority.

### Edit Issue
```bash
jira.mjs edit PROJ-123 --summary "Updated title" --priority Medium
jira.mjs edit PROJ-123 --labels "backend,v2" --components "API"
# For long descriptions, use a file:
jira.mjs edit PROJ-123 --description-file /tmp/desc.md
```

### Comments
```bash
jira.mjs comment PROJ-123 "Fixed in PR #456"
# For long comments, use a file:
jira.mjs comment PROJ-123 --body-file /tmp/comment.md
```

### Transitions (move ticket status)
```bash
jira.mjs transitions PROJ-123          # List available transitions first
jira.mjs transition PROJ-123 31        # Then transition by ID
```
Always list transitions first to get the correct ID — don't guess.

### Projects & Issue Types
```bash
jira.mjs projects                      # List all visible projects
jira.mjs issue-types PROJ              # List issue types for a project
```

### Issue Links
```bash
jira.mjs link-types                    # List available link types first
jira.mjs link PROJ-1 PROJ-2 --type "relates to"
```

### User Lookup
```bash
jira.mjs lookup-user "john"            # Returns account ID needed for --assignee
```

### Worklog
```bash
jira.mjs worklog PROJ-123 --time 2h --comment "Code review"
```

### Attachments
```bash
jira.mjs attach PROJ-123 ./screenshot.png          # Attach file to issue
jira.mjs list-attachments PROJ-123                  # List issue attachments
```

### ⚠️ Auto-Attach Referenced Files (Agent Rule)

When creating or editing a Jira issue from a markdown file, **scan the description for image or file references** before considering the job done. Common patterns to look for:

- `*(See attached screenshot: filename.png …)*`
- `![alt](filename.png)`
- `(See attached: filename.ext)`
- Any mention of "attached", "screenshot", or "see image" followed by a filename

For each referenced file:

1. Search the workspace for the file by name (use `file_search` or `grep_search`).
2. After the issue is created, attach each found file using `jira.mjs attach <issueKey> <filePath>`.
3. If a referenced file is not found in the workspace, warn the user.

This prevents the common mistake of creating a ticket that references attachments that were never uploaded. The create + attach steps should happen as one atomic workflow — never leave the user with a ticket that mentions files that aren't attached.

---

## Document Sync Operations

Scripts:

- `node <skill-path>/scripts/sync.mjs <command> [args]` for BMAD artifacts
- `node <skill-path>/scripts/sync-aidlc.mjs <command> [args]` for AIDLC artifacts

### Sync script selection config

Before choosing a sync script, agents should check `<skill-path>/memory/sync-tool-config.json` if it exists.

Recommended config shape:

```json
{
  "defaultSyncScript": "sync-aidlc.mjs",
  "rules": [
    { "contains": "/aidlc-docs/", "script": "sync-aidlc.mjs" },
    { "contains": "/_bmad/", "script": "sync.mjs" },
    { "contains": "/bmad/", "script": "sync.mjs" }
  ]
}
```

Selection rule:

- If a rule matches the file path, use that script.
- Otherwise use `defaultSyncScript`.
- If no config file exists, default to `sync.mjs` for BMAD docs and `sync-aidlc.mjs` for `aidlc-docs/` paths.

Both sync scripts auto-update the source document with links and maintain sync state, but they assume different markdown structures and child-item extraction rules.

### Setup Field Mapping (first time per doc type)
```bash
sync.mjs setup-mapping --type story --sample PROJ-200   # Auto-detect fields from existing ticket
sync.mjs setup-mapping --type epic --sample PROJ-100    # Creates memory/jira-epic-field-mapping.json
sync-aidlc.mjs setup-mapping --type story --sample PROJ-200
```
Field mappings are stored in `<skill-path>/memory/` and define how markdown sections map to Jira fields. BMAD mappings use files like `jira-story-field-mapping.json`; AIDLC mappings use files like `jira-aidlc-story-field-mapping.json`. For AIDLC story-artifact bundles, `sync-aidlc.mjs` creates and syncs only stories, not parent epics. See `references/sync-mapping-guide.md` for the full schema.

### Link & Create from Document
```bash
sync.mjs link <file> --type story --project PROJ --create    # Create Jira issue + update doc
sync.mjs link <file> --type epic --project PROJ --create     # Create epic + child stories
sync.mjs link <file> --type story --ticket PROJ-123          # Link to existing ticket
sync-aidlc.mjs link <file> --type story --project PROJ --create
```

### Push/Pull Changes
```bash
sync.mjs push <file>                    # Push local changes to Jira/Confluence
sync.mjs push <file> --delete-orphans   # Push + prompt to delete orphaned Sub-* subtasks
sync.mjs pull <file>                    # Pull remote changes to local
sync.mjs diff <file>                    # Show per-section diff
sync.mjs status <file>                  # Show sync status
sync-aidlc.mjs push <file>
sync-aidlc.mjs pull <file>
sync-aidlc.mjs diff <file>
sync-aidlc.mjs status <file>
```
When `push` reports orphaned subtasks (sections removed from local doc), ask the user if they want to delete them, then run with `--delete-orphans`. Only `Sub-*` issue types can be deleted — parent issues are skipped.

### AIDLC `tasks.md` -> Jira subtasks

Use the native task-plan sync command for `tasks.md` files:

```bash
node <skill-path>/scripts/sync-aidlc.mjs sync-task-plan <tasks.md>
node <skill-path>/scripts/sync-aidlc.mjs sync-task-plan <tasks.md> --apply
```

This command extracts checklist tasks, reads the sibling `requirements.md`, maps referenced `US-*` values to Jira stories, previews the create or update plan, and applies the subtask sync when `--apply` is provided.

Use this process:

1. Read the sibling `requirements.md` first and build a `US-* -> Jira key` map from `**Related Jira**` lines or sync-only `Related Jira` references added by previous AIDLC sync runs.
2. Parse `tasks.md` by top-level checklist item. The parent checkbox line is the task summary; the indented `Reference:` line and the remaining bullets become the task metadata and description.
3. Expand each task into one target Jira parent story per referenced `US-*`. If multiple `US-*` references are listed, create or update one subtask under each mapped parent story.
4. Before mutating Jira, show the user a mapping table: local task number, task summary, referenced `US-*`, target parent Jira key, and action per parent. Ask for confirmation.
5. Make the sync idempotent per parent story. Search for an existing child issue under each chosen parent before creating anything. Use deterministic metadata such as labels like `aidlc-spec-<spec-slug>` and `aidlc-task-<task-number>`, and include stable source markers in the description (`Source file`, `Task ID`, `Referenced US`, `Parent Jira story`). On reruns, update the existing subtask for that parent instead of creating a duplicate.
6. Create or update one child issue per mapped parent story with `jira.mjs create` or `jira.mjs edit`. Use the parent story key from the `requirements.md` mapping. Prefer the project's real subtask type if available; if unsure, run `jira.mjs issue-types <projectKey>` first.
7. If a checkbox is already checked in `tasks.md`, treat that as evidence each synced subtask may need a status update, but do not guess the transition. List transitions first for each affected issue, then propose the matching move.
8. If a task has no usable `US-*` reference, or any referenced story has no Jira key yet, stop and ask the user whether to link `requirements.md` first or which parent story set to use. Do not guess.

For a full multi-step procedure, read `workflows/sync-aidlc-task-plans.md`.

### Custom Instructions in Mapping Config
The field mapping JSON (`memory/jira-<docType>-field-mapping.json`) supports an `instructions` field for additional agent guidance:
```json
{
  "instructions": "Always set priority to High. Add label 'team-alpha'. Use Sub-Imp type for child items."
}
```
When present, instructions are printed to stdout during `push` and `link` operations so the calling agent can follow them.

### Batch Operations
```bash
sync.mjs batch                # Scan all linked docs and report status
```

---

## Confluence Operations

Script: `node <skill-path>/scripts/confluence.mjs <command> [args]`

### Search Pages
```bash
confluence.mjs search 'type = page AND text ~ "architecture"' --max 10
```

### Get Page
```bash
confluence.mjs get-page 12345
confluence.mjs get-page 12345 --format view
```

### Create Page
```bash
confluence.mjs create-page --space TEAM --title "Sprint Report" --body "Report content"
confluence.mjs create-page --space TEAM --title "Sub Page" \
  --body "<h2>Heading</h2><p>Content</p>" --parent 12345
confluence.mjs create-page --space TEAM --title "Full Doc" --body-file /tmp/body.md
```
The `--body` flag accepts **markdown** (recommended), plain text, or raw HTML storage format (if it starts with `<`). The script automatically converts markdown to Confluence storage format — headings, lists, tables, and code blocks (converted to `ac:structured-macro ac:name="code"` with language detection) are all handled. Prefer writing markdown and letting the script handle conversion rather than manually constructing storage format XHTML. Use `--body-file` for long documents that would exceed shell argument limits.

### Update Page
```bash
confluence.mjs update-page 12345 --title "Updated Title" --body "New content"
confluence.mjs update-page 12345 --title "Updated Title" --body-file /tmp/body.md
```
Version is auto-incremented — no need to track it manually. Use `--body-file` for large page updates.

### Comments
```bash
confluence.mjs comment 12345 "Reviewed and approved"
# For long comments, use a file:
confluence.mjs comment 12345 --body-file /tmp/comment.md
```

### Attachments
```bash
confluence.mjs attach 12345 ./screenshot.png --comment "Architecture diagram"
confluence.mjs list-attachments 12345 --max 10
```
Use `attach` to upload local files (images, PDFs, etc.) to a page. After uploading, embed images in the page body using `<ac:image><ri:attachment ri:filename="screenshot.png" /></ac:image>` — see `references/confluence-formatting.md` for sizing guidelines.

### Sync Confluence Space to Local Markdown
```bash
# Download an entire page tree to local markdown with attachments
node <skill-path>/scripts/sync-confluence-space.mjs --root <pageId> --output ./docs

# Preview without writing files
node <skill-path>/scripts/sync-confluence-space.mjs --root <pageId> --output ./docs --dry-run

# Skip attachment downloads (faster, markdown only)
node <skill-path>/scripts/sync-confluence-space.mjs --root <pageId> --output ./docs --skip-attachments
```
Downloads an entire Confluence page tree to local markdown files with hierarchy, images, and linked titles. Rewrites both image references and file attachment links to point to local assets. See `workflows/sync-confluence-space.md` for full details and customization options.

### Spaces & Navigation
```bash
confluence.mjs spaces --max 20
confluence.mjs descendants 12345       # Get child pages
```

---

## Format Conversion Utilities

Script: `<skill-path>/scripts/confluence-format.mjs`

This module provides bidirectional markdown ↔ Confluence storage format conversion. It's used internally by `confluence.mjs` but can also be imported directly for custom sync scripts.

### Exported Functions

```js
import { markdownToStorage, storageToMarkdown, htmlInlineToMarkdown } from '<skill-path>/scripts/confluence-format.mjs';
```

| Function | Direction | Use case |
|----------|-----------|----------|
| `markdownToStorage(md)` | Markdown → XHTML | Publishing to Confluence (auto-used by `confluence.mjs --body-file`) |
| `storageToMarkdown(html)` | XHTML → Markdown | Downloading/syncing Confluence pages to local markdown files |
| `htmlInlineToMarkdown(html)` | Inline HTML → Markdown | Converting snippets (table cells, list items) that may contain `<strong>`, `<em>`, `<a>`, `<code>` |

### What `storageToMarkdown` Handles

The converter handles real-world Confluence storage format patterns including:

- **Structured macros**: code blocks (with/without language), panels (info/tip/warning/note → GitHub alerts), expand → `<details><summary>` collapsible sections, jira references, view-file → attachment links, toc/children (stripped)
- **Unknown macros**: Any unrecognized `ac:structured-macro` types have their body content preserved (not silently dropped)
- **Tables**: `<colgroup>`, `<tbody>`, `<thead>` wrappers stripped; attributes on `<table>`, `<tr>`, `<th>`, `<td>` handled
- **Task lists**: `<ac:task-list>` with `<ac:task-id>` → markdown checkboxes
- **Images**: URL and attachment images → `![alt](url)` with filename as fallback alt text; parentheses and spaces in filenames URL-encoded
- **Code blocks**: Protected from HTML tag stripping via placeholder system — generic types like `Array<string>` preserved inside fenced blocks
- **Expand/collapsible bodies**: Full content support inside expand macros — code blocks, images, tables, panels, task lists, and nested macros all convert correctly
- **Entities**: Full HTML entity decoding (`&rsquo;`, `&ldquo;`, `&rarr;`, `&nbsp;`, numeric `&#123;`)
- **Block separation**: `\n\n` around headings, images, lists, `<hr>`, tables, code blocks
- **Attribute tolerance**: All HTML tag regexes accept optional attributes (handles Confluence's `local-id`, `data-layout`, `breakoutWidth`, etc.)
- **Bold/italic cleanup**: Trailing spaces inside markers fixed (`**text **` → `**text**`)
- **Stray angle brackets**: Escaped outside code blocks to prevent markdown renderer confusion

### Syncing a Confluence Space

For most use cases, use the built-in sync script directly:
```bash
node <skill-path>/scripts/sync-confluence-space.mjs --root <pageId> --output ./docs
```

For custom sync scripts, import `storageToMarkdown` and follow this pattern:

```js
import { storageToMarkdown } from '<skill-path>/scripts/confluence-format.mjs';

// Fetch page via Confluence v2 API
const page = await apiGet(`/wiki/api/v2/pages/${pageId}`, { 'body-format': 'storage' });
const html = page.body.storage.value;

// Convert to markdown
let markdown = storageToMarkdown(html);

// Add linked title using page._links.base + page._links.webui
const pageUrl = `${page._links.base}${page._links.webui}`;
markdown = `# [${page.title}](${pageUrl})\n\n${markdown}`;
```

**Key gotchas discovered in production use:**
- The v2 API `_links.webui` is a relative path (e.g., `/spaces/BTH/pages/123/Title`). Combine with `_links.base` (e.g., `https://company.atlassian.net/wiki`) for the full URL — do NOT use `env.domain` + `_links.webui` directly (missing `/wiki` prefix).
- Attachment filenames with spaces and parentheses must be URL-encoded in markdown links: `![alt](Screenshot%202025-11-05%20at%2016.50.02.png)`.
- When writing a hierarchical sync, use `getChildrenTree()` (recursive children API) to build the tree, then decide per-node: pages with children → `directory/index.md`, leaf pages → flat `PageName.md`.
- Keep attachments in a shared `assets/imgs/` and `assets/pdfs/` directory. Use depth-aware relative paths (`../assets/imgs/` at depth 1, `../../assets/imgs/` at depth 2, etc.).
- The sync script must rewrite **both** image references (`![alt](filename)`) and file attachment links (`[filename](filename)`) to local paths — Confluence `view-file` macros produce regular links, not image references.
- Confluence adds attributes (`local-id`, `breakoutWidth`, `data-layout`) to most HTML tags. Any regex matching tags must use `[^>]*` for optional attributes.
- Expand macro bodies can contain any content (code blocks, images, tables). The inner HTML converter must handle the same set of elements as the main converter.

### Running Tests

```bash
node <skill-path>/scripts/test-format.mjs
```

100+ tests covering forward conversion, reverse conversion, round-trip preservation, block element spacing, code block protection, image URL encoding, entity decoding, expand macros with nested content, view-file macros, unknown macro catch-all, and attribute tolerance on HTML tags.

---

## Workflows

For complex multi-step operations that require user interaction across several turns, read the corresponding workflow file and follow its step-by-step process. For simple one-shot commands, use the operations sections above directly.

| Workflow | When to use | File |
|----------|-------------|------|
| **Capture Tasks from Meeting Notes** | User provides meeting notes and wants Jira tasks created from action items | `workflows/capture-tasks-from-meeting-notes.md` |
| **Generate Status Report** | User wants a project status report, sprint summary, or weekly update | `workflows/generate-status-report.md` |
| **Search Company Knowledge** | User wants to find information across Confluence pages and Jira issues | `workflows/search-company-knowledge.md` |
| **Spec to Backlog** | User has a Confluence spec and wants it broken into an Epic + child tickets | `workflows/spec-to-backlog.md` |
| **Triage Issue** | User reports a bug and wants duplicate checking before filing | `workflows/triage-issue.md` |
| **Create Confluence Document** | User wants a professional Confluence page with macros, images, and structured formatting | `workflows/create-confluence-document.md` |
| **Sync BMAD Documents** | User wants to sync local BMAD docs (epics, tech specs, PRDs, architecture) with Jira or Confluence, or link a document to a ticket/page | `workflows/sync-bmad-documents.md` |
| **Sync AIDLC Task Plans** | User wants to sync `aidlc-docs/specs/.../tasks.md` or an implementation checklist to Jira subtasks under linked `US-*` stories | `workflows/sync-aidlc-task-plans.md` |
| **Sync Confluence Space** | User wants to download an entire Confluence space to local markdown files with hierarchy, images, and linked titles | `workflows/sync-confluence-space.md` |

---

## Error Handling

| Error | Likely Cause | Resolution |
|-------|-------------|------------|
| `401 Unauthorized` | Bad or expired API token | Regenerate at Atlassian security settings |
| `403 Forbidden` | Insufficient permissions | Check project/space permissions for the user's account |
| `404 Not Found` | Wrong issue key, page ID, or domain | Verify the resource exists and `ATLASSIAN_DOMAIN` is correct |
| `429 Too Many Requests` | Rate limited | Wait briefly and retry; reduce batch sizes |
| Missing env vars | Not configured | Run `node <skill-path>/scripts/setup.mjs` |

---

## Reference Documentation

Load these as needed — don't read them all upfront:

| Reference | When to consult |
|-----------|-----------------|
| `references/jira-api.md` | Need details on Jira API endpoints or request shapes |
| `references/confluence-api.md` | Need details on Confluence API endpoints or storage format |
| `references/confluence-formatting.md` | Building professional pages with macros, layouts, images, and document templates |
| `references/query-languages.md` | Writing JQL or CQL queries |
| `references/jql-patterns.md` | Need common JQL patterns for reports, searches, filters |
| `references/action-item-patterns.md` | Parsing meeting notes for action items |
| `references/report-templates.md` | Generating status reports |
| `references/bug-report-templates.md` | Creating well-structured bug reports |
| `references/search-patterns.md` | Multi-source search strategies |
| `references/epic-templates.md` | Writing epic descriptions |
| `references/ticket-writing-guide.md` | Writing clear ticket summaries and descriptions |
| `references/breakdown-examples.md` | Breaking specs into stories and tasks |
| `references/sync-mapping-guide.md` | Before first document sync, when mapping fields fail, or configuring custom field mappings |
