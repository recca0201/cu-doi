---
name: azure-devops
description: This skill should be used when working with Azure DevOps operations including work items, pull requests, repositories, branches, team capacity planning, iterations, backlogs, or when users mention Azure DevOps, ADO, sprint planning, or DevOps workflows. Provides comprehensive guidance using the official azure-devops Python library and REST API patterns.
---

# Azure DevOps

## Overview

This skill provides guidance for working with Azure DevOps using the **official azure-devops Python library** from Microsoft.

**Installation:**
```bash
pip install azure-devops
```

## Core Capabilities

### 1. Work Item Management
- Create, read, update, **delete** work items (tasks, bugs, user stories, features, epics)
- Create a work item already linked under a parent (`parent_id=`)
- **Link/relate** work items (parent, child, related, predecessor, successor) and **add comments**
- Read a work item's **revision history**
- Query work items using WIQL (Work Item Query Language)
- **Get child work items**: Retrieve all children of a parent work item with optional type filtering
- Get current sprint/iteration for a team
- Get user stories in current sprint (with optional child items)
- Export work items to markdown with full details and acceptance criteria
- Link work items to each other or to PRs/commits
- Add comments and track work item history
- **Filter Enabler work items**: All sprint/bolt methods support `exclude_ritual_enablers` to filter out Enabler items used for rituals
- **AIDLC-specific**: Get work items by bolt name (AIDLC sprint terminology)

### 2. Repository & Pull Request Management
- List repositories and branches
- Create and manage branches
- Create and update pull requests
- Add reviewers and manage PR comments
- Link work items to pull requests
- Search commits and track changes

### 3. Work Management (Iterations & Capacity)
- Read the current/named sprint and its work items via the helper
- Iteration **management** (create/assign iterations) and **capacity** (get/update) are
  documented as raw library/REST patterns in [references/work-operations.md](references/work-operations.md)
  — these are **not** wrapped by the helper yet

### 4. Core Operations
- List projects and teams
- Get identity information for user assignment
- Manage project settings

## Authentication

Azure DevOps uses **Personal Access Tokens (PAT)** for authentication.

**Quick Start:**
```python
from azure.devops.connection import Connection
from msrest.authentication import BasicAuthentication

credentials = BasicAuthentication('', 'YOUR_PAT')
connection = Connection(
    base_url='https://dev.azure.com/YOUR_ORG',
    creds=credentials
)

# Get clients
core_client = connection.clients.get_core_client()
git_client = connection.clients.get_git_client()
work_item_client = connection.clients.get_work_item_tracking_client()
```

**Local Configuration:**

IMPORTANT: Never commit `.env` files with real credentials!

1. Copy `.claude/skills/azure-devops/.env.example` to `.env`
2. Fill in: `AZURE_DEVOPS_ORG`, `AZURE_DEVOPS_PAT`, and optional project/team defaults
3. Use minimum required scopes, rotate tokens every 90 days

For PAT creation, authentication patterns, and troubleshooting, see [references/api-authentication.md](references/api-authentication.md).

## Using the Helper Class

The skill includes `scripts/ado_helper.py` - a modular helper class wrapping the official library with convenience methods.

**Essential usage:**
```python
from scripts.ado_helper import AzureDevOpsHelper

# Initialize (reads from .env automatically)
helper = AzureDevOpsHelper()

# Get work item
work_item = helper.get_work_item(12345)

# Create work item (optionally as a child of a parent)
new_item = helper.create_work_item(
    "Task",
    "Implement new feature",
    parent_id=200,  # optional — links under parent in one call
    **{"System.Description": "Details here"}
)

# Link, comment, delete, and read history
helper.link_work_items(12345, 200, link_type="parent")   # also: child/related/predecessor/successor
helper.add_comment(12345, "Blocked on the API team")
helper.delete_work_item(12345)                            # recycle bin; destroy=True for permanent
history = helper.get_work_item_revisions(12345)

# Query with WIQL
items = helper.query_work_items("SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'")

# Get current sprint
current_sprint = helper.get_current_sprint("My Team")

# Get sprint user stories (with optional child items)
stories = helper.get_current_sprint_user_stories("My Team", include_child_items=True)

# Get sprint items excluding Enabler work items (for rituals)
items = helper.get_sprint_items("Project\\Sprint 1", exclude_ritual_enablers=True)

# Get child work items of a parent (e.g., all PBIs under a Feature)
children = helper.get_child_work_items(7728)
tasks = helper.get_child_work_items(12345, work_item_type="Task")

# Export work items to markdown
helper.export_work_items_to_markdown(team="My Team")
```

