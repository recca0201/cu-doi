# Reliability And Flake Debugging Reference

Use this reference when tests are flaky, slow, intermittently failing, or hard to maintain.

## Diagnosis Order

1. Reproduce with the narrowest failing command.
2. Read failure output, screenshots, videos, traces, and HTML reports if available.
3. Identify failure class before editing code.
4. Fix the smallest root cause.
5. Re-run the narrowest test, then a relevant suite/tag.

## Common Failure Classes

| Symptom | Likely Cause | Preferred Fix |
| --- | --- | --- |
| Element not found | selector brittle or page not ready | stable locator plus visible/enabled assertion |
| Click ignored | overlay/loading state | wait for overlay disappearance or target enabled state |
| Assertion races data load | async API/render not complete | wait for response, URL, or user-visible state |
| Passes alone, fails in parallel | shared data/state | isolate data, use unique IDs, cleanup per test |
| Fails only in CI | viewport, env, timing, auth | align config and inspect CI artifacts |
| Slow suite | too many full E2E cases | move low-value checks to integration/unit tests |

## Wait Strategy

Avoid fixed sleeps in new code. Prefer:
- locator assertions: visible, hidden, enabled, disabled, text/value
- URL assertions or navigation waits
- API response waits for a specific endpoint/status
- app-specific loading indicator disappearance
- retry-capable framework assertions

Use fixed waits only as a temporary workaround with a comment explaining why no stable signal exists.

## Selector Hardening

Replace brittle selectors in this order:
1. accessible role/label/text when stable
2. `data-testid` / `data-cy`
3. stable semantic attributes such as `name`
4. stable CSS scoped to a component
5. XPath for complex hierarchy only

Do not change app code to add test IDs unless that is acceptable in the repository and the user requested implementation changes.

## Data Isolation

Use unique test data for create/update flows. Store generated values in the framework context, fixture, or test scope. Avoid module-level mutable state when tests can run in parallel.

## Reporting

When reporting a flake fix, include:
- failing command
- root cause category
- files changed
- why the new wait/selector/data approach is deterministic
- verification command and result
