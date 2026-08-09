# Brownfield Import

Use this guide when the input is existing requirements material — a BRD, a backlog export, Jira/ADO tickets, or informal requirement docs — rather than a fresh feature request. The goal is normalization without silent rewriting: every output story must be traceable back to its source, and every change of meaning must be visible to the user.

## Workflow

1. **Inventory the source.** List every requirement-bearing item in the input — BRD sections, tickets, backlog rows, bullet lists. Give each a source reference (ticket ID, section heading, row number). This inventory is what makes step 6's "nothing dropped silently" check possible.

2. **Map items to story candidates.** Group by user-visible outcome, not by source document order — BRDs are usually organized by system area, which is exactly the technical-layer split the skill avoids. One source item may split into several stories; several items may merge into one. Keep the item → story mapping until the artifact is approved.

3. **Preserve source identity.** Carry ticket IDs into `Related ADO` / `Related Jira` fields on each story, and pass the source files as `--source` arguments to the scaffold script so `source_artifacts` frontmatter records provenance. Downstream sync (push/pull with Jira or ADO) depends on these links.

4. **Normalize acceptance criteria** into the selected story-block format. Tightening wording is the job; changing meaning is not. If a source criterion is untestable as written ("should be user friendly"), do not invent a testable substitute — treat it as an unresolved decision.

5. **Dedupe against existing artifacts.** Check `{aidlc-docs-root}/story-artifacts/` and `{aidlc-docs-root}/specs/` for stories that already cover an inventoried item. Reference the existing story instead of duplicating it, and flag contradictions between the import and prior artifacts for the user.

6. **Flag, don't fix.** Conflicts between source items, gaps the source never addressed, and vague-but-load-bearing wording all go through the same Pre-Generation Decision Gate as greenfield requests (`references/elicitation-guide.md`). The source being written down does not make its ambiguities resolved.

## What not to do

- Do not renumber or edit existing story artifacts while importing; new stories get new IDs.
- Do not drop source items silently — every inventoried item ends up mapped to a story, merged into one, deferred with a note, or flagged as a question.
- Do not upgrade vague source wording into invented specifics. Vagueness in a BRD is an open decision owned by the user, exactly as it would be in a verbal request.
