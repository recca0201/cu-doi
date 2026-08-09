---
name: aidlc-estimation
description: "Business Complexity Points (BCP) estimation and BCP-to-time conversion for AIDLC artifacts. Use when: (1) Estimating complexity of user stories, units, or specs during Inception or Construction phases, (2) After user stories creation, units decomposition, or spec refinement, (3) Generating BCP reports with 10-dimension assessments using T-shirt sizing, (4) Converting a finalized BCP into effort and duration — trigger on 'how long will this take', 'timeline from estimation', 'team capacity estimate', 'convert BCP to time', or any request for man-months/person-days/delivery duration based on BCP. Provides AI-assisted analysis with human review. Covers Business Rules, Interface Elements, Roles/Permissions, Solution Variabilities, Domain Entities, Boundaries, and optional dimensions (New Entities, Background Processes, Notifications, Audits), plus capacity-based time estimation (org standard: 170 BCP per man-month)."
---

# AIDLC BCP Estimation

Estimate Business Complexity Points for AIDLC artifacts using standardized methodology.

## Overview

This skill provides **hybrid AI-assisted + human review** BCP estimation for:
- **User Stories** (Inception phase)
- **Units** (Inception phase)
- **Specs** (Construction phase: requirements/design/tasks)

**Approach:** AI reads foundation context to understand the existing system, analyzes current codebase to validate assumptions and identify existing patterns, analyzes artifacts, and generates initial BCP assessment with confidence indicators, then prompts human to review dimensions with low confidence before finalizing the report.

## When to Use This Skill

**Inception Phase:**
- After user stories creation → Estimate story-level BCP for backlog prioritization
- After units decomposition → Estimate unit-level BCP for sprint planning

**Construction Phase:**
- After requirements refinement → Validate and refine BCP estimates
- After design creation → Most accurate estimation with full technical detail
- After task breakdown → Track BCP across implementation tasks

**Key principle:** Estimate at all 3 levels for comprehensive tracking, but use **Spec-level as authoritative** for reporting.

## BCP Rule Source

Use [complexity-ruler.md](references/complexity-ruler.md) as the single source for all 10 dimensions, allowed T-shirt sizes, occurrence rules, mandatory dimensions, and calculator validation rules.

Formula: `Total BCP = Σ (Occurrences × T-Shirt Points)` across all dimensions.

## AI-DLC Docs Root

Paths below use `{aidlc-docs-root}/…`. Resolve it from `.mtv-aidlc/extension-config.json` `aidlcDocsPath` (searched upward), falling back to `aidlc-docs`. Don't hardcode `aidlc-docs/` — projects often configure it elsewhere (e.g. `apps/<app>/aidlc-docs`).

## Stability Principle

BCP estimates are stable when independent runs read the same evidence, apply the same calculator rules, and converge on similar points. Scripts may extract evidence, validate calculator constraints, and compare run outputs; they must not replace estimation judgment with brittle keyword scoring.

For specs, use this stability loop:

1. Build an evidence pack from the artifact source set: `requirements.md`, plus `design.md` and `tasks.md` when present.
2. Estimate from that evidence pack and the BCP ruler. Score only after evidence is listed for each dimension.
3. Run 3 independent estimates for important or calibration-sensitive specs. Use subagents when available; otherwise run the same prompt three separate times and save each estimate JSON.
4. Compare the 3 JSON outputs with `compare_bcp_estimates.py`. Pass condition: `max_numerical_deviation_percent` is below 20.
5. If the gate fails, inspect the dimensions with drift, clarify evidence or rules, revise the workflow or artifact, then rerun. Do not average conflicting runs; pick the value that the cited evidence and complexity ruler support.

## Estimation Workflow

### Estimation Independence Rule

**Always estimate from the artifact and evidence, not from prior reports.** If a previous BCP estimate file or report exists for the same artifact, do not read it before completing your own assessment. Looking at an existing estimate anchors your scoring to someone else's judgment and defeats the purpose of independent validation. Only after you have finalized your own table should you optionally compare totals if the user asks for a reconciliation.

