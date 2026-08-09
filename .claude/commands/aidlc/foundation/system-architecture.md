---
description: Analyze the system architecture and document the current technical design and rationale
argument-hint: [input]
---

# /aidlc.foundation.system-architecture

**Purpose**: Analyze and document system architecture with technical decisions and architectural rationale

**Agent**: ai-solutions-architect
**Skill**: aidlc-foundation-context

## Input

<input>$ARGUMENTS</input>

**Process**:

1. Invoke skill `aidlc-foundation-context` and run its **Step 0 input gate** for this document **here in the main session** — a spawned subagent has no way to ask the user anything, so inputs must be settled before step 2.
2. Spawn subagent `ai-solutions-architect` — **Foundation Process - System Architecture** — using the skill's dispatch contract (`references/subagent-brief.md`), which has it invoke `aidlc-foundation-context` itself for the Foundation phase and follow the single-document inline path. Pass the step-1 answers marked Confirmed / Assumed / still-open.
3. Surface any returned assumptions or unresolved inputs to the user with the finished document.