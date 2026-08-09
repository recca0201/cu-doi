# Repositories & Pull Requests Reference

Quick reference for Azure DevOps Git operations using the official `azure-devops` Python library and REST API patterns.

Prefer the helper methods (`helper.get_repositories`, `helper.get_repository`, `helper.get_pull_requests`, `helper.create_pull_request`) for everyday work — see [../SKILL.md](../SKILL.md). Drop to the raw library/REST patterns below only for operations the helper does not expose.

## Table of Contents

- [Python Library Quick Reference](#python-library-quick-reference)
- [Repositories](#repositories)
- [Branches](#branches)
- [Pull Requests](#pull-requests)
- [PR Comments](#pr-comments)
- [Commits](#commits)
- [Common Workflows](#common-workflows)
- [Error Handling](#error-handling)

## Python Library Quick Reference

```python
from azure.devops.connection import Connection
from msrest.authentication import BasicAuthentication
from azure.devops.v7_1.git.models import GitPullRequest, GitPullRequestSearchCriteria

# Get git client
credentials = BasicAuthentication('', pat)
connection = Connection(base_url=org_url, creds=credentials)
git_client = connection.clients.get_git_client()

# List repositories
repos = git_client.get_repositories(project="My Project")
for repo in repos:
    print(f"{repo.name}: {repo.web_url}")

# Get pull requests
search = GitPullRequestSearchCriteria(status="active")
prs = git_client.get_pull_requests(
    repository_id="my-repo",
    search_criteria=search,
    project="My Project"
)

# Create pull request
pr = GitPullRequest()
pr.source_ref_name = "refs/heads/feature/new-feature"
pr.target_ref_name = "refs/heads/main"
pr.title = "Add new feature"
pr.description = "PR description"
new_pr = git_client.create_pull_request(
    git_pull_request_to_create=pr,
    repository_id="my-repo",
    project="My Project"
)
```

## Repositories

### List Repositories
```
GET {org}/{project}/_apis/git/repositories?api-version=7.1
```

### Get Repository
```
GET {org}/{project}/_apis/git/repositories/{repo}?api-version=7.1
```

## Branches

### List Branches
```
GET {org}/{project}/_apis/git/repositories/{repo}/refs?filter=heads/&api-version=7.1
```

### Create Branch
```
POST {org}/{project}/_apis/git/repositories/{repo}/refs?api-version=7.1
Body: [{
  "name": "refs/heads/feature/new-branch",
  "oldObjectId": "0000000000000000000000000000000000000000",
  "newObjectId": "{commit-sha}"
}]
```

## Pull Requests

### List Pull Requests
```
GET {org}/{project}/_apis/git/repositories/{repo}/pullrequests?api-version=7.1
Parameters:
  - searchCriteria.status: active|completed|abandoned|all
  - searchCriteria.creatorId: {user-id}
  - searchCriteria.reviewerId: {user-id}
```

### Get Pull Request
```
GET {org}/{project}/_apis/git/repositories/{repo}/pullrequests/{prId}?api-version=7.1
```

### Create Pull Request
```
POST {org}/{project}/_apis/git/repositories/{repo}/pullrequests?api-version=7.1
Body: {
  "sourceRefName": "refs/heads/feature/branch",
  "targetRefName": "refs/heads/main",
  "title": "PR Title",
  "description": "Description"
}
```

### Update Pull Request
```
PATCH {org}/{project}/_apis/git/repositories/{repo}/pullrequests/{prId}?api-version=7.1
Body: {
  "status": "completed|abandoned",
  "title": "New Title",
  "description": "New Description"
}
```

### Add Reviewers
```
PUT {org}/{project}/_apis/git/repositories/{repo}/pullrequests/{prId}/reviewers/{userId}?api-version=7.1
Body: {
  "vote": 0,  // 0=No vote, 10=Approved, 5=Approved with suggestions, -10=Rejected
  "isRequired": false
}
```

## PR Comments

### List PR Threads
```
GET {org}/{project}/_apis/git/repositories/{repo}/pullrequests/{prId}/threads?api-version=7.1
```

### Create Comment Thread
```
POST {org}/{project}/_apis/git/repositories/{repo}/pullrequests/{prId}/threads?api-version=7.1
Body: {
  "comments": [{"content": "Comment text"}],
  "status": "active"
}
```

### Reply to Comment
```
POST {org}/{project}/_apis/git/repositories/{repo}/pullrequests/{prId}/threads/{threadId}/comments?api-version=7.1
Body: {"content": "Reply text"}
```

## Commits

### Search Commits
```
GET {org}/{project}/_apis/git/repositories/{repo}/commits?api-version=7.1
Parameters:
  - searchCriteria.fromDate: 2024-01-01T00:00:00Z
  - searchCriteria.toDate: 2024-12-31T23:59:59Z
  - searchCriteria.author: name
  - $top: 100
  - $skip: 0
```

## Common Workflows

**Create PR:**
1. Create feature branch
2. Make commits locally
3. Push branch
4. Create PR via API
5. Add reviewers
6. Link work items

**PR Review:**
1. Get PR details
2. Review code changes
3. Add comment threads
4. Vote (approve/reject)
5. Resolve comments
6. Complete or abandon PR

## Error Handling

- **400**: Invalid branch names, missing required fields
- **404**: Repository or PR doesn't exist
- **409**: Branch already exists, PR conflict

**PAT Scopes:** `vso.code` (Read), `vso.code_write` (Write)