### Step 1: Identify Artifact to Estimate

Determine what you're estimating:
- **User Story:** `{aidlc-docs-root}/story-artifacts/{story-name}.md`
- **Unit:** a unit section inside a units-decomposition file under `{aidlc-docs-root}/requirements/` (e.g. `{NNN}_{feature}_units_decomposition.md`)
- **Spec:** `{aidlc-docs-root}/specs/{unit-slug}/requirements.md` + `design.md` + `tasks.md`

**Batch inputs:** If the request includes multiple user stories, units, requirements, or specs, spawn one subagent per artifact and run the estimates in parallel. A units-decomposition file is always a batch input: estimating "the units file" means one subagent per unit defined in it, each given the file path plus its assigned unit name and scoped to estimate only that unit (single-unit flow applies only when the user names one specific unit). Each subagent must use the `aidlc-estimation` skill to estimate its assigned artifact and return the Step 7 table with the `Evidence` column populated. The main agent must not estimate dimensions directly; it only assigns artifacts, collects subagent outputs, checks consistency, prepares the consolidated report, and performs the Step 9 write-back once after consolidation (subagents never edit shared artifact files). If any subagent output lacks evidence, ask that subagent to revise before consolidation. If subagents are unavailable, ask the user before estimating sequentially.

### Step 2: Read BCP Rules (ALWAYS)

**REQUIRED:** Always read the complexity ruler reference first:

1. **[complexity-ruler.md](references/complexity-ruler.md)** - Complete dimension criteria and T-shirt sizing rules for all 10 dimensions

**Why this is critical:**
- Provides exact sizing criteria for XS/S/M/L/XL for each dimension
- Defines occurrence counting rules (Interface Elements per 5, New Entities per 3, etc.)
- Ensures consistent application of BCP methodology
- Prevents sizing errors and improves estimation accuracy

Read [bcp-methodology.md](references/bcp-methodology.md) only when the user asks about BCP concepts, rationale, Story Points comparison, or broader methodology background.

### Step 3: Read Foundation Context (Selective)

**Strategy:** Read foundation files selectively based on artifact type and dimensions being assessed. Avoid reading all files unnecessarily to optimize token usage.

#### Core Foundation (Always Read)

**1. `{aidlc-docs-root}/foundation/project-overview-pdr.md`** - Always read first
- **Provides:** Product vision, domain understanding, business concepts
- **Critical for:** Domain Entities, Business Rules, overall context
- **Skip if:** Never (always read for all estimates)

#### Conditional Foundation (Read as Needed)

**2. `{aidlc-docs-root}/foundation/system-architecture.md`**
- **Provides:** Architecture patterns, boundaries, existing integrations
- **Critical for:** Boundaries, Background Processes, integration complexity
- **Read when:** Story mentions integrations, external APIs, or distributed components
- **Skip if:** Simple CRUD, UI-only changes, no external system interaction

**3. `{aidlc-docs-root}/foundation/codebase-summary.md`**
- **Provides:** Existing domain entities, tech stack, components
- **Critical for:** New Domain Entities (differentiating new vs existing)
- **Read when:** Brown-field project with existing entities, need to assess what's new
- **Skip if:** Green-field project, backend-only with no entity changes

**4. `{aidlc-docs-root}/foundation/uiux-guideline.md`**
- **Provides:** UI patterns, design system, component library
- **Critical for:** Interface Elements (static/dynamic determination, element counting)
- **Read when:** Frontend work, UI changes, interface elements present
- **Skip if:** Backend-only unit/spec, API-only stories, no UI components

**5. `{aidlc-docs-root}/foundation/code-standards.md`**
- **Provides:** Coding standards, conventions, solution variabilities
- **Critical for:** Solution Variabilities (parameter-driven behavior patterns)
- **Read when:** Complex configuration scenarios, multi-tenant features
- **Skip if:** Simple stories with single solution path, standard CRUD operations

