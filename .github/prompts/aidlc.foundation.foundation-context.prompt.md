---
description: Execute complete foundation analysis producing all 5 documents with cross-referencing to eliminate duplication
---

---
description: Run the complete Foundation analysis set (product, architecture, codebase, standards, UI/UX)
argument-hint: [input]
---
# /aidlc.foundation.foundation-context

**Purpose**: Execute complete foundation analysis producing all 5 documents with cross-referencing to eliminate duplication

**Skill**: aidlc-foundation-context

## Input

<input>$ARGUMENTS</input>

**Process**:

1. Invoke skill `aidlc-foundation-context`
2. Run its **Step 0 input gate** for all five documents in the main session, before anything is written — clarification can only happen here, since the subagents that follow have no interactive channel
3. Follow its **Multiple documents (orchestrated with subagents)** path: build the Shared Facts Brief once (facts marked Observed / Confirmed / Assumed), dispatch one subagent per document in parallel, then reconcile (duplication matrix + cross-reference validation) and report the set's assumptions and unresolved inputs

**Outputs**: All 5 foundation documents in `aidlc-docs/foundation/` (resolved against the configured docs root)

**Validation**: The skill's reconcile step — each fact has one home, all cross-references resolve, and every Assumed value is marked in its document and reported to the user
