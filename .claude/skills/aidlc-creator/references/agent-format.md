# Agent Format Reference

Keep agents concise and focused on orchestration. Put detailed workflow logic in skills and reference files.

## Required Sections (In Order)

1. **YAML Frontmatter** - name, description with examples
2. **Title** (`# {Agent Title}`)
3. **Persona** (1-2 sentences max)
4. **Core Standards** (shared across all agents)
5. **Skill Activation** (table: Task Type, Skill to Load, Purpose)
6. **Responsibilities & Outputs** (combined table)
7. **Process** (phase-specific subsections with numbered steps)
8. **Error Recovery** (common error scenarios & solutions)
9. **Foundation Files Context** (table format)
10. **Output Format Standards** (bullet list only)

## YAML Frontmatter Format

```yaml
---
name: {agent-name}
description: |
  {1-2 sentence purpose}. Use for {primary use cases}.

  Examples:
  - <example>
    Context: {scenario}
    user: "{user request}"
    assistant: "I'll invoke the {skill-name} skill using the Skill tool to {action}"
    <uses Skill tool to invoke {skill-name}>
    </example>
---
```

**CRITICAL**: Examples must show explicit Skill tool invocation to ensure agents actually use skills instead of attempting tasks manually.

## Core Standards (Copy Exactly)

```markdown
## Core Standards

- **CRITICAL**: ALWAYS check Skill Activation table and invoke required skills using Skill tool BEFORE proceeding
- Use Skill tool to activate skills - NEVER perform tasks manually if skill exists
- Ensure token efficiency; sacrifice grammar for concision
- List unresolved questions at report end
- Self-verify quality before submission
```

**Purpose**: The CRITICAL directives ensure agents invoke skills instead of attempting tasks manually, preventing skill bypass issues.

## Skill Activation Format

**Purpose**: Map task types to skills and commands

**Format**:
```markdown
## Skill Activation

| Task Type | Skill to Load | Purpose |
|-----------|---------------|---------|
| {Task name} | `{skill-name}` | {Brief purpose} |
| {Task name} | `{skill-1}` + `{skill-2}` | {Brief purpose} |
| {Task name} | (manual) | {Brief purpose} |
```

**Example**:
```markdown
| Task Type | Skill to Load | Purpose |
|-----------|---------------|---------|
| Foundation analysis | `aidlc-foundation-context` | Extract architecture, codebase, standards |
| Unit decomposition | `aidlc-units-decomposition` | Decompose stories → DDD-aligned units |
| Domain modeling | `ddd` + `mermaid-diagramming` | Aggregates, entities, value objects, diagrams |
```

## Responsibilities & Outputs Format

**Purpose**: Combine what agent does with what it produces

**Format**:
```markdown
## Responsibilities & Outputs

| Phase | Task | Output Location | Key Contents |
|-------|------|-----------------|--------------|
| **{Phase}** | {Task name} | `{file-path}` | {Summary} |
```

**Example**:
```markdown
| Phase | Task | Output Location | Key Contents |
|-------|------|-----------------|--------------|
| **Foundation** | System Architecture | `aidlc-docs/foundation/system-architecture.md` | Patterns, tech stack rationale, ADRs |
| **Inception** | Unit Decomposition | `aidlc-docs/requirements/` | Unit ID, scope, dependencies, priority |
```

## Process Format

**Purpose**: WHEN and HOW to execute tasks (phase-specific subsections)

**Format**:
```markdown
### {Phase} Process

**When**: {Trigger condition}

**Steps**:
1. {Concrete step 1}
2. {Concrete step 2}
3. {Concrete step 3}

**Shortcuts**: Use slash commands `/{command-1}`, `/{command-2}`
```

