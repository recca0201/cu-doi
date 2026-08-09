---
description: Execute complete inception workflow from user intent to roadmap
argument-hint: [requirements]
---

# /aidlc.inception.inception-workflow

**Purpose**: Execute complete inception workflow from user intent to roadmap

**Agent**: ai-delivery-manager
**Workflow**: `.mtv-aidlc/workflows/inception-workflow.md`

## Input

<requirements>$ARGUMENTS</requirements>

**Inputs**:

- **Foundation** (brown-field): `aidlc-docs/foundation/{project-overview-pdr,codebase-summary,code-standards,system-architecture}.md`

**Process**:

1. Spawn subagent `ai-delivery-manager` — **Inception Workflow Orchestration**
2. Follow `.mtv-aidlc/workflows/inception-workflow.md` (8 steps)
3. Spawn `ai-assistant-product-owner` and `ai-solutions-architect` as needed
4. Manage validation checkpoints

**Outputs**:

- `aidlc-docs/story-artifacts/{id}_{feature-name}_user_stories.md`
- `aidlc-docs/requirements/{id}_{feature-name}_units_decomposition.md`
- `aidlc-docs/requirements/{nfr_requirements,risk_register}.md`
- `aidlc-docs/roadmap/product_roadmap.md`

**Validation**: Human review at 2 checkpoints
