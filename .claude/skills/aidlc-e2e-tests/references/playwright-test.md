# Playwright Test Reference

Use this reference when the repository uses the Playwright Test runner with `playwright.config.*`, `@playwright/test`, and test files such as `*.spec.ts` or `*.test.ts`.

## Repository Signals

| Signal | Meaning |
| --- | --- |
| `playwright.config.ts` or `playwright.config.js` | Runner configuration |
| `@playwright/test` imports with `test` and `expect` | Playwright Test style |
| `tests/`, `e2e/`, or `playwright/` | Common test roots |
| `test.use`, fixtures, `test.describe` | Project-specific Playwright patterns |

## Implementation Pattern

Prefer existing project style. If no project pattern exists, use:

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature name', () => {
  test('user-visible behavior', async ({ page }) => {
    await page.goto('/path');
    await page.getByRole('button', { name: 'Submit' }).click();
    await expect(page.getByText('Saved')).toBeVisible();
  });
});
```

## Page Objects and Fixtures

Use Page Objects when the repository already uses them or when flows are repeated across tests.

```typescript
import { Page, Locator, expect } from '@playwright/test';

export class LoginPage {
  readonly email: Locator;
  readonly password: Locator;
  readonly submit: Locator;

  constructor(private readonly page: Page) {
    this.email = page.getByLabel('Email');
    this.password = page.getByLabel('Password');
    this.submit = page.getByRole('button', { name: 'Login' });
  }

  async login(email: string, password: string): Promise<void> {
    await this.email.fill(email);
    await this.password.fill(password);
    await this.submit.click();
  }
}
```

Use fixtures for setup/teardown and test data isolation. Do not share mutable state across workers.

## Selector Policy

Preferred order:
1. `getByRole`, `getByLabel`, `getByText` when accessible and stable
2. `data-testid` / `getByTestId`
3. stable `name` or semantic attributes
4. stable CSS
5. XPath only when unavoidable

Avoid selectors tied to layout, generated classes, or nth-child positions.

## Wait Policy

Prefer Playwright auto-waiting and assertions:

```typescript
await expect(page.getByRole('button', { name: 'Save' })).toBeEnabled();
await page.getByRole('button', { name: 'Save' }).click();
await expect(page.getByText('Saved successfully')).toBeVisible();
```

Use `waitForResponse` or `waitForURL` when validating navigation/API-driven state. Avoid `waitForTimeout` except as a documented last resort.

## Verification

Use the narrowest command available:

```bash
npx playwright test path/to/test.spec.ts
npx playwright test -g "scenario title"
npm run test:e2e -- path/to/test.spec.ts
```

If CI reporters or traces are configured, do not remove them. Preserve screenshots/videos/traces on failure.
