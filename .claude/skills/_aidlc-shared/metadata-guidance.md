# AIDLC artifact metadata v1 guidance

Use this block as the first bytes of every new Markdown artifact.

## Required keys

- `artifact_type`: Allowed values: `requirements`, `design`, `tasks`, `story-artifact`, `quick-spec`, `unit-decomposition`, `roadmap`, `test-cases`, `decision-record`, `memory`
- `phase`: Allowed values: `foundation`, `inception`, `construction`, `operations`
- `status`: Allowed values: `draft`, `review`, `approved`, `implemented`, `archived`
- `created`: ISO date `YYYY-MM-DD`
- `updated`: ISO date `YYYY-MM-DD`

## Canonical field order

1. `artifact_type`
2. `phase`
3. `status`
4. `created`
5. `updated`
6. `intent`
7. `unit`
8. `lifecycle`
9. `artifact_id`
10. `source_artifacts`
11. `related_artifacts`

## Optional field rules

- Omit optional scalar keys (`intent`, `unit`, `lifecycle`, `artifact_id`) when unknown, empty, or whitespace-only.
- Emit `source_artifacts: []` when no non-empty source paths are available after normalization.
- Omit optional list keys such as `related_artifacts` when no non-empty values exist.
- Keep list paths workspace-relative and POSIX style when possible.

## Fill-in template

```yaml
---
artifact_type: {artifact_type}
phase: {phase}
status: draft
created: {yyyy-mm-dd}
updated: {yyyy-mm-dd}
source_artifacts: []
# intent: {intent-slug}
# unit: {unit-slug}
# lifecycle: {lifecycle-name}
# artifact_id: {stable-id}
# related_artifacts:
#   - DR-0001
---
```