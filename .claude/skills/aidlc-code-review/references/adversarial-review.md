# Adversarial Review — Stage 3

Failure-mode analysis that runs after Stage 2 passes. The goal is not to check requirements or quality — those are done. The goal is to find every way the implementation can fail, be exploited, or produce wrong results.

## Scope Gate

**Skip adversarial review when ALL of these are true:**
- Changed files ≤ 2 AND lines changed ≤ 30
- No security-sensitive files touched (auth, crypto, env vars, SQL, input parsing, sessions)
- No new external dependencies added
- No cross-unit integration contracts added/changed

**NEVER skip when:**
- New API routes or external service integrations are added
- Auth, permissions, or session logic changed
- Database schema modified
- Environment variables added or changed
- A shared interface (used by other units) is changed
- `package.json` or lockfile changed

When skipped, output: `Adversarial: skipped (below threshold — N files, N lines changed)`

---

## Mindset

> "You are hired to tear apart the implementer's work. Your job is to find every way this code can fail, be exploited, or produce incorrect results. Assume the implementer made mistakes. Prove it."

Standard reviews check if code meets requirements. Adversarial review assumes requirements are met and asks: **"How can this still break?"**

Only review ADDED/MODIFIED lines (+ prefix in diff). Pre-existing code is out of scope unless the change makes it newly exploitable.

---

## What to Attack

### Security Holes
- Injection vectors (SQL, command, XSS, template injection)
- Auth bypass paths (missing checks, privilege escalation via roles)
- Secrets in logs, error messages, or stack traces
- User input trusted without validation at the unit boundary
- SSRF, path traversal, unsafe deserialization

### False Assumptions
- "This will never be null" — prove it can be
- "This list always has elements" — find the empty case
- "Users always call A before B" — find the out-of-order path
- "This config value exists" — find the missing env var scenario
- "This other unit's API always returns successfully" — find the failure mode
- "This shared contract is stable" — find the breaking caller scenario

### Failure Modes & Resource Exhaustion
- What happens when disk is full or a write fails midway?
- What happens when an external call times out?
- What happens when the DB connection drops during a transaction?
- Unbounded allocations from user-controlled input
- Missing timeouts on external calls
- Sync operations blocking an async context
- Connection or handle leaks on error paths

### Race Conditions
- Shared mutable state without locks
- Time-of-check-to-time-of-use (TOCTOU)
- Async operations with implicit ordering assumptions
- Cache invalidation during concurrent writes

### Data Corruption
- Partial writes with no transaction/rollback
- Type coercion surprises (e.g., string "0" as falsy)
- Timezone-naive datetime operations
- Floating-point equality comparisons

### Cross-Unit Coupling (AIDLC-specific)
- Does this unit assume another unit's internal structure or DB table?
- Are outputs from other units validated before use, or trusted blindly?
- If this unit fails, what state does it leave behind for dependent units?

### Supply Chain & Dependencies
- New packages: postinstall scripts, maintainer reputation, bundle size impact
- Lockfile changes: version drift, removed integrity hashes
- Transitive dependencies pulling in known-vulnerable packages

### Observability Blind Spots
- Swallowed errors (`catch {}` with no log)
- Missing structured context in error logs (e.g., no request ID, no unit context)
- PII appearing in log output

---

## Process

### 1. Spawn Adversarial Reviewer Subagent

Use the `code-reviewer` agent type (or general-purpose subagent) with this prompt:

```
You are an adversarial code reviewer. Your ONLY job is to find ways this code
can fail, be exploited, or produce incorrect results.

DO NOT praise the code. DO NOT note what works well.
ONLY report problems. If you find nothing, say "No findings" — but try harder first.

Focus on ADDED/MODIFIED lines (+ prefix in diff). Pre-existing code is out of scope
unless the change makes it newly exploitable.

Context files (read for understanding, DO NOT review these):
{CONTEXT_FILES — list paths to: requirements.md, design.md, code-standards.md}

Runtime: {RUNTIME — e.g., Node.js, Python 3.11, browser}
Framework: {FRAMEWORK — e.g., Express 4.x, FastAPI, React 18}
Unit: {UNIT_SLUG} — part of a larger system with these other units: {OTHER_UNIT_NAMES}

Review this diff:
{DIFF}

Attack vectors to check:
1. Security holes (injection, auth bypass, secrets exposure)
2. False assumptions (null, empty, ordering, config, API contracts)
3. Failure modes + resource exhaustion (timeouts, leaks, unbounded input)
4. Race conditions (shared state, TOCTOU, async ordering)
5. Data corruption (partial writes, type coercion, encoding)
6. Cross-unit coupling (assumptions about other units' internals or APIs)
7. Supply chain (new deps, lockfile changes, transitive vulns)
8. Observability (swallowed errors, missing logs, PII in output)

For each finding, report:
- SEVERITY: Critical / Medium / Low
- CATEGORY: Security / Assumption / Failure / Race / Data / CrossUnit / Supply / Observability
- LOCATION: file:line
- ATTACK: How to trigger the problem (be concrete)
- IMPACT: What happens when triggered
- FIX: Describe the fix approach — do NOT write implementation code
```

**Calibration**: If the adversarial reviewer produces >10 findings for <100 lines changed, it's likely over-aggressive. Batch-reject noise; deep-review only Critical and Medium findings.

---

### 2. Adjudicate Findings

For each finding, assign a verdict:

| Verdict | Meaning | Action |
|---------|---------|--------|
| **Accept** | Valid flaw, reproducible or clearly reasoned | Must fix before proceeding |
| **Reject** | False positive, already handled, or impossible path | Document why |
| **Defer** | Valid but low-risk, tracked for later | Create issue/note |

**Rules:**
- Every finding gets a verdict — no silent dismissals
- Critical findings: Accept unless you can PROVE it's a false positive
- Benefit of doubt goes to the adversary — safer to fix than dismiss
- If >50% of findings are Rejected, the adversary was too aggressive — but still report all

---

### 3. Output Format

```markdown
## Adversarial Review — Stage 3

### Summary
- Findings: N total (X Critical, Y Medium, Z Low)
- Accepted: A (must fix)
- Rejected: B (false positive)
- Deferred: C (tracked)

### Accepted Findings (Must Fix)

#### [1] SEVERITY — CATEGORY — file:line
**Attack:** How to trigger
**Impact:** What happens
**Fix:** Approach
**Verdict:** Accept — [reason]

### Rejected Findings

#### [N] SEVERITY — CATEGORY — file:line
**Attack:** Claimed vector
**Verdict:** Reject — [reason this is a false positive]

### Deferred Findings

#### [N] SEVERITY — CATEGORY — file:line
**Attack:** How to trigger
**Verdict:** Defer — [reason] → [tracking reference]
```

---

### 4. Fix Accepted Findings

| Severity | Action |
|----------|--------|
| Critical | Block task/unit completion. Fix immediately. |
| Medium | Fix before unit completes. Defer only with explicit user approval. |
| Low | Track. Fix in follow-up if pattern repeats. |

**Re-review optimization**: On fix cycles, pass only the FIX diff to the adversarial reviewer — not the full original diff. Verify each accepted finding is resolved and check whether the fix introduced new issues.

---

## Integration Position

```
Stage 1 (Spec Compliance) → PASS
  ↓
Stage 2 (Code Quality) → PASS
  ↓
Scope gate → below threshold? → skip (note in report)
  ↓ (above threshold)
Stage 3 (Adversarial) → findings
  ├── 0 Accepted → PASS → proceed
  ├── Accepted Critical → BLOCK → fix → re-run Stage 3 (fix diff only)
  └── Accepted Medium/Low only → fix or defer → proceed
```
