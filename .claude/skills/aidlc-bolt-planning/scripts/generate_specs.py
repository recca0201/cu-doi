#!/usr/bin/env python3
"""
Generate specs folder structure from units decomposition and user stories.

Usage:
    python3 generate_specs.py --units <units-file> --stories <stories-file> --output <output-dir>

Example:
    python3 generate_specs.py \
        --units aidlc-docs/requirements/units-decomposition-aidlc-landing.md \
        --stories aidlc-docs/story-artifacts/user-stories-aidlc-landing.md \
        --output specs
"""

import argparse
from datetime import date
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional


def slugify(text: str) -> str:
    """Convert text to kebab-case slug."""
    # Remove special chars, lowercase, replace spaces with hyphens
    text = text.lower()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[-\s]+', '-', text)
    return text.strip('-')


def strip_markdown(text: str) -> str:
    """Remove simple markdown markers from inline text."""
    text = re.sub(r'\*\*(.*?)\*\*', r'\1', text)
    text = re.sub(r'^[-*]\s+', '', text.strip())
    return text.strip()


def parse_units(units_file: Path) -> List[Dict[str, Any]]:
    """Parse units decomposition file and extract unit information.

    Supports two formats:
    - Legacy: - US-XXX: Title
    - New: - **1.1**: Title or just "1.1, 2.1, 2.3" in User Stories section
    """
    content = units_file.read_text()
    units = []

    # Find all unit sections (### **Unit N: Name** or ### Unit N: Name)
    unit_pattern = r'###\s+(?:\*\*)?Unit\s+(\d+):\s+(.+?)(?:\*\*)?(?=\n|$)'
    unit_matches = list(re.finditer(unit_pattern, content))

    for i, match in enumerate(unit_matches):
        unit_num = match.group(1)
        unit_name = match.group(2).strip()

        # Extract section content (from this unit to next unit or end)
        start_pos = match.end()
        end_pos = unit_matches[i + 1].start() if i + 1 < len(unit_matches) else len(content)
        section_content = content[start_pos:end_pos]

        # Try legacy format first: - **US-XXX**: or - US-XXX:  (supports US-123 and US-MDR-01 etc.)
        story_pattern_legacy = r'-\s+\*\*(US-[\w-]+)\*\*:|' + r'-\s+(US-[\w-]+):'
        story_ids = re.findall(story_pattern_legacy, section_content)
        # Flatten the tuple results from alternation pattern
        story_ids = [s for match in story_ids for s in match if s]

        # If no matches, try new format: - **1.1**:
        if not story_ids:
            story_pattern_new = r'-\s+\*\*(\d+\.\d+)\*\*:'
            story_ids = re.findall(story_pattern_new, section_content)

        purpose_match = re.search(r'\*\*Purpose\*\*:\s*(.+)', section_content)
        value_prop_match = re.search(r'\*\*Value Proposition\*\*:\s*(.+)', section_content)
        dependencies_match = re.search(r'\*\*Dependencies\*\*:\s*(.+)', section_content)
        risk_match = re.search(r'\*\*Technical Risk\*\*:\s*(.+)', section_content)
        deployable_match = re.search(r'\*\*Deployable Independently\*\*:\s*(.+)', section_content)

        units.append({
            'number': unit_num,
            'name': unit_name,
            'slug': slugify(unit_name),
            'story_ids': story_ids,
            'purpose': purpose_match.group(1).strip() if purpose_match else '',
            'value_proposition': value_prop_match.group(1).strip() if value_prop_match else '',
            'dependencies': dependencies_match.group(1).strip() if dependencies_match else 'None',
            'technical_risk': risk_match.group(1).strip() if risk_match else '',
            'deployable_independently': deployable_match.group(1).strip() if deployable_match else '',
        })

    return units


