---
description: Generate phase completion report with deliverables, metrics, and lessons learned
---

# /aidlc-phase-report

**Purpose**: Generate phase completion report with deliverables, metrics, and lessons learned

**Agent**: ai-delivery-manager
**Skill**: aidlc-core

**Inputs**:

- **State Tracking**:
  - `aidlc-docs/aidlc-state.md` - Workflow execution history
- **All Phase Outputs**: All artifacts generated during the completed phase
  - Foundation: All foundation/\*.md files
  - Inception: All story-artifacts/, requirements/, estimation/, roadmap/, plans/ files
  - Construction: All design-artifacts/ files and source code
  - Operations: Deployment logs, monitoring data

**Process**:

1. Spawn subagent `ai-delivery-manager` — **Phase Completion Report**
2. Invoke skill `aidlc-core`
3. Review completed phase deliverables
4. Collect metrics (effort, duration, velocity)
5. Gather validation results
6. Document lessons learned
7. Assess readiness for next phase
8. Generate completion report

**Output**: `aidlc-docs/operations/{phase}_completion_report.md`

**Validation**: Phase sign-off required