#### Decision Tree

**For User Story estimation:**
```
1. Always read: project-overview-pdr.md
2. Has UI elements? → Read uiux-guideline.md
3. Mentions integrations/APIs? → Read system-architecture.md
4. Modifying entities? → Read codebase-summary.md
5. Complex configuration? → Read code-standards.md
```

**For Unit estimation:**
```
1. Always read: project-overview-pdr.md
2. Frontend unit? → Read uiux-guideline.md
3. Backend unit with integrations? → Read system-architecture.md
4. Creating/modifying entities? → Read codebase-summary.md
5. Configuration-heavy? → Read code-standards.md
```

**For Spec estimation:**
```
1. Always read: project-overview-pdr.md
2. Has design.md with UI components? → Read uiux-guideline.md
3. Has requirements.md mentioning APIs/integrations? → Read system-architecture.md
4. Has design.md with new entities? → Read codebase-summary.md
5. Has complex variability in requirements? → Read code-standards.md
```

### Step 4: Analyze Current Codebase Selectively

Analyze the codebase only when it improves estimate accuracy. Keep the search proportional to the artifact level and the uncertainty being resolved.

**By artifact level:**
- **Story:** Light scan for similar features, existing domain entities, reusable UI/API patterns, or unclear new-vs-existing entity assumptions.
- **Unit:** Moderate scan of related modules, services, components, boundaries, and partial implementations the unit will extend.
- **Spec:** Deep scan when design/tasks are available: verify planned components against code, check completed tasks, validate actual entities, services, and integration points.

**Use deep analysis when:**
- The project is brown-field or maintenance/enhancement work.
- The estimate depends on whether entities, boundaries, UI patterns, or services are new or existing.
- Estimating remaining work after implementation has started.
- The artifact conflicts with code or foundation docs.

**Skip or keep minimal when:**
- The project is green-field with little/no existing code.
- The artifact is high-level and code details would not change BCP sizing.
- The relevant dimensions are already explicit and high-confidence from the artifact and foundation context.

Use targeted file searches and reads; cite source paths when code evidence affects a dimension or confidence level.

### Step 5: Read and Analyze Artifact

**Estimation Context by AIDLC Phase:**

| Level | Artifact | Granularity | Accuracy | When to Use |
|-------|----------|-------------|----------|-------------|
| **User Story** | `story-artifacts/*.md` | High-level business functionality | ±30-40% | After story creation, for backlog prioritization |
| **Unit** | `requirements/units-decomposition.md` | Technical implementation units | ±20-30% | After decomposition, for sprint planning |
| **Spec** | `specs/{unit}/requirements.md` + `design.md` + `tasks.md` | Detailed technical specification | ±10-15% | After requirements/design/tasks, authoritative estimate |

**For User Story:**
- Read story description and all acceptance criteria
- Identify business concepts, UI elements, integrations mentioned
- Note: High-level information, may need assumptions
- Focus on business requirements, not technical decisions

**For Unit:**
- Read unit description, scope, and dependencies
- Focus on technical implementation responsibility
- Consider unit boundaries and integrations
- More technical clarity than story level

**For Spec:**
- Read requirements.md, design.md, and tasks.md
- Most detailed view - count specific components, entities, APIs
- **Source of truth for accurate estimation** (use for velocity tracking)
- Complete technical visibility with all design decisions
- For reusable calibration or future specs, create an evidence pack before scoring:
  `python3 .claude/skills/aidlc-estimation/scripts/extract_spec_evidence.py <spec-or-specs-dir> --output <workspace>/evidence.json`
