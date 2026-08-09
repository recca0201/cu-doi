# Foundation Workflow Execution

Discover and document existing codebase, standards, and design system.

## Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Workflow Steps](#workflow-steps)
  - [Step 1: Product Overview and PDR (Required)](#step-1-product-overview-and-pdr-required)
  - [Step 2: Codebase Summary (Requires Existing Code)](#step-2-codebase-summary-requires-existing-code)
  - [Step 3: System Architecture Analysis (Required)](#step-3-system-architecture-analysis-required)
  - [Step 4: Code Standards Extraction (Required)](#step-4-code-standards-extraction-required)
  - [Step 5: UI/UX Guideline Documentation (Optional)](#step-5-uiux-guideline-documentation-optional)
- [Workflow Execution Strategies](#workflow-execution-strategies)
- [Orchestration Context](#orchestration-context)
- [Success Criteria](#success-criteria)
- [Integration with Next Phase](#integration-with-next-phase)

---

## Overview

**Purpose**: Establish comprehensive understanding of existing system before Inception phase.

**When to Use**:
- Starting AI-DLC on existing project (brown-field)
- Need to document current architecture and standards
- Documenting project context and requirements

**Key Steps**: 5 steps
- Step 1: Product Overview and PDR (required)
- Step 2: Codebase Summary (requires existing code)
- Step 3: System Architecture (required)
- Step 4: Code Standards (required)
- Step 5: UI/UX Guidelines (optional)

**Note**: Steps 2-4 can be created for green-field projects if user provides architecture/standards information

---

## Prerequisites

**Required**:
- Existing codebase accessible
- Read access to project files

**Optional**:
- Documentation files (PDF, Word, Excel, PowerPoint)
- Architecture diagrams
- Requirements documents

---

## Workflow Steps

### Step 1: Product Overview and PDR (Required)

**Agent**: ai-assistant-product-owner
**Skill**: aidlc-foundation-context
**Command**: `/aidlc.foundation.product-overview`

**Purpose**: Analyze business domain and document product requirements

**Inputs**:
- Project codebase (if exists)
- Documentation files (if provided)
- User input about product

**Process**:
1. Analyze business domain and purpose
2. Document key features and capabilities
3. Identify user personas and workflows
4. Extract Product Development Requirements (functional and non-functional)
5. Document data models and entities
6. Parse documentation if provided (PDF, Excel, Word, PowerPoint)

**Outputs**:
- `aidlc-docs/foundation/project-overview-pdr.md`

**Next Step**: Step 2 (Codebase Summary) if brown-field, or Step 3 (System Architecture)

**Validation**: **REQUIRED** - Human approval to validate product understanding

---

### Step 2: Codebase Summary (Requires Existing Code)

**Agent**: ai-solutions-architect
**Skill**: aidlc-foundation-context
**Command**: `/aidlc.foundation.codebase-summary`

**Purpose**: Scan and analyze existing codebase structure and tech stack

**Inputs**:
- Project codebase files
- Package manifests (package.json, requirements.txt, pom.xml, etc.)

**Process**:
1. Scan folder structure and file organization
2. Identify project type (React, Vue, Node.js, Python, etc.)
3. Analyze package manifests
4. Identify frameworks, libraries, and dependencies
5. Document tech stack versions
6. Identify build tools and CI/CD setup
7. Map module/component dependencies

**Outputs**:
- `aidlc-docs/foundation/codebase-summary.md`

**Next Step**: Step 3 (System Architecture)

**Validation**: Optional - Automated analysis

---

### Step 3: System Architecture Analysis (Required)

**Agent**: ai-solutions-architect
**Skill**: aidlc-foundation-context
**Command**: `/aidlc.foundation.system-architecture`

**Purpose**: Document architecture patterns and system design

**Inputs**:
- `foundation/codebase-summary.md` (from Step 2, if exists)
- Codebase files
- User-provided architecture information

**Process**:
1. Identify architecture patterns (MVC, microservices, monolith, etc.)
2. Document system components and their interactions
3. Map integration points and external dependencies
4. Analyze data flow and communication patterns
5. Document deployment architecture
6. Create architecture diagrams (using Mermaid)

**Outputs**:
- `aidlc-docs/foundation/system-architecture.md`

**Next Step**: Step 4 (Code Standards)

**Validation**: **REQUIRED** - Human approval to review architecture findings

---

### Step 4: Code Standards Extraction (Required)

**Agent**: ai-solutions-architect
**Skill**: aidlc-foundation-context
**Command**: `/aidlc.foundation.code-standards`

**Purpose**: Extract and document coding conventions and standards

**Inputs**:
- `foundation/codebase-summary.md` (from Step 2, if exists)
- Codebase files
- User-provided standards information

**Process**:
1. Analyze code style and formatting conventions
2. Document naming conventions
3. Identify file organization patterns
4. Extract testing standards
5. Document API conventions (REST, GraphQL)
6. Identify database patterns
7. Document security practices

**Outputs**:
- `aidlc-docs/foundation/code-standards.md`

**Next Step**: Step 5 (UI/UX Guidelines)

**Validation**: Optional - Automated extraction

---

### Step 5: UI/UX Guideline Documentation (Optional)

**Agent**: ai-design-orchestrator
**Skill**: aidlc-foundation-context
**Command**: `/aidlc.foundation.uiux-guideline`

**Purpose**: Document design system and UI/UX patterns

**Inputs**:
- UI component files
- Style files (CSS, SCSS, styled-components)
- Design system documentation

**Process**:
1. Inventory UI components (buttons, forms, cards, etc.)
2. Extract color palette and typography
3. Document spacing and layout patterns
4. Identify icon system
5. Document animation and interaction patterns
6. Identify responsive breakpoints
7. Document accessibility standards

**Outputs**:
- `aidlc-docs/foundation/uiux-guideline.md`

**Next Step**: Inception phase

**Validation**: **REQUIRED** - Human approval to validate design system

---

## Workflow Execution Strategies

### Brown-field Project (Existing Codebase)

**Pattern**:
```
Step 1 (Product Overview) → Step 2 (Codebase Summary) → Step 3 (Architecture) → Step 4 (Standards) → Step 5 (UI/UX)
```

**When**: Starting AI-DLC on existing project

**Example**:
- Step 1: Document product overview from codebase
- Step 2: Analyze existing tech stack and structure
- Step 3: Extract architecture patterns
- Step 4: Document coding conventions
- Step 5: Document design system (if UI exists)
- → Proceed to Inception

---

### Green-field Project (New Project)

**Pattern**:
```
Step 1 (Product Overview) → Step 3 (Architecture) → Step 4 (Standards) → Step 5 (UI/UX)
```

**When**: Starting new project without existing code

**Example**:
- Step 1: Document product requirements and PDR
- Step 3: Define target architecture (user provides info)
- Step 4: Define coding standards (user provides info)
- Step 5: Define design system (if applicable)
- → Proceed to Inception

**Note**: Skip Step 2 (Codebase Summary) as no existing code to analyze

---

### Parallel Execution (Optional Optimization)

**Pattern**:
```
Step 1 → ┌─ Step 2 (Codebase)
         ├─ Step 3 (Architecture)
         └─ Step 4 (Standards)
         → Step 5 (UI/UX)
```

**When**: Steps 2, 3, 4 are independent and can run simultaneously

**Note**: Step 1 must complete first (provides context for all other steps)

---

## Orchestration Context

### Agent Selection

**Per Step** (from `references/agent-mapping.md`):
- Step 1: ai-assistant-product-owner (business domain expertise)
- Step 2: ai-solutions-architect (technical analysis)
- Step 3: ai-solutions-architect (architecture patterns)
- Step 4: ai-solutions-architect (technical conventions)
- Step 5: ai-design-orchestrator (design system expertise)

### Validation Checkpoints

**Per Step**:
- Step 1: **REQUIRED human approval** ⚠️
- Step 2: Optional validation
- Step 3: **REQUIRED human approval** ⚠️
- Step 4: Optional validation
- Step 5: **REQUIRED human approval** ⚠️

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
✅ Product overview created
Output: foundation/project-overview-pdr.md

⚠️  Human approval required before proceeding

Please review:
- Product features and capabilities
- User personas
- Product Development Requirements

Approve to continue? [Y/n]
```

**Example After Step 2**:
```
✅ Codebase analyzed
Output: foundation/codebase-summary.md

Next: Step 3 - System Architecture Analysis
Agent: ai-solutions-architect

Proceed with architecture analysis? [Y/n]
```

**Example After Step 5**:
```
✅ UI/UX guidelines documented
Output: foundation/uiux-guideline.md

⚠️  Human approval required before proceeding

Please review:
- Design system components
- Color palette and typography
- Accessibility standards

Foundation phase complete. Ready to proceed to Inception phase? [Y/n]
```

---

## Success Criteria

- [ ] Project overview created
- [ ] Codebase structure mapped (if existing code)
- [ ] Tech stack identified (if existing code)
- [ ] Architecture patterns documented
- [ ] Technical standards defined
- [ ] Design system captured (if applicable)
- [ ] Ready to proceed to Inception phase

---

## Integration with Next Phase

**To Inception** (outputs used):
- Product Overview → Informs user story creation
- Technical Standards → Guide implementation
- Design System → Influences UI/UX requirements
- Codebase Structure → Helps identify unit boundaries
- Architecture → Informs technical design decisions

---

_Foundation Workflow Execution - MTV AI-DLC v2.1.0_
