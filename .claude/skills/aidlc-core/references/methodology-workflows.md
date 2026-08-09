# MTV AI-DLC Workflows

Detailed explanation of the 3 MTV AI-DLC workflows: Foundation, Inception, and Construction.

## Foundation Workflow

**Purpose**: Establish comprehensive understanding of existing system (brown-field) or new project foundation (green-field).

**When to Use**:
- Starting AI-DLC on existing project
- Need to document current architecture and standards
- Documenting project context before feature development

**Note**: Steps 2-4 can be created for green-field projects if user provides architecture/standards information.

### Workflow Steps

**Step 1: Product Overview and PDR**
- **Agent**: AI Assistant Product Owner
- **Command**: `/aidlc.foundation.product-overview`
- **Process**: Analyze business domain, document features, identify personas, extract Product Development Requirements
- **Output**: `foundation/project-overview-pdr.md`
- **Validation**: Yes (validate understanding of product)

**Step 2: Codebase Summary** (Requires Existing Code)
- **Agent**: AI Solutions Architect
- **Command**: `/aidlc.foundation.codebase-summary`
- **Process**: Scan folder structure, identify tech stack, analyze dependencies, map components
- **Output**: `foundation/codebase-summary.md`
- **Validation**: No (automated analysis)

**Step 3: System Architecture Analysis**
- **Agent**: AI Solutions Architect
- **Command**: `/aidlc.foundation.system-architecture`
- **Process**: Identify patterns (MVC, microservices, etc.), document components, map integrations, create architecture diagrams
- **Output**: `foundation/system-architecture.md`
- **Validation**: Yes (review architecture findings)

**Step 4: Code Standards Extraction**
- **Agent**: AI Solutions Architect
- **Command**: `/aidlc.foundation.code-standards`
- **Process**: Analyze code style, document naming conventions, identify testing standards, extract API conventions
- **Output**: `foundation/code-standards.md`
- **Validation**: No (automated extraction)

**Step 5: UI/UX Guideline Documentation**
- **Agent**: AI Design Orchestrator
- **Command**: `/aidlc.foundation.uiux-guideline`
- **Process**: Inventory UI components, extract color palette/typography, document patterns
- **Output**: `foundation/uiux-guideline.md`
- **Validation**: Yes (validate design system)

### Foundation Outputs Feed Into Inception

- **Product Overview** → Informs user story creation
- **Technical Standards** → Guide implementation
- **Design System** → Influences UI/UX requirements
- **Codebase Structure** → Helps identify unit boundaries
- **Architecture** → Informs technical design decisions

---

## Inception Workflow

**Purpose**: Transform user intent into actionable user stories, optional story-level UX direction, technical units, non-functional requirements, priorities, and roadmap.

**When to Use**:
- New feature development
- After Foundation phase
- Start of new project (green-field)

### Workflow Steps

**Step 0: Brainstorm** (Optional)
- **Agent**: AI Assistant Product Owner
- **Skill**: `aidlc-brainstorm`
- **Command**: `/aidlc.inception.brainstorm`
- **Use When**: Problem space is ambiguous, multiple approaches need comparison, or product/technical trade-offs should be explicit before creating stories
- **Process**: Capture decision to be made, explore approaches and trade-offs, produce concise decision record
- **Output**: `brainstorming/*.md`
- **Validation**: No (informational)

**Step 1: User Stories**
- **Agent**: AI Assistant Product Owner
- **Command**: `/aidlc.inception.user-stories`
- **Process**:
  1. Analyze user intent and identify ambiguities or scope conflicts
  2. Generate clarifying questions if needed, or proceed with explicit assumptions only when the user asks for a rough draft
  3. Split multi-goal requests into independently valuable user stories
  4. Transform intent into user stories (EARS-Lite format)
  5. Define acceptance criteria for each story
  6. Identify and reuse user personas from foundation context
  7. Capture dependency notes when story ordering matters
- **Output**: `story-artifacts/{id}_{feature-name}_user_stories.md` (3-digit ID: 001, 002...)
- **Validation**: Yes (approve user stories and answer clarifying questions)