- Apply the "Dimension Calibration Rules" in `complexity-ruler.md` before scoring — they resolve counting-granularity and sizing ambiguities for every estimate, not just sparse ones. If only `requirements.md` exists, also follow its requirements-only tie-breakers and keep design-dependent dimensions at Medium/Low confidence unless the requirement text is explicit enough to count.
- Use the evidence pack as a checklist, not as an estimate. Add missing evidence from foundation docs or codebase scans before assigning points.

### Step 6: Assess Each BCP Dimension

For each of the 10 dimensions:

1. **Determine applicability:** Does this dimension apply? Optional dimensions can be N/A; mandatory dimensions cannot.
2. **Name the counted unit:** Rule set, interface component pattern, permission model, variant model, entity, boundary model, process, notification combination, or audited entity.
3. **Count quantity or occurrences:** Use the per-dimension calculation protocol in `complexity-ruler.md`; do not count every requirement sentence unless the dimension's counted unit is truly independent.
4. **Select T-shirt size:** Apply only sizes allowed by the ruler. Do not use a size that the standard ruler leaves unspecified.
5. **Calculate points:** `Occurrences × Size Points`.
6. **Assess confidence:** High/Medium/Low based on information quality.
7. **Document rationale:** Clear explanation citing specific evidence: AC/REQ/US IDs, design sections, source files, or an `evidence` list.

**Calculator rule checks:**
- Use only the T-shirt sizes allowed for each dimension in complexity-ruler.md.
- Interface Elements occurrences must be `ROUNDUP(qty / 5, 0)`.
- New Domain Entities occurrences must be `ROUNDUP(qty / 3, 0)`.
- Domain Entities complexity is derived from `qty`: 1=XS, 2-3=S, 4-5=M, 6-7=L, >7=XL.
- Points must equal `occurrences × size points`; do not override totals manually.
- When evidence is incomplete, lower confidence instead of inflating points.
- Apply the Dimension Calibration Rules in `complexity-ruler.md` to resolve sizing ambiguity consistently across agents; for requirements-only specs, additionally use its conservative tie-breakers.

**Dimension assessment signals:**

- **Business Rules:** Count distinct rule sets — a validation group, decision workflow, formula, or state transition that can change independently. Do **not** use the number of acceptance criteria or `SHALL` sentences as a proxy for occurrences; multiple related ACs that all belong to the same workflow are one rule set. Size the rule set by its own phase/decision density (XS simple check, S few steps no decisions, M few steps with decisions, XL many steps or many decisions). If a functional section has no decision points at all, prefer XS or S over XL regardless of how many ACs describe it.
- **Interface Elements:** Count only runtime user-facing or API-contract-facing elements: UI controls, data display components, API endpoints, request/response fields, and schema fields that are part of the delivered product's contract. Do **not** count infrastructure/configuration artifacts (Dockerfiles, CI scripts, linter configs, env files, architecture docs, IAM descriptions, operational runbooks) as Interface Elements — those are N/A. For backend-only or infrastructure-only specs with no runtime UI or API contract, mark this dimension N/A. For backend API specs that define endpoints/schemas, use static sizing (S existing context, M new context) unless dynamic interaction patterns are explicit.
- **Roles/Permissions:** Identify user types, permission sets, role depth, guards, middleware, or access matrices. Size by permission structure complexity, not by the number of named users.
- **Solution Variabilities:** Look for configurable behavior, feature flags, tenant/product differences, strategy patterns, or parameter-driven paths. Size by how much behavior changes between variants: a parameter that selects between runtime behaviors or external targets (e.g. a model-selection env var) is at least M even if application branching is identical; use XL only when parameters change the strategy, topology, or contract.
- **Domain Entities:** Count business concepts, models, records, aggregates, and dependency entities involved in the artifact. Include entities read or referenced for decisions, not only entities being written.
- **New Domain Entities:** Distinguish new or modified entities from existing ones; use foundation docs or targeted code evidence when unclear. Count modified existing entities separately from newly introduced domain concepts.
- **Boundaries:** Identify external systems, APIs, services, devices, queues, databases, or ownership/durability boundaries. Size by the nature of exchange and ownership, not just endpoint count. The M-vs-XL question is payload durability: remote exchange of durable/perennial business information is M; ethereal/request-scoped payloads (audio, transient transcripts, model outputs never stored) are XL even when they are the business deliverable.
- **Background Processes:** Count scheduled, automated, async, batch, worker, or system-triggered processes. Separate distinct triggers or execution responsibilities when they can fail or change independently.
- **Notifications:** Count distinct notification triggers, templates, channels, or recipient types. Group repeated sends from the same trigger/template unless channel or recipient logic differs.
- **Audits:** Count entities requiring history, audit trail, change log, or compliance traceability. Include actor, timestamp, before/after value, or retention requirements in the rationale when present.

