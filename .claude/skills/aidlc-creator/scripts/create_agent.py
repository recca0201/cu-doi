#!/usr/bin/env python3
"""Create a new AI-DLC agent from template."""

import argparse
import sys
from pathlib import Path


def create_agent(name: str, output_dir: str) -> None:
    """Create a new agent file from template.

    Args:
        name: Agent name (kebab-case)
        output_dir: Output directory path
    """
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    agent_file = output_path / f"{name}.md"

    if agent_file.exists():
        print(f"❌ Error: Agent file already exists: {agent_file}")
        sys.exit(1)

    # Convert kebab-case to Title Case
    title = " ".join(word.capitalize() for word in name.split("-"))

    template = f"""---
name: {name}
description: |
  {{1-2 sentence purpose}}. Use for {{primary use cases}}.

  Examples:
  - <example>
    Context: {{scenario}}
    user: "{{user request}}"
    assistant: "I'll invoke the {{skill-name}} skill using the Skill tool to {{action}}"
    <uses Skill tool to invoke {{skill-name}}>
    </example>
---

# {title}

## Persona

{{1-2 sentences describing the agent's role}}

## Core Standards

- **CRITICAL**: ALWAYS check Skill Activation table and invoke required skills using Skill tool BEFORE proceeding
- Use Skill tool to activate skills - NEVER perform tasks manually if skill exists
- Ensure token efficiency; sacrifice grammar for concision
- List unresolved questions at report end
- Self-verify quality before submission

## Skill Activation

| Task Type | Skill to Load | Purpose |
|-----------|---------------|---------|
| {{Task name}} | `{{skill-name}}` | {{Brief purpose}} |
| {{Task name}} | `{{skill-1}}` + `{{skill-2}}` | {{Brief purpose}} |
| {{Task name}} | (manual) | {{Brief purpose}} |

## Responsibilities & Outputs

| Phase | Task | Output Location | Key Contents |
|-------|------|-----------------|--------------|
| **{{Phase}}** | {{Task name}} | `aidlc-docs/{{path}}/{{file}}.md` | {{Summary}} |

### {{Phase}} Process

**When**: {{Trigger condition}}

**Steps**:
1. {{Concrete step 1}}
2. {{Concrete step 2}}
3. {{Concrete step 3}}

**Shortcuts**: Use slash commands `/{{command-1}}`, `/{{command-2}}`

### {{Phase}} Process - {{Task Name}}

**When**: {{Trigger condition}}

**Steps**:
1. **USE SKILL TOOL**: Invoke `{{skill-name}}` skill FIRST
2. {{Concrete step 2}}
3. Output to `aidlc-docs/{{path}}/`

**Shortcut**: Use `/aidlc.{{phase}}.{{command}}`

## Error Recovery

**{{Error scenario}}**:
1. {{Detection/notification step}}
2. {{Offer options or solutions}}
3. {{Fallback action if needed}}
4. {{Document assumptions/gaps}}

## Foundation Files Context

**Read before tasks** (brown-field only):

| File | Use For | Key Info |
|------|---------|----------|
| `aidlc-docs/foundation/{{file}}.md` | {{Purpose}} | {{What it contains}} |

## Output Format Standards

- Use markdown headers (##, ###) for clear hierarchy
- Include Mermaid diagrams where visual aids clarity
- Use tables for structured data (tech stack, dependencies)
- Use bullet points for lists (avoid long paragraphs)
- Include code examples in fenced blocks with language tags
"""

    agent_file.write_text(template)
    print(f"✅ Created agent: {agent_file}")
    print(f"\nNext steps:")
    print(f"1. Edit {agent_file} to complete the placeholders")
    print(f"2. Keep the agent concise and focused on orchestration")
    print(f"3. Fill in Skill Activation table (Task Type, Skill, Purpose)")
    print(f"4. Combine Responsibilities & Outputs in one table")
    print(f"5. Create phase-specific Process subsections")
    print(f"6. Add Error Recovery patterns")
    print(f"7. See references/agent-format.md for detailed guidelines")


def main():
    parser = argparse.ArgumentParser(description="Create a new AI-DLC agent")
    parser.add_argument("name", help="Agent name in kebab-case (e.g., ai-code-generator)")
    parser.add_argument("--output-dir", default=".claude/agents",
                       help="Output directory (default: .claude/agents)")

    args = parser.parse_args()
    create_agent(args.name, args.output_dir)


if __name__ == "__main__":
    main()
