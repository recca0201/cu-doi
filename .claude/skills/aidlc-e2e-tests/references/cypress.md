# Cypress Reference

Use this reference when the repository has `cypress.config.*`, a `cypress/` folder, or Cypress command patterns.

## Repository Signals

| Signal | Meaning |
| --- | --- |
| `cypress.config.ts` or `cypress.config.js` | Cypress runner configuration |
| `cypress/e2e/**/*.cy.ts` | Cypress E2E specs |
| `cypress/support/commands.*` | Custom command layer |
| `cy.intercept`, `cy.visit`, `cy.get` | Cypress test style |

## Implementation Pattern

Prefer existing custom commands and support files.

```typescript
describe('Feature name', () => {
  it('user-visible behavior', () => {
    cy.visit('/path');
    cy.findByRole('button', { name: 'Submit' }).click();
    cy.contains('Saved successfully').should('be.visible');
  });
});
```

If the repository does not use Testing Library commands, follow its existing selector helpers such as `cy.dataCy()`.

## Custom Commands

Add custom commands only when reused across multiple tests or already part of the project style.

```typescript
Cypress.Commands.add('dataCy', (value: string) => {
  return cy.get(`[data-cy="${value}"]`);
});
```

Update TypeScript declarations when adding commands.

## Network Control

Use `cy.intercept` for deterministic tests when third-party or slow APIs are not the behavior under test.

```typescript
cy.intercept('GET', '/api/items', { fixture: 'items.json' }).as('getItems');
cy.visit('/items');
cy.wait('@getItems');
```

Do not mock the exact integration being validated unless the scenario is explicitly an offline/error-state test.

## Selector Policy

Preferred order:
1. accessible queries when project supports them
2. `data-cy` / `data-testid`
3. stable semantic attributes
4. stable CSS

Avoid generated classes, deep DOM chains, and nth-child selectors.

## Verification

Use the narrowest command available:

```bash
npx cypress run --spec cypress/e2e/path/to/spec.cy.ts
npm run cypress:run -- --spec cypress/e2e/path/to/spec.cy.ts
```

Preserve screenshot/video/report settings configured by the project.