### Step 7: Present Initial Assessment

Generate assessment table with:
- All 10 dimensions
- Occurrences, quantity (where applicable), complexity size, points
- Confidence level for each dimension
- Evidence references: AC/REQ/US IDs, spec sections, source paths, or foundation docs
- Rationale explaining the sizing with specific references

**Format example:**
```markdown
| Dimension | Occ | Qty | Complexity | Points | Confidence | Evidence | Rationale |
|-----------|-----|-----|------------|--------|------------|----------|-----------|
| Business Rules | 1 | - | XL (8) | 8 | High | AC-3, AC-4 | Multi-step approval with 5 decision points per complexity ruler XL criteria |
| Interface Elements | 4 | 16 | S (2) | 8 | Medium | AC-2, design.md#form-fields | ~16 form fields. ROUNDUP(16/5)=4 occurrences × S(2) per ruler |
...
```

**Confidence Level Criteria:**

**High Confidence:**
- Explicit information in artifact (clear counts, documented decisions)
- Examples: "5 form fields", "3 entities", design decisions documented

**Medium Confidence:**
- Inferred from context with reasonable assumptions
- Examples: General descriptions, typical implementation patterns assumed

**Low Confidence:**
- Significant guesswork required
- Examples: Conflicting/missing information, technical unknowns at current phase

### Step 8: Request Human Review

**Flag dimensions needing review:**
- Low confidence dimensions
- Mandatory dimensions marked N/A
- Significant assumptions made
- Conflicting information in artifacts

**Ask user:**
> "I've generated an initial BCP assessment with **[X] total points** (**[Category]** complexity).
>
> **Confidence Summary:**
> - High: [N] dimensions
> - Medium: [N] dimensions
> - Low: [N] dimensions
>
> I have low confidence on these dimensions: [list with rationale].
> Would you like to review and adjust these before finalizing the report?"

### Step 9: Finalize and Save Report

After human validation/adjustments:

1. **Generate final markdown report** with updated values
2. **Save to:** `{aidlc-docs-root}/estimation/{artifact-type}-{artifact-name}-{timestamp}.md`
3. **Display summary:** Total BCP, complexity category, confidence distribution
4. **Write the estimation point back to the artifact meta.** How depends on whether the artifact owns its file:
   - **File-per-artifact (user story file, spec `requirements.md`, quick-spec `spec.md`):** update the artifact's YAML frontmatter: set `estimation_bcp` to the finalized total, `estimation_report` to the workspace-root-relative path of the report saved in step 2, and `updated` to the estimation date. The field schema is defined in `.claude/skills/_aidlc-shared/scripts/artifact_metadata.py`.
   - For `requirements.md` and quick-spec `spec.md`, also replace the `**Estimation (BCP)**` visible-header value with `{total} ([report]({relative-report-path}))`.
   - **Units (sections of a shared units-decomposition file):** the file's frontmatter has only one `estimation_bcp` slot, so per-unit totals are recorded in the document body instead:
     - Under each estimated unit's section heading, add or update an `**Estimation (BCP)**: {total} ([report]({relative-report-path}))` line alongside the unit's other attribute lines (Purpose, Dependencies, etc.).
     - If the file has a unit summary/prioritization table, add or update a `BCP` column with each estimated unit's total; leave cells for unestimated units empty.
     - Set the file-level frontmatter `estimation_bcp` (sum of unit totals) only when every unit in the file has an estimation line, and point `estimation_report` at the consolidated batch report when one exists; otherwise leave file-level fields untouched.
     - In batch mode, the main agent performs this write-back once after consolidation — subagents must not edit the shared decomposition file, or concurrent edits will corrupt it.
   - Idempotent: if these fields/lines/cells already exist (re-estimation), overwrite the values in place — do not append duplicates.
   - If the artifact has no frontmatter (legacy doc), skip the frontmatter update and apply only the visible body updates above; do not fabricate a frontmatter block.
