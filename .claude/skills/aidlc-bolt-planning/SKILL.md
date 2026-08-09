---
name: aidlc-bolt-planning
description: |
  Generate specs folder structure from AI-DLC units and user stories. This skill should be used when planning bolt execution, organizing requirements by unit, or creating implementation specifications from units decomposition and user stories. Automatically extracts unit definitions, maps user stories to units, and generates specs/{unit-name}/requirements.md files containing all associated user stories in EARS-Lite format with hierarchical numbering. Supports both decimal IDs (1.1, 2.1, 3.2) and legacy US-XXX format.

  Examples:
  - <example>
    Context: User has completed units decomposition and needs to create specs.
    user: "Generate specs from the units decomposition"
    assistant: "Use aidlc-bolt-planning to parse units and create specs folder structure"
    </example>
  - <example>
    Context: User wants to organize requirements by unit for implementation.
    user: "Create requirements files for each unit"
    assistant: "Use aidlc-bolt-planning to generate requirements.md files per unit"
    </example>
version: 1.1.0
license: MIT
---

# AI-DLC Bolt Planning Skill

## Purpose

Generate structured specs folder from AI-DLC units decomposition and user stories. Parse unit definitions, extract associated user stories, and create organized requirement files for implementation planning.

## When to Use

Activate this skill when:

- Planning bolt execution after units decomposition
- Organizing requirements by unit for development
- Creating implementation specifications from user stories
- Preparing unit-specific requirement documents

## How to Use

### 1. Generate Specs Folder

Execute `scripts/generate_specs.py` to create specs folder structure:

```bash
python3 scripts/generate_specs.py \
  --units aidlc-docs/requirements/units-decomposition-{project}.md \
  --stories aidlc-docs/story-artifacts/user-stories-{project}.md
```

**Input Requirements**:
- Units decomposition file with format: `### **Unit N: Name**` and story listings:
  - Decimal format: `- **1.1**:`, `- **2.1**:`, `- **3.2**:` (decimal IDs like 1.1, 2.1)
  - Legacy format: `- US-XXX:` (also supported)
- User stories file with format:
  - Decimal format: `### Story 1.1: [Title]`, `### Story 2.1: [Title]` (decimal IDs with EARS-Lite)
  - Alternative: `### 1.1: [Title]` (without "Story" prefix)
  - Legacy format: `### US-XXX: Title` (also supported)
  - Optional external references: `Related ADO` / `Related Jira` lines may be present for sync scenarios and do not affect parsing

**Output Structure** (default: `aidlc-docs/specs/`):
```
aidlc-docs/specs/
├── unit-slug-1/
│   └── requirements.md
├── unit-slug-2/
│   └── requirements.md
└── unit-slug-n/
    └── requirements.md
```

**Custom Output** (optional):
```bash
# Specify custom output directory
python3 scripts/generate_specs.py \
  --units aidlc-docs/requirements/units-decomposition-{project}.md \
  --stories aidlc-docs/story-artifacts/user-stories-{project}.md \
  --output custom/path
```

### 2. Understand Output Format

Each `requirements.md` contains:
- Unit metadata (number, name, story IDs)
- Complete user stories with acceptance criteria
- EARS-Lite format with hierarchical numbering (1.1.1, 1.2.3)
- Structured sections with WHEN/IF/WHILE + SHALL keywords

See `assets/requirements_template.md` for structure.

### 3. EARS-Lite Format Reference

User stories use EARS-Lite (LLM-Optimized) for acceptance criteria with hierarchical numbering.

**Format**: `{ID}.{Section}.{Criterion}` (e.g., 1.1.1, 1.2.3)

**Keywords**: WHEN (event/trigger), IF (condition), WHILE (state), THEN (response), SHALL (requirement)

**Example**:
```markdown
**1.1 Authentication**

1.1.1 WHEN user enters credentials THEN system SHALL:
- Validate email format
- Check password ≥8 chars
- Verify against auth service

1.1.2 IF auth succeeds THEN system SHALL:
- Generate JWT (24h validity)
- Redirect to dashboard <1s
```

See `.claude/skills/aidlc-requirements-engineering/assets/user_story_template.md` for complete reference.

## Script Details

**`scripts/generate_specs.py`**:
- Parses units markdown to extract unit definitions and story mappings
- Parses user stories markdown to extract full story content
- **Supports both formats**: Numeric IDs (1, 2, 3) and legacy US-XXX format
- Creates aidlc-docs/specs/{unit-slug}/ directories (default location)
- Generates requirements.md with all associated user stories
- Validates story IDs and reports missing stories

**`scripts/test_generate_specs.py`**:
- Unit tests for parsing and generation logic
- Run with: `python3 scripts/test_generate_specs.py`

## Workflow Integration

**After**: Units decomposition (`/aidlc-decompose-units`)
**Before**: Construction phase, bolt execution

**Typical Flow**:
1. Complete user stories creation (using aidlc-requirements-engineering)
2. Complete units decomposition (using aidlc-units-decomposition)
3. Run this skill to generate specs
4. Use aidlc-docs/specs/{unit-name}/requirements.md for implementation

---

_AI-DLC Bolt Planning Skill v1.1.0_
