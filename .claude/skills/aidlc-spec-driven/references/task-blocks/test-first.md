# Test-First Implementation Task Block

Use this task block when implementation should be planned in a strict TDD style: red, verify red, green, verify green, then wire or refactor only after tests pass.

## Template Structure

```markdown
### {N}. {Group task title}

- [ ] {N}.1 Write the failing test
  - Reference: US-{n} AC-{section}.{criterion}
  - Files: `{path/to/test}`, `{path/to/file}`
  - Add coverage for {specific observable behavior}.
  - Test file: `{path/to/test}`
  - Expected assertion: {concrete expected result}
- [ ] {N}.2 Run test to verify it fails
  - Reference: US-{n} AC-{section}.{criterion}
  - Command: `{targeted test command}`
  - Expected: FAIL because {missing behavior}, not because of setup, syntax, or fixture errors.
- [ ] {N}.3 Write minimal implementation
  - Reference: US-{n} AC-{section}.{criterion}
  - Implementation file: `{path/to/file}`
  - Implement only {smallest production change needed to satisfy the failing test}.
- [ ] {N}.4 Run test to verify it passes
  - Reference: US-{n} AC-{section}.{criterion}
  - Command: `{targeted test command}`
  - Expected: PASS with no unrelated failures.
- [ ] {N}.5 Wire, refactor, or broaden verification only if needed
  - Reference: US-{n} AC-{section}.{criterion}
  - Files: `{path/to/integration-or-test}`
  - Keep behavior unchanged unless covered by another failing test.
```

## Rules

1. Prefer this format for feature work, bug fixes, refactoring, and behavior changes when the repo has practical automated test seams.
2. Preserve the red/green order exactly: write failing test, run it and confirm the right failure, implement minimal code, run it and confirm pass.
3. Cite granular requirement criteria with `Reference: US-{n} AC-{section}.{criterion}` on every checkbox item.
4. If a task needs multiple behaviors, split it into multiple red/green task groups rather than writing several tests before implementation.
5. Keep the implementation step minimal; do not add options, cleanup, or extra behavior that the failing test does not require.
6. Use the final wiring/refactor step only after green, and add another failing test first if wiring introduces new observable behavior.
7. Do not force this format onto generated code, configuration-only changes, documentation-only work, or UI exploration where automated behavior tests are not meaningful.
