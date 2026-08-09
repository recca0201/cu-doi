---
description: Document the UI/UX design system and component guidelines as a single source of truth
argument-hint: [input]
---

# /aidlc.foundation.uiux-guideline

**Purpose**: Document complete UI/UX design system as single source of truth (colors, typography, components)

**Agent**: ai-design-orchestrator
**Skill**: aidlc-foundation-context

## Input

<input>$ARGUMENTS</input>

**Process**:

1. Invoke skill `aidlc-foundation-context` and run its **Step 0 input gate** for this document **here in the main session** — a spawned subagent has no way to ask the user anything, and with no design input this document becomes an invented design system that UI code then gets built against.
2. Spawn subagent `ai-design-orchestrator` — **Foundation Process - UI/UX Guideline** — using the skill's dispatch contract (`references/subagent-brief.md`), which has it invoke `aidlc-foundation-context` itself for the Foundation phase and follow the single-document inline path. Pass the step-1 answers marked Confirmed / Assumed / still-open.
3. Surface any returned assumptions or unresolved inputs to the user with the finished document.
