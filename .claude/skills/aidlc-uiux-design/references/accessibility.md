# Accessibility Guidelines (WCAG 2.1 AA)

Essential accessibility requirements for UX specifications.

## Perceivable

### Color Contrast
- **Normal text**: 4.5:1 minimum contrast ratio
- **Large text** (18pt+ or 14pt+ bold): 3:1 minimum
- **UI components**: 3:1 for active/focus states
- Test with: WebAIM Contrast Checker

### Text Alternatives
- Alt text for images (descriptive, not "image of")
- Empty alt (`alt=""`) for decorative images
- ARIA labels for icon buttons
- Captions for video content

### Adaptable Content
- Semantic HTML (headings, lists, landmarks)
- Logical reading order
- Responsive to 200% zoom
- No loss of content or functionality when zoomed

## Operable

### Keyboard Accessible
All functionality available via keyboard:
- Tab: Move forward
- Shift+Tab: Move backward
- Enter/Space: Activate
- Esc: Close/Cancel
- Arrow keys: Navigate lists/menus

### Visible Focus
- 2px minimum indicator, high contrast
- Never remove without replacement

### Touch Targets
- Minimum 44x44 pixels, 8px spacing

### Navigation
- Skip links, consistent structure, clear titles

## Understandable

### Predictable
- Consistent navigation/labeling, no unexpected changes
- Clear errors, instructions before fields

### Input Assistance
- Label fields, identify errors, confirm destructive actions

### Readable
- Plain language, clear instructions, 1.5x line spacing

## Robust

### Standards Compliance
- Valid HTML
- ARIA used correctly
- Compatible with assistive technologies
- Progressive enhancement

## Quick Checklist

Use in UX specs:

- [ ] Color contrast meets 4.5:1 (normal text) or 3:1 (large text/UI)
- [ ] All images have alt text or `alt=""`
- [ ] All functionality keyboard accessible
- [ ] Visible focus indicators (2px minimum)
- [ ] Touch targets at least 44x44px
- [ ] Form fields labeled
- [ ] Error messages clear and actionable
- [ ] Semantic HTML structure
- [ ] ARIA labels for icon buttons
- [ ] Responsive to 200% zoom
- [ ] Skip links for main content
- [ ] Consistent navigation

## Testing Tools

Recommend in validation:
- Axe DevTools (browser extension)
- WAVE Web Accessibility Evaluation Tool
- WebAIM Contrast Checker
- Keyboard-only navigation test
- Screen reader test (NVDA/JAWS/VoiceOver)

For code patterns and examples, use `references/html-artifacts.md` first, then the concrete artifact guide for either `references/html-prototype.md` or `references/html-implementation-mockup.md`.
