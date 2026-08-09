# Test case types

Use the selected type to shape scenario content. Keep all types business-first.

## functional

Use for planned QA validation based on Agile Testing Quadrants Q2: business-facing tests that support the team.

Focus on:
- user journeys and acceptance criteria
- business rules and role behavior
- data outcomes visible to users or operations
- negative paths and recoverable errors
- cross-module business flows when they affect the user outcome

Avoid deep implementation details. Mention technical boundaries only when they affect setup, data, dependency behavior, or an observable result.

## uat

Use for PO, business, or stakeholder sign-off.

Focus on:
- real business workflow fit
- business rule approval
- role/persona expectations
- end-user wording and visible outcomes
- sign-off blockers and open decisions

Avoid internal technical assertions and automation planning unless the business explicitly needs them.

## regression

Use for release confidence after change.

Focus on:
- critical existing business flows
- impacted capabilities and adjacent workflows
- previous defects or high-risk behavior
- smoke checks that block release
- business data integrity after change

Prefer fewer high-value cases over broad low-signal coverage.
