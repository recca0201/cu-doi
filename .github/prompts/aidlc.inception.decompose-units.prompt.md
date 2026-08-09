---
description: Decompose user stories into implementable units and prioritize based on technical dependencies
---

---
description: Decompose user stories into implementable units with priorities
argument-hint: [user-stories]
---

# /aidlc.inception.decompose-units

**Purpose**: Decompose user stories into implementable units and prioritize based on technical dependencies

**Agent**: ai-solutions-architect
**Skill**: aidlc-units-decomposition

## Input

<user-stories>$ARGUMENTS</user-stories>

**Process**:

1. Spawn subagent `ai-solutions-architect` — **Inception Process - Unit Decomposition**
2. Invoke skill `aidlc-units-decomposition`
