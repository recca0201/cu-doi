# Core Operations Reference

Core operations handle organization-level entities like projects, teams, and identities.

## Table of Contents

- [Operations](#operations)
  - [core_list_projects](#core_list_projects)
  - [core_list_project_teams](#core_list_project_teams)
  - [core_get_identity_ids](#core_get_identity_ids)
- [Common Patterns](#common-patterns)
  - [Project Discovery Flow](#project-discovery-flow)
  - [Identity Resolution Flow](#identity-resolution-flow)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Authentication](#authentication)

## Operations

### core_list_projects

**Purpose:** Retrieve all projects in the Azure DevOps organization.

**Parameters:** None required

**Response Format:**
```json
{
  "value": [
    {
      "id": "project-guid",
      "name": "Project Name",
      "description": "Project description",
      "url": "https://dev.azure.com/{org}/_apis/projects/{id}",
      "state": "wellFormed",
      "revision": 123,
      "visibility": "private"
    }
  ]
}
```

**Common Use Cases:**
- Initial discovery of available projects
- Validating project existence before operations
- Listing all projects for reporting

**API Endpoint:** `GET https://dev.azure.com/{organization}/_apis/projects?api-version=7.1`

---

### core_list_project_teams

**Purpose:** Get all teams within a specific project.

**Required Parameters:**
- `project` (string) - Project ID or name

**Optional Parameters:**
- `$mine` (boolean) - Return only teams the user is a member of
- `$top` (integer) - Maximum number of teams to return
- `$skip` (integer) - Number of teams to skip

**Response Format:**
```json
{
  "value": [
    {
      "id": "team-guid",
      "name": "Team Name",
      "url": "https://dev.azure.com/{org}/_apis/projects/{project}/teams/{id}",
      "description": "Team description",
      "identityUrl": "https://spsprodcus3.vssps.visualstudio.com/{id}/_apis/Identities/{id}",
      "projectName": "Project Name",
      "projectId": "project-guid"
    }
  ]
}
```

**Common Use Cases:**
- Finding team IDs for capacity planning
- Discovering team structure within a project
- Filtering teams for specific operations

**API Endpoint:** `GET https://dev.azure.com/{organization}/_apis/projects/{projectId}/teams?api-version=7.1`

---

### core_get_identity_ids

**Purpose:** Convert unique names (email addresses, display names) to Azure DevOps identity IDs.

**Required Parameters:**
- `uniqueNames` (array of strings) - List of unique identifiers to resolve

**Response Format:**
```json
{
  "value": [
    {
      "id": "identity-guid",
      "displayName": "John Doe",
      "uniqueName": "john.doe@company.com",
      "imageUrl": "https://...",
      "descriptor": "aad.identity-descriptor"
    }
  ]
}
```

**Common Use Cases:**
- Getting identity IDs for work item assignment
- Resolving user identities for capacity updates
- Mapping email addresses to Azure DevOps accounts

**API Endpoint:** `POST https://vssps.dev.azure.com/{organization}/_apis/identities?api-version=7.1`

**Request Body:**
```json
{
  "searchFilter": "General",
  "filterValue": "email@company.com"
}
```

---

## Common Patterns

### Project Discovery Flow
```
1. core_list_projects
   → Get all available projects
2. core_list_project_teams(projectId)
   → Find teams within target project
3. Use project/team IDs for downstream operations
```

### Identity Resolution Flow
```
1. Collect unique names (emails, display names)
2. core_get_identity_ids(uniqueNames)
   → Get Azure DevOps identity IDs
3. Use identity IDs for assignment or capacity operations
```

---

## Error Handling

**Common Errors:**

**401 Unauthorized:**
- PAT token expired or invalid
- Insufficient permissions
- Solution: Regenerate PAT with appropriate scopes

**404 Not Found:**
- Project or team doesn't exist
- Incorrect project/team name or ID
- Solution: Verify project/team existence with list operations

**403 Forbidden:**
- User lacks permissions for the operation
- Project visibility restrictions
- Solution: Check user permissions and project access

---

## Best Practices

1. **Cache Project/Team IDs:** Avoid repeated calls by caching IDs locally
2. **Use IDs over Names:** IDs are stable; names can change
3. **Filter Teams Early:** Use `$mine` parameter to reduce unnecessary data
4. **Validate Before Operations:** Always verify project/team existence before complex operations
5. **Handle Missing Identities:** Not all unique names may resolve; handle partial results gracefully

---

## Authentication

All core operations require authentication via Personal Access Token (PAT):

**Required PAT Scopes:**
- `vso.project` (Read) - For listing projects
- `vso.identity` (Read) - For identity resolution

**Header Format:**
```
Authorization: Basic {base64(:{PAT})}
```

**Example:**
```bash
# Generate base64 encoded PAT
echo -n ":your-pat-token" | base64

# Use in API call
curl -H "Authorization: Basic <base64-pat>" \
  https://dev.azure.com/{org}/_apis/projects?api-version=7.1
```
