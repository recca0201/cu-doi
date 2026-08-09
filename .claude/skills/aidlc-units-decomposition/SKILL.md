---
name: aidlc-units-decomposition
description: |
  Decomposes user stories into independent, loosely coupled implementation units using DDD bounded context patterns. Use this skill proactively whenever:
  - Breaking down user stories into implementable units during AI-DLC Inception Phase
  - Defining unit boundaries, dependencies, and interfaces
  - Creating unit dependency maps and execution prioritization
  - Analyzing which work can run in parallel vs. must be sequential
  - A user says "break down stories into units", "define units", "unit decomposition", "decompose features", or "what units do we need"
  - Any Inception Phase work where user stories exist but implementation units haven't been defined yet
---

# Units Decomposition

Decompose user stories into independent, implementable units using DDD bounded context patterns.

**Unit**: Cohesive, self-contained work element analogous to DDD Bounded Contexts - loosely coupled, highly cohesive, independently deployable, buildable by a single team.

## When to Clarify

Check context before asking. If `aidlc-docs/foundation/team-info.md` exists and team size is recorded, skip the team size question. Only ask when information is genuinely missing and ambiguous:

- **Team size** (if not in team-info.md): needed to calibrate unit count — fewer devs → fewer units
- **Unit boundaries**: only if two or more groupings seem equally plausible
- **Domain boundaries**: only if stories clearly span capabilities with no obvious split

When asking, use AskUserQuestion with 2–4 options based on DDD patterns. Mark the recommended option. Include "Other" for custom input.

**Save team size for reuse** — when first confirmed, write to `aidlc-docs/foundation/team-info.md`:

```markdown
# Team Information

## Team Size
**Developers in the team**: {number}

## Unit Sizing Guidance
- **Fewer developers (2-3)**: Fewer units, prioritize sequential execution
- **More developers (4-5)**: Can handle parallel execution across more units
- **Large teams (6+)**: Can manage many units simultaneously
```

## Workflow

### 1. Analyze Inputs

1. **Check team size** (CRITICAL):
   - Check if `aidlc-docs/foundation/team-info.md` exists
   - If NOT exists or team size missing, ask user via AskUserQuestion
   - Save answer for future use
2. **Read and track user stories**: Read user story artifacts and **track file paths** for "Source Artifacts" section
3. Read system architecture (`aidlc-docs/foundation/system-architecture.md`)
4. **Clarify unclear scope** if needed (see "When to Clarify")
5. Identify domain concepts and business capabilities
6. Group related stories by domain boundaries

### 2. Apply Bounded Context

Use DDD bounded context to identify unit boundaries. If `.claude/skills/ddd/references/bounded-context.md` exists, read it for detailed patterns. Otherwise use these key heuristics:

- **Domain language**: where vocabulary shifts, a boundary often exists (e.g., "order" in sales vs. "order" in fulfillment are different concepts)
- **Aggregates**: group data and behavior that must change together (e.g., cart + cart items)
- **Transaction boundaries**: if two things must be consistent in the same operation, keep them in one unit
- **Ownership**: which team or capability naturally owns this? That's often a unit boundary

### 3. Define Units

For each unit, document (see `references/unit-criteria.md`):
- **Purpose**: one-sentence business capability statement
- **Value Proposition**: "As a [user type], I can [capability] so that [outcome]"
- **Scope**: 2-5 bullet points describing what's included
- **User Stories**: list by ID and title (min 2-4; brownfield exception: 1 is acceptable)
- **Dependencies**: other units this unit requires (or "None")
- **Technical Risk**: Low / Medium / High
- **Deployable Independently**: always YES — if NO, merge with the feature unit it depends on

### 4. Map Dependencies

Create dependency map showing:
- Sequential dependencies (must be built in order)
- Parallel opportunities (can be built simultaneously)
- Use Mermaid `graph TD` for visualization

### 5. Prioritize Units

Priority by:
1. Dependency Order (no dependencies first)
2. Risk Mitigation (higher-risk earlier)
3. Parallel Opportunities (identify independent units)

### 6. Verify Decomposition

See `references/unit-criteria.md` for complete checklist:
- ✅ Deployable Independently = YES
- ✅ Passes Independent Value Test
- ✅ Has minimum 2-4 stories (can have more; exception: 1 for brownfield)
- ✅ Value Proposition uses template format
- ✅ Vertical Slice complete (UI + Domain + Infrastructure)
- ✅ No circular dependencies

**If any critical check fails**: Re-decompose and merge units until all pass

## Output Format

### Scaffold with CLI

Use `scripts/units_decomp_cli.py` to create the output file deterministically:

```bash
python .claude/skills/aidlc-units-decomposition/scripts/units_decomp_cli.py init FEATURE_SLUG
```

The CLI:
- Resolves the AI-DLC docs root (same precedence as aidlc-quick-spec: `--docs-root` → `.mtv-aidlc/extension-config.json` `aidlcDocsPath` → `aidlc-docs`)
- Auto-assigns the next 3-digit ID by scanning existing `NNN_*_units_decomposition.md` files
- Accepts `--id NNN` to override the ID
- Renders metadata frontmatter via `_aidlc-shared/scripts/artifact_metadata.py`
- Does not overwrite an existing file

After `init`, replace every placeholder in the scaffolded file with real content.

**Output location**: `{docs-root}/requirements/{id}_{feature-slug}_units_decomposition.md`

Check status of an existing artifact:

```bash
python .claude/skills/aidlc-units-decomposition/scripts/units_decomp_cli.py status FEATURE_SLUG --id NNN
```

### Document Structure (follow this order)

1. **Summary**: Key insights (parallel execution, foundation units, risks) at the top
2. **Unit Prioritization**: Table with User Story IDs, dependencies, risk, rationale
3. **Unit Dependency Map**: Mermaid graph showing sequential/parallel relationships
4. **Source Artifacts**: List of user story files analyzed for this decomposition
5. **Unit Structure**: Detailed unit definitions with purpose, scope, stories, dependencies
6. **Next Steps**: Validation and roadmap planning actions

**IMPORTANT**:
- Follow template structure exactly
- **Include User Story IDs** in prioritization table (e.g., US-001, US-002)
- **Track source files**: List all user story artifact files used in "Source Artifacts" section
- Stay at business/domain level (no APIs, schemas, class diagrams)
- Use AI-DLC terminology only (no "sprint", "storypoint", "velocity")

## References

- `references/unit-criteria.md` - Sizing criteria, boundaries, validation checklist, value proposition templates
- `references/examples.md` - Good decomposition examples and anti-patterns to avoid
- `.claude/skills/ddd/references/bounded-context.md` - DDD bounded context patterns
- `assets/units_decomposition_template.md` - Output template
