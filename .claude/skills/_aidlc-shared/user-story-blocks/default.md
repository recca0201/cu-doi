# Default User Story Block

Use this story block when acceptance criteria need hierarchical EARS-Lite wording and downstream traceability.

## Template Structure

```markdown
### US-{ID}: {User Story Title}
**User Story**: As a {persona}, I want {capability}, so that {benefit}

**Related ADO** (optional, sync only): #14920
**Related Jira** (optional, sync only): ABC-123

**Priority**: High | Medium | Low
**Business Value** (optional): {why this story matters now}
**Dependencies**: None | {story IDs, external prerequisites, integrations, approvals, or prior artifacts}

**Acceptance Criteria**:

**1. [Section Name]**

1.1 WHEN [context/trigger] THEN system SHALL [requirement]

1.2 WHEN [context/trigger] THEN system SHALL:
- [requirement 1]
- [requirement 2]
- [requirement 3]

1.3 IF [condition] THEN system SHALL:
- [variant behavior 1]
- [variant behavior 2]
```

## Numbering Convention

- **User Story**: 1, 2, 3...
- **Section**: 1, 2, 3... (logical grouping within story)
- **Criterion**: 1.1, 1.2, 1.3... (individual testable requirement)

Example: **2.3** = Section 2, Criterion 3.

## Rules

1. Use `WHEN`, `IF`, or `WHILE` to anchor every criterion to a concrete context.
2. Use `THEN system SHALL` for mandatory behavior.
3. Keep each numbered criterion independently testable.
4. Use bullet lists for multiple SHALL requirements.
5. Write bullets as short, verb-first requirements.
6. Preserve stable criterion IDs during revisions because design and tasks cite them, for example `per AC-2.3`.
7. Use concrete metrics where relevant, such as `<=768px`, `<0.1 CLS`, or `44x44px`.
8. Cover variants with `IF` conditions for errors and edge cases.
9. Use `Dependencies: None` when the story is independently deliverable; otherwise name the story IDs, external prerequisites, integrations, approvals, or prior artifacts that must exist first.

## EARS Keywords

- **WHEN** - Event or trigger that initiates behavior
- **IF** - Conditional variant or alternative path
- **WHILE** - State-driven continuous behavior
- **THEN** - Expected response to condition
- **SHALL** - Mandatory requirement, implied in bullets under a SHALL criterion

## Best Practices

1. **Logical sections** - Group related criteria (1.1 = Hero, 1.2 = Workflow, 1.3 = Navigation)
2. **Atomic criteria** - Each numbered item = one testable rule
3. **Bullet for multiple SHALL** - Clean list when criterion has multiple requirements
4. **Specific metrics** - Use concrete values (<=768px, <0.1 CLS, 44x44px)
5. **Cover variants** - Include IF conditions for errors and edge cases
