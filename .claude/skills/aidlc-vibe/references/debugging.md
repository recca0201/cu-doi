# Debugging Reference — FIX Path Deep-Dive

Read this before proposing a fix for anything beyond a trivial lint/type/syntax error. Use these techniques to avoid guess-and-check and symptom patches.

## 1. Pre-Fix State Capture

Before any investigation, record the broken state — it becomes the baseline you verify against in F5:

- Exact error messages and stack traces — copy-paste, never paraphrase (paraphrasing loses the detail that matters)
- The full failing command and its output
- Relevant log lines with timestamps
- `git log --oneline -15 -- <affected files>` — what changed recently

## 2. The Root-Cause Gate

Do not propose a fix until you can answer ALL six in one concrete sentence each:

1. **Exact symptom** — verbatim error / failing assertion / observed behavior
2. **Reproduction** — minimal command/steps that trigger it
3. **Expected vs actual** — what should happen vs what does
4. **Root cause** — the underlying defect: a specific line, missing check, race, or contract violation, with file:line evidence
5. **Why now** — what exposed it (recent commit, new data shape, env change, dependency upgrade)
6. **Blast radius** — every code path that depends on the broken behavior or shares the same root cause

If any answer contains "probably", "I think", or "something with…" — that's a guess, not a diagnosis. Gather more evidence: re-read the error completely, add instrumentation (§5), or ask the user for logs/repro steps. Never fix on a guess.

The blast radius answer matters twice: it tells you which tests to consider in verification, and it tells you whether the fix will break something that depends on the *current* (broken) behavior.

## 3. Hypothesis Discipline

Work one hypothesis at a time, scientifically. For each hypothesis, state:

- The claim: "I think X causes this because Y"
- What evidence would CONFIRM it
- What evidence would REFUTE it
- The cheapest way to test it

Common root-cause categories to draw hypotheses from:

- Recent code change introduced a regression (`git log`, `git diff`)
- Data or state mismatch (wrong input, stale cache, race condition)
- Environment difference (dependency version, config, platform)
- Missing validation (null check, type guard, boundary condition)
- Wrong assumption (API contract, data shape, ordering, timing)

Test with the SMALLEST possible change — one variable at a time. If refuted, form a new hypothesis; don't stack a second change on top of the first. Changes that pile up can't be isolated: you won't know which one worked, and the dead ones become latent bugs.

When you genuinely don't understand something, say "I don't understand X" and investigate or ask — pretending to know guarantees a wrong fix.

## 4. Backward Tracing

Bugs usually surface deep in the call chain, far from their origin. Fixing where the error appears treats a symptom.

Trace backward:

```
Symptom                 (where the error appears)
  ↑ Immediate cause     (the code that directly failed)
    ↑ What called it — with what values?
      ↑ Where did the bad value originate?
        ↑ ROOT CAUSE    (fix here)
```

Keep asking "what called this, and with what?" until the answer is the source. Fix the origin rather than adding a guard only where the bad value surfaces.

Also compare against working examples: find similar code in the same codebase that works, and list every difference from the broken code — however small. Don't assume "that can't matter"; differences you dismiss are where root causes hide.

## 5. Instrumentation When Tracing Stalls

When you can't trace by reading code, make the system tell you:

- Log inputs/outputs at each component boundary the data crosses (workflow → script → service → operation)
- Log BEFORE the dangerous operation — after it fails is too late; include context (directory, cwd, env, arguments) and a stack trace (`new Error().stack` in JS, `traceback.format_stack()` in Python, or equivalent)
- Run the repro ONCE, read the evidence to identify the failing layer, then investigate that layer — and remove the instrumentation afterward

In tests, print with a mechanism that can't be suppressed (`console.error` rather than a logger that may be silenced).

## 6. Trivial Fast-Path

For lint, type, and syntax errors with an obvious cause, the full gate is overkill:

1. Read the error message completely
2. Locate the file/line
3. Confirm the cause is what the message says it is
4. Fix

Still required even here: pre-fix capture (§1) — re-running the same lint/type command after the fix IS the verification. And an "obvious" cause that turns out wrong twice means the error wasn't trivial: switch to the full gate.

## 7. Regression Test Contract

Write the test as part of the fix, not after:

- It exercises the exact captured failure from §1
- It would FAIL without the fix — by construction, since you know the broken input and behavior precisely
- It will PASS with the fix

Do NOT run this newly written regression test during the FIX path — running it is user-confirmed in Step 5 of the main workflow. F5 still re-runs the original reproduction captured in §1. If the user skips Step 5, the final report must say the new test was written but not run (an unrun test is a claim, not evidence). If the project has no test harness, skip the test and state that in the report rather than inventing infrastructure.

## 8. Prevention Quick-Check

A fix without prevention lets the same bug class recur. After the fix, spend one minute on this table — apply only what fits the actual bug (YAGNI applies to guards too):

| The bug was… | Consider adding |
|--------------|-----------------|
| Invalid data reaching deep code | Validation at the entry point, not just the crash site |
| Null/undefined | Strict null handling (`??`, `?.`, type guard) at the boundary |
| Wrong type passed | Type guard or runtime validation; never `any` to silence it |
| Silent failure | Explicit error logging or propagation |
| Env-sensitive operation | A guard that refuses the dangerous operation in the wrong context |
| Hard to diagnose | Leave (cheap) logging that would have made this bug obvious |

Layered validation is the strong form: entry-point check + business-logic check + environment guard make a bug structurally impossible rather than merely fixed. Use judgment — a one-line typo fix needs none of this; an invalid-data bug that crossed three layers usually deserves two.

## 9. The 3-Strike Rule

Track your fix attempts honestly.

- **Attempt 1 fails** → return to §2 with the new evidence; your root cause was wrong
- **Attempt 2 fails** → widen the hypothesis categories (§3), consider instrumentation (§5), and do not try a blind third patch. Attempt 3 requires new evidence for a contained root cause; escalate immediately if the proper fix needs broader design or architecture.
- **Attempt 3 fails** → STOP. Regardless of the cause, the issue has exceeded vibe scope.

Signs you're in architecture territory:
- Each fix reveals new shared state, coupling, or a problem in a different place
- A proper fix would require "massive refactoring"
- Each fix creates new symptoms elsewhere

At 3 strikes: summarize the symptom, the three attempts, and what each revealed. Present it to the user and recommend escalating to `aidlc-quick-spec` (single-area redesign with a written record) or `aidlc-spec-driven` (cross-module). Your diagnosis notes are the most valuable input to that next workflow — carry them over. Never attempt fix #4 inside vibe: a fourth patch on a wrong architecture doesn't just fail, it deepens the hole the redesign must climb out of.

## When Investigation Finds No Root Cause

If systematic investigation genuinely shows the issue is environmental, timing-dependent, or external:

1. Document what you investigated and ruled out
2. Implement appropriate handling (retry, timeout, clear error message)
3. Add logging so the next occurrence carries evidence

But be honest: ~95% of "no root cause" conclusions are incomplete investigations. Re-check §2 before settling for this.