def parse_user_stories(stories_file: Path) -> Dict[str, str]:
    """Parse user stories file and extract story sections by ID.

    Supports multiple formats:
    - Legacy (level 2): ## US-XXX: Title
    - Legacy (level 3): ### US-XXX: Title
    - New: ### Story 1.1: Title or ### 1.1: Title
    """
    content = stories_file.read_text()
    stories = {}

    # Try level 2 format first: ## US-XXX: Title (exactly 2 hashes, not ###)
    story_pattern_h2 = r'(?ms)^##(?!#)\s+(US-[\w-]+):\s+(.+?)(?=^##(?!#)\s+US-|^##(?!#)\s+Summary|\Z)'
    story_matches = list(re.finditer(story_pattern_h2, content))

    for match in story_matches:
        story_id = match.group(1)
        story_content = match.group(0)  # Include the heading
        stories[story_id] = story_content.strip()

    # If no matches, try new format: ### Story 1.1: Title
    if not stories:
        story_pattern_new = r'(?ms)^###(?!#)\s+Story\s+(\d+\.\d+):\s+(.+?)(?=^###(?!#)\s+Story\s+\d+\.\d+:|^###(?!#)\s+\d+\.\d+:|^##(?!#)\s+|\Z)'
        story_matches = list(re.finditer(story_pattern_new, content))

        for match in story_matches:
            story_id = match.group(1)
            story_content = match.group(0)  # Include the heading
            stories[story_id] = story_content.strip()

    # If no matches, try legacy format (level 3): ### US-XXX: Title (supports US-MDR-01 etc.)
    if not stories:
        story_pattern_legacy = r'(?ms)^###(?!#)\s+(US-[\w-]+):\s+(.+?)(?=^###(?!#)\s+US-|^##(?!#)\s+|\Z)'
        story_matches = list(re.finditer(story_pattern_legacy, content))

        for match in story_matches:
            story_id = match.group(1)
            story_content = match.group(0)  # Include the heading
            stories[story_id] = story_content.strip()

    # Also try alternate new format: ### 1.1: Title (without "Story")
    if not stories:
        story_pattern_alt = r'(?ms)^###(?!#)\s+(\d+\.\d+):\s+(.+?)(?=^###(?!#)\s+\d+\.\d+:|^##(?!#)\s+|\Z)'
        story_matches = list(re.finditer(story_pattern_alt, content))
        
        for match in story_matches:
            story_id = match.group(1)
            story_content = match.group(0)  # Include the heading
            stories[story_id] = story_content.strip()

    return stories


def load_metadata_renderer():
    """Import the shared metadata renderer from _aidlc-shared."""
    shared_scripts = Path(__file__).resolve().parents[2] / "_aidlc-shared" / "scripts"
    shared_scripts_str = str(shared_scripts)
    if shared_scripts_str not in sys.path:
        sys.path.insert(0, shared_scripts_str)

    from artifact_metadata import ArtifactMetadata, render_frontmatter

    return ArtifactMetadata, render_frontmatter


def derive_feature_slug(source_path: Path) -> Optional[str]:
    """Derive a feature slug from known unit decomposition filenames."""
    stem = source_path.stem
    patterns = [
        r"^\d{3}_(.+?)_units_decomposition$",
        r"^\d{3}-(.+?)-units-decomposition$",
        r"^units-decomposition-(.+)$",
        r"^(.+?)_units_decomposition$",
        r"^(.+?)-units-decomposition$",
    ]

    for pattern in patterns:
        match = re.match(pattern, stem)
        if match:
            slug = slugify(match.group(1).replace("_", "-"))
            return slug or None

    return None


def is_relative_to(path: Path, root: Path) -> bool:
    """Return whether path is under root without requiring Python 3.9 APIs."""
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def infer_workspace_root(*paths: Path) -> Path:
    """Infer the root used for workspace-relative metadata paths."""
    cwd = Path.cwd().resolve()
    resolved_paths = [path.resolve() for path in paths if path]
    if resolved_paths and all(is_relative_to(path, cwd) for path in resolved_paths):
        return cwd

    for path in resolved_paths:
        parts = path.parts
        if "aidlc-docs" in parts:
            docs_index = parts.index("aidlc-docs")
            if docs_index > 0:
                return Path(*parts[:docs_index])

    return cwd


def render_requirements_frontmatter(
    unit: Dict,
    source_artifacts: Optional[List[str]] = None,
    intent: Optional[str] = None,
    workspace_root: Optional[Path] = None,
) -> str:
    """Render compliant frontmatter for generated unit requirements."""
    ArtifactMetadata, render_frontmatter = load_metadata_renderer()
    today = date.today().isoformat()
    unit_slug = unit.get("slug") or slugify(unit.get("name", ""))

    metadata = ArtifactMetadata(
        artifact_type="requirements",
        phase="construction",
        status="draft",
        created=today,
        updated=today,
        intent=intent,
        unit=unit_slug,
        source_artifacts=source_artifacts or [],
    )
    return render_frontmatter(metadata, workspace_root=workspace_root)


