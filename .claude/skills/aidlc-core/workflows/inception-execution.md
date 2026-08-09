# Inception Workflow Execution

Transform user intent into actionable user stories, units, and roadmap.

## Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Workflow Steps](#workflow-steps)
  - [Step 1: User Stories (Required)](#step-1-user-stories-required)
  - [Step 2: Unit Decomposition & Prioritization (Required)](#step-2-unit-decomposition--prioritization-required)
  - [Step 3: Roadmap Creation (Optional)](#step-3-roadmap-creation-optional)
  - [Step 4: Risk Assessment (Optional)](#step-4-risk-assessment-optional)
- [Workflow Execution Strategies](#workflow-execution-strategies)
- [Orchestration Context](#orchestration-context)
- [Success Criteria](#success-criteria)
- [Integration with Other Phases](#integration-with-other-phases)

---

## Overview

**Purpose**: Plan the work before construction begins by creating user stories, decomposing into technical units, and optionally creating roadmap and risk assessment.

**When to Use**:
- New feature development
- After Foundation phase is complete
- Start of new project (green-field)

**Key Steps**: 4 steps (2 required, 2 optional)
- Step 1: User Stories (required)
- Step 2: Unit Decomposition (required)
- Step 3: Roadmap (optional)
- Step 4: Risk Assessment (optional)

The complete current sequence also supports optional Brainstorm before stories, optional story-level UX before decomposition, and NFR definition after decomposition. See `references/methodology-workflows.md`; the sections below retain the established core story → unit → optional roadmap/risk detail.

---

## Prerequisites

**Required from Foundation**:
- `aidlc-docs/foundation/project-overview-pdr.md`
- `aidlc-docs/foundation/codebase-summary.md`
- `aidlc-docs/foundation/code-standards.md`
- `aidlc-docs/foundation/system-architecture.md`

If Foundation documents are missing, continue with available artifacts and live code, and disclose the context gap instead of blocking the workflow.

**User Input**:
- Clear user intent/requirement statement

---

## Workflow Steps

### Step 1: User Stories (Required)

**Agent**: ai-assistant-product-owner
**Skill**: aidlc-requirements-engineering
**Command**: `/aidlc.inception.user-stories`

**Purpose**: Transform user intent into structured user stories with acceptance criteria

**Inputs**:
- User intent statement
- Foundation docs (project-overview-pdr, system-architecture, uiux-guideline)

**Process**:
1. Analyze user intent and identify ambiguities or scope conflicts
2. Generate clarifying questions if needed, or proceed with explicit assumptions only when the user asks for a rough draft
3. Split multi-goal requests into independently valuable user stories
4. Transform intent using the explicit story template, workspace configuration, or the requirements skill default, in that order
5. Define acceptance criteria for each story
6. Identify and reuse user personas from foundation context
7. Capture dependency notes when story ordering matters

**Outputs**:
- `aidlc-docs/story-artifacts/{id}_{feature-name}_user_stories.md`

**Next Step**: Step 2 (Unit Decomposition)

**Validation**: **REQUIRED** - Human approval of user stories

---

### Step 2: Unit Decomposition & Prioritization (Required)

**Agent**: ai-solutions-architect
**Skill**: aidlc-units-decomposition
**Command**: `/aidlc.inception.decompose-units`

**Purpose**: Decompose stories into bounded technical units with priorities

**Inputs**:
- `story-artifacts/{id}_{feature-name}_user_stories.md` (from Step 1)
- Foundation docs (codebase-summary, code-standards, system-architecture)

**Process**:
1. Apply bounded context to decompose stories into units
2. Define unit boundaries and scope
3. Identify dependencies between units
4. Map user stories to units
5. Document technical considerations
6. Create dependency graph
7. Prioritize units based on:
   - Technical dependencies (primary)
   - Technical risk (secondary)
   - Parallel execution opportunities
8. Sequence units for optimal delivery

**Outputs**:
- `aidlc-docs/requirements/{id}_{feature-name}_units_decomposition.md`

**Next Step**: Step 3 (Roadmap - optional) or Construction phase

**Validation**: **REQUIRED** - Human approval of unit boundaries and priorities

---

### Step 3: Roadmap Creation (Optional)

**Agent**: ai-delivery-manager
**Skill**: aidlc-units-roadmap
**Command**: `/aidlc.inception.roadmap`

**Purpose**: Create timeline with Gantt chart showing unit delivery sequence

**Inputs**:
- `requirements/{id}_{feature-name}_units_decomposition.md` (from Step 2)

**Process**:
1. Create timeline based on unit priorities
2. Generate Gantt chart showing unit delivery
3. Identify milestones
4. Document phases and stages
5. Plan validation checkpoints

**Outputs**:
- `aidlc-docs/roadmap/product_roadmap.md`

**Next Step**: Step 4 (Risk Assessment - optional) or Construction phase

**Validation**: **REQUIRED** - Human approval of roadmap and timeline

---

### Step 4: Risk Assessment (Optional)

**Agent**: ai-delivery-manager
**Command**: `/aidlc.inception.risks`

**Purpose**: Identify risks and mitigation strategies

**Inputs**:
- `requirements/{id}_{feature-name}_units_decomposition.md` (from Step 2)
- `roadmap/product_roadmap.md` (from Step 3, if exists)

**Process**:
1. Identify risks:
   - Technical risks
   - Resource risks
   - Schedule risks
   - Business risks
   - External risks
2. Assess impact and likelihood
3. Define mitigation strategies
4. Create contingency plans
5. Assign risk owners

**Outputs**:
- `aidlc-docs/requirements/risk_register.md`

**Next Step**: Construction phase

**Validation**: Optional - Informational only

---

## Workflow Execution Strategies

### Linear Execution (Typical)

**Pattern**:
```
Step 1 (User Stories) → Step 2 (Unit Decomposition) → Construction
```

**When**: Standard feature development without timeline constraints

**Example**:
- Step 1: Create stories for notification system
- Step 2: Decompose into units (backend, frontend, database)
- → Proceed to Construction

---

### Full Planning (Complex Projects)

**Pattern**:
```
Step 1 → Step 2 → Step 3 (Roadmap) → Step 4 (Risk Assessment) → Construction
```

**When**: Complex projects requiring detailed planning

**Example**:
- Step 1: Stories for multi-module system
- Step 2: Decompose into 8-10 units
- Step 3: Create 6-month roadmap
- Step 4: Assess risks (integration, resources, dependencies)
- → Proceed to Construction with full plan

---

### Minimal Inception (Simple Features)

**Pattern**:
```
Step 1 → Step 2 → Construction (Skip Steps 3-4)
```

**When**: Simple features with clear scope

**Example**:
- Step 1: Stories for user profile enhancement
- Step 2: Decompose into 2-3 units
- → Skip roadmap and risks, proceed directly to Construction

---

## Orchestration Context

### Agent Selection

**Per Step** (from `references/agent-mapping.md`):
- Step 1: ai-assistant-product-owner (requirements elicitation)
- Step 2: ai-solutions-architect (technical decomposition)
- Step 3: ai-delivery-manager (timeline coordination)
- Step 4: ai-delivery-manager (risk analysis)

### Validation Checkpoints

**Per Step**:
- Step 1: **REQUIRED human approval** ⚠️
- Step 2: **REQUIRED human approval** ⚠️
- Step 3: **REQUIRED human approval** (if executed) ⚠️
- Step 4: Optional validation (informational)

### Next-Step Prompting

**After Each Step** (from `references/orchestration-patterns.md`):
```
✅ [Step Name] complete
Output: [artifact-path]

Next: [Step X] - [Step Description]
Agent: [agent-name]

Proceed? [Y/n]
```

**Example After Step 1**:
```
✅ User stories created
Output: story-artifacts/001_notification-system_user_stories.md

⚠️  Human approval required before proceeding

Please review:
- User stories and acceptance criteria
- Personas and feature mapping

Approve to continue? [Y/n]
```

**Example After Step 2**:
```
✅ Units decomposed and prioritized
Output: requirements/001_notification-system_units_decomposition.md

⚠️  Human approval required before proceeding

Please review:
- Unit boundaries and scope
- Dependencies and sequence
- Priority order

Next steps available:
1. Create roadmap (recommended for complex projects)
2. Skip to Construction phase (for simple features)

What would you like to do? [1/2]
```

---

## Success Criteria

- [ ] Intent clearly understood and documented
- [ ] All user stories created with acceptance criteria
- [ ] Units decomposed with clear boundaries
- [ ] Units prioritized based on technical dependencies
- [ ] Roadmap created (if needed)
- [ ] Risks identified and mitigated (if needed)
- [ ] Ready to proceed to Construction phase

---

## Integration with Other Phases

**From Foundation** (prerequisite):
- Product overview informs user stories
- Technical standards guide NFRs
- Architecture informs unit decomposition
- UI/UX guidelines inform story acceptance criteria

**To Construction** (outputs used):
- User stories guide implementation
- Units define work scope
- Roadmap sequences work (if created)
- Risks inform planning (if assessed)

---

_Inception Workflow Execution - MTV AI-DLC v2.1.0_