**Step 1a: Story-Level UX Exploration** (Optional, When Stories Need UX Clarification)
- **Agent**: AI Design Orchestrator
- **Command**: `/aidlc.construction.ux-design` or equivalent AI Design Orchestrator workflow
- **Process**: Explore user flows, rough wireframes, screen relationships, interaction patterns, and accessibility considerations at the feature or story level before unit decomposition when user-facing behavior is still being clarified
- **Output**: `design-artifacts/prototype/{feature-name}/` when visual prototype is needed
- **Validation**: Yes (approve UX direction when it affects story scope, acceptance criteria, or decomposition)

**Step 2: Unit Decomposition & Prioritization**
- **Agent**: AI Solutions Architect
- **Skill**: `aidlc-units-decomposition`
- **Command**: `/aidlc.inception.decompose-units`
- **Process**:
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
- **Output**: `requirements/{id}_{feature-name}_units_decomposition.md`
- **Validation**: Yes (approve unit boundaries and priorities)

**Estimation Checkpoint (After Step 1 and/or Step 2)**
- **Agent**: AI Delivery Manager
- **Skill**: `aidlc-estimation`
- **Command**: `/aidlc-estimation {artifact-path}`
- **Use When**: Team needs BCP estimates for backlog prioritization (after stories) or sprint planning (after unit decomposition)
- **Output**: `aidlc-docs/estimation/{type}-{name}-{timestamp}.md`
- **Validation**: Yes — AI generates initial assessment, human reviews low-confidence dimensions

**Step 3: Non-Functional Requirements**
- **Agent**: AI Solutions Architect
- **Command**: `/aidlc.inception.nfr`
- **Process**:
  1. Review unit decomposition and architecture context
  2. Define performance, security, scalability, reliability, and accessibility expectations
  3. Document project-level NFRs that guide Construction
- **Output**: `requirements/nfr_requirements.md`
- **Validation**: Recommended for production-facing work

**Step 4: Roadmap Creation** (Optional)
- **Agent**: AI Delivery Manager
- **Skill**: `aidlc-units-roadmap`, `mermaid-diagramming` (Gantt)
- **Command**: `/aidlc.inception.roadmap`
- **Process**: Create timeline based on unit priorities, generate Gantt chart, identify milestones, plan validation checkpoints
- **Output**: `roadmap/product_roadmap.md`
- **Validation**: Yes (approve roadmap and timeline)

**Step 5: Risk Assessment** (Optional)
- **Agent**: AI Delivery Manager
- **Command**: `/aidlc.inception.risks`
- **Process**: Identify risks (technical, resource, schedule, business, external), assess impact and likelihood, define mitigation strategies, create contingency plans
- **Output**: `requirements/risk_register.md`
- **Validation**: No (informational)

### Required Foundation Context Files

Inception workflows reference these foundation files:
- `foundation/project-overview-pdr.md` - Business context, features, personas
- `foundation/codebase-summary.md` - Tech stack and module structure
- `foundation/code-standards.md` - Coding conventions
- `foundation/system-architecture.md` - Architecture patterns
- `foundation/uiux-guideline.md` - Design system and interaction patterns (when user-facing UX is being shaped)

---

## Construction Workflow

**Purpose**: Build complete units through bolt planning, requirements refinement, UX design for UI-bearing units, technical design, tasks, and execution.

**When to Use**:
- After Inception phase is complete
- For each unit identified in unit decomposition
- Can run multiple instances for different units

**Key Innovation: Bolt Planning** - One-time spec generation step (Step 0) before building all units.

### Workflow Steps

**Step 0: Bolt Planning** (One-Time, Before All Units)
- **Agent**: AI Assistant Product Owner
- **Command**: `/aidlc.construction.plan-bolts`
- **Process**:
  1. Read units decomposition file
  2. Read user stories files
  3. Execute `generate_specs.py` script
  4. Generate `specs/{unit-slug}/requirements.md` for EACH unit
  5. Validate all story IDs mapped correctly
