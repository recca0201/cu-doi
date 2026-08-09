---
description: Create product roadmap with Gantt chart visualization
argument-hint: [units]
---

# /aidlc.inception.roadmap

**Purpose**: Create product roadmap with Gantt chart visualization

**Agent**: ai-delivery-manager
**Skill**: aidlc-units-roadmap

## Input

<units>$ARGUMENTS</units>

**Process**:

1. Spawn subagent `ai-delivery-manager` — **Inception - Roadmap & Risk Assessment**
2. Invoke skill `aidlc-units-roadmap`
