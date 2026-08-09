---
description: Review implementation before AIDLC task/unit completion against requirements, design decisions, and quality standards
argument-hint: [input]
---

# /aidlc.construction.code-review

**Purpose**: Review implementation before AIDLC task/unit completion against requirements, design decisions, and quality standards

**Agent**: ai-orchestration-engineer
**Skill**: aidlc-code-review

## Input

<input>$ARGUMENTS</input>

**Process**:

1. Resolve review scope from `<input>`:
   - Unit/spec slug or `aidlc-docs/specs/{unit}/` path
   - Scope: task number/range, current changed task, or full unit
   - Optional git range (`BASE_SHA..HEAD_SHA`) or note that current staged/unstaged changes should be reviewed
2. Spawn subagent `ai-orchestration-engineer` — **Construction Phase 4 - Code Review**.
3. Instruct the agent to invoke skill `aidlc-code-review` before reviewing.
4. Instruct the agent to review only; it must not modify implementation code or update `tasks.md`.
5. Pass this context block to the agent:
   - Project root
   - Unit/spec slug and spec directory
   - Review scope
   - Git range or worktree mode
   - Changed files, when known
   - Excluded unrelated changes, when known
   - Verification evidence, when available
   - Whether UI files changed or `mockup.html` exists
6. Require the review report to include spec-compliance verdict, code-quality findings, adversarial review result/skipped reason, reviewed files, excluded unrelated changes, verification evidence, and ready-to-proceed decision.
7. If the review is full-unit or broad multi-task scope, keep it in the subagent session and return a concise findings summary to the user.
