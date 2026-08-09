---
name: aidlc-creator
description: Create AI-DLC agents and commands following standard format with dot notation (/aidlc.{phase}.{command-name}). Use when creating new agents (system design, domain modeling), slash commands (workflow orchestration), or when user mentions AI-DLC agent/command creation.
---

# AI-DLC Creator

Create AI-DLC agents and commands following standard templates.

## When to Use

- Creating new AI-DLC agents for workflow orchestration
- Creating new slash commands for phase execution
- Updating existing agents/commands to match standards
- Understanding AI-DLC agent/command structure

## Agent Creation

**Script**: `scripts/create_agent.py`

```bash
python3 scripts/create_agent.py {agent-name} [--output-dir .claude/agents]
```

**Example**:
```bash
python3 scripts/create_agent.py ai-test-generator
```

**Format Reference**: `references/agent-format.md`

**Requirements**:
- Name in kebab-case
- Keep concise and focused on orchestration
- Follow standard section order
- Include YAML frontmatter with examples

## Command Creation

**Script**: `scripts/create_command.py`

Two templates are available — choose based on whether the task needs a subagent or runs directly in the current conversation.

```bash
python3 scripts/create_command.py {command-name} \
  [--phase foundation|inception|construction|operations|common] \
  [--mode subagent|direct] \
  [--output-dir .claude/commands/aidlc]
```

### Template A — Subagent Spawn (default, `--mode subagent`)

Use when the task needs isolated agent context: complex analysis, multi-file generation, architecture documents.

```bash
# Creates /aidlc.construction.create-design (spawns agent → invokes skill)
python3 scripts/create_command.py create-design --phase construction

# Creates /aidlc.inception.user-stories
python3 scripts/create_command.py user-stories --phase inception
```

### Template B — Direct Skill Invocation (`--mode direct`)

Use when the task should run **in the current conversation**: brainstorming, interactive sessions, lightweight workflows.

```bash
# Creates /aidlc.common.brainstorm (invokes skill directly, no subagent)
python3 scripts/create_command.py brainstorm --phase common --mode direct

# Creates /aidlc.inception.brainstorm
python3 scripts/create_command.py brainstorm --phase inception --mode direct
```

### Template C — Active Agent + Delegated Review (`--mode hybrid`)

Use when execution must stay in the active conversation, but a later review or quality gate needs isolated context.

```bash
# Creates a command like /aidlc.construction.execute-task
# Active session invokes the primary skill; only the review gate spawns a subagent
python3 scripts/create_command.py execute-task --phase construction --mode hybrid
```

**Format Reference**: `references/command-format.md`

**Requirements**:
- Name in kebab-case (without phase prefix)
- Command format: `/aidlc.{phase}.{command-name}` (dot notation)
- Keep as a thin orchestration wrapper
- Template A: Declare both `**Agent**` and `**Skill**`; 2-step process: spawn agent → invoke skill
- Template B: Declare only `**Skill**`; 1-step process: invoke skill directly in conversation
- Template C: Declare `**Active Agent**`, `**Primary Skill**`, optional review agent/skill headers, run execution in active session, and spawn a subagent only for the delegated review/quality gate
- Skill/agent names only — no file paths
- Organize by phase directory

**Output**: Commands saved to `.claude/commands/aidlc/{phase}/{command-name}.md`

## Standard Format Rules

**Agents**:
1. YAML frontmatter with examples showing Skill tool usage
2. Core Standards with CRITICAL skill invocation directives
3. 10 required sections in order
4. Use Skill Activation table (Task Type, Skill, Purpose)
5. Combine Responsibilities & Outputs in one table
6. Phase-specific Process subsections with "USE SKILL TOOL" prefixes
7. Include Error Recovery patterns
8. Reference skills, don't duplicate
9. Imperative/infinitive form

**Commands** (thin orchestration wrapper):
1. Use dot notation format: `/aidlc.{phase}.{command-name}`
2. Include frontmatter with `description` and `argument-hint` fields
3. Include `$ARGUMENTS` placeholder with semantic XML tags (e.g., `<input>$ARGUMENTS</input>`)
4. Choose one command template explicitly: Template A subagent, Template B direct skill, or Template C active agent plus delegated review
5. Keep process steps thin; commands route to agents/skills and avoid duplicating full workflow logic
6. No file paths in agent/skill references — names only (discovered via `.claude/` settings)
7. Organize by phase directory (foundation/inception/construction/operations/common)