def generate_requirement_md(
    unit: Dict,
    stories: Dict[str, str],
    source_artifacts: Optional[List[str]] = None,
    intent: Optional[str] = None,
    workspace_root: Optional[Path] = None,
) -> str:
    """Generate requirement.md content for a unit."""
    frontmatter = render_requirements_frontmatter(
        unit,
        source_artifacts=source_artifacts,
        intent=intent,
        workspace_root=workspace_root,
    )
    introduction_parts = []
    if unit.get('purpose'):
        introduction_parts.append(unit['purpose'])
    if unit.get('value_proposition'):
        introduction_parts.append(unit['value_proposition'])
    if unit.get('technical_risk'):
        introduction_parts.append(f"Technical risk for this unit is {unit['technical_risk'].lower()}.")
    introduction = " ".join(introduction_parts) or (
        f"This unit defines the implementation requirements for {unit['name'].lower()}."
    )

    dependency_text = strip_markdown(unit.get('dependencies') or 'None')
    next_steps = [
        "Once these requirements are approved, proceed to Phase 2: Design Document Creation.",
        "",
        "**What to do next:**",
        "1. Use the slash command: `/aidlc.construction.create-design`",
        "2. The agent will automatically read `references/phase-2-design.md` for detailed workflow instructions",
        "3. Foundation docs will be referenced for architecture alignment",
    ]
    if dependency_text and dependency_text != 'None':
        next_steps.insert(0, f"This unit depends on {dependency_text}; keep those upstream requirements stable before finalizing design.")

    lines = [
        f"# Requirements - {unit['name']}",
        "",
        f"**Unit**: Unit {unit['number']} - {unit['name']}",
        f"**User Stories**: {', '.join(unit['story_ids'])}",
        "",
        "---",
        "",
        "## Introduction",
        "",
        introduction,
        "",
        "## Requirements",
        ""
    ]

    # Add each user story
    for index, story_id in enumerate(unit['story_ids']):
        if story_id in stories:
            lines.append(stories[story_id])
            if index < len(unit['story_ids']) - 1:
                lines.append("")
        else:
            lines.append(f"### {story_id}: NOT FOUND")
            lines.append("")
            lines.append(f"⚠️ User story {story_id} was not found in the stories file.")
            if index < len(unit['story_ids']) - 1:
                lines.append("")

    lines.extend([
        "## Next Steps",
        "",
        *next_steps,
        "",
        "This will create `design.md` with comprehensive design based on these requirements.",
    ])

    return frontmatter + "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Generate specs folder structure from units and user stories"
    )
    parser.add_argument(
        "--units",
        required=True,
        help="Path to units decomposition markdown file"
    )
    parser.add_argument(
        "--stories",
        required=True,
        help="Path to user stories markdown file"
    )
    parser.add_argument(
        "--output",
        default="aidlc-docs/specs",
        help="Output directory for specs (default: aidlc-docs/specs)"
    )

    args = parser.parse_args()

    # Validate input files
    units_file = Path(args.units)
    stories_file = Path(args.stories)

    if not units_file.exists():
        print(f"❌ Units file not found: {units_file}")
        return 1

    if not stories_file.exists():
        print(f"❌ Stories file not found: {stories_file}")
        return 1

    # Parse files
    print(f"📖 Parsing units from: {units_file}")
    units = parse_units(units_file)
    print(f"   Found {len(units)} units")

    print(f"📖 Parsing user stories from: {stories_file}")
    stories = parse_user_stories(stories_file)
    print(f"   Found {len(stories)} user stories")

    # Generate specs
    output_dir = Path(args.output)
    print(f"\n📁 Generating specs in: {output_dir}")
    source_artifacts = [str(units_file), str(stories_file)]
    intent = derive_feature_slug(units_file)
    workspace_root = infer_workspace_root(units_file, stories_file, output_dir)

    for unit in units:
        # Create unit directory
        unit_dir = output_dir / unit['slug']
        unit_dir.mkdir(parents=True, exist_ok=True)

        # Generate requirements.md
        req_content = generate_requirement_md(
            unit,
            stories,
            source_artifacts=source_artifacts,
            intent=intent,
            workspace_root=workspace_root,
        )
        req_file = unit_dir / "requirements.md"
        req_file.write_text(req_content)

        print(f"   ✅ {unit_dir.name}/requirements.md ({len(unit['story_ids'])} stories)")

    print(f"\n✅ Successfully generated specs for {len(units)} units")
    return 0


if __name__ == "__main__":
    exit(main())
