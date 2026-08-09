---
description: Document project structure, directory organization, dependencies, and complete setup instructions
---

---
description: Document codebase structure, key dependencies, and setup/run instructions
argument-hint: [input]
---

# /aidlc.foundation.codebase-summary

**Purpose**: Document project structure, directory organization, dependencies, and complete setup instructions

**Agent**: ai-solutions-architect
**Skill**: aidlc-foundation-context

## Input

<input>$ARGUMENTS</input>

**Process**:

1. Invoke skill `aidlc-foundation-context` and run its **Step 0 input gate** for this document **here in the main session** — a spawned subagent has no way to ask the user anything. Brownfield clears this with no questions (read the repo); greenfield has nothing to read.
2. Spawn subagent `ai-solutions-architect` — **Foundation Process - Codebase Summary** — using the skill's dispatch contract (`references/subagent-brief.md`), which has it invoke `aidlc-foundation-context` itself for the Foundation phase and follow the single-document inline path. Pass the repo (or saved repomix output) for brownfield, or the step-1 answers marked Confirmed / Assumed / still-open for greenfield.
3. Surface any returned assumptions or unresolved inputs to the user with the finished document.