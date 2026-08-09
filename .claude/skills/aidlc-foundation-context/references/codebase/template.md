# Codebase Summary - {Project Name}

**Project**: {Project Name}
**Project Type**: {Greenfield/Brownfield}
**Technology Stack**: {Framework} + {Language} + {Styling}
**Created**: {Date}
**Status**: Foundation Phase
**Analysis Tool**: repomix (AI-friendly codebase packaging)

---

## Table of Contents

1. [Project Status](#project-status)
2. [Technology Stack](#technology-stack)
3. [Directory Structure](#directory-structure)
4. [Dependencies](#dependencies)
5. [Scripts](#scripts)
6. [Configuration Files](#configuration-files)
7. [Initial Setup Steps](#initial-setup-steps)
8. [Foundation Documents Reference](#foundation-documents-reference)

> **Using this template:** replace every `{placeholder}`, keep the section order, and expand any section as needed — completeness beats a line count (see `workflow.md` for length guidance).

---

## Project Status

**Current State**: {Description of current state}

**Analysis Method**: This summary was generated using repomix to package and analyze the complete codebase structure, dependencies, and configurations

---

## Technology Stack

**Core Framework**: {Framework}
**Language**: {Language}
**Styling**: {Styling Solution}

---

## Directory Structure

**Note**: Generated using `repomix` for comprehensive codebase analysis.

```
{project}/
├── {dir}/                  # {Purpose}
│   ├── {subdir}/          # {Purpose}
│   └── {file}             # {Purpose}
├── {dir}/                  # {Purpose}
└── {config file}           # {Purpose}
```

---

## Dependencies

### Production Dependencies

```json
{
  "{package}": "{version}",
  "{package}": "{version}"
}
```

### Development Dependencies

```json
{
  "{package}": "{version}",
  "{package}": "{version}"
}
```

---

## Scripts

**package.json scripts**:
```json
{
  "scripts": {
    "{command}": "{script}",
    "{command}": "{script}"
  }
}
```

---

## Configuration Files

### {Config Name}

**File**: `{config-file}`
**Purpose**: {Brief description of what this config controls}
**Key settings**:
- `{setting}`: {value/description}
- `{setting}`: {value/description}
- `{setting}`: {value/description}

[View full config](../{config-file})

**Example**:
```markdown
### TypeScript Configuration

**File**: `tsconfig.json`
**Purpose**: TypeScript compiler settings with strict mode and path aliases
**Key settings**:
- `strict`: true (enables all strict type-checking options)
- `paths`: {"@/*": ["./src/*"]} (absolute imports from src)
- `target`: "ES2020" (compilation target)

[View full config](../tsconfig.json)
```

**Note**: Only include 2-3 most important settings. Full config files can be read when needed (progressive disclosure principle).

---

## Initial Setup Steps

### 1. {Step Title}

```bash
{commands}
```

### 2. {Step Title}

{Description and commands}

---

## Foundation Documents Reference

- [Project Overview](./project-overview-pdr.md) — business vision, personas, scope
- [System Architecture](./system-architecture.md) — architecture decisions and rationale
- [Code Standards](./code-standards.md) — code conventions and patterns
- [UI/UX Guideline](./uiux-guideline.md) — design system

*Link only to documents in this run's scope.*

---

## Assumptions & Open Inputs

*Brownfield: this section should be empty — every fact here is readable from the repo. Greenfield: list anything you chose rather than the user. Omit the section when there is nothing to list.*

| Item | Value used above | Basis | Affects | To confirm |
|---|---|---|---|---|
| {e.g. Package manager} | {e.g. pnpm} | Assumed — user deferred | {Scripts, Setup Steps} | {tech lead} |

**Open inputs** (deliberately left unstated — decision still pending):
- {input}: {which section is affected}

---

**Document Status**: Foundation - Draft
**Created By**: AI Solutions Architect
**Last Updated**: {Date}