- **Output**: `specs/{unit-slug}/requirements.md` (for all units)
- **Validation**: No (automated generation)
- **Run Once**: Before any unit construction begins

**Step 1: Refine Requirements** (Per Unit)
- **Agent**: AI Solutions Architect or AI Assistant Product Owner
- **Command**: `/aidlc.construction.refine-requirements`
- **Process**: Review user stories and unit decomposition, clarify scope and acceptance criteria, identify technical constraints, define unit boundaries, document assumptions and dependencies
- **Output**: `specs/{unit-slug}/requirements.md` (refined)
- **Validation**: Optional (can review)

**Step 2a: UX Design** (When Unit Has UI Changes)
- **Agent**: AI Design Orchestrator
- **Skill**: `aidlc-uiux-design`
- **Command**: `/aidlc.construction.ux-design`
- **Process**: Create HTML UI handoff artifacts with user flows, component mapping, interaction states, accessibility structure, responsive behavior, and optional visual prototypes for UI-bearing units
- **Output**: `specs/{unit-slug}/mockup.html` for implementation handoff; optionally `design-artifacts/prototype/{unit-slug}/` for stakeholder visual review
- **Validation**: Yes (approve UX direction when user-facing behavior changes)

**Step 2: Create Design** (Per Unit)
- **Agent**: AI Orchestration Engineer
- **Skill**: `aidlc-spec-driven` (Phase 2)
- **Command**: `/aidlc.construction.create-design`
- **Process**: Create comprehensive technical design, define API contracts and data models, incorporate approved UX artifacts when present, plan architecture patterns, document design decisions, create visual diagrams
- **Output**: `specs/{unit-slug}/design.md`
- **Validation**: Yes (approve design; AI Solutions Architect reviews before user approval)

**Step 3: Create Tasks** (Per Unit)
- **Agent**: AI Orchestration Engineer
- **Skill**: `aidlc-spec-driven` (Phase 3)
- **Command**: `/aidlc.construction.create-tasks`
- **Process**: Break design into implementation tasks, define task dependencies, estimate task complexity, sequence tasks logically, create task checklist, assign acceptance criteria per task
- **Output**: `specs/{unit-slug}/tasks.md`
- **Validation**: Optional (can review)

**Step 4: Execute Tasks** (Per Unit)
- **Agent**: AI Orchestration Engineer
- **Skill**: `aidlc-spec-driven` (Phase 4)
- **Command**: `/aidlc.construction.execute-task` (per task)
- **Process**: Resolve inline/subagent mode from explicit wording, workspace config, then inline default; execute task groups; in subagent mode scope-check and verify each return; run full executed-scope verification; delegate one broad `aidlc-code-review`; fix blockers; then update checkboxes
- **Output**: `src/` (or appropriate code directory)
- **Validation**: Coordinator verification + one broad delegated code review before checkbox completion

**Quality Gate: Code Review** (Before Marking Unit Complete)
- **Agent**: AI Orchestration Engineer (delegates to dedicated review subagent)
- **Skill**: `aidlc-code-review`
- **Command**: `/aidlc.construction.code-review`
- **Process**: Validate against `requirements.md`, `design.md`, `tasks.md`, verification evidence, and UI handoff when present; treat findings as implementation work — fix gaps and re-review
- **Validation**: Yes (final gate before unit is complete)

**Optional QA: Test Case Planning**
- **Agent**: AI Quality Orchestrator
- **Skill**: `aidlc-test-cases`
- **Command**: `/aidlc-test-cases`
- **Process**: Generate traceable Gherkin scenarios from spec artifacts; produce traceability matrix and automation recommendations
- **Output**: `specs/{unit-slug}/test-cases.md`

**Optional QA: E2E Automation**
- **Agent**: AI Quality Orchestrator
- **Skill**: `aidlc-e2e-tests`
- **Command**: `/aidlc-e2e-tests`
- **Process**: Convert E2E-candidate test cases into executable Playwright/Cypress tests; reuse repo test framework, fixtures, and Page Object Model
- **Output**: Repository E2E test files under project test structure