5. **Suggest the next step.** After presenting the summary, offer the time-estimation phase in one line — e.g. *"Want me to convert this into a time estimate (effort/duration) using your team capacity?"* BCP alone answers "how complex"; most users finalizing an estimate also need "how long", so surface the option without running it uninvited. For batch/unit estimates, mention that the resulting time rollup can then update the product roadmap (`aidlc-units-roadmap`).

**Report format:** Standardized markdown with all 10 dimensions, evidence, rationale, confidence summary, and metadata footer. For batch reports, every per-artifact breakdown table must preserve the `Evidence` column from the subagent outputs.

## Time Estimation (Optional Phase — After Step 9)

When the user wants effort or duration ("how long will this take", "timeline",
"team capacity estimate", "man-months"), run the time-estimation phase **after**
the BCP total is finalized. Never estimate time before BCP is final — time
derives from BCP; a time number without a complexity basis is a guess. If no
BCP exists yet, run Steps 1-9 first.

**REQUIRED:** Read [time-estimation.md](references/time-estimation.md) before
producing any time numbers. It defines the full workflow (Steps 10-12), the
capacity model (org default: 170 BCP/man-month, overridable by a
team-calibrated rate), the `Delivery Capacity` section format in
`{aidlc-docs-root}/foundation/team-info.md`, parallelism heuristics, and the
range rules (always Optimistic/Likely/Pessimistic — never a single number).

Use `scripts/estimate_time.py` for the arithmetic — never compute
effort/duration by hand. Output goes into the BCP report only (no artifact
frontmatter changes, no separate rollup file); multi-unit runs include the
rollup table in the consolidated batch report. `aidlc-units-roadmap` re-derives
durations from per-unit BCP + `team-info.md` capacity using the same script.

## Output Format

### Markdown Report Structure

```markdown
# BCP Estimation Report

## Artifact Information
- **Name:** [artifact name]
- **Type:** User Story / Unit / Spec
- **Estimated By:** AI + Human Review
- **Date:** [timestamp]
- **Total BCP:** **[X] points**
- **Recorded To:** artifact frontmatter (`estimation_bcp`, `estimation_report`), or for units the `**Estimation (BCP)**` line in the unit's section of the decomposition file

## Complexity Breakdown

[10-dimension table with all assessments, evidence, and rationale]

**Total:** [X] points

**Complexity Category:** Trivial/Simple/Moderate/Complex/Very Complex

## Confidence Summary

- **High Confidence:** [N] dimensions
- **Medium Confidence:** [N] dimensions
- **Low Confidence:** [N] dimensions

[Review warning if low confidence dimensions exist]

---

_Business Complexity Points (BCP) estimation report_
```

### Complexity Categories

Based on total BCP:
- **Trivial** (1-10): Simple CRUD, minimal business rules
- **Simple** (11-25): Basic workflow, standard UI
- **Moderate** (26-50): Multiple decision points, moderate UI
- **Complex** (51-100): Rich business logic, complex UI, integrations
- **Very Complex** (101+): Extensive workflows, sophisticated systems

## Reference Files

Additional references (complexity-ruler.md is loaded automatically in Step 2):

