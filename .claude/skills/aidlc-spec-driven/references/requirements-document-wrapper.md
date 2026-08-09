# Requirements Document Wrapper

Use this wrapper only for `aidlc-spec-driven` Phase 1 `requirements.md` files. Insert the selected shared story block at `{{USER_STORY_BLOCK}}`.

```markdown
# Requirements: {{SPEC_NAME}}

**Unit**: {Unit Number - Feature Name}
**Feature**: {Short feature description}
**Created**: {{CREATED_DATE}}
**User Stories**: US-1
**Estimation (BCP)**: Not yet estimated

---

## Introduction

[2-3 sentences: feature purpose and business value]

## Requirements

{{USER_STORY_BLOCK}}

---

## Next Steps

Once these requirements are approved, proceed to Phase 2: Design Document Creation.

**What to do next:**
1. Use the slash command: `/aidlc.construction.create-design`
2. The agent will automatically read `references/phase-2-design.md` for detailed workflow instructions
3. Foundation docs will be referenced for architecture alignment

This will create `design.md` with comprehensive design based on these requirements.
```
