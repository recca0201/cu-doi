# Unit Decomposition Criteria

## Good Unit Boundaries

- Single responsibility aligned with business capability
- Clear interfaces with other units
- Minimal dependencies
- Can be developed by the team (based on team size from `aidlc-docs/foundation/team-info.md`)
  - **Fewer developers (2-3)**: Create fewer units to avoid overwhelming the team
  - **More developers (4-5)**: Can handle more units with parallel execution
  - **Large teams (6+)**: Can manage many units simultaneously
- Can be deployed independently

## Unit Sizing Criteria

**Minimum Viable Unit** - Must meet ALL criteria:
- Delivers standalone value users can experience
- Covers minimum 2-4 related user stories (can have more; prefer 3+)
- Can be deployed to production independently
- Includes all layers: UI + Domain + Infrastructure
- Can be demoed to stakeholders as working feature

**Exception - Brownfield Improvements**:
Single unit with 1 user story is acceptable when:
- Delivers complete, standalone business value
- Focused enhancement to existing functionality
- Well-defined and independently deployable
- Example: "Add export to PDF" - single improvement, clear value

## Warning Signs

- Too many cross-unit dependencies → reconsider boundaries
- Unit too large (multiple business capabilities) → break down further
- Unit too small (only 1 story, unless brownfield exception) → consider merging
- Infrastructure-only with no user value → merge into feature unit
- Circular dependencies → redesign boundaries

## Business Value Validation

### Value Proposition

For each unit, create a clear value statement:
- **Template**: "As a [user type], I can [capability] so that [business outcome]"
- **Example**: "As a premium user trying to conceive, I can see daily recommendations based on my cycle phase, so that I know what actions to take"

### Independent Value Test

Ask: "If we ONLY shipped this unit, would users find it valuable?"
- ✅ YES → Good unit (e.g., "Todo List System" - users can see and track todos)
- ❌ NO → Reconsider boundaries (e.g., "Blob Storage Infrastructure" alone has no user value)

### Success Metrics

Define measurable outcomes for each unit:
- User adoption: % of target users engaging with feature
- Business impact: Retention, conversion, or satisfaction improvement
- Technical: Performance, reliability, or quality metrics

**Note**: Infrastructure units score low on user value but are necessary. Merge with feature units that deliver user value.

## Verification Checklist

Verify EACH unit before finalizing:

**Critical Checks**:
1. ✅ "Deployable Independently" = YES (mandatory - if NO, merge with feature unit)
2. ✅ Passes Independent Value Test (if NO, unit is infrastructure-only → merge)
3. ✅ Has minimum 2-4 user stories (can have more; exception: 1 for brownfield)
4. ✅ Value Proposition uses template format
5. ✅ Vertical Slice complete (UI + Domain + Infrastructure)
6. ✅ No circular dependencies

**Anti-Pattern Checks**:
- ❌ Infrastructure-only (e.g., "Blob Storage Config") → Merge into feature unit
- ❌ Enhancement-only without core → Merge or ensure core exists first
- ❌ Technical details in output (code, APIs, classes) → Remove, keep business-level only
- ❌ Scrum/Agile terms (sprint, story point) → Use AI-DLC terms (bolt, phase, unit)

**If any critical check fails**: Re-decompose and merge units until all pass
