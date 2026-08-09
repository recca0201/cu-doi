---
name: magenta-mds
description: >
  Use this Chorus-project skill only when the user explicitly asks to use magenta-mds or when the active task/background context mentions Chorus, ONE, Magenta Design System, MDS, or magenta design-system UI work. It helps map Figma or product requirements to MDS components, choose valid props and variants, translate design tokens into code, answer component API questions, and review React UI code for MDS alignment. Do not use it by default for generic React, frontend, UI, design-system, or unrelated Magenta-brand tasks.
---

# Magenta Design System (MDS)

**Package:** `@ocean-network-express/magenta-react` v1.24.0  
**Styling engine:** PandaCSS (CSS-in-JS at build time, `--mag-*` CSS variables at runtime)  
**Source:** `apps/magenta/` in the d-odyssey repo  
**Font:** Noto Sans (primary font family)

Related packages:

- Core components: `@ocean-network-express/magenta-react`
- Icons: `@ocean-network-express/magenta-react-icons`
- Date/time components: `@ocean-network-express/magenta-react-dates`
- Rich text editor: `@ocean-network-express/magenta-react-text-editor`
- Unified entry package: `@ocean-network-express/magenta` with subpath imports only (`/react`, `/icons`, `/dates`, `/text-editor`)

---

## What this skill is for

Use this skill to turn ambiguous Chorus UI requests into valid MDS-based React code.

This skill is scoped to Chorus and ONE Magenta Design System work. If the task does not mention Chorus, ONE, Magenta Design System, MDS, magenta design-system UI, or an explicit request to use this skill, stop and proceed without loading MDS guidance.

Typical tasks:

- Choose the right MDS components for a screen, form, dialog, table, status badge, or navigation pattern.
- Confirm valid prop names, enum values, and size or color variants before writing code.
- Translate a Figma spec or visual description into MDS primitives and token-backed styling.
- Review existing React code for places where custom UI should be replaced or aligned with MDS.

The generated files in `references/` are the source of truth for tokens and variant props. Use them before guessing.

For icons, use the generated icon catalog before naming or importing a specific icon.

## Working approach

### 1. Identify the request type

Classify the task before answering:

- **API lookup**: the user wants valid props, variants, sizes, or token values.
- **Implementation**: the user wants JSX or TSX using MDS components.
- **Design translation**: the user has a Figma spec, screenshot, or UX requirement and needs an MDS mapping.
- **Review**: the user already has code and wants alignment with MDS.

### 2. Verify what MDS can actually do

Before suggesting props or variants:

- Read `references/components.md` for component variant props.
- Read `references/tokens.md` for token names and values.
- Read `references/icons.md` for valid icon component names and icon package usage.
- If a prop or variant is not in the references, do not invent it. Say it is not confirmed and suggest the closest supported pattern.

### 3. Map intent to components

Prefer small, composable MDS primitives over ad hoc wrappers.

- Primary actions: `Button` or `IconButton`
- Text entry: `Input`, `Textarea`, `NumberInput`, `SearchInput`, `Autocomplete`, `Select`, `TagsInput`
- Status and metadata: `Tag`, `Indicator`, `Progress`, `Spinner`
- Structure and navigation: `Tabs`, `Accordion`, `Pagination`, `Breadcrumb`, `TreeView`, `Timeline`, `Stepper`
- Overlays and help: `Dialog`, `Tooltip`, `Menu`

If the user asks for a pattern that is not directly available, compose it from supported primitives and explain the tradeoff briefly.

### 4. Write code that matches how consuming apps use MDS

- Import from `@ocean-network-express/magenta-react`.
- Import icons from `@ocean-network-express/magenta-react-icons` when the example needs a concrete icon.
- If the consuming app uses the unified `@ocean-network-express/magenta` package, use subpath imports such as `@ocean-network-express/magenta/react` or `@ocean-network-express/magenta/icons`.
- Do not import from the bare `@ocean-network-express/magenta` root export.
- Include the package stylesheet in the app entry when the task involves setup.
- Keep examples realistic: wire `label`, `helperText`, `state`, `variant`, and `size` only when they are useful to the example.
- Prefer token-backed spacing and color choices over raw hex values when custom styling is required.
- In consuming apps, do not import internal MDS implementation paths like `~styled-system/css`.

### 5. Call out uncertainty and gaps explicitly

If the request depends on information outside the skill references, say what is confirmed versus assumed. Good answers are safer than overconfident answers.

## Output expectations

Adapt the response to the task:

- For lookup questions, answer with the valid values and a minimal code example.
- For implementation tasks, provide the MDS component mapping first, then the TSX.
- For design translation, explain which MDS components cover the requested behavior and where custom styling is still needed.
- For review tasks, point out mismatches between the existing code and MDS-supported props or patterns.

When producing code, optimize for something a developer can paste into a React codebase with minimal cleanup.

