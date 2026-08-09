---
name: aidlc-e2e-tests
description: Convert manual/AIDLC test cases into reliable executable E2E automation and improve existing browser test suites. Use whenever the user asks to automate QA scenarios, implement browser tests from `test-cases.md`, generate Cucumber feature/step/POM code, write Playwright/Cypress tests, debug flaky E2E tests, establish E2E standards, or integrate tests with CI/Xray. Prefer this skill over generic coding when the work involves executable browser tests or manual-testcase-to-automation handoff.
argument-hint: "[test-cases.md|feature file|failing test|QA scenario] [--playwright|--cypress|--cucumber]"
---

# AIDLC E2E Tests

Build reliable executable browser tests from product requirements, manual test-case documents, and existing repository patterns.

This skill is an orchestration router. Keep `SKILL.md` lean and load only the reference needed for the detected framework.

## When To Use

Use this skill for:
- Converting `aidlc-test-cases` Markdown documents into executable E2E tests
- Automating manual Gherkin scenarios while preserving traceability
- Generating Cucumber feature files, step definitions, and Page Object Model code
- Writing or improving Playwright Test or Cypress tests
- Debugging flaky or unreliable browser tests
- Setting E2E standards, selectors, fixtures, reporting, and CI execution

Do not use this skill for:
- Pure manual QA documentation; use `aidlc-test-cases`
- Unit/integration tests without browser behavior
- Test strategy documents that do not require executable artifacts
- Security/performance scanning unless paired with a browser E2E scenario

## Reference Router

Load references progressively:

| Situation | Read |
| --- | --- |
| Repo has `cucumber.js`, `features/`, `stepdefinitions/`, `types/world.ts` | `references/cucumber-playwright-bdd.md` |
| Repo has `playwright.config.*` and `@playwright/test` test files | `references/playwright-test.md` |
| Repo has `cypress.config.*` or `cypress/` | `references/cypress.md` |
| New UI selectors, uncertain DOM behavior, or live UI debugging | `references/playwright-mcp-verification.md` |
| Debugging flaky tests or improving stability | `references/reliability-debugging.md` |

If multiple frameworks exist, choose the one already used for the nearest matching feature area. If unclear, ask one concise question before writing code.

## Core Workflow

Follow this sequence for any E2E implementation task.

1. **Resolve source of truth**
   - For AIDLC work, read `test-cases.md` first.
   - For Jira/Xray work, read exported Cucumber or ticket details first.
   - For existing failures, read the failing test, trace/report, and relevant app code.

2. **Select automation scope**
   - Automate only scenarios explicitly requested or marked `Automation target = e2e` / `E2E candidate = yes/conditional`.
   - Keep manual-only, exploratory, low-value edge, and visual-review-only cases out of E2E unless explicitly requested.
   - Preserve traceability: `Test Case ID`, `Source ID`, Jira/Xray key, scenario title.

3. **Detect framework and load reference**
   - Cucumber Playwright: load `references/cucumber-playwright-bdd.md`.
   - Playwright Test: load `references/playwright-test.md`.
   - Cypress: load `references/cypress.md`.
   - New selectors or uncertain UI behavior: also load `references/playwright-mcp-verification.md`.
   - Flake/debug work: also load `references/reliability-debugging.md`.

4. **Search before generating**
   - Search existing feature/spec files, step definitions, page objects, fixtures, constants, helpers, and CI scripts.
   - Reuse existing step vocabulary, selectors, page methods, fixtures, and data factories where practical.
   - Add the smallest missing code only.

5. **Generate executable artifacts**
   - Match the repository's current organization and naming conventions.
   - Prefer Page Object Model or existing abstraction style.
   - Keep assertions user-visible and behavior-focused.
   - Keep tests independent and deterministic.

6. **Verify selectors and waits**
   - Prefer stable selectors: `data-testid`, `name`, accessible role/label, stable CSS, then XPath only when needed.
   - Do not guess selectors for new UI. Prefer Playwright MCP/browser tooling for live DOM verification.
   - Avoid fixed sleeps in new code; use locator assertions, response waits, URL waits, or state-based waits.
   - If selector verification cannot run, mark output as draft/unverified with `required`, `blocked:no-browser-tool`, or `blocked:no-access`.

7. **Run narrow verification**
   - Run the smallest command available: tag, file, focused grep, or specific test name.
   - Then run lint/typecheck if the repo has fast commands.
   - Report commands run, results, and any blocked verification.

## AIDLC Manual Test Cases To E2E

When consuming `aidlc-test-cases` output, treat the Markdown document as canonical.

Read these sections if present:
- Header and source artifacts
- Scenario inventory
- E2E automation handoff
- Reusable step vocabulary
- Gherkin scenarios
- Automation handoff notes

Mapping rules:

| AIDLC field | E2E usage |
| --- | --- |
| `Test Case ID` | Stable tag if no external key exists |
| `Source ID` | Traceability in title/comment/report notes |
| `Automation Target` | Generate only when `e2e` |
| `E2E Candidate` | Generate when `yes`; ask or defer when `conditional` is unclear |
| `Framework Target` | Prefer if it matches repo detection |
| `Scenario Tag` | Canonical executable tag, e.g. `@BKM5-1942` |
| `Test Data Shape` | Choose inline values, `Examples`, fixture, or `DataTable` |
| `POM/page area` | Search/update nearest page object or screen abstraction |

If the document lacks E2E handoff metadata, infer only from explicit scenario content and existing repository patterns. Do not invent routes, selectors, Xray keys, or unsupported framework choices.

## E2E Selection Rules

Good E2E candidates:
- Critical user journeys and revenue/business-critical flows
- High-confidence regression paths across multiple components
- Authentication, checkout, booking, submission, or workflow completion paths
- Browser-visible validation, permission, or state-transition behavior
- Scenarios where real integration adds value beyond unit/integration tests

Poor E2E candidates:
- Pure calculation or internal logic
- Exhaustive validation matrices better handled by unit/integration tests
- API contracts without browser behavior
- Implementation details or private component state
- Edge cases that make the suite slow/flaky without meaningful confidence

## Output Rules

When generating code, return:
- Files changed and purpose
- Traceability preserved from manual test case to executable scenario
- Reuse decisions: existing steps/POM/helpers reused vs new code added
- Selector verification status
- Verification commands and results
- Known gaps or follow-up questions

When only planning, return:
- Framework detected
- Candidate scenarios selected/skipped
- Files likely to change
- Risks and required selector/browser verification

## Quality Gate

Before finishing, check:
- Source scenario is in scope and traceability is preserved
- Framework-specific reference was followed
- Existing code was searched before generating new code
- No duplicate Cucumber steps or redundant POM methods were introduced
- Tests are deterministic and independent
- Runtime data does not leak across tests/workers
- New selectors are verified through MCP/browser tooling, existing passing tests, or clearly marked as blocked/required
- Narrow verification ran or blocked reason is documented

## Handoff

- If the user needs manual QA scenarios first, invoke `aidlc-test-cases` before this skill.
- If the user needs code review after implementing E2E tests, use the normal code-review workflow.
- If the user needs browser performance data, pair with `chrome-devtools` after E2E flow is stable.