**CLI usage:**
```bash
python3 scripts/ado_helper.py projects
python3 scripts/ado_helper.py workitem 12345
python3 scripts/ado_helper.py children 7728              # Get all children of work item
python3 scripts/ado_helper.py children 7728 Task         # Get only Task children
python3 scripts/ado_helper.py link 12345 200 parent      # Link 12345 under parent 200
python3 scripts/ado_helper.py comment 12345 "Blocked on API team"
python3 scripts/ado_helper.py delete 12345               # Delete to recycle bin (add 'destroy' for permanent)
python3 scripts/ado_helper.py current_sprint "My Team"
python3 scripts/ado_helper.py export_sprint --team "My Team"
python3 scripts/ado_helper.py export_sprint --ids 123 456 --output bugs.md
```

**IMPORTANT:** Always use the existing `ado_helper.py` for Azure DevOps operations (via Python import or CLI). Never create new scripts like `update_workitems.py` or `sync_ado.py` - this avoids code duplication and maintains consistency.

## AIDLC-Specific Methods

The skill includes specialized methods for **AIDLC (AI-Driven Development Lifecycle)** workflows using "bolt" terminology:

**Python usage:**
```python
from scripts.ado_helper import AzureDevOpsHelper

helper = AzureDevOpsHelper()

# Get current bolt (AIDLC sprint)
current_bolt = helper.get_current_bolt("AI Team")

# Get work items in specific bolt by name
items = helper.get_bolt_items("Bolt 15", "AI Team")

# Get work items in current bolt (excludes Enabler by default)
current_items = helper.get_current_bolt_items("AI Team")

# Include all work items (including Enabler)
all_items = helper.get_current_bolt_items("AI Team", exclude_ritual_enablers=False)

# Get only User Stories in current bolt
stories = helper.get_current_bolt_items("AI Team", work_item_type="User Story")
```

**CLI usage:**
```bash
# Get current bolt
python3 scripts/ado_helper.py current_bolt "AI Team"

# Get work items in specific bolt
python3 scripts/ado_helper.py bolt_items "Bolt 15" "AI Team"

# Get work items in current bolt (excludes Enabler by default)
python3 scripts/ado_helper.py current_bolt_items "AI Team"
```

**Key features:**
- **Automatic Enabler filtering**: By default, `get_bolt_items()` and `get_current_bolt_items()` exclude Enabler work items (used for rituals)
- **Flexible filtering**: Use `exclude_ritual_enablers=False` to include all items
- **Bolt name resolution**: `get_bolt_items()` finds the iteration by name (e.g., "Bolt 15", "Sprint 2")
- **AIDLC terminology**: Methods use "bolt" instead of "sprint" to align with AIDLC vocabulary

## Work Item Export to Markdown

Export work items with full details using `export_work_items_to_markdown()`:

**Three export modes:**
1. **Current Sprint:** `helper.export_work_items_to_markdown(team="AI Team")`
2. **Specific Sprint:** `helper.export_work_items_to_markdown(sprint_path="AI Initiative\\Sprint 15")`
3. **By ID:** `helper.export_work_items_to_markdown(work_item_ids=[123, 456], output_file="bugs.md")`

Exports include titles, descriptions, acceptance criteria, state, priority, story points, tags, assignees, and direct ADO links.

**User Story format:** Enhanced with US-{ID} heading, extracted user story field, High/Medium/Low priority, optional Related ADO/Jira fields, organized sections.

## API References

Load these references as needed for specific operations:

- [references/api-authentication.md](references/api-authentication.md) - PAT generation, authentication patterns, troubleshooting
- [references/work-items.md](references/work-items.md) - Work item API, field schemas, WIQL patterns, linking, comments
- [references/repositories.md](references/repositories.md) - Repository/branch ops, PR lifecycle, comments, commit tracking
- [references/work-operations.md](references/work-operations.md) - Iteration management, team capacity planning
- [references/core-operations.md](references/core-operations.md) - Project/team operations, identity resolution

## Work Item & PR Templates

Pre-configured templates in `assets/`:
- `work-item-templates/` - task.json, bug.json, user-story.json
- `pr-templates/` - feature-pr.md, bugfix-pr.md

Use with helper's `create_work_item()` method.

## Best Practices

- **Authentication:** Store PAT in `.env`, never commit to version control
- **Work Items:** Use WIQL for efficient filtering, batch operations for bulk updates
- **Pull Requests:** Use descriptive titles, link work items, leverage comment threads
- **Error Handling:** Library raises exceptions for API errors - use try/except blocks
- **Pagination:** Helper class handles continuation tokens automatically
- **API Version:** Library uses API version 7.1 by default

## Resources

- **Official Library:** https://github.com/microsoft/azure-devops-python-api
- **REST API Docs:** https://learn.microsoft.com/en-us/rest/api/azure/devops/
- **Code Samples:** https://github.com/microsoft/azure-devops-python-samples