## Quick Start

```tsx
import { Button, Input, Tag } from '@ocean-network-express/magenta-react'
import { BookingOutline } from '@ocean-network-express/magenta-react-icons'

// Always import the MDS stylesheet in your app entry
import '@ocean-network-express/magenta-react/dist/index.css'
```

If the task needs a specific icon, verify the icon name in [references/icons.md](references/icons.md) before using it.

If the app uses the unified package, prefer this pattern instead:

```tsx
import { Button, Input, Tag } from '@ocean-network-express/magenta/react'
import { BookingOutline } from '@ocean-network-express/magenta/icons'

import '@ocean-network-express/magenta/style.css'
```

## Important source-backed caveats

- `responsive` is a semantic MDS size option, not a freeform fluid size. Use it when the component should switch sizes across breakpoints using its built-in mappings.
- Date and time components are a separate package surface. If the request is about date pickers, calendars, or date ranges, use `@ocean-network-express/magenta-react-dates` or `@ocean-network-express/magenta/dates` rather than inventing them from core components.
- Rich text editing is also a separate package surface. If the request needs a TipTap-like editor, use `@ocean-network-express/magenta-react-text-editor` or `@ocean-network-express/magenta/text-editor`.
- The dates package bootstraps its own `dayjs` plugins at package entry; treat that behavior as package-owned rather than re-documenting internal plugin setup in consumer examples.
- For icon-only actions such as `IconButton`, provide an `aria-label`.
- For inputs without a visible `label`, provide an `aria-label`. If a visible `label` is present, that already covers accessibility in the common case.

---

## Design Tokens

Tokens are defined in `apps/magenta/packages/css/src/tokens.ts` and compiled to CSS custom properties prefixed `--mag-*`.

See [references/tokens.md](references/tokens.md) for the full token table.

Use tokens for spacing, radii, and colors whenever styling needs to stay visually aligned with MDS.

### Color palette summary

| Scale | Purpose |
|-------|---------|
| `primary` | Brand pink/magenta — `#BD0F72` at 500 |
| `secondary` | Teal — `#2F728C` at 500 |
| `neutral` | Greys — `#333333` at 900 |
| `blue` | Info / links |
| `green` | Success |
| `red` | Error / danger |
| `orange` | Warning |
| `purple` / `royal` | Accent |

### Spacing scale (key values)

`4px` `8px` `12px` `16px` `20px` `24px` `32px` `40px` `48px` `64px` `80px`  
CSS vars: `var(--mag-spacing-4)` … `var(--mag-spacing-80)`

### Border radii

| Token | Value | CSS var |
|-------|-------|---------|
| `sm` | 2px | `var(--mag-radii-sm)` |
| `md` | 4px | `var(--mag-radii-md)` |
| `lg` | 8px | `var(--mag-radii-lg)` |
| `xl` | 12px | `var(--mag-radii-xl)` |
| `full` | 9999px | `var(--mag-radii-full)` |

---

## Component Reference

Regenerated reference files live in `references/` — see [references/components.md](references/components.md) for the full table. Below are the most-used components.

For the icon catalog and shared icon props, see [references/icons.md](references/icons.md).

Treat the component table as authoritative for enum-like props such as `variant`, `size`, `color`, `state`, and `maxWidth`.

### Button

```tsx
<Button variant="fill" color="primary" size="lg">Label</Button>
```

| Prop | Values | Default |
|------|--------|---------|
| `variant` | `fill` `outline` `ghost` | `fill` |
| `color` | `primary` `secondary` `neutral` `danger` | `primary` |
| `size` | `sm` `md` `lg` `xl` `2xl` `responsive` | `lg` |
| `disabled` | boolean | `false` |
| `loading` | boolean | `false` |
| `fullWidth` | boolean | `false` |
| `floating` | boolean | — |
| `leftIcon` / `rightIcon` | `ReactNode` | — |

**Color × variant behavior:**
- `fill` + `primary` → `bg: primary.500`, white text
- `fill` + `danger` → `bg: red.500`, white text
- `outline` → white bg, colored border + text
- `ghost` → transparent bg, colored text only
- Any disabled state → `bg/color: neutral.200`

---

### IconButton

```tsx
<IconButton variant="ghost" color="neutral" size="md"><CloseIcon /></IconButton>
```

Same `variant` and `color` as Button. Extra sizes: `xs` `2xs` `3xs`.

---

### Input

```tsx
<Input label="Email" size="lg" state="error" helperText="Required" />
```

| Prop | Values | Default |
|------|--------|---------|
| `size` | `sm` `md` `lg` `responsive` | — |
| `state` | `error` `warning` `success` | — |
| `labelAlignment` | `top` `inline` `left` | — |
| `loading` | boolean | — |
| `fullWidth` | boolean | — |

