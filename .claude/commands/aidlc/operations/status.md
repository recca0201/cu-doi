---
description: Check project status and progress across all AI-DLC phases
---

# /aidlc-status

**Purpose**: Check project status and progress across all AI-DLC phases

**Agent**: ai-delivery-manager
**Skill**: aidlc-core

**Inputs**:

- **State Tracking**:
  - `aidlc-docs/aidlc-state.md` - Current workflow state and progress
- **Inception** (if available):
  - `aidlc-docs/requirements/{id}_{feature-name}_units_decomposition.md` - Unit status
  - `aidlc-docs/roadmap/product_roadmap.md` - Timeline and milestones
- **All Phase Outputs**: Checks existence and completeness of all artifacts

**Process**:

1. Spawn subagent `ai-delivery-manager` — **Project Status Check**
2. Invoke skill `aidlc-core`
3. Review AI-DLC state file
4. Check current phase and step
5. Collect progress from all agents
6. Identify completed/in-progress/blocked items
7. Calculate completion percentage
8. Generate status summary

**Output**: Console output with current status

**Validation**: Real-time status query
