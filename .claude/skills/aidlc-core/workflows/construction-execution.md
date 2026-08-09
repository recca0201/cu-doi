# Construction Workflow Execution

Complete unit implementation through bolt planning, requirements refinement, design, tasks, and execution.

## Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Workflow Steps](#workflow-steps)
  - [Step 0: Bolt Planning (One-Time)](#step-0-bolt-planning-one-time-before-all-units)
  - [Step 1: Refine Requirements (Per Unit)](#step-1-refine-requirements-per-unit)
  - [Step 2: Create Design (Per Unit)](#step-2-create-design-per-unit)
  - [Step 3: Create Tasks (Per Unit)](#step-3-create-tasks-per-unit)
  - [Step 4: Execute Tasks (Per Unit)](#step-4-execute-tasks-per-unit)
- [Multi-Unit Execution Strategies](#multi-unit-execution-strategies)
- [Orchestration Context](#orchestration-context)
- [Success Criteria](#success-criteria)
- [Alternative: Quick Implementation (Vibe Mode)](#alternative-quick-implementation-vibe-mode)

---

## Overview

**Purpose**: Build complete units through structured implementation.

**When to Use**:
- After Inception phase is complete
- For each unit identified in unit decomposition
- Can run multiple instances for different units

**Key Innovation**: Bolt Planning (Step 0) generates specs for ALL units before building any unit.

---

## Prerequisites

**Required from Inception**:
- `aidlc-docs/story-artifacts/{id}_{feature-name}_user_stories.md`
- `aidlc-docs/requirements/{id}_{feature-name}_units_decomposition.md`
- `aidlc-docs/requirements/nfr_requirements.md`
- `aidlc-docs/roadmap/product_roadmap.md` (optional)

**Required from Foundation**:
- `aidlc-docs/foundation/codebase-summary.md`
- `aidlc-docs/foundation/code-standards.md`
- `aidlc-docs/foundation/system-architecture.md`
- `aidlc-docs/foundation/uiux-guideline.md` (for UI units)

---

## Workflow Steps

### Step 0: Bolt Planning (One-Time, Before All Units)

**Agent**: ai-assistant-product-owner
**Skill**: aidlc-bolt-planning
**Command**: `/aidlc.construction.plan-bolts`

**Purpose**: Generate initial spec files for ALL units from decomposition

**Inputs**:
- Units decomposition file
- User stories files

**Process**:
1. Read units decomposition
2. Read user stories
3. Execute `generate_specs.py` script
4. Generate `specs/{unit-slug}/requirements.md` for EACH unit
5. Validate all story IDs mapped correctly

**Outputs**:
- `aidlc-docs/specs/{unit-slug}/requirements.md` (for all units)

**Next Step**: Step 1 (Refine Requirements) for first unit

**Validation**: Structure - all spec files generated

---

### Step 1: Refine Requirements (Per Unit)

**Agent**: ai-solutions-architect
**Skill**: aidlc-spec-driven (Phase 1)
**Command**: `/aidlc.construction.refine-requirements`

**Purpose**: Clarify scope and acceptance criteria for specific unit

**Inputs**:
- `specs/{unit-slug}/requirements.md` (from Step 0)
- Foundation docs (codebase-summary, code-standards, architecture)

**Process**:
1. Review user stories and unit decomposition
2. Clarify scope and acceptance criteria
3. Identify technical constraints
4. Define unit boundaries clearly
5. Document assumptions and dependencies
6. Align with NFRs

**Outputs**:
- `aidlc-docs/specs/{unit-slug}/requirements.md` (refined)

**Next Step**: Step 2 (Create Design)

**Validation**: Optional - content validation (requirements clarified)

---

### Step 2: Create Design (Per Unit)

**Agent**: ai-orchestration-engineer
**Skill**: aidlc-spec-driven (Phase 2)
**Command**: `/aidlc.construction.create-design`

**Purpose**: Create comprehensive technical design

**Inputs**:
- `specs/{unit-slug}/requirements.md` (refined from Step 1)
- Foundation docs (codebase-summary, code-standards, architecture, uiux-guideline)

**Process**:
1. Create comprehensive technical design
2. Define API contracts and data models
3. Design UX components and user flows
4. Plan architecture patterns
5. Document design decisions
6. Create visual diagrams (Mermaid)

**Outputs**:
- `aidlc-docs/specs/{unit-slug}/design.md`

**Next Step**: Step 3 (Create Tasks)

**Validation**: **REQUIRED** - Human approval before proceeding to tasks

**Critical Decision Point**: Design approved means commitment to implementation approach

---

### Step 3: Create Tasks (Per Unit)

**Agent**: ai-orchestration-engineer
**Skill**: aidlc-spec-driven (Phase 3)
**Command**: `/aidlc.construction.create-tasks`

**Purpose**: Break design into actionable implementation tasks

**Inputs**:
- `specs/{unit-slug}/design.md` (from Step 2)

**Process**:
1. Break design into implementation tasks
2. Define task dependencies
3. Estimate task complexity
4. Sequence tasks logically
5. Create task checklist with checkboxes
6. Assign acceptance criteria per task

**Outputs**:
- `aidlc-docs/specs/{unit-slug}/tasks.md`

**Next Step**: Step 4 (Execute Tasks)

**Validation**: Optional - content validation (tasks have acceptance criteria)

---

### Step 4: Execute Tasks (Per Unit)

**Agent**: ai-orchestration-engineer
**Skill**: aidlc-spec-driven (Phase 4)
**Command**: `/aidlc.construction.execute-task` (per task)

**Purpose**: Implement code according to design specs

**Inputs**:
- `specs/{unit-slug}/tasks.md` (task checklist from Step 3)
- `specs/{unit-slug}/design.md` (design reference)
- Foundation docs (code-standards, codebase-summary)

**Process**:
1. Resolve the execution approach: explicit prompt wording wins, then workspace `taskExecution.approach` / injected `Task Execution Approach`, then default inline. Do not ask for confirmation.
2. For each task group in the checklist:
   - Inline mode implements in the active session; subagent mode dispatches one scoped implementer per task group in sequence — `aidlc-spec-driven/references/phase-4-execution.md` and `phase-4-subagent-execution.md` own the protocol
   - In subagent mode, capture the dirty-worktree baseline and allowed scope before dispatch; the coordinator does not write implementation code or let implementers edit `tasks.md`
   - Follow code standards and patterns
   - Add appropriate error handling
   - Document implementation notes
   - Coordinator scope-checks each return and re-runs relevant verification; implementer validation claims are not trusted
3. After full executed-scope verification, spawn one fresh broad `aidlc-code-review` subagent for code-changing work; do not spawn one reviewer per task group
   - Fix blocking review findings per the resolved approach (inline: active session; subagent-driven: one fixer subagent with the complete findings list) and rerun impacted verification/review
   - Mark task complete in checklist only after verification and required code review pass
4. If review cannot run, leave the scope `verified-pending-review` and unchecked.
5. Track task completion progress

**Outputs**:
- `src/` (or appropriate code directory)
- Updated `specs/{unit-slug}/tasks.md` (with completed checkboxes)

**Next Step**:
- More tasks → Continue Step 4
- All tasks done → Unit complete, move to next unit OR workflow complete

**Validation**: Yes — coordinator verification plus one broad delegated `aidlc-code-review` before checkbox completion

---

## Multi-Unit Execution Strategies

### Sequential Execution

**When**: Units have dependencies

**Pattern**:
```
Unit 1 (Steps 1-4) → Unit 2 depends on Unit 1 → Unit 2 (Steps 1-4) → Unit 3 depends on Unit 2 → Unit 3 (Steps 1-4)
```

**Example**:
- Unit 1: Foundation (authentication, database setup)
- Unit 2: User management (depends on auth from Unit 1)
- Unit 3: Notifications (depends on users from Unit 2)

### Parallel Execution

**When**: Units are independent

**Pattern**:
```
Unit 1 (Steps 1-4) ┐
Unit 2 (Steps 1-4) ├─ All run simultaneously
Unit 3 (Steps 1-4) ┘
```

**Example**:
- Unit 1: User profile
- Unit 2: Settings page
- Unit 3: Help documentation
(All independent, no shared dependencies)

### Hybrid Execution

**When**: Mix of dependencies and independence

**Pattern**:
```
Unit 1 (Steps 1-4) → ┌─ Unit 2 (Steps 1-4)
                     └─ Unit 3 (Steps 1-4)
```

**Example**:
- Unit 1: API foundation (required by all)
- Units 2 & 3: Different API endpoints (depend on Unit 1, but independent from each other)

---

## Orchestration Context

### Agent Selection

**Per Step** (from `references/agent-mapping.md`):
- Step 0: ai-assistant-product-owner (requirements synthesis)
- Step 1: ai-solutions-architect (technical scoping)
- Step 2: ai-orchestration-engineer (comprehensive design)
- Step 3: ai-orchestration-engineer (task planning)
- Step 4: ai-orchestration-engineer (implementation)

### Validation Checkpoints

**Per Step**:
- Step 0: Structure validation (specs generated)
- Step 1: Optional content validation
- Step 2: **REQUIRED human approval** ⚠️
- Step 3: Optional content validation
- Step 4: Continuous per-task validation

### Next-Step Prompting

**After Each Step** (from `references/orchestration-patterns.md`):
```
✅ [Step Name] complete
Output: [artifact-path]

Next: [Step X] - [Step Description]
Agent: [agent-name]

Proceed? [Y/n]
```

**Example After Step 2**:
```
✅ Design created
Output: specs/notification-service/design.md

⚠️  Human approval required before proceeding

Please review:
- API endpoints and contracts
- Data models and validation
- Component architecture

Approve design to continue? [Y/n]
```

---

## Success Criteria

- [ ] Bolt planning complete (specs generated for all units)
- [ ] Requirements refined and scope clarified
- [ ] Comprehensive design approved by human
- [ ] Tasks broken down with clear acceptance criteria
- [ ] Implementation progressing systematically
- [ ] Code following standards and design specs
- [ ] Unit implementation tracked and documented

---

## Alternative: Quick Implementation (Vibe Mode)

For simple bug fixes and features that don't require full spec-driven approach:

**Command**: `/aidlc.construction.vibe`
**Agent**: ai-orchestration-engineer
**Skill**: aidlc-vibe

**Use When**:
- Bug fixes
- Simple features (1-3 files)
- Refactoring with existing patterns
- CSS/styling changes
- Quick iterations

**Skip When**:
- Complex features (5+ files)
- New infrastructure needed
- Multi-component features
- Architecture decisions required

---

_Construction Workflow Execution - MTV AI-DLC v2.1.0_
