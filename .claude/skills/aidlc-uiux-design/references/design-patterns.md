# UX Design Patterns

Common patterns and best practices for UX specifications. Pick what fits the feature — don't apply everything.

---

## User Flow Patterns

| Pattern | Shape | Use when |
|---------|-------|----------|
| Linear Flow | `Step 1 → Step 2 → Step 3 → Complete` | Onboarding, checkout, multi-step forms, wizards |
| Branching Flow | `Start → Condition → Path A/B` | Authentication gates, role-based features, conditional logic |
| Cyclic / CRUD Flow | `List → Select → Edit → Save → List` | Dashboards, content management, task managers |
| Hub-and-Spoke | `Home ↔ Detail screens` | Mobile apps, dashboards with multiple sections |
| Funnel Flow | gated step progression | Checkout, signup, required multi-step onboarding |

---

## Wireframe Layouts

| Layout | Shape | Use when |
|--------|-------|----------|
| App Shell (Mobile) | header + main + bottom tab bar | Native-feeling mobile app with persistent navigation |
| Dashboard (Web) | top nav + sidebar + card/widget area | Admin panels, analytics dashboards, content-heavy web apps |
| List/Detail | split list and detail panel | Email clients, file browsers, settings panels |
| Form Layout | title + stacked fields + footer actions | Data entry, profile editing, configuration |
| Full-Screen Modal / Bottom Sheet | header + content + primary action | Contextual actions, quick forms, media preview on mobile |
| Empty State | illustration + explanation + primary CTA | Lists or feeds that can be empty for new users |

Use ASCII wireframes only when the screen structure is ambiguous enough that a short table row is not sufficient.

---

## Component Patterns

### Navigation Patterns

| Context | Pattern |
|---------|---------|
| Mobile primary nav | Bottom tab bar (4–5 tabs, icon + label) |
| Mobile secondary nav | Hamburger menu / drawer |
| Web primary nav | Top nav bar or collapsible sidebar |
| Web secondary nav | Breadcrumbs, in-page tabs |
| Deep hierarchy | Back button + page title in header |

### Button Hierarchy
- **Primary**: One per screen/section — the main call to action
- **Secondary**: Supporting actions (outlined or ghost style)
- **Destructive**: Red/error color; always confirm before executing
- **Icon-only**: Needs `aria-label`; use for compact toolbars only

### Button States
Default → Hover → Active (pressed) → Loading (spinner) → Disabled → Success (brief)

### FAB (Floating Action Button)
- One per screen, bottom-right
- Only for the primary creation/action (e.g., + New, Compose)
- Hide on scroll-down, show on scroll-up

### Form Validation
- Validate on blur (not on every keystroke)
- Show error inline below the field
- Error message: specific and actionable ("Enter a valid email" not "Invalid input")
- Disable submit only after first failed attempt, not proactively

### Loading States
| Duration | Pattern |
|----------|---------|
| < 300ms | No indicator needed |
| 300ms – 1s | Spinner / pulse |
| > 1s | Skeleton screen (preferred) |
| Indeterminate long | Progress bar + cancel option |
| Optimistic update | Show result immediately, revert on error |

### Skeleton Screens
- Replicate the shape of real content (cards, lines, circles)
- Animate with a left-to-right shimmer
- Don't show too many skeleton rows — match expected content count

### Drag and Drop
- Show drag handle icon (⠿) on hover/focus
- Ghost copy follows cursor during drag
- Drop zones highlight on hover-over
- Keyboard alternative: Move Up/Down buttons or cut/paste
- Announce result to screen reader: "Item moved to position 3"

### Infinite Scroll vs. Pagination
| Use | Pattern |
|-----|---------|
| Content feeds (social, news) | Infinite scroll |
| Data tables, search results | Pagination (preserves position) |
| Lists the user must return to | Pagination or "Load more" button |

---

## Interaction Patterns

### Progressive Disclosure
Show essential info first; reveal detail on demand.
- Collapsed sections, "Show more", accordions
- Use for complex settings, long forms, advanced options

### Inline Editing
User edits in place — click a value to turn it into an input.
- Show edit affordance on hover (pencil icon)
- Confirm on blur or Enter; cancel on Esc
- Use for tables, list item properties, dashboard titles

### Confirmation Dialogs
Confirm before destructive or irreversible actions.
- Title: action verb ("Delete project?")
- Body: consequence ("This cannot be undone.")
- Buttons: "Cancel" (left/secondary), "Delete" (right/danger)
- Don't use for non-destructive actions — it's friction

### Toast / Snackbar Notifications
- Success, error, warning, info variants
- Auto-dismiss after 4–6s (success), persistent for errors
- One at a time; stack if needed
- Include undo action when possible ("Deleted · Undo")

### Pull to Refresh (Mobile)
- Visual indicator on overscroll
- Spinner + "Refreshing…" label
- Lock scroll during refresh

### Swipe Actions (Mobile)
- Reveal destructive action (Delete, Archive) on swipe left
- Reveal primary action (Pin, Snooze) on swipe right
- Require explicit tap to confirm deletion, not just swipe-to-end
- Keyboard/VoiceOver alternative must exist

---

## Responsive Patterns

### Mobile-First Approach
Design for the smallest screen first; layer in enhancements.
- Define base styles for < 768px
- Add layout changes at 768px (tablet)
- Add layout changes at 1024px (desktop)

### Content Reflow
| Layout | Mobile | Tablet | Desktop |
|--------|--------|--------|---------|
| 2-column | Stack | Side by side | Side by side |
| 3-column | Stack | 2-column | 3-column |
| Sidebar | Hidden (drawer) | Collapsible | Persistent |
| Data table | Horizontal scroll or card view | Partial columns | Full table |

### Touch vs. Pointer Targets
- Mobile: 44×44px minimum with 8px gap
- Desktop: 32×32px acceptable; tooltips on hover
- Never rely on hover-only for functionality on mobile

---

See `accessibility.md` for WCAG 2.1 AA requirements and testing tools.
