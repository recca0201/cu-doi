# [Feature Name] — Quick Spec

> **Workflow:** This is an `aidlc-quick-spec` document. One file, one approval gate before execution.

**Status:** Draft | Approved | In Progress | Complete
**Date:** YYYY-MM-DD
**Estimation (BCP):** Not yet estimated

---

## Goal

[One sentence. What this feature does for the user (or system) and why now.]

## Requirements

[Keep each acceptance criterion independently testable. Use the shallowest trace ID depth that stays clear: `1`, `1.1`, or `1.1.1`. Include only categories relevant to this quick spec.]

### 1. [Category / Example: Primary Flow]
- **1.1** [Actor/user type] can [primary action/capability] when [condition].
- **1.2** [System/application] displays or returns [expected result/output] after [trigger].

### 2. [Category / Example: Validation, Rules, or Permissions]
- **2.1** [System/application] validates [input/condition/rule] before [action/submission].
- **2.2** [System/application] rejects [invalid input/state] and shows [message/result].

### 3. [Category / Example: Data, State, Integration, or Edge Cases]
- **3.1** [System/application] persists, updates, sends, or returns [expected data/state] after [event].
- **3.2** [System/application] handles [edge case/failure mode] by [observable behavior].

## Design

[The technical solution: how the change works, which existing codebase patterns it follows, and what data/state flows where. This is one solution, not options.]

**Decisions confirmed:**

- [Design decision the user confirmed, with the one-line reason. Remove this block if no decision needed confirmation.]

## File Structure

[Exact paths to be created or modified, with one-line responsibilities. This is where decomposition gets locked in.]

- **Modify** `path/to/existing/file.ext` — [what changes here]
- **Create** `path/to/new/file.ext` — [what this file owns]
- **Test** `path/to/test/file.ext` — [what it covers, if the project tests this area]

## Tasks

[Bite-sized checkboxed steps. Each task is 2–5 minutes of real work and contains the concrete file, behavior, and verification detail the engineer needs. No placeholders — see SKILL.md "No Placeholders" rule.]

### Task 1: [Short name]

**Implements:** [requirement IDs this task delivers, e.g. 1.1, 2.1]

**Files:**
- Modify: `exact/path/to/file.ext:LINE-RANGE`

- [ ] **Step 1:** [Concrete implementation action. Include a code snippet only for exact contracts, non-obvious logic, validation rules, integration keys, data transforms, error mappings, surgical replacements, or test assertions.]

- [ ] **Step 2:** [Verification command]

Run: [project lint + build commands — take from codebase-summary.md or the project's package config]
Expected: pass

### Task 2: [Short name]

**Implements:** [requirement IDs this task delivers]

**Files:**
- Create: `exact/path/to/new.ext`

**Interfaces:**
- Produces: [exact function/type signature that later tasks consume. Include this block only when another task depends on this one's output; delete it otherwise.]

- [ ] **Step 1:** [Concrete implementation action. Include a code snippet only if prose would leave room for materially different implementations.]

- [ ] **Step 2:** [Verification]

Run: `[verification command]`
Expected: [observable result]

---

## Notes

[Optional. Anything the engineer reading this in 3 months would want to know — design alternatives considered, why a non-obvious choice was made, links to related specs or issues. Leave blank if nothing applies.]