- **[bcp-methodology.md](references/bcp-methodology.md)** - BCP concepts, principles, benefits vs Story Points, typical ranges
- **[calibration-examples.md](references/calibration-examples.md)** - Worked requirements-only estimates (AI summarize API, long-audio chunking, CI/CD pipeline). Read for the *reasoning* when an artifact resembles one of these shapes; re-derive counts from your own evidence rather than copying the numbers.
- **[time-estimation.md](references/time-estimation.md)** - BCP-to-time workflow (Steps 10-12): capacity model, team-info.md Delivery Capacity format, parallelism heuristics, range rules, multi-unit rollup, recalibration. Read whenever effort/duration is requested.

## Scripts

**generate_bcp_report.py** - Validates and formats BCP estimation reports

Usage:
```bash
python3 .claude/skills/aidlc-estimation/scripts/generate_bcp_report.py <estimation_json> [output_path]
```

Validates mandatory dimensions, checks confidence levels, generates formatted markdown report.

**extract_spec_evidence.py** - Extracts reusable evidence from one spec directory, one file inside a spec directory, or every spec under a specs folder. It emits source references, requirement IDs, named items, roles, warnings, and dimension signal counts, but it does not assign BCP points.

Usage:
```bash
python3 .claude/skills/aidlc-estimation/scripts/extract_spec_evidence.py specs --output aidlc-estimation-workspace/evidence.json
```

**compare_bcp_estimates.py** - Compares 3 or more independently produced estimate JSON files or run directories and computes total and per-dimension numerical deviation.

Usage:
```bash
python3 .claude/skills/aidlc-estimation/scripts/compare_bcp_estimates.py run-1/ run-2/ run-3/ --threshold 20 --output aidlc-estimation-workspace/stability-report.json
```

Use this as the repeatability gate for real estimates. The run passes only when the maximum numerical deviation across totals and dimensions is below the threshold.

**estimate_time.py** - Converts a finalized BCP total into effort (man-months / person-days) and duration (working days / weeks) with an Optimistic/Likely/Pessimistic range, using the team capacity profile. Also produces the multi-unit time rollup.

Usage:
```bash
# Single artifact
python3 .claude/skills/aidlc-estimation/scripts/estimate_time.py \
  --bcp 57 --level spec --parallel-fte 2 --team-size 3 \
  --rate 170 --rate-source team-calibrated --json-out time-estimate.json

# Multi-unit rollup
python3 .claude/skills/aidlc-estimation/scripts/estimate_time.py \
  --units-json units.json --parallel-fte 2 --team-size 3
```

See [time-estimation.md](references/time-estimation.md) for the full workflow around this script.

## Best Practices

### Mandatory Dimension Coverage

These 4 dimensions **must** have non-N/A values for every estimate:
1. Roles/Permissions
2. Solution Variabilities
3. Domain Entities
4. Boundaries

**Invalid:** Mandatory dimension marked N/A
**Valid:** Mandatory dimension with XS-XL sizing

### Rationale Quality

Always cite specific sources in rationale:

**Good rationale:**
"M (3) per complexity ruler - Iterative process with few phases (file existence check, provider selection, content gathering) and few decision points (copilot/claude/clipboard paths). Debounce logic adds one decision layer. Meets 'few phases/steps and few decision points' criteria per ruler."

**Poor rationale:**
"Complex workflow with multiple steps"

**Required elements:**
- Reference to complexity ruler criteria
- Specific AC IDs, design sections, or file references
- Explicit counts when applicable
- Assumptions clearly stated
- Concrete evidence in the rationale text or an `evidence` list in the JSON input

## Integration with AIDLC Commands

**Future commands** (not yet implemented):
- `/aidlc:estimation:stories` - Batch estimate all user stories
- `/aidlc:estimation:units` - Batch estimate all units
- `/aidlc:estimation:spec` - Estimate current spec

For now, invoke this skill directly and follow the 9-step workflow for each artifact.
