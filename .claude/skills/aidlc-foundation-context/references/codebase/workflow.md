# Codebase Summary Workflow

**Output**: `aidlc-docs/foundation/codebase-summary.md`
**Agent**: ai-solutions-architect
**Target Length**: 500-750 lines (guideline, not a cap)

## Inputs this document cannot invent

**Brownfield: nothing.** Every fact here is observable — tree, dependencies, scripts, configs. Asking the user about any of it is a smell; read the repo (or the saved repomix output). This is where the gate should cost zero turns.

**Greenfield: almost everything**, since there is no repo to read (floor in `references/input-gate.md`). A fabricated dependency list is quietly corrosive — someone runs the setup steps, they fail, and the whole foundation set loses credibility. Write the sections the inputs support and list the rest under Assumptions & Open Inputs.

Inline: ask before writing. Dispatched: use the brief's Confirmed values, report gaps in `unresolved_inputs`.

## When dispatched as a subagent

If you received a **Shared Facts Brief**, follow your dispatch prompt's rules (contract in `references/subagent-brief.md`): use the brief's facts without re-running repomix (read the saved repomix output named in the brief for the full tree/configs), ask the user nothing, cross-reference anything outside your ownership, self-validate (below), write the file, and return the structured summary.

## Focus

**Purpose**: Project structure, setup mechanics (WHAT/WHERE)

### Include

- Project status (brownfield/greenfield)
- Technology stack (list only)
- Complete directory structure with descriptions
- Dependencies (production + dev with versions)
- Build/run scripts (all commands — package.json, Makefile, etc.)
- Configuration files (summary + key settings + file references)
- Initial setup steps (numbered, actionable)
- Foundation documents cross-reference

### Exclude

- ❌ Architecture rationale
- ❌ Component UI examples
- ❌ Coding patterns

### Note

Single source of truth for configuration files - all other docs reference this.

## Greenfield vs Brownfield

**Brownfield** (existing codebase):
- Use `repomix` to analyze the codebase (see Tools below)
- Extract real directory structure, actual dependencies, real config files
- Setup steps come from the actual project README/scripts

**Greenfield** (new/empty project, nothing to scan yet):
- Skip repomix — no codebase exists
- Derive directory structure from the **agreed** intended architecture (the Shared Facts Brief in orchestrated runs; system-architecture.md when it already exists; the user via the input gate when neither exists)
- List planned dependencies based on the agreed tech stack — agreed, not guessed
- Document planned config files and build scripts as "to be created"
- Mark all sections clearly as **Planned** rather than observed. Reserve **Planned** for what the user agreed to build; anything you chose because they deferred is **Assumed** and belongs in Assumptions & Open Inputs too

## Process

1. Determine project type (brownfield → use repomix; greenfield → derive from architecture)
2. Document project status
3. Scan or plan complete directory structure with descriptions
4. Extract or specify technology stack (list only)
5. List all dependencies (actual or planned)
6. Document build/run scripts
7. Summarize configuration files with key settings and references (or mark as planned)
8. Provide setup instructions

## Required Sections

1. Project Status
2. Technology Stack (list only)
3. Complete Directory Structure
4. Dependencies (production + dev)
5. Scripts (build/run/test commands)
6. Configuration Files (summary + key settings + references)
7. Initial Setup Steps
8. Foundation Documents Reference
9. Assumptions & Open Inputs (greenfield mainly; omit only when nothing was assumed or left open)

## Constraints

- Brownfield: use `repomix` to analyze the codebase (in orchestrated runs, read the saved repomix output instead of re-running it)
- No architecture rationale, UI examples, or coding patterns
- Single source of truth for configurations (summary only - not full code)
- Config pattern: File path + purpose + 2-3 key settings + reference link
- AI agent reads actual config files when needed (progressive disclosure)

## Tools

- **repomix**: Package entire codebase into AI-friendly format for comprehensive analysis
  - Use: `repomix --include "src/**,*.json,*.md" --style markdown`
  - Helps identify directory structure, dependencies, and configuration files

## Post-generation validation (Todo Tool)

Add Todo: "Validate: codebase-summary.md" then confirm:
- Required Sections present
- 500-750 lines (or longer when justified)
- Single source of truth for configs (summaries + references, not full code)
- Brownfield: every fact traces to the repo, nothing asked of the user that the code answers
- Greenfield: Planned vs Assumed used correctly, no fabricated dependency versions or setup steps
- Content concise (no architecture rationale, no patterns)
