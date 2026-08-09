# Cross-Reference Patterns

Use cross-references instead of duplicating content. Each piece of information lives in ONE document only.

Document-to-document relationships live in `orchestration-workflow.md` (Document relationships).

## Cross-Reference Format

### Technology Stack References

**In project-overview-pdr.md**:
```markdown
## Technology Stack

Built with Next.js 14, TypeScript, and Tailwind CSS.

For detailed architecture decisions and technical rationale, see [System Architecture](./system-architecture.md#technology-stack).
```

**In code-standards.md**:
```markdown
## TypeScript Configuration

For complete tsconfig.json, see [Codebase Summary](./codebase-summary.md#typescript-configuration).
```

### Design System References

**In project-overview-pdr.md**:
```markdown
## Design

Uses MTI Design System for consistent branding.

For complete design specifications, see [UI/UX Guideline](./uiux-guideline.md#design-system).
```

**In system-architecture.md**:
```markdown
## Component Architecture

For component specifications and code examples, see [UI/UX Guideline](./uiux-guideline.md#component-library).
```

### Configuration References

**In system-architecture.md**:
```markdown
## Build Configuration

Next.js configured for static generation with security headers.

For complete next.config.js, see [Codebase Summary](./codebase-summary.md#nextjs-configuration).
```

**In code-standards.md**:
```markdown
## Linting Rules

Key ESLint rules:
- no-unused-vars: error
- no-explicit-any: warn

For complete .eslintrc.json, see [Codebase Summary](./codebase-summary.md#eslint-configuration).
```

### Directory Structure References

**In system-architecture.md**:
```markdown
## Application Structure

High-level structure:
- app/ (Next.js App Router)
- components/ (React components)
- lib/ (Utilities)

For complete directory tree with descriptions, see [Codebase Summary](./codebase-summary.md#directory-structure).
```

## Information Ownership

This table is the single home for fact ownership — the orchestrator's reconcile step (duplication matrix) validates against it.

| Fact | Owner (detailed home) | Everyone else |
|---|---|---|
| Business vision / personas | project-overview-pdr.md | link |
| Tech stack **rationale** (WHY) | system-architecture.md | list-only or link |
| Directory tree (full) + configs (full) | codebase-summary.md | 10–20 line high-level or link |
| Code conventions | code-standards.md | link |
| Design system (colors, tokens, components) | uiux-guideline.md | link |

**Exception — `## Assumptions & Open Inputs`.** Each document carries its own, and that is not duplication: an assumption is scoped to the document whose content depends on it, and a reader checking one document's reliability shouldn't have to chase a central list. Don't collapse them into one home. The orchestrator does aggregate them at reconcile — but into its summary to the user, not into a shared document section.

## Predetermined anchors (for the orchestrator's cross-reference map)

Section headings are fixed by the templates, so link anchors are known **before** the target doc is written. This is what lets subagents cross-reference each other while generating in parallel. Hand these exact targets to subagents in the Shared Facts Brief; a subagent links to a target only if that doc is in the run scope.

| Target doc | Stable anchors to link to |
|---|---|
| project-overview-pdr.md | `#product-vision`, `#target-audience--user-personas`, `#business-objectives`, `#product-scope` |
| system-architecture.md | `#architecture-overview`, `#c4-model-diagrams`, `#technology-stack`, `#infrastructure-architecture` |
| codebase-summary.md | `#technology-stack`, `#directory-structure`, `#dependencies`, `#configuration-files`, `#initial-setup-steps` |
| code-standards.md | `#code-style--formatting`, `#naming-conventions`, `#testing-standards` |
| uiux-guideline.md | `#design-system`, `#component-library`, `#accessibility-guidelines` |

Anchors follow GitHub-style slugs: lowercase, spaces → hyphens, punctuation dropped, `&`/other symbols removed (so `## Target Audience & User Personas` → `#target-audience--user-personas`, with the double hyphen where ` & ` collapsed). Treat this table as the **approximate** target — a writer may extend a heading (e.g. add "& User Personas"), so a subagent should confirm the exact slug against the target doc's actual heading when it can, and the orchestrator's reconcile step validates every emitted anchor against real headings. If a template heading changes, update this table too.
