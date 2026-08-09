# Work Items Reference

Quick reference for Azure DevOps Work Items operations using the official `azure-devops` Python library and REST API patterns.

Prefer the helper methods (`helper.get_work_item`, `helper.create_work_item`, `helper.update_work_item`, `helper.query_work_items`, `helper.get_child_work_items`, `helper.link_work_items`, `helper.add_comment`, `helper.delete_work_item`, etc.) for everyday work — see [../SKILL.md](../SKILL.md). Drop to the raw library/REST patterns below only for operations the helper does not expose.

## Table of Contents

- [Python Library Quick Reference](#python-library-quick-reference)
- [Work Item Types (Project-Specific)](#work-item-types-project-specific)
- [Common Operations](#common-operations)
- [Common Fields](#common-fields)
- [WIQL Examples](#wiql-examples)
- [Links and Relations](#links-and-relations)
- [Get Child Work Items](#get-child-work-items)
- [Error Handling](#error-handling)

## Python Library Quick Reference

```python
from azure.devops.connection import Connection
from msrest.authentication import BasicAuthentication
from azure.devops.v7_1.work_item_tracking.models import JsonPatchOperation, Wiql

# Get work item tracking client
credentials = BasicAuthentication('', pat)
connection = Connection(base_url=org_url, creds=credentials)
wit_client = connection.clients.get_work_item_tracking_client()

# Get work item
work_item = wit_client.get_work_item(id=12345)
print(work_item.fields['System.Title'])

# Create work item
document = [
    JsonPatchOperation(op="add", path="/fields/System.Title", value="New task"),
    JsonPatchOperation(op="add", path="/fields/System.Description", value="Details")
]
new_item = wit_client.create_work_item(document=document, project="My Project", type="Task")

# Update work item
update_doc = [
    JsonPatchOperation(op="replace", path="/fields/System.State", value="Active")
]
wit_client.update_work_item(document=update_doc, id=12345)

# Query with WIQL
wiql = Wiql(query="SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'")
result = wit_client.query_by_wiql(wiql=wiql, project="My Project")
work_items = wit_client.get_work_items(ids=[item.id for item in result.work_items])
```

## Work Item Types (Project-Specific)

Types vary by project. Common: Task, Bug, User Story, Product Backlog Item, Action Item, Feature, Epic.

**Always discover types first:**
```python
items = api.get_sprint_items(iteration_path)
types = set([item['fields']['System.WorkItemType'] for item in items])
```

## Common Operations

### Query Work Items (WIQL)
```
POST {org}/_apis/wit/wiql?api-version=7.1
Body: {"query": "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'"}
```

### Get Work Item
```
GET {org}/_apis/wit/workitems/{id}?api-version=7.1
```

### Create Work Item
```
POST {org}/{project}/_apis/wit/workitems/${type}?api-version=7.1
Content-Type: application/json-patch+json
Body: [{"op":"add","path":"/fields/System.Title","value":"Title"}]
```

### Update Work Item
```
PATCH {org}/_apis/wit/workitems/{id}?api-version=7.1
Content-Type: application/json-patch+json
Body: [{"op":"replace","path":"/fields/System.State","value":"Active"}]
```

### Batch Get Work Items
```
POST {org}/_apis/wit/workitemsbatch?api-version=7.1
Body: {"ids": [1,2,3], "fields": ["System.Id","System.Title"]}
```

## Common Fields

- `System.Id` - Work item ID
- `System.WorkItemType` - Type (Task, Bug, etc.)
- `System.Title` - Title
- `System.State` - State (New, Active, Closed, etc.)
- `System.AssignedTo` - Assigned user
- `System.Description` - Description (HTML)
- `System.IterationPath` - Sprint/iteration
- `System.AreaPath` - Area path
- `System.Tags` - Tags (semicolon-separated)
- `Microsoft.VSTS.Scheduling.StoryPoints` - Story points
- `Microsoft.VSTS.Common.Priority` - Priority

## WIQL Examples

```sql
-- Items in current sprint
SELECT [System.Id], [System.Title], [System.State]
FROM WorkItems
WHERE [System.IterationPath] = 'Project\\Sprint 1'
  AND [System.WorkItemType] = 'Task'
ORDER BY [System.State]

-- Active items assigned to me
SELECT [System.Id] FROM WorkItems
WHERE [System.State] = 'Active'
  AND [System.AssignedTo] = @Me

-- Items changed this week
SELECT [System.Id] FROM WorkItems
WHERE [System.ChangedDate] >= @Today - 7
```

## Links and Relations

**Link Types:**
- `System.LinkTypes.Hierarchy-Forward` - Parent/Child
- `System.LinkTypes.Related` - Related items
- `System.LinkTypes.Dependency-Forward` - Predecessor/Successor

**Add Link:**
```
PATCH {org}/_apis/wit/workitems/{id}?api-version=7.1
Body: [{
  "op": "add",
  "path": "/relations/-",
  "value": {
    "rel": "System.LinkTypes.Hierarchy-Forward",
    "url": "{work-item-url}"
  }
}]
```

## Get Child Work Items

Use `get_child_work_items()` to retrieve all children of a parent work item with optional type filtering.

**Using AzureDevOpsHelper (recommended):**
```python
from scripts.ado_helper import AzureDevOpsHelper

helper = AzureDevOpsHelper()

# Get all children of a Feature (ID: 7728)
children = helper.get_child_work_items(7728)
for child in children:
    print(f"#{child.id}: [{child.fields['System.WorkItemType']}] {child.fields['System.Title']}")

# Get only Product Backlog Item children
pbis = helper.get_child_work_items(7728, work_item_type="Product Backlog Item")

# Get only Task children
tasks = helper.get_child_work_items(12345, work_item_type="Task")

# Get only Bug children
bugs = helper.get_child_work_items(12345, work_item_type="Bug")
```

**CLI usage:**
```bash
# Get all children of work item 7728
python3 scripts/ado_helper.py children 7728

# Get only Task children
python3 scripts/ado_helper.py children 7728 Task

# Get only Bug children
python3 scripts/ado_helper.py children 12345 Bug
```

**Using WorkItemOperations directly:**
```python
from scripts.ado_client import AzureDevOpsClient
from scripts.ado_work_items import WorkItemOperations

client = AzureDevOpsClient()
work_item_ops = WorkItemOperations(client)

# Get all children of a User Story (ID: 12345)
children = work_item_ops.get_child_work_items(12345)
```

**WIQL for hierarchical queries:**
```sql
SELECT [System.Id]
FROM WorkItemLinks
WHERE [Source].[System.Id] = {parent_id}
AND [System.Links.LinkType] = 'System.LinkTypes.Hierarchy-Forward'
MODE (MustContain)
```

## Error Handling

- **400**: Invalid JSON Patch, missing required field
- **404**: Work item doesn't exist
- **409**: Revision conflict (work item modified)

**PAT Scopes:** `vso.work` (Read), `vso.work_write` (Write)
