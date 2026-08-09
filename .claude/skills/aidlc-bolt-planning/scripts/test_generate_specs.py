#!/usr/bin/env python3
"""
Tests for generate_specs.py script.
"""

import tempfile
import shutil
from pathlib import Path
import sys

# Add parent directory to path to import generate_specs
sys.path.insert(0, str(Path(__file__).parent))
from generate_specs import slugify, parse_units, parse_user_stories, generate_requirement_md


def test_slugify():
    """Test slug generation."""
    assert slugify("Platform Foundation") == "platform-foundation"
    assert slugify("Core Content & First Impression") == "core-content-first-impression"
    assert slugify("User Experience Excellence") == "user-experience-excellence"
    assert slugify("Test 123!@# Name") == "test-123-name"
    print("✅ test_slugify passed")


def test_parse_units():
    """Test parsing units from markdown."""
    sample_units = """
# Units Definition

### **Unit 1: Platform Foundation**

**User Stories**:
- US-006: Navigate Landing Page
- US-007: View Footer Information

---

### **Unit 2: Core Content**

**User Stories**:
- US-001: View Hero Section
- US-002: Learn About Phases
"""

    with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False) as f:
        f.write(sample_units)
        temp_file = Path(f.name)

    try:
        units = parse_units(temp_file)
        assert len(units) == 2
        assert units[0]['name'] == "Platform Foundation"
        assert units[0]['slug'] == "platform-foundation"
        assert units[0]['story_ids'] == ['US-006', 'US-007']
        assert units[1]['name'] == "Core Content"
        assert units[1]['story_ids'] == ['US-001', 'US-002']
        print("✅ test_parse_units passed")
    finally:
        temp_file.unlink()


def test_parse_user_stories():
    """Test parsing user stories from markdown."""
    sample_stories = """
# User Stories

### US-001: View Hero Section

**As an** engineer
**I want** to see hero
**So that** I understand

**Priority**: High
**Status**: Backlog
**Effort**: 5 points

#### Acceptance Criteria (EARS Format)

**WHEN** user loads page
**THEN** system shall:
- Display hero headline
- Show CTA buttons

#### Technical Notes

- Component: `Hero.tsx`
- Uses brand colors

---

### US-002: Learn About Phases

**As a** PM
**I want** to learn
**So that** I can decide

**Priority**: High
**Status**: Backlog
**Effort**: 8 points

#### Acceptance Criteria (EARS Format)

- Show 3 phase cards

#### Technical Notes

- Component: `Phases.tsx`
"""

    with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False) as f:
        f.write(sample_stories)
        temp_file = Path(f.name)

    try:
        stories = parse_user_stories(temp_file)
        assert len(stories) == 2
        assert 'US-001' in stories
        assert 'US-002' in stories
        assert 'View Hero Section' in stories['US-001']
        assert 'Learn About Phases' in stories['US-002']
        # Verify full content including acceptance criteria and technical notes
        assert 'Acceptance Criteria' in stories['US-001']
        assert 'Technical Notes' in stories['US-001']
        assert 'Hero.tsx' in stories['US-001']
        assert 'WHEN' in stories['US-001']
        print("✅ test_parse_user_stories passed")
    finally:
        temp_file.unlink()


def test_generate_requirement_md():
    """Test requirement.md generation."""
    unit = {
        'number': '1',
        'name': 'Platform Foundation',
        'slug': 'platform-foundation',
        'story_ids': ['US-006', 'US-007']
    }

    stories = {
        'US-006': '### US-006: Navigate\n\nContent for US-006',
        'US-007': '### US-007: Footer\n\nContent for US-007'
    }

    content = generate_requirement_md(unit, stories)

    assert content.startswith('---\n')
    assert 'artifact_type: requirements' in content
    assert 'phase: construction' in content
    assert 'status: draft' in content
    assert 'unit: platform-foundation' in content
    assert 'Platform Foundation' in content
    assert 'US-006, US-007' in content
    assert 'US-006: Navigate' in content
    assert 'US-007: Footer' in content
    print("✅ test_generate_requirement_md passed")


def test_generate_requirement_md_includes_source_artifacts():
    """Test requirement.md metadata includes generator source paths."""
    unit = {
        'number': '1',
        'name': 'Metadata Rollout',
        'slug': 'metadata-rollout',
        'story_ids': ['US-004']
    }
    stories = {
        'US-004': '### US-004: Frontmatter\n\nContent for US-004',
    }

    content = generate_requirement_md(
        unit,
        stories,
        source_artifacts=[
            'aidlc-docs/requirements/003_metadata_units_decomposition.md',
            'aidlc-docs/story-artifacts/009_metadata_user_stories.md',
        ],
        intent='metadata',
    )

    assert content.startswith('---\n')
    assert 'artifact_type: requirements' in content
    assert 'phase: construction' in content
    assert 'status: draft' in content
    assert 'intent: metadata' in content
    assert 'unit: metadata-rollout' in content
    assert 'source_artifacts:' in content
    assert '- aidlc-docs/requirements/003_metadata_units_decomposition.md' in content
    assert '- aidlc-docs/story-artifacts/009_metadata_user_stories.md' in content
    print("✅ test_generate_requirement_md_includes_source_artifacts passed")


def run_all_tests():
    """Run all tests."""
    print("\n🧪 Running tests for generate_specs.py...\n")

    test_slugify()
    test_parse_units()
    test_parse_user_stories()
    test_generate_requirement_md()
    test_generate_requirement_md_includes_source_artifacts()

    print("\n✅ All tests passed!\n")


if __name__ == "__main__":
    run_all_tests()
