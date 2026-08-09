# Troubleshooting Guide

Recovery strategies for when a spec-driven phase stalls. The phase references own the full workflow; this file only covers getting unstuck.

## Requirements Clarification Stalls

**Symptoms**: Clarification going in circles, not converging.

- Summarize what's established, name the specific remaining gaps, and offer to lock in the settled parts now and refine the rest later.
- Offer concrete options (not open questions) when the user seems unsure, or suggest quick research to inform a decision.

```
"We've established [X, Y, Z]. The remaining unclear areas are [A, B].
Would you like to clarify [A] first, or proceed with [X, Y, Z] and
refine [A, B] later?"
```

## Research Limitations

**Symptoms**: Can't access information needed for a design decision.

- Proceed with an explicitly noted assumption based on common patterns rather than blocking; document what's missing and where more research would sharpen the design.

```
"Unable to find information about [X]. Proceeding with assumption [Y]
based on common patterns. This can be refined once [X] is clarified."
```

## Design Complexity

**Symptoms**: Design growing too complex to implement cleanly.

- Identify the MVP/core, sequence the rest as follow-on tasks or a phased approach, or split into multiple specs.
- Return to requirements to reprioritize when scope is the real problem.

```
"This design covers [A, B, C, D]. Core is [A, B]. Suggest implementing
[A, B] first, then [C, D] as enhancements in separate tasks or specs."
```

## Task Execution Issues

**Symptoms**: A task is unclear, depends on others, or is too large.

- Read all spec docs (and `mockup.html` when present) before executing — full protocol in `references/phase-4-execution.md`.
- Break oversized tasks into sub-tasks, execute dependencies in order, and ask the user when task details are genuinely insufficient.

## Approval Cycle Confusion

**Symptoms**: Unclear whether the user approved.

- Proceed only on a clear approval statement ("yes", "approved", "looks good"); never on an ambiguous one ("maybe", "I think so").
- After changes, ask "Does this address your feedback?" and keep the revision loop going until approval is explicit.

## Foundation Doc Integration Issues

**Symptoms**: Output doesn't follow existing patterns or is inconsistent with the codebase.

- Read foundation docs before each phase and reference their guidance explicitly in the artifact.
- Propose any deviation from an established pattern with a clear rationale rather than diverging silently.
