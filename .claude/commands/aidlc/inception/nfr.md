---
description: Document non-functional requirements (performance, security, scalability)
argument-hint: [context]
---

# /aidlc.inception.nfr

**Purpose**: Document non-functional requirements (performance, security, scalability, reliability, accessibility)

**Agent**: ai-solutions-architect
**Skill**: architecture-design

## Input

<context>$ARGUMENTS</context>

**Inputs**:

- **Foundation** (brown-field): `aidlc-docs/foundation/{system-architecture,code-standards}.md`
- **Inception**: `aidlc-docs/requirements/{id}_{feature-name}_units_decomposition.md`

**Process**:

1. Spawn subagent `ai-solutions-architect` — **NFR Definition**
2. Invoke skill `architecture-design`
3. Review user stories and domain requirements
4. Define performance, security, scalability requirements
5. Document reliability and accessibility standards

**Output**: `aidlc-docs/requirements/nfr_requirements.md`

**Validation**: Technical review required
