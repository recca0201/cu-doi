#!/usr/bin/env python3
"""Create a new AI-DLC command from template."""

import argparse
import sys
from pathlib import Path


def create_subagent_template(command_name: str, phase: str) -> str:
    """Template A: spawns a subagent that invokes the skill."""
    return f"""---
description: {{Brief description of what the command does}}
argument-hint: [input]
---

# /{command_name}

**Purpose**: {{1 sentence describing purpose and deliverables}}

**Agent**: {{agent-name}}
**Skill**: {{skill-name}}

## Input

<input>$ARGUMENTS</input>

**Process**:

1. Spawn subagent `{{agent-name}}` — **{{Process Section Name}}**
2. Invoke skill `{{skill-name}}` ({phase.capitalize()} - {{step-label}})
"""


def create_direct_template(command_name: str, phase: str) -> str:
    """Template B: invokes the skill directly in the current conversation."""
    return f"""---
description: {{Brief description of what the command does}}
argument-hint: [question]
---

# /{command_name}

**Purpose**: {{1 sentence describing purpose and deliverables}}

**Skill**: {{skill-name}}

## Input

<question>$ARGUMENTS</question>

**Process**:

1. Invoke skill `{{skill-name}}` directly in current conversation
"""


def create_command(name: str, phase: str, output_dir: str, mode: str) -> None:
    """Create a new command file from template.

    Args:
        name: Command name (kebab-case, without phase prefix)
        phase: Command phase (foundation/inception/construction/operations/common)
        output_dir: Output directory path
        mode: 'subagent' (Template A) or 'direct' (Template B)
    """
    output_path = Path(output_dir) / phase
    output_path.mkdir(parents=True, exist_ok=True)

    command_file = output_path / f"{name}.md"

    if command_file.exists():
        print(f"❌ Error: Command file already exists: {command_file}")
        sys.exit(1)

    command_name = f"aidlc.{phase}.{name}"

    if mode == "direct":
        template = create_direct_template(command_name, phase)
        next_steps = [
            f"1. Edit {command_file} to fill in the placeholders",
            "2. Set argument-hint and XML tag to match your input type (e.g., [question] / <question>)",
            "3. Set **Skill**: to the correct name (no file path)",
            "4. Keep as a thin wrapper — see references/command-format.md (Template B)",
        ]
    else:
        template = create_subagent_template(command_name, phase)
        next_steps = [
            f"1. Edit {command_file} to fill in the placeholders",
            "2. Set argument-hint and XML tag to match your input type (e.g., [task] / <task>)",
            "3. Set **Agent**: and **Skill**: to the correct names (no file paths)",
            "4. Set process step 1 process section name (see agent definition)",
            "5. Keep as a thin wrapper — see references/command-format.md (Template A)",
        ]

    command_file.write_text(template)
    print(f"✅ Created command ({mode} mode): {command_file}")
    print(f"   Command name: /{command_name}")
    print(f"\nNext steps:")
    for step in next_steps:
        print(f"  {step}")


def main():
    parser = argparse.ArgumentParser(
        description="Create a new AI-DLC command with format /aidlc.{phase}.{command-name}"
    )
    parser.add_argument(
        "name",
        help="Command name in kebab-case (e.g., 'foundation-context' for /aidlc.foundation.foundation-context)",
    )
    parser.add_argument(
        "--phase",
        choices=["foundation", "inception", "construction", "operations", "common"],
        default="common",
        help="Command phase (default: common)",
    )
    parser.add_argument(
        "--output-dir",
        default=".claude/commands/aidlc",
        help="Output directory (default: .claude/commands/aidlc)",
    )
    parser.add_argument(
        "--mode",
        choices=["subagent", "direct"],
        default="subagent",
        help=(
            "Command mode: 'subagent' (Template A — spawns agent + skill) "
            "or 'direct' (Template B — invokes skill in current conversation). "
            "Default: subagent"
        ),
    )

    args = parser.parse_args()
    create_command(args.name, args.phase, args.output_dir, args.mode)


if __name__ == "__main__":
    main()
