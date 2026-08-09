# Symptom Playbooks

Targeted tips per failure category. Find your symptom and apply these on top of the normal FIX path — they don't replace root-cause diagnosis (see `debugging.md`), they speed it up.

## Test Failures

- Run the single failing test first (`npm test -- -t "name"`, `pytest path::test_name`, `dotnet test --filter Name`) — iteration speed dominates everything else while diagnosing
- Multiple failures? Group by shared root cause before fixing anything — five failures are often one bug, and fixing them "one by one" wastes four rounds
- Compare the assertion with actual behavior and decide which is wrong: the code, or the test? Never modify a test just to make it pass — only when the test is provably wrong about the requirement
- Check fixtures and mocks — a stale mock fails correctly-changed code and points you at the wrong suspect
- **Flaky test** (passes alone / fails in suite, passes locally / fails in CI):
  - Suspect shared state between tests, or timing
  - Replace arbitrary sleeps with condition-based waiting: poll for the actual condition (event fired, file exists, state reached) with a timeout and a clear failure message — never `sleep(50)` and hope. Sleeps calibrated on a fast machine fail under CI load.
  - An arbitrary timeout is only acceptable when testing actual timing behavior (debounce, throttle), derived from known intervals, with a comment explaining why
  - To find which test pollutes shared state, bisect: run tests one at a time / in halves until the polluter is isolated

## Type Errors

- Fix all in-scope type errors, not just the first — but group by root cause first: one wrong type at the source often produces a dozen downstream errors that vanish together. Report unrelated pre-existing errors without modifying them.
- Never use `any` to silence an error — that trades a compile-time bug for a runtime one. Prefer `unknown` + type guards, or fix the actual type
- Common causes: missing type imports, null/undefined handling, generic type parameters, union narrowing
- Re-run the type checker until the in-scope errors are clean. Report unrelated pre-existing errors. For pure type fixes the type system IS the regression test — a separate test file usually adds nothing

## Errors Reported via Logs

- Read tail-first — the most recent lines usually contain the failure; Grep with a limit rather than reading the whole file
- Look for: stack traces, error codes, timestamps (correlate with deploys and commits), repeated patterns (frequency separates a one-off from a systemic failure)
- One log line is a symptom; the pattern across lines is the evidence
- If logs lack the detail to diagnose, that's itself a finding — add the missing logging as part of prevention (`debugging.md` §8)

## CI Failures

- Fetch exactly what failed: `gh run view <run-id> --log-failed` (fall back to `--log` for full context)
- Check the steps BEFORE the failing step — the real error is often earlier: a warning, a bad cache restore, a skipped install
- Reproduce locally before pushing a fix; pushing to see if CI goes green is guess-and-check with a 10-minute feedback loop
- Causes that hit CI but not local: env vars/secrets, dependency versions, permissions, timeouts, platform differences (Linux runners vs macOS dev machines)

## UI Bugs

- Reproduce visually first — screenshot or run the app; a UI bug you haven't seen is a UI bug you haven't understood
- Check `aidlc-docs/foundation/uiux-guideline.md` for what the correct state should be — the design system defines "expected", not your intuition
- Verify the fix visually too, in the affected container — "build passed" proves nothing about pixels
- When the diagnosed defect is shared, prefer fixing at the component/token level over local overrides. Otherwise keep the fix scoped to the affected UI.
- If the user skips the Step 5 application run, state that the fix was not visually verified; don't imply that lint/build proves the pixels.
