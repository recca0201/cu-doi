# Tests Later Task Block

Use this task block when implementation must be planned first and test work is intentionally grouped after implementation tasks.

## Template Structure

```markdown
### {N}. {Group task title}

- [ ] {N}.1 Implement {behavior, component, or integration}
  - Reference: US-{n} AC-{section}.{criterion}
  - Files: `{path/to/file}`
  - Implement {specific code change, component, function, route, or integration}.
  - Leave clear test seams for later coverage in task {N}.2.
  - Validate with {build, typecheck, lint, or targeted smoke command that does not replace automated tests}.

- [ ] {N}.2 Add automated coverage for implemented behaviors
  - Reference: US-{n} AC-{section}.{criterion}
  - Files: `{path/to/test}`
  - Test cases:
    - {behavior from task N}
    - {edge case from task N}
    - {integration path from task N}
  - Validate with `{targeted test command}`.
```

## Rules

1. Use this format only when project constraints require implementation tasks before test tasks.
2. Cite granular requirement criteria with `Reference: US-{n} AC-{section}.{criterion}` on every checkbox item.
3. Every implementation task MUST name the later test task that will cover it.
4. Every later test task MUST list the implementation task behaviors it covers and the concrete test file paths.
5. Prefer `test-first` or `implement-with-tests` when coverage gates, SonarQube, or review policy depend on tests landing with implementation.
