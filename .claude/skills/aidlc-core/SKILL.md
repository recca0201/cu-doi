---
name: aidlc-core
description: MTV AI-DLC (AI-Driven Development Lifecycle) methodology - complete AI-powered development approach transforming user intent into production code through 3 delivery workflows (Foundation, Inception, Construction), with supporting operations artifacts, orchestrated by 6 specialized AI agents. Use when implementing MTV AI-DLC workflows, understanding the methodology phases, coordinating agent collaboration, or following MTV AI-DLC development lifecycle.
---

# MTV AI-DLC Methodology

Complete AI-powered development lifecycle transforming user intent into production-ready code.

Paths written as `aidlc-docs/` mean the configured docs root: explicit path/`--docs-root`, then `.mtv-aidlc/extension-config.json` `aidlcDocsPath`, then workspace-root `aidlc-docs/`.

## What is MTV AI-DLC?

MTV AI-DLC is a structured methodology where **6 AI agents** collaborate through **3 orchestrated workflows** to deliver complete features with comprehensive documentation, plus operations follow-through for deployment and monitoring.

**The Progression**:
```
User Intent → User Stories → Technical Units → Specs → Tasks → Production Code
```

## The 3 Workflows

### 1. Foundation Workflow
**Purpose**: Document existing project context (brown-field) or establish new project foundation (green-field)

**Steps**:
1. **Product Overview & PDR** — business context, features, personas (AI Asst. PO)
2. **Codebase Summary** — tech stack, folder structure (AI Solutions Architect; brown-field only)
3. **System Architecture** — patterns, components, integration map (AI Solutions Architect)
4. **Code Standards** — conventions, naming, testing, API patterns (AI Solutions Architect)
5. **UI/UX Guidelines** — components, colors, typography, design system (AI Design Orchestrator; optional)

**Commands**: `/aidlc.foundation.*`  
**Outputs**: `aidlc-docs/foundation/` (5 files)  
**When**: Recommended for all projects before Inception; deepest for brown-field

### 2. Inception Workflow
**Purpose**: Transform user intent into a complete development plan

**Steps**:
- **Step 0: Brainstorm** (optional) — explore approaches and trade-offs when problem space is ambiguous; produces decision records in `brainstorming/`
- **Step 1: User Stories** — configured or explicitly selected story template with acceptance criteria and dependency notes
- **Step 1a: Story-Level UX Exploration** (optional) — rough wireframes, user flows, screen relationships when UX direction affects scope or decomposition
- **Step 2: Unit Decomposition** — bounded-context decomposition with dependencies, priorities, execution sequence
- **Step 3: NFRs** — performance, security, scalability, reliability, accessibility expectations
- **Step 4: Roadmap** (optional) — timeline with Gantt chart
- **Step 5: Risk Assessment** (optional) — identify risks, impact, mitigation strategies

**Commands**: `/aidlc.inception.*`  
**Outputs**: `brainstorming/*.md`, `story-artifacts/{id}_*_user_stories.md`, `requirements/{id}_*_units_decomposition.md`, `requirements/nfr_requirements.md`, `roadmap/product_roadmap.md`, `requirements/risk_register.md`

### 3. Construction Workflow
**Purpose**: Build each unit through structured implementation

**Steps** (per unit):
- **Step 0: Bolt Planning** (one-time) — generate `specs/{unit}/requirements.md` for ALL units from decomposition
- **Step 1: Refine Requirements** — clarify scope, acceptance criteria, constraints, assumptions
- **Step 2a: UX Design** (when unit has UI changes) — HTML handoff with user flows, component mapping, interaction states, accessibility, responsive behavior; optional visual prototype
- **Step 2: Create Design** — comprehensive technical design: API contracts, data models, architecture patterns, diagrams, incorporating approved UX artifacts
- **Step 3: Create Tasks** — break design into implementation tasks with dependencies, complexity, and acceptance criteria
- **Step 4: Execute Tasks** — resolve inline/subagent mode from explicit wording, workspace config, then inline default; verify the executed scope; run one broad delegated code review before checking off
- **Quality Gate: Code Review** — validate against `requirements.md`, `design.md`, `tasks.md`, and foundation standards before marking unit complete
- **Optional QA: Test Cases** — traceable Gherkin scenarios from spec artifacts
- **Optional QA: E2E Automation** — executable Playwright/Cypress tests for E2E candidates
- **Alternative: Quick Spec** — single-document, single-approval-gate flow for medium features (1-5 files, one area of code); produces `specs/{feature}/spec.md` with Goal, Requirements, Design, File Structure, and Tasks; sits between Vibe and full spec-driven
- **Alternative: Vibe Mode** — skip spec-driven flow for simple fixes (1-3 files), bug fixes, styling changes

**Commands**: `/aidlc.construction.*`  
**Outputs**: `specs/{unit}/requirements.md`, `specs/{unit}/mockup.html` (when UX), `specs/{unit}/design.md`, `specs/{unit}/tasks.md`, `specs/{unit}/test-cases.md` (optional), `src/`, executable test files (optional)

**Details**: [methodology-workflows.md](references/methodology-workflows.md)

## The 6 AI Agents

