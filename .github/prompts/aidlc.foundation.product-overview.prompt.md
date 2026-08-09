---
description: Create project overview and product requirements document (business vision, user personas, product scope)
---

---
description: Create the project overview (vision, personas, scope) as the foundation baseline
argument-hint: [input]
---

# /aidlc.foundation.product-overview

**Purpose**: Create project overview and product requirements document (business vision, user personas, product scope)

**Agent**: ai-assistant-product-owner
**Skill**: aidlc-foundation-context

## Input

<input>$ARGUMENTS</input>

**Process**:

1. Invoke skill `aidlc-foundation-context` and run its **Step 0 input gate** for this document **here in the main session** — a spawned subagent has no way to ask the user anything, and nothing in a codebase reveals vision, users, or scope.
2. Spawn subagent `ai-assistant-product-owner` — **Foundation Process - Product Overview** — using the skill's dispatch contract (`references/subagent-brief.md`), which has it invoke `aidlc-foundation-context` itself for the Foundation phase and follow the single-document inline path. Pass the step-1 answers marked Confirmed / Assumed / still-open.
3. Surface any returned assumptions or unresolved inputs to the user with the finished document.
