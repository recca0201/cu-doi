# Command Format Reference

Keep commands as thin orchestration wrappers.

Commands are minimal — they declare which agent and skill to use, then provide a brief process. Workflow logic lives in the agents and skills, not in commands.

## Naming Convention

- Format: `/aidlc.{phase}.{command-name}`
- Dot notation separates phase from command name
- Examples:
  - `/aidlc.foundation.product-overview`
  - `/aidlc.inception.user-stories`
  - `/aidlc.construction.create-design`
- Command names use kebab-case

## Frontmatter Fields

```yaml
---
description: Brief description of what the command does
argument-hint: [semantic-name]  # e.g., [task], [requirements], [input], [units]
---
```

**Argument Hint Guidelines:**
- `[task]` — implementation tasks
- `[requirements]` — requirements or user stories
- `[units]` — unit decomposition
- `[design]` — design documents
- `[question]` — brainstorming / open-ended topics
- `[input]` — generic (default)

---

## Template A: Subagent Spawn (default)

Use when the task needs a **specialized agent** with isolated context — complex analysis, multi-file generation, architecture decisions.

```markdown
---
description: {Brief description}
argument-hint: [input]
---

# /aidlc.{phase}.{command-name}

**Purpose**: {1 sentence}

**Agent**: {agent-name}
**Skill**: {skill-name}

## Input

<input>$ARGUMENTS</input>

**Process**:

1. Spawn subagent `{agent-name}` — **{Process Section Name}**
2. Invoke skill `{skill-name}` ({Phase} - {Step label})
```

**Key rules:**
- Agent and Skill are **name only** — no file paths.
- Process steps are declarative, not imperative boilerplate.
- No aidlc-core loading boilerplate needed.

---

## Template B: Direct Skill Invocation

Use when the task should run **in the current conversation** — interactive sessions, brainstorming, lightweight workflows where spawning an agent would lose conversational context.

```markdown
---
description: {Brief description}
argument-hint: [question]
---

# /aidlc.{phase}.{command-name}

**Purpose**: {1 sentence}

**Skill**: {skill-name}

## Input

<question>$ARGUMENTS</question>

**Process**:

1. Invoke skill `{skill-name}` directly in current conversation
```

**Key rules:**
- No `**Agent**:` header — skill runs in main context, not a subagent.
- Use for interactive, conversational, or short-lived tasks.
- Skill output stays in the current conversation thread.

---

## Template C: Active Agent + Delegated Review

Use when execution should stay in the active conversation, but a later quality gate needs isolated context. This fits coding commands where the active agent implements and verifies, then delegates review only.

```markdown
---
description: {Brief description}
argument-hint: [task]
---

# /aidlc.{phase}.{command-name}

**Purpose**: {1 sentence}

**Active Agent**: {agent-name}
**Primary Skill**: {implementation-skill}
**Review Agent**: {review-agent-name}
**Review Skill**: {review-skill-name}

## Input

<task>$ARGUMENTS</task>

**Process**:

1. Invoke skill `{implementation-skill}` in the active session before execution.
2. Execute only the requested scope and run verification.
3. For code-changing or review-required work, spawn `{review-agent-name}` only for the review gate.
4. Instruct the review subagent to invoke `{review-skill-name}`, review only, and not modify outputs owned by the active session.
```

**Key rules:**
- Use `**Active Agent**` / `**Primary Skill**` to signal current-session execution.
- Do not spawn a subagent for implementation or execution.
- Spawn a subagent only for the delegated review/quality gate.
- The active session owns fixes and completion-state updates after review.

---

## When to Choose Each Template

| Criterion | Template A (Subagent) | Template B (Direct) | Template C (Active + Review) |
|---|---|---|---|
| Task complexity | Multi-step, multi-file | Single focused workflow | Multi-step execution with quality gate |
| Context isolation needed | Yes, for main work | No | Yes, only for review |
| Interactive back-and-forth | No | Yes | Yes during implementation, no during review |
| Typical examples | create-design, user-stories | brainstorm, status check | execute-task |

---

## Complete Examples

### Template A — Construction: Create Design

