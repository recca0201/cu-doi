---
name: aidlc-test-cases
description: Generate business-first, traceable AI-DLC test-case artifacts from story or spec sources. Use when Codex needs to create QA test cases, functional test cases, UAT cases, regression cases, Gherkin scenarios, table-format test cases, acceptance coverage, or CSV/XLSX/Jira-Xray exports from user stories, acceptance criteria, requirements.md, design.md, tasks.md, or mockup artifacts. Use for documented test cases, not executable test code.
---

# AIDLC Test Cases

Generate documented QA test cases from AI-DLC artifacts. Do not write executable test code.

## Core model

Separate **format** from **type**:

- `format` controls display style.
- `type` controls the scenario focus.

Supported formats:

- `gherkin-table` (default): Gherkin fields in a table.
- `gherkin-blocks`: classic `Scenario` / `Given` / `When` / `Then` blocks.
- `standard-table`: normal non-Gherkin test-case table.
- `custom`: Markdown template from `.mtv-aidlc/extension-config.json`.

Supported types (no default — never assume one):

- `functional`: business-facing QA validation, aligned to Agile Testing Quadrants Q2.
- `uat`: PO/business sign-off and real workflow fit.
- `regression`: release confidence for changed and impacted business capabilities.

Type has no default because the three types produce materially different coverage, and silently picking `functional` would routinely generate the wrong artifact. When the user request, CLI flag, or config does not make the type clear, confirm it with `AskUserQuestion` (offer `functional`, `uat`, `regression`) before generating. The CLI mirrors this: `--type` is required, so scaffolding fails fast rather than guessing.

Treat integration as a coverage note or automation target, not as a primary test-case type.

For type guidance, read `references/test-types.md` when the requested type is unclear or the source has mixed QA goals.

## Supported source scopes

### Story-level

Use when the source is:

- `aidlc-docs/story-artifacts/{story-slug}.md`
- a backlog item or user story
- acceptance criteria without a construction spec

Output:

- `aidlc-docs/test-cases/{story-slug}-test-cases.md`

### Spec-level

Use when the source is:

- `aidlc-docs/specs/{spec-slug}/requirements.md`
- optional `design.md`, `tasks.md`, `mockup.html`, or related design artifact

Output:

- `aidlc-docs/specs/{spec-slug}/test-cases.md`

Do not generate unit-level test-case artifacts.

## Workflow

1. Identify scope: `story` or `spec`.
2. Identify source artifacts: story, requirements, design, tasks, mockup, or explicit pasted requirements.
3. Identify format from the user request, CLI flag, config, or default.
4. Identify type from the user request, CLI flag, config, or default.
5. Read the relevant source artifacts before drafting.
6. Extract traceability anchors: story IDs, acceptance criteria, FR/NFR IDs, business rules, roles, and visible outcomes.
7. Generate business-first test cases in the selected format.
8. Export CSV/XLSX only when explicitly requested.

## Clarification rule

Use `AskUserQuestion` when available if an artifact-shaping input is unclear:

- source scope: story or spec
- source path or slug
- requirements or acceptance criteria
- business rules or expected behavior
- roles/personas
- test data assumptions
- format
- type

Ask one focused question and stop before generating. Do not guess requirements, expected behavior, or source scope.

## CLI

Scaffold a story-level document:

```bash
python .claude/skills/aidlc-test-cases/scripts/test_cases_cli.py init SLUG --scope story
```

Scaffold a spec-level document:

```bash
python .claude/skills/aidlc-test-cases/scripts/test_cases_cli.py init SLUG --scope spec
```

Choose format and type explicitly:

```bash
python .claude/skills/aidlc-test-cases/scripts/test_cases_cli.py init SLUG --scope spec --format gherkin-table --type functional
python .claude/skills/aidlc-test-cases/scripts/test_cases_cli.py init SLUG --scope spec --format gherkin-blocks --type uat
python .claude/skills/aidlc-test-cases/scripts/test_cases_cli.py init SLUG --scope story --format standard-table --type regression
```

Check artifact status:

```bash
python .claude/skills/aidlc-test-cases/scripts/test_cases_cli.py status SLUG --scope story
python .claude/skills/aidlc-test-cases/scripts/test_cases_cli.py status SLUG --scope spec
```

Resolution order:

1. Explicit `--format`.
2. `.mtv-aidlc/extension-config.json` `testCase.format`.
3. Default format: `gherkin-table`.

Type resolution:

1. Explicit `--type` (required by the CLI — no fallback).
2. When the type is unclear from the user request or config, confirm with `AskUserQuestion` before scaffolding.

Config shape:

```json
{
  "testCase": {
    "format": "gherkin-table",
    "customTemplatePath": null
  }
}
```

## Template assets

Use these bundled display templates:

- `assets/templates/gherkin-table.md`
- `assets/templates/gherkin-blocks.md`
- `assets/templates/standard-table.md`

Keep generated documents lean. Do not add long export schemas or E2E handoff sections to the document.
Do not add a separate `## Traceability matrix`; use the `Source ID` column in the main test-case table or scenario inventory.

## Export

Markdown remains canonical. Export only after the Markdown test-case document exists.

Use the exporter:

```bash
python3 .claude/skills/aidlc-test-cases/scripts/export_test_cases.py path/to/test-cases.md
python3 .claude/skills/aidlc-test-cases/scripts/export_test_cases.py path/to/test-cases.md --csv path/to/test-cases.csv --xlsx path/to/test-cases.xlsx
python3 .claude/skills/aidlc-test-cases/scripts/export_test_cases.py path/to/test-cases.md --profile xray
```

The exporter reads:

- `gherkin-table`: `## Test cases` table with `Given` / `When` / `Then` columns.
- `gherkin-blocks`: `## Scenario inventory` plus `## Gherkin scenarios`.
- `standard-table`: `## Test cases` table with `Preconditions` / `Steps` / `Expected result`.

CSV/XLSX column definitions live in `assets/export-schema.json`.
For Jira/Xray details, read `references/jira-xray-export.md`.

## Output rules

- Use business language first.
- Map every test case to a source ID when one exists.
- Cover happy path, negative path, edge/data conditions, role behavior, and relevant business-visible failures.
- Use `Coverage type` for scenario classification: `happy`, `negative`, `edge`, `data-boundary`, `role-permission`, or `business-rule`.
- Keep technical detail shallow and only where needed for setup, data, boundary, or observable result.
- Keep automation notes lightweight: `manual`, `unit`, `integration`, or `e2e`.
- Do not include selectors, framework paths, POM notes, or step vocabulary by default.
- Use `aidlc-e2e-tests` when the user wants executable browser tests.

## Validation before finishing

Check:

- every requirement or acceptance criterion has coverage or a documented gap
- no scenario is orphaned from source context when source IDs exist
- expected results are observable
- assumptions and open questions are explicit
- no important behavior was guessed
- exports, when requested, use the bundled exporter