| Agent | Role | Key Skills Used |
|-------|------|-----------------|
| **AI Assistant Product Owner** | Business Requirements | `aidlc-requirements-engineering`, `aidlc-bolt-planning`, `aidlc-spec-driven` (Phase 1), `aidlc-brainstorm`, `aidlc-foundation-context` |
| **AI Solutions Architect** | Technical Design | `aidlc-units-decomposition`, `aidlc-foundation-context`, `architecture-design`, `ddd`, `mermaid-diagramming` |
| **AI Design Orchestrator** | UI/UX Design | `aidlc-uiux-design`, `aidlc-foundation-context` |
| **AI Orchestration Engineer** | Implementation | `aidlc-spec-driven` (Phases 2-4), `aidlc-quick-spec`, `aidlc-vibe`, `aidlc-code-review` |
| **AI Quality Orchestrator** | Testing & Validation | `aidlc-test-cases`, `aidlc-e2e-tests`, `chrome-devtools` |
| **AI Delivery Manager** | Coordination | `aidlc-units-roadmap`, `aidlc-estimation`, risk assessment (manual) |

All agents load `aidlc-core` for methodology patterns, quality standards, and process orchestration.

## BCP Estimation

**Skill**: `aidlc-estimation`  
**Command**: `/aidlc-estimation {artifact-path}` (exact root command for Claude and Copilot)
**Formula**: `Total BCP = Σ (Occurrences × T-Shirt Points)` across 10 dimensions

Estimation runs at 3 levels; use **Spec-level as authoritative** for reporting:

| Level | Artifact | Accuracy | When |
|-------|----------|----------|------|
| User Story | `story-artifacts/*.md` | ±30-40% | After story creation — backlog prioritization |
| Unit | `requirements/*_units_decomposition.md` | ±20-30% | After decomposition — sprint planning |
| Spec | `specs/{unit}/requirements.md` + `design.md` + `tasks.md` | ±10-15% | After requirements, design, and tasks — authoritative for velocity |

**10 Dimensions** (4 mandatory, 6 optional):
- *Mandatory*: Roles/Permissions, Solution Variabilities, Domain Entities, Boundaries
- *Optional*: Business Rules, Interface Elements, New Domain Entities, Background Processes, Notifications, Audits

**Output**: `aidlc-docs/estimation/{type}-{name}-{timestamp}.md`

- A units-decomposition file is batch input: estimate each unit independently, then let the coordinator consolidate and write the shared file once.
- Finalized estimates write `estimation_bcp` and `estimation_report` back to the source artifact; requirements and Quick Specs also keep the visible `**Estimation (BCP)**` line current.
- Convert BCP to effort/duration only after BCP is final; use capacity-based Optimistic/Likely/Pessimistic ranges from `aidlc-estimation`, not a single hand-calculated date.

**Complexity categories**: Trivial (1-10), Simple (11-25), Moderate (26-50), Complex (51-100), Very Complex (101+)

## Key Methodology Patterns

### Plan → Approve → Execute
All workflows follow this core pattern:
1. Agent creates execution plan
2. Human validates at critical checkpoints
3. Agent executes after approval
4. State tracked for resumption

### Bolt Planning
**One-time operation** at start of Construction:
- Reads units decomposition + user stories
- Generates `specs/{unit-slug}/requirements.md` for ALL units
- Enables parallel unit construction

### Multi-Unit Execution
**Sequential**: Units with dependencies execute in priority order
**Parallel**: Independent units execute simultaneously

Dependency analysis → Sequencing → Parallel execution where possible

### Review Before Complete
Construction is not complete when code compiles. After task execution, run an AIDLC review gate against the unit's `requirements.md`, `design.md`, `tasks.md`, and relevant foundation standards.

- In subagent mode, scope-check and re-run relevant verification after each task-group return; do not spawn a reviewer per group
- Run one broad delegated review after full executed-scope verification and before checkbox completion
- Treat review findings as implementation work, not optional commentary: fix gaps, then re-review

### State Tracking
**State File**: `aidlc-docs/aidlc-state.md`

Tracks: Current phase, completed steps, validation results, next actions

Enables: Workflow resumption, progress monitoring, audit trail

**Details**: [methodology-workflows.md](references/methodology-workflows.md)

## Artifact Organization

All outputs go to `aidlc-docs/` with phase-based structure:

```
aidlc-docs/
├── foundation/                    # Phase 0: Project context (5 files)
│   ├── project-overview-pdr.md
│   ├── codebase-summary.md        # brown-field only
│   ├── system-architecture.md
│   ├── code-standards.md
│   └── uiux-guideline.md          # optional
├── brainstorming/                 # Phase 1 (optional): Decision records
├── story-artifacts/               # Phase 1: {id}_{name}_user_stories.md
├── requirements/                  # Phase 1: units decomposition, NFRs, risks
│   ├── {id}_{name}_units_decomposition.md
│   ├── nfr_requirements.md
│   └── risk_register.md           # optional
├── roadmap/                       # Phase 1 (optional): product_roadmap.md
├── design-artifacts/              # Phase 1/2 UX artifacts
│   └── prototype/{name}/          # optional visual prototypes
├── estimation/                    # Story, unit, and spec BCP reports
├── specs/                         # Phase 2: Per-unit specs
│   └── {unit-slug}/
│       ├── requirements.md        # generated by Bolt Planning, refined in Step 1
│       ├── mockup.html            # optional, for UI-bearing units
│       ├── design.md
│       ├── tasks.md
│       └── test-cases.md          # optional
├── operations/                    # Phase 3: Deployment & monitoring
└── aidlc-state.md                 # Workflow state (managed by AI Delivery Manager)
```

**Details**: [methodology-artifacts.md](references/methodology-artifacts.md)

## Reference Files

- **[methodology-workflows.md](references/methodology-workflows.md)** - Foundation, Inception, Construction workflows in detail
- **[methodology-artifacts.md](references/methodology-artifacts.md)** - Complete artifact structure and file naming

---

_MTV AI-DLC Methodology v2.0.0_