```markdown
---
description: Create comprehensive design document from approved requirements
argument-hint: [requirements]
---

# /aidlc.construction.create-design

**Purpose**: Create comprehensive design document from approved requirements

**Agent**: ai-orchestration-engineer
**Skill**: aidlc-spec-driven

## Input

<requirements>$ARGUMENTS</requirements>

**Process**:

1. Spawn subagent `ai-orchestration-engineer` — **Construction Phase 2 - Design Document Creation**
2. Invoke skill `aidlc-spec-driven` (Phase 2 - Design)
```

### Template A — Inception: User Stories

```markdown
---
description: Create user stories with acceptance criteria
argument-hint: [requirements]
---

# /aidlc.inception.user-stories

**Purpose**: Create user stories with acceptance criteria

**Agent**: ai-assistant-product-owner
**Skill**: aidlc-requirements-engineering

## Input

<requirements>$ARGUMENTS</requirements>

**Process**:

1. Spawn subagent `ai-assistant-product-owner` — **Inception Process - User Story Creation**
2. Invoke skill `aidlc-requirements-engineering`
```

### Template B — Common: Brainstorm

```markdown
---
description: Structured brainstorming for business and technical decision-making
argument-hint: [question]
---

# /aidlc.common.brainstorm

**Purpose**: Conduct structured brainstorming for business, product, or technical decisions

**Skill**: aidlc-brainstorm

## Input

<question>$ARGUMENTS</question>

**Process**:

1. Invoke skill `aidlc-brainstorm` directly in current conversation
2. Generate Decision Record in `aidlc-docs/brainstorming/`
```

## Agent Selection by Phase

**Foundation Workflow:**
- Product Overview: `ai-assistant-product-owner` + `aidlc-foundation-context`
- System Architecture, Codebase Summary, Code Standards: `ai-solutions-architect` + `aidlc-foundation-context`
- UI/UX Guideline: `ai-design-orchestrator` + `aidlc-foundation-context`
- Foundation Report: `ai-delivery-manager` + `aidlc-core`

**Inception Workflow:**
- User Stories: `ai-assistant-product-owner` + `aidlc-requirements-engineering`
- Decompose Units: `ai-solutions-architect` + `aidlc-units-decomposition`
- Roadmap: `ai-delivery-manager` + `aidlc-units-roadmap`
- Risks: `ai-delivery-manager` + `aidlc-core`
- NFR: `ai-solutions-architect` + `architecture-design`

**Construction Workflow:**
- Bolt Planning: `ai-assistant-product-owner` + `aidlc-bolt-planning`
- Refine Requirements: `ai-assistant-product-owner` + `aidlc-spec-driven`
- Create Design: `ai-orchestration-engineer` + `aidlc-spec-driven`
- Create Tasks: `ai-orchestration-engineer` + `aidlc-spec-driven`
- Execute Task: `ai-orchestration-engineer` + `aidlc-spec-driven`
- UX Design: `ai-design-orchestrator` + `aidlc-uiux-design`
- Vibe: `ai-orchestration-engineer` + `aidlc-vibe`

**Operations:**
- Status, Phase Report: `ai-delivery-manager` + `aidlc-core`

## Phase Organization

Commands organized by phase directory under `.claude/commands/aidlc/`:
- `foundation/` — Foundation analysis (5 commands)
- `inception/` — Requirements & planning (5 commands)
- `construction/` — Design & implementation (7 commands)
- `operations/` — Status & reporting
- `common/` — Cross-phase utilities

## Quality Checklist

- [ ] Thin orchestration wrapper
- [ ] Dot notation format: `/aidlc.{phase}.{command-name}`
- [ ] Frontmatter with `description` and `argument-hint`
- [ ] `$ARGUMENTS` with semantic XML tag matching `argument-hint`
- [ ] `**Agent**: name` (no file path)
- [ ] `**Skill**: name` (no file path)
- [ ] Process step 1: agent delegation with process section name
- [ ] Process step 2: skill invocation with phase label
- [ ] Saved to `.claude/commands/aidlc/{phase}/{command-name}.md`