Same prop shape applies to: **Textarea**, **SearchInput**, **NumberInput**, **Autocomplete**, **Select**, **TagsInput**.

---

### Select

```tsx
<Select items={[{ label: 'A', value: 'a' }]} size="lg" variant="default" />
```

Extra props vs Input: `multiple`, `clearable`, `renderValueType: 'text' | 'tag'`, `variant: 'default' | 'ghost'`.

---

### Tag

```tsx
<Tag color="primary" variant="light" size="md">Label</Tag>
```

| Prop | Values |
|------|--------|
| `color` | `neutral` `primary` `secondary` `blue` `green` `orange` `red` `purple` `royal` |
| `variant` | `light` `bold` |
| `size` | `sm` `md` `lg` `responsive` |
| `deletable` | boolean |
| `interactive` | boolean |

---

### Indicator (Badge)

```tsx
<Indicator color="red" variant="bold" size="sm" />
```

Same color palette as Tag. Sizes: `xs` `sm` `md` `lg` `responsive`.

---

### Spinner

```tsx
<Spinner size="md" />
```

Sizes: `sm` `md` `lg` `xl` `2xl` `3xl` `responsive`.

---

### Toggle / Checkbox / Radio

```tsx
<Toggle size="md" labelAlignment="right" />
<Checkbox size="sm" label="Accept" />
<Radio size="md" label="Option A" />
```

Sizes for all: `sm` `md` `lg` `responsive` (via `FormCheckSize`).

---

### Dialog

```tsx
<Dialog open={open} onClose={handleClose} maxWidth="md">
  <DialogHeader title="Title" />
  <DialogContent>…</DialogContent>
  <DialogAction>…</DialogAction>
</Dialog>
```

`maxWidth`: `xs` `sm` `md` `lg` `xl`

---

### Tooltip

```tsx
<Tooltip>
  <TooltipTrigger><button>Hover me</button></TooltipTrigger>
  <TooltipContent>Help text</TooltipContent>
</Tooltip>
```

`size`: `sm` `md` `lg` `responsive`. `caret`: boolean.

---

### Tabs

```tsx
<Tabs>
  <TabList>
    <TabListItem>Tab 1</TabListItem>
    <TabListItem>Tab 2</TabListItem>
  </TabList>
  <TabPanels>
    <TabPanel>Content 1</TabPanel>
    <TabPanel>Content 2</TabPanel>
  </TabPanels>
</Tabs>
```

`TabListItem` and `TabListGroup` accept `size: sm | md | lg | responsive`.

---

### Table

```tsx
<Table>
  <Thead><Tr><Th>Col</Th></Tr></Thead>
  <Tbody><Tr><Td>Val</Td></Tr></Tbody>
</Table>
```

Aliased exports: `Thead`, `Tbody`, `Tfoot`, `Tr`, `Th`, `Td`.  
`TableCell` (`Td`) accepts `divider: 'full' | 'half' | 'none'`.

---

### Pagination

```tsx
<Pagination size="md" type="navigable" />
```

`type`: `navigable` | `editable`.

---

### Progress

```tsx
<Progress color="primary" size="md" />  // linear
```

`color`: `primary` `green` `red`. Also exports circular variant.

---

### Stepper

```tsx
<Stepper orientation="horizontal" size="md" iconType="number">
  <Step>…</Step>
</Stepper>
```

`iconType`: `number` | `icon`. `orientation`: `horizontal` | `vertical`.

---

### TreeView

```tsx
<TreeView size="md" variant="default">
  <TreeItem>…</TreeItem>
</TreeView>
```

`variant`: `default` | `branch-line`.

---

### Timeline

```tsx
<Timeline orientation="vertical" size="md">
  <TimelineItem>…</TimelineItem>
</Timeline>
```

---

### Accordion

```tsx
<Accordion>
  <AccordionItem>
    <AccordionControl arrowPosition="right">Title</AccordionControl>
    <AccordionPanel>Content</AccordionPanel>
  </AccordionItem>
</Accordion>
```

`arrowPosition`: `left` | `right`.

---

## Styling Pattern (PandaCSS)

MDS uses PandaCSS recipes internally. When extending styles, use the `cx()` utility from the styled-system:

```tsx
import { cx } from '~styled-system/css'

<Button className={cx('my-class', someCondition && 'other-class')} />
```

Do **not** import from `'~styled-system/css'` in consuming apps — that path is internal to the MDS package. In consuming apps, add class names directly or use your own CSS.

---

## Reference Files

- [references/tokens.md](references/tokens.md) — Full token table (colors, spacing, radii, typography, shadows)
- [references/components.md](references/components.md) — All 46 components with variant props in one table
- [references/icons.md](references/icons.md) — Icon catalog, import package, shared props, and icon names by set

**Regenerate reference files** (run after MDS updates):

```bash
python3 .claude/skills/magenta-mds/scripts/generate_references.py
```
