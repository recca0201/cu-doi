# Design Spec Format Reference

The Markdown spec produced by `extract_spec.py --format md` follows this schema. This document explains each section so Claude can interpret spec files accurately when generating UI code.

---

## File Header

```markdown
# Design Spec: [File Name]
Figma Last Modified: 2025-01-15T10:30:00Z  |  File key: `AbCdEfGhIjKl`
```

- **File Name**: The name set in Figma
- **Figma Last Modified**: Stable timestamp from Figma used to keep generated specs deterministic for the same input JSON
- **File key**: Used to re-fetch or cross-reference nodes

---

## Design Tokens

### Colors

```markdown
| Token | Hex | Opacity |
|-------|-----|---------|
| `primary/500` | `#1a73e8` | 100% |
| `neutral/100` | `#f5f5f5` | 100% |
| `overlay/dark` | `#00000099` | 60% |
```

- **Token**: Figma style name (often uses slash-separated namespacing like `color/brand/primary`)
- **Hex**: Resolved RGBA hex (`#rrggbb` or `#rrggbbaa` for transparency)
- Use these as the authoritative color values — do not approximate

### Typography

```markdown
| Style | Token | Font | Size | Weight | Line Height | Letter Spacing |
|-------|-------|------|------|--------|-------------|----------------|
| `heading/h1` | `size:4xl | weight:semi-bold | lh:5xl` | Inter | 32px | 700 | 40px | 0 |
| `body/regular` | `size:md | weight:regular | lh:2xl` | Inter | 16px | 400 | 24px | 0 |
```

- Map these directly to CSS `font-*` properties or framework equivalents
- Treat `Style` as the human-readable label and `Token` as the mapped design-token expression when available
- `Letter Spacing: 0` means no tracking — don't add a default
- When generating code, always apply the full typography style (size + weight + line-height together)

### Shadows & Effects

```markdown
- `shadow/card`: DROP_SHADOW: 0px 2px 8px 0px #00000026
```

Format: `type: x y blur spread color`

### Design Variables (Token System)

When present, variables supersede named styles for token-to-code mapping. They include mode-aware values (light/dark).

```markdown
#### Collection: Semantic
Modes: Light, Dark

| Variable | Type | Default Value |
|----------|------|---------------|
| `color/background/primary` | color | `#ffffff` |
| `spacing/4` | float | `16px` |
```

- **Collection**: Groups of related tokens (e.g., Primitives, Semantic, Component)
- **Mode**: The default mode value is shown — other modes exist for theming
- Variables with alias values (referencing another variable) show the resolved value

---

## Components

Each component section describes a single component or component set.

### Structure

```markdown
### Button
_Primary action button with icon support_

**Properties:**

| Property | Type | Default | Options |
|----------|------|---------|---------|
| Label | text | "Button" | |
| Size | variant | md | sm \| md \| lg |
| Disabled | boolean | false | |
| LeadingIcon | instance-swap | none | |

**Layout:**
- Direction: row
- Main axis align: center
- Cross axis align: center
- Padding: 12px 16px 12px 16px
- Gap: 8px
- Width: hug
- Height: hug
- Border radius: 8px

**Background:** `#1a73e8`

**Variants (3):** Size=sm, Size=md, Size=lg

**Child elements:**
- `Icon` (instance): icon component
- `Label` (text): "Button" — color: `#ffffff` — 16px/600
```

### Interpreting Properties

| Type | Meaning for code |
|------|-----------------|
| `text` | String prop — renders as text content |
| `variant` | Enum prop — maps to CSS classes, variant keys, or conditional styles |
| `boolean` | Toggle prop — usually maps to `disabled`, `loading`, `checked` etc. |
| `instance-swap` | Slot for another component — usually an icon or sub-component |

### Interpreting Layout

| Field | CSS/Tailwind equivalent |
|-------|------------------------|
| Direction: row | `flex-row` / `flex-direction: row` |
| Direction: column | `flex-col` / `flex-direction: column` |
| Main axis align: center | `justify-center` |
| Main axis align: space-between | `justify-between` |
| Cross axis align: center | `items-center` |
| Padding: 12px 16px | `py-3 px-4` (Tailwind) |
| Gap: 8px | `gap-2` (Tailwind) |
| Width: hug | `w-fit` / `width: fit-content` |
| Width: fill | `w-full` / `width: 100%` |
| Border radius: 8px | `rounded-lg` / `border-radius: 8px` |

### Interpreting Child Elements

Child elements describe the internal structure of a component. Use them to build accurate slot/children implementations:

- `(text)` nodes → render as text, using the specified typography style
- `(instance)` nodes → render as a sub-component (icon, avatar, etc.)
- `(frame)` or `(rectangle)` nodes → render as div/container with the described fills and layout

### Compacted Tree Notation

The Target Node and component structure trees are compacted so the spec stays readable on large screens. Two transforms are applied, both lossless for implementation:

- **Zero-size layout artifacts are pruned.** Figma auto-layout inserts helper nodes (commonly named `Resizer`, `Start`, `End`) with sub-pixel width/height (`0.001px`). They render nothing and carry no design data, so they are omitted. If you need them for a pixel-exact rebuild of the Figma auto-layout internals, consult `figma-spec.json`, which keeps the full node tree.
- **Identical repeated siblings are collapsed.** When consecutive sibling subtrees are byte-identical, they are shown once with a `(×N identical)` marker on the first line instead of N copies. Example: `- \`Autocomplete\` [col gap=4.0 w=374 h=40]  (×2 identical)` means two identical Autocomplete instances. Reproduce the element N times. Siblings that differ (e.g. table rows with different data) are NOT collapsed — each is shown in full.

---

## Screens / Frames

```markdown
| Name | Page | Width | Height | Layout |
|------|------|-------|--------|--------|
| Login Screen | Mobile | 390px | 844px | vertical |
| Dashboard | Desktop | 1440px | 900px | none |
```

- Screens represent full views/pages
- Width/Height = the Figma frame dimensions (design canvas size, not viewport)
- Layout = auto-layout direction if set; `none` means absolute positioning

---

## Using This Spec for Code Generation

When generating UI code from this spec:

1. **Start with tokens** — map color, typography, and spacing tokens to your framework's theme/config before writing components
2. **Honor the layout exactly** — padding, gap, direction, and alignment are intentional; don't approximate
3. **Use property types to choose implementation patterns** — variants → enum props, booleans → optional flags, instance-swap → slot/children
4. **Child elements define the DOM structure** — don't invent wrappers or simplify unless the nesting adds no value
5. **States come from variants** — if variants like `State=Hover` or `State=Disabled` exist, implement them as CSS states or conditional classes
