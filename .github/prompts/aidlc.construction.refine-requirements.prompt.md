---
description: Refine high-level inception user stories into detailed requirements using the selected requirements template
---

---
description: Refine high-level inception user stories into detailed requirements using the selected requirements template
argument-hint: [user-stories|spec-name|requirements.md] [--template default|checklist|given-when-then-table|custom]
---

# /aidlc.construction.refine-requirements

**Purpose**: Refine high-level inception user stories into detailed requirements using the selected requirements template

**Skill**: aidlc-spec-driven

## Input

<user-stories>$ARGUMENTS</user-stories>

**Process**:

1. Resolve the target spec. Extract `--template ...` only when explicitly present; otherwise omit it so `aidlc-spec-driven` can read workspace config before defaults.
2. Invoke skill `aidlc-spec-driven` directly in current conversation (Phase 1 - Requirements). Treat `--template` as workflow config, not user-story text.
3. Before writing or editing requirements, read complete `aidlc-spec-driven/references/phase-1-requirements.md` plus required Phase 1 companion guidance from the skill.
