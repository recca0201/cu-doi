# Work Operations Reference

Work operations handle sprint planning, iterations, and team capacity management.

> **Helper coverage:** The `ado_helper.py` helper exposes only the **read** side
> of sprints — `get_current_sprint`, `get_sprint_items`, `get_current_sprint_user_stories`,
> and the AIDLC bolt methods. The iteration **management** and **capacity** operations
> below (create/assign iterations, get/update capacity) are **not implemented in the
> helper** — use the raw library/REST patterns shown here directly. Don't look for a
> `helper.update_team_capacity()`; it doesn't exist yet.

## Table of Contents

- [Operations](#operations)
- [Common Workflows](#common-workflows)
- [Capacity Calculation](#capacity-calculation)
- [Best Practices](#best-practices)
- [Error Handling](#error-handling)
- [Authentication](#authentication)
- [Date Format Notes](#date-format-notes)

## Operations

### work_list_team_iterations

**Purpose:** Retrieve all iterations (sprints) for a specific team.

**Required Parameters:**
- `project` (string) - Project ID or name
- `team` (string) - Team ID or name

**Optional Parameters:**
- `$timeframe` (string) - Filter by timeframe (current, past, future)

**Response Format:**
```json
{
  "value": [
    {
      "id": "iteration-guid",
      "name": "Sprint 1",
      "path": "\\ProjectName\\Sprint 1",
      "attributes": {
        "startDate": "2025-01-01T00:00:00Z",
        "finishDate": "2025-01-14T00:00:00Z",
        "timeFrame": "current"
      },
      "url": "https://dev.azure.com/{org}/{project}/{team}/_apis/work/teamsettings/iterations/{id}"
    }
  ]
}
```

**Common Use Cases:**
- Finding current sprint for capacity planning
- Listing all sprints for a team
- Getting iteration IDs for work item queries

**API Endpoint:** `GET https://dev.azure.com/{organization}/{project}/{team}/_apis/work/teamsettings/iterations?api-version=7.1`

---

### work_create_iterations

**Purpose:** Create new sprint iterations in a project.

**Required Parameters:**
- `project` (string) - Project ID or name
- `name` (string) - Iteration name
- `startDate` (string) - ISO 8601 date format
- `finishDate` (string) - ISO 8601 date format

**Optional Parameters:**
- `path` (string) - Iteration path (defaults to project root)

**Request Body:**
```json
{
  "name": "Sprint 5",
  "attributes": {
    "startDate": "2025-03-01T00:00:00Z",
    "finishDate": "2025-03-14T00:00:00Z"
  }
}
```

**Response Format:**
```json
{
  "id": "iteration-guid",
  "name": "Sprint 5",
  "path": "\\ProjectName\\Sprint 5",
  "attributes": {
    "startDate": "2025-03-01T00:00:00Z",
    "finishDate": "2025-03-14T00:00:00Z"
  },
  "url": "..."
}
```

**Common Use Cases:**
- Setting up sprint schedule for upcoming quarter
- Creating iteration hierarchy
- Batch creating sprints for the year

**API Endpoint:** `POST https://dev.azure.com/{organization}/{project}/_apis/wit/classificationnodes/iterations?api-version=7.1`

---

### work_assign_iterations

**Purpose:** Assign existing iterations to a specific team.

**Required Parameters:**
- `project` (string) - Project ID or name
- `team` (string) - Team ID or name
- `iterationId` (string) - ID of iteration to assign

**Request Body:**
```json
{
  "id": "iteration-guid"
}
```

**Response Format:**
```json
{
  "id": "iteration-guid",
  "name": "Sprint 5",
  "path": "\\ProjectName\\Sprint 5",
  "attributes": {
    "startDate": "2025-03-01T00:00:00Z",
    "finishDate": "2025-03-14T00:00:00Z",
    "timeFrame": "future"
  }
}
```

**Common Use Cases:**
- Configuring team sprints after creating iterations
- Managing team-specific sprint assignments
- Setting up new teams with existing iteration schedule

**API Endpoint:** `POST https://dev.azure.com/{organization}/{project}/{team}/_apis/work/teamsettings/iterations?api-version=7.1`

---

### work_get_team_capacity

**Purpose:** Retrieve team capacity for a specific iteration.

**Required Parameters:**
- `project` (string) - Project ID or name
- `team` (string) - Team ID or name
- `iterationId` (string) - Iteration ID

**Response Format:**
```json
{
  "value": [
    {
      "teamMember": {
        "id": "member-guid",
        "displayName": "John Doe",
        "uniqueName": "john.doe@company.com",
        "url": "...",
        "imageUrl": "..."
      },
      "activities": [
        {
          "capacityPerDay": 6.0,
          "name": "Development"
        }
      ],
      "daysOff": [
        {
          "start": "2025-01-15T00:00:00Z",
          "end": "2025-01-15T00:00:00Z"
        }
      ],
      "url": "..."
    }
  ]
}
```

**Common Use Cases:**
- Reviewing team capacity at sprint start
- Checking individual capacity settings
- Calculating available team hours

**API Endpoint:** `GET https://dev.azure.com/{organization}/{project}/{team}/_apis/work/teamsettings/iterations/{iterationId}/capacities?api-version=7.1`

---

### work_update_team_capacity

**Purpose:** Update capacity settings for a team member in a specific iteration.

**Required Parameters:**
- `project` (string) - Project ID or name
- `team` (string) - Team ID or name
- `iterationId` (string) - Iteration ID
- `teamMemberId` (string) - Team member identity ID

**Optional Parameters:**
- `activities` (array) - Activity name and capacity per day
- `daysOff` (array) - Date ranges for time off

**Request Body:**
```json
{
  "activities": [
    {
      "capacityPerDay": 6.0,
      "name": "Development"
    },
    {
      "capacityPerDay": 2.0,
      "name": "Testing"
    }
  ],
  "daysOff": [
    {
      "start": "2025-01-20T00:00:00Z",
      "end": "2025-01-21T00:00:00Z"
    }
  ]
}
```

**Response Format:** Updated capacity object

**Common Use Cases:**
- Setting individual capacity at sprint planning
- Updating capacity when team members have PTO
- Adjusting capacity based on other commitments

**API Endpoint:** `PATCH https://dev.azure.com/{organization}/{project}/{team}/_apis/work/teamsettings/iterations/{iterationId}/capacities/{teamMemberId}?api-version=7.1`

---

### work_get_iteration_capacities

**Purpose:** Get capacity for all teams in a specific iteration.

**Required Parameters:**
- `project` (string) - Project ID or name
- `iterationId` (string) - Iteration ID

**Response Format:** Array of team capacity objects

**Common Use Cases:**
- Cross-team capacity planning
- Organization-level sprint capacity reporting
- Identifying capacity gaps across teams

**API Endpoint:** `GET https://dev.azure.com/{organization}/{project}/_apis/work/iterations/{iterationId}/capacities?api-version=7.1`

---

## Common Workflows

### Sprint Setup Workflow
```
1. work_create_iterations
   → Create sprints for the quarter

2. work_assign_iterations
   → Assign sprints to each team

3. core_get_identity_ids
   → Get identity IDs for team members

4. work_update_team_capacity
   → Set capacity for each team member

5. work_get_team_capacity
   → Verify capacity settings
```

### Capacity Planning Workflow
```
1. work_list_team_iterations($timeframe: "current")
   → Get current sprint

2. work_get_team_capacity
   → Review current capacity

3. work_update_team_capacity
   → Adjust for PTO or changed availability

4. Calculate available hours vs committed work
```

---

## Capacity Calculation

**Formula:**
```
Available Hours =
  (Work Days in Sprint - Days Off) ×
  Sum(Capacity Per Day for all Activities)
```

**Example:**
- Sprint: 10 work days
- Days Off: 1 day
- Activities: Development (6h/day) + Testing (2h/day)
- Available Hours = (10 - 1) × (6 + 2) = 72 hours

---

## Best Practices

1. **Set Capacity Early:** Update capacity at sprint planning, not mid-sprint
2. **Account for Non-Work Activities:** Include meetings, admin time in capacity calculation
3. **Track Days Off:** Always record PTO and holidays in capacity
4. **Use Activity Breakdown:** Separate capacity by activity type for better planning
5. **Standard Capacity:** Establish team norms (e.g., 6h/day for development)
6. **Batch Updates:** When possible, update capacity for all team members together
7. **Iteration Naming:** Use consistent naming (e.g., "Sprint 1", "Sprint 2" or "2025.1", "2025.2")

---

## Error Handling

**Common Errors:**

**400 Bad Request:**
- Invalid date format (must be ISO 8601)
- End date before start date
- Invalid capacity values (negative or excessive)

**404 Not Found:**
- Iteration doesn't exist
- Team member not found in team
- Solution: Verify iteration/team member IDs

**409 Conflict:**
- Iteration dates overlap with existing iteration
- Duplicate iteration name
- Solution: Check existing iterations and adjust dates/names

---

## Authentication

**Required PAT Scopes:**
- `vso.work` (Read) - For reading iterations and capacity
- `vso.work_write` (Write) - For creating/updating iterations and capacity

---

## Date Format Notes

All dates must be in **ISO 8601 format**:
- Format: `YYYY-MM-DDTHH:mm:ssZ`
- Example: `2025-03-01T00:00:00Z`
- Timezone: Use UTC (Z suffix) for consistency

**Common Date Operations:**
```python
from datetime import datetime

# Create ISO 8601 date
start_date = datetime(2025, 3, 1).isoformat() + 'Z'
# Result: '2025-03-01T00:00:00Z'

# Parse ISO 8601 date
parsed = datetime.fromisoformat('2025-03-01T00:00:00Z'.replace('Z', '+00:00'))
```
