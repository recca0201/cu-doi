# Code Standards Workflow

**Output**: `aidlc-docs/foundation/code-standards.md`
**Agent**: ai-solutions-architect
**Target Length**: 300-450 lines (guideline, not a cap)

## Inputs this document cannot invent

**Brownfield: very little.** The existing code and its linter/formatter configs *are* the standard — read them out rather than legislating. Two things justify a question: the codebase genuinely contradicts itself with no config arbitrating (the user picks which style wins), or a convention exists nowhere yet (commit format, coverage target). Prescribing your own preferred style over a working codebase's is the failure mode here — it produces a document humans ignore while AI agents dutifully follow it.

**Greenfield:** the choices themselves must be Confirmed (floor in `references/input-gate.md`) — a standards document is only useful if the team actually agreed to it.

Inline: ask before writing. Dispatched: use the brief's Confirmed values, mark deferred ones **Assumed**, report gaps in `unresolved_inputs`.

## When dispatched as a subagent

If you received a **Shared Facts Brief**, follow your dispatch prompt's rules (contract in `references/subagent-brief.md`): use the brief's facts without re-running repomix, ask the user nothing, cross-reference anything outside your ownership (e.g. full configs → codebase-summary), self-validate (below), write the file, and return the structured summary.

## Focus

**Purpose**: How to write code in this specific project

### Include

- Code style & formatting (key rules only — not full configs)
- Primary language conventions (type safety, idioms, patterns for the detected stack)
- Framework/platform standards (component patterns, routing, data fetching — adapt to project's framework)
- Naming conventions (files, modules, variables — match the project's existing style)
- File organization (structure rules, imports, exports)
- Testing standards (file naming, patterns, coverage targets)
- Git & commit standards (branch naming, commit message format)

### Exclude

- ❌ Full configuration files (link to codebase-summary.md instead)
- ❌ UI component examples (belong in uiux-guideline.md)
- ❌ Architecture rationale (belongs in system-architecture.md)

### Note

Adapt sections to the detected tech stack — do not assume TypeScript/React/Next.js. For a Python/FastAPI backend, cover Python typing, FastAPI patterns, pytest. For a mobile app, cover platform idioms (Swift/Kotlin). Include good vs bad code examples for key conventions.

## Process

1. Identify the project's primary language(s) and framework(s) from codebase-summary.md
2. Extract code style rules (key rules only — use linter config if present)
3. Document language-specific conventions (typing, idioms, error handling)
4. Extract framework best practices (patterns specific to this project's stack)
5. Document naming conventions (infer from existing codebase if brownfield)
6. Identify file organization rules
7. Document testing standards
8. Extract git/commit conventions

## Required Sections (adapt names to the project stack)

1. Code Style & Formatting
2. Language Standards (e.g., TypeScript, Python, Swift — name after actual language)
3. Framework Standards (e.g., React, FastAPI, SwiftUI — name after actual framework; omit if no framework)
4. Naming Conventions
5. File Organization
6. Testing Standards
7. Git & Commit Standards
8. Assumptions & Open Inputs (omit only when nothing was assumed or left open)

## Constraints

- Show key rules only, not full configs — link to codebase-summary.md for full config files
- Brownfield: rules describe what the codebase and its configs already do; a rule you introduced yourself is marked **Assumed** so the team can accept or reject it deliberately
- No UI examples, no architecture decisions
- Include at least 2-3 good vs bad code examples for the most important conventions
- Section names and content must reflect the actual tech stack, not a generic template

## Post-generation validation (Todo Tool)

Add Todo: "Validate: code-standards.md" then confirm:
- Required Sections present and named for actual stack
- 300-450 lines (or longer when justified)
- No full config duplication (links to codebase-summary.md used instead)
- Rules reflect the project's real conventions; newly introduced rules marked **Assumed**
- Content concise (key rules only, examples included)
