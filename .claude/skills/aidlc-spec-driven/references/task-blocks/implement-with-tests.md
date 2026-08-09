# Implement With Tests Task Block

Use this task block when implementation can be written before tests, but every implementation task must include its own test work.

## Template Structure

```markdown
### {N}. {Group task title}

- [ ] {N}.1 Implement {behavior, component, or integration}
  - Reference: US-{n} AC-{section}.{criterion}
  - Files: `{path/to/file}`, `{path/to/test}`
  - Implement {specific code change, component, function, route, or integration}.
  - Tests:
    - Test file: `{path/to/test}`
    - Test cases: {case 1}; {case 2}; {case 3}
    - Coverage target: exercise the implementation changed in this same task.
  - Validate with `{targeted test command}`.

- [ ] {N}.2 Integrate {implemented behavior}
  - Reference: US-{n} AC-{section}.{criterion}
  - Files: `{path/to/file}`, `{path/to/integration-test}`
  - Implement {wiring, route, UI state, data flow, or adapter change}.
  - Tests:
    - Test file: `{path/to/integration-test}`
    - Test cases: {integration success case}; {error or edge case}
  - Validate with `{targeted test command}`.
```

## Rules

1. Unit, component, or integration tests MUST be included inside the same checkbox task as the implementation they cover.
2. Never split tests into a separate task for code implemented earlier; that can cause coverage tools to report zero coverage on implementation tasks.
3. Cite granular requirement criteria with `Reference: US-{n} AC-{section}.{criterion}` on every checkbox item.
4. Include test file paths and named test cases under each implementation task.
5. Use this format when strict TDD is not required, but coverage must land with each implementation change.
