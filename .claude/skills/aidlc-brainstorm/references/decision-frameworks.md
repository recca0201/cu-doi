# Decision-Making Frameworks

Structured approaches for evaluating alternatives and making technical decisions in AI-DLC workflows.

## Table of Contents
- [SWOT Analysis](#swot-analysis)
- [Cost-Benefit Analysis](#cost-benefit-analysis)
- [Decision Matrix](#decision-matrix)
- [RACI Matrix](#raci-matrix)
- [Risk Assessment](#risk-assessment)
- [Trade-Off Sliders](#trade-off-sliders)

## SWOT Analysis

**Use when**: Evaluating a single approach comprehensively

**Structure**:
- **Strengths**: Internal advantages (capabilities, efficiency, existing expertise)
- **Weaknesses**: Internal disadvantages (limitations, complexity, learning curve)
- **Opportunities**: External benefits (ecosystem, community, future potential)
- **Threats**: External risks (vendor lock-in, deprecation, security)

**Example (GraphQL vs REST)**:

**GraphQL**:
- Strengths: Flexible queries, strong typing, single endpoint
- Weaknesses: Complex caching, higher initial setup, overfetching risk
- Opportunities: Growing ecosystem, excellent tooling, great DX
- Threats: Overengineering for simple APIs, security complexity

**REST**:
- Strengths: Simple, well-understood, excellent caching, standard HTTP
- Weaknesses: Over/under-fetching, versioning complexity, multiple endpoints
- Opportunities: Universal support, proven at scale, extensive tooling
- Threats: Documentation drift, inconsistent implementations

## Cost-Benefit Analysis

**Use when**: Comparing resource implications of alternatives

**Dimensions**:
1. **Development Cost**: Time to implement, complexity, new dependencies
2. **Maintenance Cost**: Ongoing effort, debugging difficulty, upgrade burden
3. **Performance Cost**: Runtime overhead, memory usage, latency
4. **Benefits**: Features enabled, problems solved, DX/UX improvements

**Template**:

```markdown
## Option: [Name]

### Costs
- Development: [X days/weeks] - [reasoning]
- Maintenance: [Low/Medium/High] - [ongoing effort description]
- Performance: [impact description]
- Learning curve: [Low/Medium/High]

### Benefits
- [Benefit 1]: [quantified value]
- [Benefit 2]: [quantified value]
- [Benefit 3]: [quantified value]

### ROI: [High/Medium/Low]
[Justification]
```

## Decision Matrix

**Use when**: Comparing multiple options across multiple criteria

**Process**:
1. List all alternatives as columns
2. List evaluation criteria as rows
3. Weight each criterion (1-5, total = sum of all weights)
4. Score each option per criterion (1-10)
5. Calculate weighted score: weight × score
6. Sum weighted scores for each option

**Example (State Management Libraries)**:

| Criterion | Weight | Redux | Zustand | Jotai | Context |
|-----------|--------|-------|---------|-------|---------|
| Simplicity | 5 | 4 (20) | 9 (45) | 8 (40) | 10 (50) |
| Performance | 4 | 8 (32) | 9 (36) | 9 (36) | 6 (24) |
| DevTools | 3 | 10 (30) | 8 (24) | 7 (21) | 5 (15) |
| Bundle Size | 3 | 6 (18) | 9 (27) | 9 (27) | 10 (30) |
| Learning Curve | 2 | 5 (10) | 9 (18) | 8 (16) | 10 (20) |
| **Total** | **17** | **110** | **150** | **140** | **139** |

**Decision**: Zustand (highest score) for new projects, Redux for complex enterprise apps

## RACI Matrix

**Use when**: Clarifying decision ownership and stakeholder roles

**Roles**:
- **R**esponsible: Who does the work
- **A**ccountable: Who owns the decision (only one)
- **C**onsulted: Who provides input (two-way communication)
- **I**nformed: Who needs to know (one-way communication)

**Example (API Design Decision)**:

| Stakeholder | Role | Involvement |
|-------------|------|-------------|
| Backend Team | R | Implement the API |
| Tech Lead | A | Final decision maker |
| Frontend Team | C | API consumer requirements |
| Product Manager | C | Business requirements |
| DevOps | C | Infrastructure implications |
| QA Team | I | Testing implications |
| Stakeholders | I | Informed of decision |

## Risk Assessment

**Use when**: Evaluating potential negative consequences

**Framework**:
1. Identify risks
2. Assess probability (Low/Medium/High)
3. Assess impact (Low/Medium/High)
4. Calculate priority (Probability × Impact)
5. Define mitigation strategies

**Template**:

```markdown
## Risk: [Name]

**Probability**: [Low/Medium/High]
**Impact**: [Low/Medium/High]
**Priority**: [P × I = Low/Medium/High/Critical]

**Description**: [What could go wrong]

**Triggers**: [Conditions that would cause this risk]

**Mitigation**:
- [Prevention strategy 1]
- [Prevention strategy 2]

**Contingency**:
- [Fallback plan if risk occurs]
```

**Example Risks**:

### Risk: Vendor Lock-in
- **Probability**: Medium
- **Impact**: High
- **Priority**: High
- **Mitigation**: Abstraction layer, standardized interfaces, escape hatch design
- **Contingency**: Migration plan to alternatives

### Risk: Performance Degradation
- **Probability**: Low
- **Impact**: Medium
- **Priority**: Low-Medium
- **Mitigation**: Benchmarking during development, load testing, monitoring
- **Contingency**: Optimization sprint, caching layer, architecture pivot

## Trade-Off Sliders

**Use when**: Visualizing competing priorities

**Common Trade-offs**:

### Development Speed vs Long-Term Maintainability
```
Fast MVP ←────────●──→ Robust Architecture
         (Choose one or balance)
```

### Flexibility vs Simplicity
```
Generic/Configurable ←────●─────→ Specific/Simple
                     (YAGNI warning zone →)
```

### Performance vs Developer Experience
```
Optimized/Complex ←───────●───→ Clean/Readable
                 (Premature optimization →)
```

### Build vs Buy
```
Custom Solution ←─────●────→ Third-party Library
                 (NIH syndrome ←)
```

## YAGNI/KISS/DRY Validation

**Use for all decisions**: Check alignment with core principles

### YAGNI Check
- [ ] Does this solve a **current** problem (not hypothetical future)?
- [ ] Is the complexity justified by **existing** requirements?
- [ ] Are we building the **simplest** thing that works?

**Red flags**:
- "We might need this later..."
- "What if we want to support..."
- "Let's make it configurable just in case..."

### KISS Check
- [ ] Can this be explained in < 2 minutes?
- [ ] Does it have minimal moving parts?
- [ ] Could a junior developer understand it?

**Red flags**:
- Nested abstractions (>3 layers)
- "Clever" solutions requiring extensive comments
- Complex configuration or setup

### DRY Check
- [ ] Does this eliminate actual repetition (not coincidental similarity)?
- [ ] Is the abstraction worth the indirection cost?
- [ ] Does it reduce code **and** complexity?

**Red flags**:
- Premature abstraction (< 3 instances)
- Abstraction increases cognitive load
- "DRY" but harder to understand

## Decision Documentation

After using any framework, document:

1. **Context**: What decision was needed and why
2. **Alternatives Considered**: What options were evaluated
3. **Framework Used**: Which framework(s) informed the decision
4. **Analysis Results**: Scores, assessments, trade-offs
5. **Decision**: What was chosen
6. **Rationale**: Why this option was best
7. **Consequences**: What this means going forward
8. **Validation**: How to know if this was the right choice

**Output**: Decision Record — use `dr-lite.md` for simple decisions, `decision-record-template.md` for complex ones

---

**Principle**: No framework replaces thinking. Use frameworks to structure analysis, not to outsource judgment.
