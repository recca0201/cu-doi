# Story Artifact Wrapper

Use this wrapper only for `aidlc-requirements-engineering` standalone story artifacts in `aidlc-docs/story-artifacts/`. Insert the selected shared story block at `{{USER_STORY_BLOCK}}`.

Frontmatter reference block (the scaffold script emits this automatically — `intent` from the feature slug, `source_artifacts` from `--source` arguments, `[]` when none):

```yaml
---
artifact_type: story-artifact
phase: inception
status: draft
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
intent: {feature-slug}
source_artifacts: []
---
```

If a source document surfaces after scaffolding, append it to `source_artifacts` when editing the artifact; never remove the key.

```markdown
# User Stories: {{FEATURE_NAME}}

## Overview

[1-3 sentences describing the feature goal, target user, and business value.]

## User stories

{{USER_STORY_BLOCK}}

## Dependency Notes

- [Only include when sequencing matters.]
```
