# UI/UX Guideline - {Project Name}

**Project**: {Project Name}
**Design System**: {Design System Name}
**Created**: {Date}
**Status**: Foundation Phase

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Design System](#design-system)
3. [Layout System](#layout-system)
4. [Component Library](#component-library)
5. [Responsive Design Patterns](#responsive-design-patterns)
6. [Accessibility Guidelines](#accessibility-guidelines)
7. [Animation & Interactions](#animation--interactions)

> **Using this template:** replace every `{placeholder}` (including in headings), keep the section order, and expand any section as needed — completeness beats a line count (see `workflow.md` for length guidance).

---

## Design Philosophy

### Core Principles

1. **{Principle}**: {Description}
2. **{Principle}**: {Description}

### Design Goals

- {Goal}
- {Goal}

---

## Design System

**System**: {Design System Name}

### Brand Colors

**Primary Palette**:
- **Brand Primary**: `{color}` ({Name}) - {Usage}
- **Brand Secondary**: `{color}` ({Name}) - {Usage}
- **Brand Tertiary**: `{color}` ({Name}) - {Usage}

**Extended Palette**:
- **{Name}**: `{color}` - {Usage}

### Typography

**Font Family**:
- **Primary**: `{Font Name}`
- **Fallback Stack**: `{Fonts}`

**Font Weights**:
- **{Weight} ({Number})**: {Usage}

**Type Scale**:
| Size | rem | px | Usage |
|------|-----|-----|-------|
| {size} | {rem} | {px} | {usage} |

---

## Layout System

### Grid & Spacing

**{Grid} Grid System**:
- All spacing multiples of {base}
- Common values: {values}

**Container Widths**:
- **Max Width**: `{width}`
- **Padding**: {values}

**Responsive Breakpoints**:
| Breakpoint | Min Width | Usage |
|------------|-----------|-------|
| {name} | {width} | {usage} |

---

## Component Library

### Buttons

**Button Sizes**:
| Size | Height | Padding | Font Size |
|------|--------|---------|-----------|
| {size} | {h} | {p} | {fs} |

**Button Variants**:

**1. Primary (Solid)**
- Background: `{color}`
- Text: `{color}`
- Use: {usage}

```{language}
<{component} className="{classes}">
  {label}
</{component}>
```

---

## Responsive Design Patterns

**Mobile-First Approach**:
- {Pattern}
- {Pattern}

---

## Accessibility Guidelines

### WCAG 2.1 AA Compliance

**1. {Category}**:
- {Guideline}

**2. {Category}**:
- {Guideline}

---

## Animation & Interactions

**Transitions**:
```css
{css code}
```

**Hover States**:
- {Description}

---

## Assumptions & Open Inputs

*This document is read as the single source of truth for design, so anything not Observed in code or Confirmed by the user must appear here. Omit the section only when nothing was assumed or left open.*

| Item | Value used above | Basis | Affects | To confirm |
|---|---|---|---|---|
| {e.g. Primary brand colour} | {e.g. #0B5FFF} | Assumed — no brand kit provided | {Design System, Component Library} | {brand owner / designer} |

**Open inputs** (deliberately left unstated — decision still pending):
- {input}: {which section is affected}

---

**Document Status**: Foundation - Draft
**Created By**: AI Design Orchestrator
**Last Updated**: {Date}
