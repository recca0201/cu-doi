# Given/When/Then Table User Story Block

Use this story block for QA-oriented specs, manual test scenarios, UI flows, and teams that prefer BDD-style acceptance criteria in a table.

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

**Feature 1: {Feature name}**

| No. | Scenario | Given | When | Then |
|---|---|---|---|---|
| 1.1 | {Scenario name} | {precondition or starting state} | {action or trigger} | {expected result} |
| 1.2 | {Alternate scenario name} | {alternate precondition} | {action or trigger} | {expected result} |
| 1.3 | {Negative scenario name} | {error or edge precondition} | {action or trigger} | {validation, prevention, or recovery result} |

**Feature 2: {Another feature name}**

| No. | Scenario | Given | When | Then |
|---|---|---|---|---|
| 2.1 | {Scenario name} | {precondition or starting state} | {action or trigger} | {expected result} |
```

## Numbering Convention

- Use numbered feature headings such as `Feature 1`.
- Use the feature ID as the first part of each table row ID: Feature 1 rows use `1.1`, `1.2`; Feature 2 rows use `2.1`, `2.2`.

## Rules

1. Group acceptance criteria by numbered feature headings such as `**Feature 1: {Feature name}**` before each table.
2. Use the `No.`, `Scenario`, `Given`, `When`, and `Then` columns exactly.
3. Use the feature ID as the first part of each row number: Feature 1 rows use `1.1`, `1.2`; Feature 2 rows use `2.1`, `2.2`.
4. Write short scenario names such as `Suggestion Logic`, `Page URL`, `POD filter renders empty on page load`, or `Invalid Search`.
5. Use business-readable Given, When, and Then cells; do not force the words `Given`, `When`, and `Then` inside every cell unless the team wants that style.
6. Use `<br><br>` inside cells for multiple preconditions or multiple expected results.
7. Include normal path, alternate path, and negative path rows when relevant.
8. Keep table text concise enough for Markdown and Confluence-style rendering.
9. Use concrete page, field, button, icon, status, and message names when known.
10. Preserve stable row IDs during revisions because design and tasks cite them, for example `per AC-2.3`.
11. Use `Dependencies: None` when the story is independently deliverable; otherwise name the story IDs, external prerequisites, integrations, approvals, or prior artifacts that must exist first.
