# Checklist User Story Block

Use this story block when stakeholders need checkable acceptance criteria grouped by category while preserving stable IDs.

## Template Structure

```markdown
### US-{ID}: {User Story Title}
**User Story**: As a {persona}, I want {capability}, so that {benefit}

**Related ADO** (optional, sync only): #14920
**Related Jira** (optional, sync only): ABC-123

**Priority**: High | Medium | Low
**Business Value** (optional): {why this story matters now}
**Dependencies**: None | {story IDs, external prerequisites, integrations, approvals, or prior artifacts}

**Acceptance Criteria**

Simple story:
- [ ] **1** {Single acceptance criterion}.
- [ ] **2** {Single acceptance criterion}.

Default grouped story:
### 1. {Category / Main Flow}
- [ ] **1.1** {Actor/user type} can {complete action} when {condition}.
- [ ] **1.2** System displays or returns {expected result} after {trigger}.

### 2. {Category / Validation & Edge Cases}
- [ ] **2.1** System validates {input/state/rule} before {action/submission}.
- [ ] **2.2** System rejects {invalid input/state} and shows {message/result}.

Complex grouped story:
### 1. {Category / Example: Access & Main Flow}
#### 1.1 {Scenario Name / Example: Open Feature}
- [ ] **1.1.1** {Actor/User type} can access {feature/module/page} when {condition}.
- [ ] **1.1.2** {System/Application} displays or returns {expected result/output}.

#### 1.2 {Scenario Name / Example: Complete Workflow}
- [ ] **1.2.1** {Actor/User type} can complete {workflow/action} successfully.
```

## Rules

1. Use the shallowest trace ID depth that keeps the criteria clear:
   - `1`, `2`, `3` for very small stories with no useful grouping.
   - `1.1`, `1.2`, `2.1` by default when category grouping is useful.
   - `1.1.1`, `1.1.2` only when scenario subheadings reduce repetition.
2. Keep user story metadata outside checklist items.
3. Include only categories relevant to the story; add UI, NFR, or integration categories only when useful.
4. Group related checklist items under scenario headings only when several criteria share the same context.
5. Restart numbering for each story and keep IDs stable during revisions because design and tasks cite them, for example `per AC-2.3`.
6. Keep each checklist item independently testable and include validation, error, empty, permission, or recovery criteria when relevant.
7. Use `Dependencies: None` when the story is independently deliverable; otherwise name the story IDs, external prerequisites, integrations, approvals, or prior artifacts that must exist first.
