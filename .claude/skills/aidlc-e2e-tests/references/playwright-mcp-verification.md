# Playwright MCP Verification Reference

Use this reference when E2E work needs live browser exploration, selector verification, page-state discovery, or debugging. Playwright MCP/browser tooling is a verification layer; it does not replace the repository's test framework.

## When To Use

Use Playwright MCP or equivalent browser tooling when:
- Adding selectors for new or changed UI
- Converting manual/AIDLC test cases into executable UI automation
- Validating popup, dropdown, loading, disabled, empty, or error states
- Debugging a failing or flaky E2E scenario
- Confirming generated steps match real user behavior
- Checking UI behavior against `mockup.html` or design handoff states

Do not require MCP for:
- Pure API tests
- Existing selectors already covered by stable passing tests
- Non-UI refactors where no browser behavior changes

## Verification Workflow

1. Open the app using the repo's configured environment or local URL.
2. Navigate to the page/state required by the scenario.
3. Perform the same user action described by the Gherkin/manual step.
4. Inspect the live DOM snapshot or accessibility tree.
5. Choose the most stable selector available.
6. Re-run the interaction using the chosen selector.
7. Record verification evidence in the handoff or code comment when useful.

## Selector Priority

Prefer selectors in this order:
1. `data-testid` / `data-cy`
2. `name` or stable semantic attributes
3. accessible role/label when stable in the product language
4. stable CSS scoped to the component
5. XPath only for complex hierarchy or third-party widgets

Avoid:
- generated classes
- deep DOM chains
- `nth-child` paths
- translated text when localization may change
- selectors inferred from similar fields without checking the actual element

## Evidence To Capture

For each new selector or difficult interaction, capture:

| Field | Example |
| --- | --- |
| Scenario/Test ID | `TC-SPEC-001` or `BKM5-1942` |
| Page/state | Booking creation, Contact section expanded |
| Element purpose | Contact Person Name textbox |
| Selector | `input[data-testid="contact-person-name-input"]` |
| Interaction verified | fill, click, select, assert visible |
| Stability reason | `data-testid` from live DOM |
| Remaining risk | dynamic popup option not verified on STG |

## Handoff Language

Use these statuses consistently:
- `verified:mcp` - browser tooling inspected the live DOM and the selector/interaction worked
- `verified:existing-test` - existing passing tests already exercise this selector/interaction
- `required` - selector must be verified before production-ready automation
- `blocked:no-browser-tool` - browser tooling was unavailable
- `blocked:no-access` - environment, credentials, or permissions prevented verification

## If MCP Is Unavailable

Do not claim selectors are verified. Continue only if useful, but mark the output as draft.

Required notes:
- attempted tool
- reason unavailable
- selectors or interactions still requiring verification
- exact command or browser step the user should run later

Example:

```text
Selector verification: blocked:no-browser-tool
Unverified selectors:
- Contact Person Name textbox: proposed `input[data-testid="contact-person-name-input"]`
Required follow-up: open Booking Contact page with Playwright MCP, inspect the field, and verify fill/assert behavior before merging.
```

## Quality Gate Addition

Before marking E2E work complete:
- New selectors are `verified:mcp`, `verified:existing-test`, or explicitly marked blocked/required.
- Generated feature steps were walked through against the live UI when the scenario depends on new UI behavior.
- Any unverified selector is called out in the final response and code comments only when necessary.