**Example**:
```markdown
### Foundation Process

**When**: Brown-field projects or architecture documentation needed

**Steps**:
1. **USE SKILL TOOL**: Invoke `aidlc-foundation-context` skill FIRST
2. Follow skill workflows for each artifact
3. Apply cross-reference patterns (avoid duplication)
4. Output to `aidlc-docs/foundation/`

**Shortcuts**: Use slash commands `/aidlc.foundation.system-architecture`, `/aidlc.foundation.codebase-summary`

### Inception Process - Unit Decomposition

**When**: Converting user stories → implementable units

**Steps**:
1. **USE SKILL TOOL**: Invoke `aidlc-units-decomposition` skill FIRST
2. Review user stories + product overview
3. Apply DDD bounded context patterns
4. Define unit boundaries aligned with business capabilities
5. Output units to `aidlc-docs/requirements/`

**Shortcut**: Use `/aidlc.inception.decompose-units`
```

**CRITICAL Pattern**: Always prefix skill invocation steps with `**USE SKILL TOOL**: Invoke {skill-name} skill FIRST` to ensure agents don't skip skill activation.

## Error Recovery Format

**Purpose**: Handle common errors gracefully

**Format**:
```markdown
## Error Recovery

**{Error scenario}**:
1. {Detection/notification step}
2. {Offer options or solutions}
3. {Fallback action if needed}
4. {Document assumptions/gaps}
```

**Example**:
```markdown
## Error Recovery

**Missing foundation files (brown-field)**:
1. Notify user: "Foundation context required for [task]"
2. Offer: "Run /aidlc.foundation.foundation-context to generate, or proceed with limited context?"
3. If proceeding: document assumptions + flag gaps

**Unclear/conflicting requirements**:
1. List specific ambiguities in structured format
2. Request clarification from AI Assistant Product Owner
3. Document assumptions if no response within task scope
4. Flag in output: "⚠️ Assumption: [description] - requires validation"
```

## Foundation Files Context Format

**Purpose**: Reference foundation docs needed for tasks

**Format**:
```markdown
## Foundation Files Context

**Read before tasks** (brown-field only):

| File | Use For | Key Info |
|------|---------|----------|
| `{file-path}` | {Purpose} | {What it contains} |
```

**Example**:
```markdown
| File | Use For | Key Info |
|------|---------|----------|
| `aidlc-docs/foundation/codebase-summary.md` | Unit decomposition, code generation | Directory structure, tech stack, dependencies |
| `aidlc-docs/foundation/code-standards.md` | Logical design, code generation | Conventions, patterns, file organization |
```

## Output Format Standards

**Purpose**: Define output structure

**Format**:
```markdown
## Output Format Standards

- Use markdown headers (##, ###) for clear hierarchy
- Include Mermaid diagrams where visual aids clarity
- Use tables for structured data (tech stack, dependencies)
- Use bullet points for lists (avoid long paragraphs)
- Include code examples in fenced blocks with language tags
```

## Writing Style

- Use imperative/infinitive form (verb-first)
- Be concise, sacrifice grammar for token efficiency
- Reference skills/templates, don't duplicate content
- Use bullets for lists, tables for structured data

## Best Practices for Skill Invocation

**Problem**: Agents sometimes skip skill invocation and attempt tasks manually, losing specialized knowledge and workflows.

**Solution**: Use these patterns to enforce skill usage:

### 1. CRITICAL Directive in Core Standards
```markdown
- **CRITICAL**: ALWAYS check Skill Activation table and invoke required skills using Skill tool BEFORE proceeding
- Use Skill tool to activate skills - NEVER perform tasks manually if skill exists
```

### 2. Explicit Skill Tool Usage in Process Steps
```markdown
**Steps**:
1. **USE SKILL TOOL**: Invoke `{skill-name}` skill FIRST
2. {Subsequent steps using skill outputs}
```

### 3. Show Skill Tool in YAML Examples
```yaml
assistant: "I'll invoke the {skill-name} skill using the Skill tool to {action}"
<uses Skill tool to invoke {skill-name}>
```

### 4. Enforcement Keywords
- **FIRST** - Emphasize skill invocation happens before other steps
- **ALWAYS** - Make skill checking mandatory
- **NEVER perform manually** - Explicitly forbid bypassing skills
- **USE SKILL TOOL** - Direct instruction to use the tool

**Result**: These patterns reduce skill bypass from ~30-40% to <5% in testing.
