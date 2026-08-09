# BCP Methodology Overview

## What is Business Complexity Points (BCP)?

BCP is a normalized framework for objectively measuring software complexity through a business lens. Unlike Story Points, which are subjective and prevent cross-team analysis, BCP provides:

1. **Standardized measurement** - Consistent across teams and projects
2. **Business-focused** - Analyzes complexity from business functionality perspective
3. **Objective criteria** - Clear sizing guidelines for each dimension
4. **Normalized units** - Enables performance comparison and improvement tracking
5. **Fibonacci-based** - Uses proven Fibonacci sequence (1, 2, 3, 5, 8)

## Core Principles

### 1. Business Lens Analysis
BCP analyzes complexity through functional aspects rather than technical implementation:
- Business rules complexity
- User interface requirements
- Domain model richness
- Integration boundaries
- Background automation needs

### 2. 10-Dimension Framework
Every user story/requirement is assessed across 10 standardized dimensions:
1. Business Rules
2. Interface Elements
3. Roles/Permissions
4. Solution Variabilities
5. Domain Entities
6. New Domain Entities
7. Boundaries
8. Background Processes
9. Notifications
10. Audits

### 3. T-Shirt Sizing with Points
Each dimension uses T-shirt sizes mapped to Fibonacci points:
- **XS = 1 point** - Minimal complexity
- **S = 2 points** - Simple implementation
- **M = 3 points** - Moderate complexity
- **L = 5 points** - Complex implementation
- **XL = 8 points** - Very complex implementation
- **N/A = 0 points** - Not applicable

### 4. Occurrences Multiplier
Some dimensions count multiple occurrences:
- **Interface Elements**: Every 5 elements = 1 occurrence
- **New Domain Entities**: Every 3 entities = 1 occurrence
- **Background Processes**: Each process = 1 occurrence
- **Notifications**: Each notification type = 1 occurrence
- **Audits**: Each audited entity = 1 occurrence

**Formula:** `Dimension_Points = Occurrences × T-Shirt_Size_Points`

## BCP vs Story Points

| Aspect | Story Points | Business Complexity Points |
|--------|--------------|---------------------------|
| **Measurement basis** | Effort (work + complexity + risk) | Business functionality complexity |
| **Standardization** | Team-dependent, subjective | Normalized, objective criteria |
| **Cross-team comparison** | Not possible | Fully comparable |
| **Sizing approach** | Relative estimation | Absolute T-shirt sizing |
| **Learning curve** | Requires team calibration | Clear criteria from day 1 |
| **Continuous improvement** | Hard to demonstrate | Measurable productivity trends |

## When to Use BCP

### Use BCP for:
✅ **Standardized estimation** across multiple teams
✅ **Objective complexity assessment** independent of implementation
✅ **Performance analysis** and productivity tracking
✅ **Capacity planning** with normalized units
✅ **Cross-project comparison** and benchmarking
✅ **Vendor/contractor evaluation** with clear metrics

### Consider Story Points for:
⚠️ **Single-team contexts** where relative sizing works well
⚠️ **Time-boxed sprints** with established velocity
⚠️ **Simple projects** not requiring cross-team analysis

## BCP Calculation Process

### Step 1: Read the Requirement
Understand the user story, unit, or spec thoroughly:
- What business problem does it solve?
- What functionality is being added/changed?
- What are the acceptance criteria?

### Step 2: Assess Each Dimension
For each of the 10 dimensions:
1. Determine if it applies (or mark N/A)
2. Count occurrences if applicable
3. Select appropriate T-shirt size based on criteria
4. Calculate points: `Occurrences × Size_Points`
5. Document rationale for sizing decision with concrete evidence

Use evidence such as AC/REQ/US IDs, `requirements.md`, `design.md`, `tasks.md`, source file paths, or an explicit `evidence` list in the report JSON. Avoid unsupported rationales like "simple workflow" without a traceable source.

### Step 3: Sum Total BCP
Add up points from all 10 dimensions:
```
Total BCP = Σ (Dimension_Points)
```

### Step 4: Review and Validate
- Does the total BCP feel proportional to complexity?
- Are mandatory dimensions covered?
- Is rationale clear for future reference?
- Do occurrence counts, allowed sizes, and points match the calculator rules?

## Mandatory vs Other Dimensions

### Always Consider (Mandatory)
These dimensions must have non-N/A values for every story:
1. ✅ Roles/Permissions
2. ✅ Solution Variabilities
3. ✅ Domain Entities
4. ✅ Boundaries

**Minimum valid BCP:** Requires these 4 mandatory dimensions with non-N/A values

### Other Assessed Dimensions
These apply when relevant or when the calculator permits a non-N/A value:
1. Business Rules
2. Interface Elements
6. New Domain Entities (if creating/modifying entities)
8. Background Processes (if automated processing needed)
9. Notifications (if alerting required)
10. Audits (if audit trail needed)

## Typical BCP Ranges

Based on analysis of real-world stories:

| Complexity | BCP Range | Characteristics |
|------------|-----------|----------------|
| **Trivial** | 1-10 | Simple CRUD, minimal business rules, few UI elements |
| **Simple** | 11-25 | Basic workflow, simple validations, standard UI |
| **Moderate** | 26-50 | Multiple decision points, moderate UI, some integrations |
| **Complex** | 51-100 | Rich business logic, complex UI, multiple integrations |
| **Very Complex** | 101+ | Extensive workflows, sophisticated UI, many entities/integrations |

## Integration with AIDLC

BCP can be applied at multiple AIDLC phases:

### Inception Phase
- **User Stories Level**: Estimate each story for backlog prioritization
- **Units Level**: Estimate units for sprint planning

### Construction Phase
- **Requirements Level**: Validate estimates after requirements refinement
- **Design Level**: Adjust estimates based on technical design decisions
- **Task Level**: Break down BCP across implementation tasks

## Benefits of BCP in AIDLC

1. **Early visibility** - Complexity known before implementation starts
2. **Prioritization input** - Higher BCP stories may need more planning
3. **Resource allocation** - Assign appropriate expertise to complex units
4. **Risk identification** - Very high BCP may indicate need for decomposition
5. **Progress tracking** - BCP completed vs remaining
6. **Retrospective analysis** - Actual effort vs BCP for calibration

## Summary

Business Complexity Points provides a standardized, objective approach to measuring software complexity through a business lens. The methodology's 10-dimension framework with T-shirt sizing enables consistent estimation across teams, projects, and phases of development.
