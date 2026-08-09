---
description: Generate specs folder structure from units decomposition for bolt execution
argument-hint: [units]
---

# /aidlc.construction.plan-bolts

**Purpose**: Generate specs folder structure from units decomposition with mapped user stories for bolt execution

**Agent**: ai-assistant-product-owner
**Skill**: aidlc-bolt-planning

## Input

<units>$ARGUMENTS</units>

The argument list must include the unit decomposition source path. Preserve that
path in the handoff to `aidlc-bolt-planning`. When the matching user-story
artifact paths are known from the decomposition source or the invocation, pass
them to `generate_specs.py --stories` so generated unit `requirements.md` files
can populate `source_artifacts` with both the decomposition and story sources.
If an exact story source path cannot be resolved, instruct the producer to emit
`source_artifacts: []` rather than omitting the key.

**Process**:

1. Spawn subagent `ai-assistant-product-owner` — **Construction Process - Bolt Planning & Specs Generation**
2. Invoke skill `aidlc-bolt-planning`
3. Ensure `aidlc-bolt-planning/scripts/generate_specs.py` receives the resolved
   `--units` path and `--stories` path before writing
   `aidlc-docs/specs/{unit-slug}/requirements.md`
