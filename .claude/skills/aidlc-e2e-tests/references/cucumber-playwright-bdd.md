# Cucumber Playwright BDD Reference

Use this reference when a repository has `cucumber.js`, `features/`, `stepdefinitions/`, and Playwright browser APIs. This mode is for BDD frameworks that run Playwright through Cucumber step definitions, not through the Playwright Test runner.

## Repository Signals

| Signal | Meaning |
| --- | --- |
| `cucumber.js` | Cucumber runner profiles, tags, reporting, parallelism |
| `features/**/*.feature` | Executable Gherkin scenarios |
| `stepdefinitions/**/*.ts` | Cucumber step implementations |
| `types/world.ts` | Shared Cucumber world/context |
| `pages/**` | Page Object Model classes |
| `pages/page-manager/PageManager.ts` | Page object registry or lazy loader |
| `reports/cucumber-report.json` | Cucumber JSON report for HTML/Xray upload |

## Manual Test Case to Executable Feature Mapping

Map AIDLC test-case documents as follows:

| AIDLC Field | Cucumber Artifact |
| --- | --- |
| Test Case ID | Scenario tag when no Jira/Xray key exists |
| Source ID | Comment or scenario title context, not usually an executable tag |
| Scenario title | `Scenario:` or `Scenario Outline:` title |
| Preconditions | `Background` or first `Given` steps |
| Test Steps | `When` and `And` steps |
| Expected Result | `Then` and verification `And` steps |
| Test data | `Examples` or Cucumber `DataTable` |
| Automation Target | Only generate executable code for `e2e` |

Prefer `Scenario Outline` for the same flow repeated with different scalar values. Prefer `DataTable` for validation matrices such as multiple input descriptions and values.

## Feature File Conventions

Use the existing repository wording when possible. A common shape is:

```gherkin
Feature: Booking Party and Contract
  As a user I want to verify Booking Party and Contract related fields on Booking page

  Background:
    Given I am on the booking page

  @BKM5-1942 @Contact @Regression_Test
  Scenario: Contact Person Name - User can input various types of characters
    When the user enters multiple values into the "Contact Person Name" textbox
      | description         | inputValue                    |
      | Special characters  | @#$%^&*<?                     |
      | Japanese characters | japanese sample              |
    Then all input values should be accepted
```

Tag rules:
- Use exactly one canonical Jira/Xray test key when uploading execution results to Xray, such as `@BKM5-1942`.
- Add suite tags like `@Smoke_Test` or `@Regression_Test` only if the repository uses them for execution selection.
- Avoid multiple `@BKM5-*` tags on one scenario unless the test result is intentionally reported to multiple test cases.
- If no external key exists, use the stable AIDLC test case ID as a tag, such as `@TC-SPEC-001`.

## Step Definition Conventions

Search existing steps before adding new ones. Reuse exact wording or adjust the feature file to match reusable step text.

Use this TypeScript shape:

```typescript
import { When, Then, DataTable } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { CustomWorld } from '../../types/world';

When(
  'the user enters {string} into the {string} textbox',
  async function (this: CustomWorld, inputValue: string, fieldName: string) {
    await this.pageManager!.bookingContactPage.inputField(fieldName, inputValue);
  },
);
```

Rules:
- Use `async function (this: CustomWorld, ...)`, not arrow functions, so Cucumber binds `this` correctly.
- Access page objects through `this.pageManager!`.
- Store runtime data in `this.scenarioContext`, `this.bookingNo`, or typed world fields.
- Avoid module-level mutable variables because Cucumber parallel execution can leak state.
- Keep steps thin; browser operations belong in page objects.
- Avoid no-op Then steps unless the verification already happened inside a prior DataTable loop and the marker is clearly intentional.

## Page Object Conventions

Before adding code:
- Search `pages/**` for an existing page class.
- Search existing page methods for equivalent actions.
- Add only missing methods needed by the selected scenarios.
- Register new pages in `PageManager.ts` and exports only when a new page class is created.

Typical shape:

```typescript
import { Page } from '@playwright/test';
import { BasePage } from '../shared';

export class BookingContactPage extends BasePage {
  constructor(page: Page) {
    super(page);
  }

  private selectors = {
    contactPersonNameField: 'input[data-testid="contact-person-name-input"]',
  };

  public async inputContactPersonName(value: string): Promise<void> {
    await this.page.fill(this.selectors.contactPersonNameField, value);
  }
}
```

Selector priority:
1. `data-testid`
2. `name`
3. accessible role or label
4. stable CSS selector
5. XPath only for complex hierarchy

Selector policy:
- Verify selectors against the real DOM with browser tooling before marking generated code production-ready.
- If verification cannot run, comment or report `selector verification: required` and keep the output as draft.
- Do not infer selectors from similar fields without checking the actual element.

## Cucumber World and Lifecycle

Common Cucumber Playwright frameworks create a browser/context/page per scenario in hooks and expose them through `CustomWorld`.

Expected context usage:
- `this.page` for direct Playwright operations when necessary
- `this.pageManager` for page object access
- `this.scenarioContext` for cross-step values
- scenario artifacts such as video and screenshots handled by hooks

Generated code should not create its own browser lifecycle unless the repository has no existing hooks.

## Verification Commands

Prefer the narrowest existing command:

```bash
npm run test:cucumber:tag "@BKM5-1942"
npm run test:cucumber:smoke
npm run test:cucumber:regression
npm run test:cucumber
```

If the repository has a report command, run it only after the test command when the workflow expects reports. Do not upload to Xray unless the user explicitly asks or the repository workflow does it in CI.

## Quality Gate

Before finishing, confirm:
- E2E scenarios came from `Automation target = e2e` or explicit user scope.
- Feature steps match step-definition text exactly.
- No duplicate step definitions were introduced.
- Existing page methods and selectors were reused where possible.
- New selectors are verified or clearly marked as unverified.
- Runtime data uses `scenarioContext` or world fields, not module globals.
- PageManager/export updates are only added when needed.
- The scenario has one canonical traceability tag.
- The narrowest test command was run or the reason it could not run is documented.
