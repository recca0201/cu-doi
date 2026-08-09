---
description: Consolidate foundation outputs into a brown-field readiness report and recommendations
argument-hint: [input]
---

# /aidlc.foundation.foundation-report

**Purpose**: Consolidate all foundation discoveries into comprehensive report for brown-field projects

**Agent**: ai-delivery-manager
**Skill**: aidlc-core

## Input

<input>$ARGUMENTS</input>

**Inputs**:

- `aidlc-docs/foundation/codebase-summary.md`
- `aidlc-docs/foundation/system-architecture.md`
- `aidlc-docs/foundation/code-standards.md`
- `aidlc-docs/foundation/uiux-guideline.md`
- `aidlc-docs/foundation/project-overview-pdr.md`

**Process**:

1. Spawn subagent `ai-delivery-manager` — **Foundation Report Consolidation**. Tell it to invoke skill `aidlc-core`, and that its job is to *consolidate* the five existing documents, not write or rewrite them — a missing document is a reported gap, not something to generate.
2. Collect outputs from all foundation agents
3. Consolidate findings and readiness assessment — include each document's `## Assumptions & Open Inputs` entries, since a readiness call built on unconfirmed inputs is not a readiness call
4. Create recommendations for new development
5. Fill foundation report template

**Output**: `aidlc-docs/foundation/foundation_report.md`

**Validation**: Human review required - validates foundation completeness before proceeding to Inception