## Progressive Disclosure

Load references only when needed:
- `references/agent-format.md` - Detailed agent structure
- `references/command-format.md` - Detailed command structure

Scripts generate templates with placeholders for customization.

## Quality Checks

**Agents**:
- [ ] Concise and focused on orchestration
- [ ] All 10 sections present in order
- [ ] YAML examples show explicit Skill tool invocation
- [ ] Core Standards include CRITICAL skill invocation directives
- [ ] Skill Activation table present (Task Type, Skill, Purpose)
- [ ] Responsibilities & Outputs combined in single table
- [ ] Process steps prefixed with "USE SKILL TOOL" where applicable
- [ ] Process uses phase-specific subsections
- [ ] Error Recovery patterns included
- [ ] Foundation Files Context in table format
- [ ] Output Format Standards as bullets only
- [ ] Skills referenced, not duplicated

**Commands (Template A — Subagent)**:
- [ ] Thin orchestration wrapper
- [ ] Dot notation format: `/aidlc.{phase}.{command-name}`
- [ ] Frontmatter with `description` and `argument-hint` fields included
- [ ] `$ARGUMENTS` placeholder with semantic XML tags included
- [ ] Argument tag matches `argument-hint` field
- [ ] `**Agent**: agent-name` header (name only, no file path)
- [ ] `**Skill**: skill-name` header (name only, no file path)
- [ ] Process step 1: `Spawn subagent \`name\` — **Process Section Name**`
- [ ] Process step 2: `Invoke skill \`name\`` with phase label
- [ ] Organized in correct phase directory

**Commands (Template B — Direct Skill)**:
- [ ] Thin direct skill wrapper
- [ ] Dot notation format: `/aidlc.{phase}.{command-name}`
- [ ] Frontmatter with `description` and `argument-hint` fields included
- [ ] `$ARGUMENTS` placeholder with semantic XML tags included
- [ ] Argument tag matches `argument-hint` field
- [ ] `**Skill**: skill-name` header (name only, no file path) — **NO `**Agent**:` header**
- [ ] Process step 1: `Invoke skill \`name\` directly in current conversation`
- [ ] Organized in correct phase directory

**Commands (Template C — Active Agent + Delegated Review)**:
- [ ] Thin hybrid orchestration wrapper
- [ ] Dot notation format: `/aidlc.{phase}.{command-name}`
- [ ] Frontmatter with `description` and `argument-hint` fields included
- [ ] `$ARGUMENTS` placeholder with semantic XML tags included
- [ ] `**Active Agent**: agent-name` header included
- [ ] `**Primary Skill**: skill-name` header included
- [ ] Review agent/skill headers included when the command has a delegated review gate
- [ ] Process invokes the primary skill in the active session before execution
- [ ] Process does not spawn a subagent for implementation/execution
- [ ] Process spawns a subagent only for the review or quality gate and constrains it to review-only work
- [ ] Organized in correct phase directory

## Preventing Skill Bypass

**Problem**: Agents sometimes skip skill invocation and attempt tasks manually, losing specialized knowledge.

**Solution Patterns**:

### 1. CRITICAL Directive (Core Standards)
```markdown
- **CRITICAL**: ALWAYS check Skill Activation table and invoke required skills using Skill tool BEFORE proceeding
- Use Skill tool to activate skills - NEVER perform tasks manually if skill exists
```

### 2. Explicit Process Steps
```markdown
1. **USE SKILL TOOL**: Invoke `skill-name` skill FIRST
2. {Subsequent steps}
```

### 3. Show Skill Tool in Examples
```yaml
assistant: "I'll invoke the {skill-name} skill using the Skill tool to {action}"
<uses Skill tool to invoke {skill-name}>
```

### 4. Enforcement Keywords
- **FIRST** - Emphasize skill invocation order
- **ALWAYS** - Make skill checking mandatory
- **NEVER perform manually** - Forbid skill bypass
- **USE SKILL TOOL** - Direct tool instruction

**Impact**: Reduces skill bypass from ~30-40% to <5%

See `references/agent-format.md` for detailed patterns and examples.
