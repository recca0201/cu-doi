---
description: Create risk register with identification and mitigation strategies
argument-hint: [context]
---

# /aidlc.inception.risks

**Purpose**: Create risk register with identification, assessment, and mitigation strategies

**Agent**: ai-delivery-manager
**Skill**: aidlc-core

## Input

<context>$ARGUMENTS</context>

**Inputs**:

- **Inception**: `aidlc-docs/{requirements/units_decomposition,roadmap/product_roadmap}.md`

**Process**:

1. Spawn subagent `ai-delivery-manager` — **Risk Register Creation**
2. Invoke skill `aidlc-core`
3. Identify technical, business, resource, schedule risks
4. Assess impact and likelihood
5. Create mitigation strategies and contingency plans
6. Assign owners and define monitoring

**Output**: `aidlc-docs/requirements/risk_register.md`

**Validation**: Review with stakeholders
