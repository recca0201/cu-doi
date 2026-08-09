# Jira/Xray export notes

This skill can generate a Jira/Xray-friendly CSV profile from the Markdown source of truth.

Generated test-case documents should stay lean. Export column definitions live in
`assets/export-schema.json`; do not copy the full export schema into the Markdown document.

## Commands

Standard CSV and Excel:

```bash
python3 scripts/export_test_cases.py path/to/test-cases.md
```

Xray-friendly CSV plus standard Excel:

```bash
python3 scripts/export_test_cases.py path/to/test-cases.md --profile xray
python3 scripts/export_test_cases.py path/to/test-cases.md --profile xray --csv path/to/test-cases.xray.csv --xlsx path/to/test-cases.xlsx
```

Batch-export an eval iteration:

```bash
python3 scripts/export_eval_iteration.py .claude/skills/aidlc-test-cases-workspace/iteration-1
python3 scripts/export_eval_iteration.py .claude/skills/aidlc-test-cases-workspace/iteration-1 --profile xray --with-skill-only
```

## Xray CSV shape

The `xray` profile emits the columns configured in `assets/export-schema.json`:

| Column | Value |
| --- | --- |
| `External ID` | AIDLC test case ID such as `TC-SPEC-001` |
| `Summary` | Scenario title |
| `Issue Type` | `Test` |
| `Test Type` | `Manual` |
| `Priority` | AIDLC priority value |
| `Labels` | Derived from coverage, automation target, and priority |
| `Description` | Source IDs, source summary, coverage type, automation target |
| `Manual Test Step` | Flattened `When` steps |
| `Manual Test Data` | Flattened `Given` steps |
| `Manual Test Result` | Flattened `Then` and result steps |

## Mapping note

Jira/Xray field names and import configuration can differ by deployment and custom field setup.

Use this profile as the default starting point for CSV import, then map the emitted columns to your project's actual Xray fields during import. If your Jira/Xray instance expects different field names, keep the Markdown source canonical and adapt only the CSV export profile.