### Implementation Tier Ladder

Choose the implementation track based on scope:

| Signal | Vibe Mode | Quick Spec | Spec-Driven |
|--------|-----------|------------|-------------|
| File count | 1–3 | 1–5 (one area) | 5+ or cross-module |
| Written artifact | None | One `spec.md` | requirements + design + tasks |
| Approval gates | None | One | Three |
| New patterns / deps | No | Maybe one | Yes |
| Code review | No | Conditional | Mandatory |
| Deciding question | "No one will ever read a doc" | "One gate is enough" | "Needs separate sign-offs on what/how/tasks" |

**Upgrading in place**: Quick Spec can be split into `requirements.md` / `design.md` / `tasks.md` mid-flight and handed to `aidlc-spec-driven` without moving files.

---

### Alternative: Vibe Mode (Quick Implementation)

**Agent**: AI Orchestration Engineer  
**Skill**: `aidlc-vibe`  
**Command**: `/aidlc.construction.vibe`

**Use when**: bug fixes, simple features (1-3 files), refactoring with existing patterns, CSS/styling changes. **Skip when**: complex features (5+ files), new infrastructure, multi-component features, architecture decisions.

### Alternative: Quick Spec (Medium Features)

**Agent**: AI Orchestration Engineer  
**Skill**: `aidlc-quick-spec`  
**Output**: `specs/{feature}/spec.md`

Eight steps to approval: load foundation → analyze codebase → clarify requirements → design → plan tasks → write `spec.md` → two scoped reviewer checks → one user approval gate. After approval, execute through the Quick Spec task-execution reference. The spec contains Goal, Requirements, Design, File Structure, and bite-sized checkboxed Tasks.

---

### Multi-Unit Execution Strategies

After Step 0 (Bolt Planning) completes, units can be built:

**Sequential Execution**:
- Units have dependencies
- Build in priority order defined in Inception
- Example: Unit 1 (Foundation) → Unit 2 (depends on 1) → Unit 3 (depends on 2)

**Parallel Execution**:
- Units are independent
- Can execute simultaneously
- Example: Units 2 & 3 both depend on Unit 1, so after Unit 1 completes, Units 2 & 3 run in parallel

### Required Inputs

**From Inception**:
- `story-artifacts/{id}_{feature-name}_user_stories.md` - User requirements
- `requirements/{id}_{feature-name}_units_decomposition.md` - Unit definition and scope
- `requirements/nfr_requirements.md` - Non-functional requirements
- `roadmap/product_roadmap.md` - Timeline and priorities

**From Foundation**:
- `foundation/codebase-summary.md` - Project structure and tech stack
- `foundation/code-standards.md` - Coding conventions
- `foundation/system-architecture.md` - Architecture patterns
- `foundation/uiux-guideline.md` - Design system (for UI units)

---

## State Tracking

**State File**: `aidlc-docs/aidlc-state.md`

All workflows maintain workflow state to enable resumption and progress tracking.

### State Structure

```yaml
aidlc_state:
  workflow_id: { unique_id }
  current_phase: foundation | inception | construction | operations
  current_step: { step_identifier }
  intent: { user_intent }

  completed_steps:
    - phase: { phase_name }
      step: { step_number }
      completed_at: { timestamp }
      artifacts: [file_paths]

  validation_checkpoints:
    - name: { checkpoint_name }
      status: approved | pending | rejected
      validated_at: { timestamp }
      comments: { feedback }

  next_action:
    description: { what_to_do_next }
    estimated_duration: { minutes }
```

### State Management

- **Initialize**: AI Delivery Manager creates state at workflow start
- **Update**: Agents update after each completed step
- **Persist**: Saved to `aidlc-docs/aidlc-state.md` after each change
- **Resume**: Load state to continue interrupted workflows from last checkpoint

---

_MTV AI-DLC Methodology - Workflows Reference_
