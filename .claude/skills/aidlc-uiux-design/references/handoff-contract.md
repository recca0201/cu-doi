# UI Handoff Contract

Use this reference when creating or validating AIDLC UI handoff artifacts. New work should produce HTML artifacts.

## Outputs

Choose the artifact type in `references/html-artifacts.md` first.

| Artifact | Purpose | Output |
|----------|---------|--------|
| `mockup` | Construction/developer handoff and code generation | `aidlc-docs/specs/{spec}/mockup.html` |
| `prototype` | PO/designer/stakeholder visual review | `aidlc-docs/design-artifacts/prototype/{feature}/` |

## Lean `mockup.html` contract

The HTML is the spec. Prefer visible, semantic HTML over prose.

`mockup.html` should carry layout, component hierarchy, interaction structure, states, responsive behavior, and accessibility structure directly in the markup. Follow `references/html-implementation-mockup.md` for compact header, state presentation, bottom source metadata, and collapsed support-section affordances. Add metadata only for things HTML cannot express clearly:

- Provenance and source identity
- Figma/design image paths
- Visual extraction decision
- Visual QA status or main-agent handoff
- MDS/component mapping and confidence
- Open questions, uncertainty, and implementation-critical notes

Do not duplicate full wireframes, full component specs, long accessibility checklists, full token tables, full requirements, or large state matrices. When states matter, show them directly in HTML using sections such as `data-state="default"`, `data-state="validation-error"`, or `data-state="empty"`.

## Minimal metadata block

Place a compact metadata comment near the top of `mockup.html`:

```html
<!--
AIDLC UI Handoff
workflow: aidlc-uiux-design
artifact_type: mockup
figma_source: <url or none>
figma_file_key: <key or none>
figma_node_id: <node-id or none>
figma_extraction: succeeded:<mode> | fallback:<mode-or-reason> | unavailable:<reason>
figma_handoff: <temp/figma_scope/figma-spec.md or none>
design_image_source: <path | user-approved-text-only | none>
visual_scope: <single-screen | multi-screen-board | component-board | unclear | none>
visual_qa: <completed | pending:main-agent | skipped:no-design-image | skipped:no-browser-tool | failed>
attempted_browser_tool: <built-in browser | chrome-devtools | unavailable | other | none>
-->
```

For prototypes, put equivalent source and QA notes in `README.md`.

## Magenta MDS precedence

- Figma visual values win for colors, spacing rhythm, typography, radii, and visual hierarchy.
- Figma dimensions inform proportions and target layout intent, but implementation should stay responsive and design-system-led unless a fixed size is explicitly required.
- Magenta MDS wins for canonical component names only when values map cleanly.
- Mark unmatched or conflicting MDS mappings as `candidate` or `unavailable` instead of substituting values.
- MDS mapping tables and `data-mds-confidence` must use `confirmed`, `candidate`, or `unavailable`.

## Subagent handoff response

When run by `ai-design-orchestrator` for `/aidlc.construction.create-design`, return this JSON object:

```json
{
  "status": "success | failed | skipped",
  "reason": "short human-readable reason",
  "html_artifact_type": "prototype | mockup | both | none",
  "html_status": "created | skipped | needs_design_image | failed",
  "prototype_path": "path or none",
  "mockup_path": "path or none",
  "mockup_exists": true,
  "figma_spec_md_path": "path or none",
  "figma_spec_json_path": "path or none",
  "figma_artifacts_complete": true,
  "source_figma_url": "url or none",
  "source_file_key": "key or none",
  "source_node_id": "node-id or none",
  "fallback_used": "none | mcp | direct-figma-design | partial-artifact | screenshot | failed",
  "design_image_source": "path | user-approved-text-only | none",
  "mds_traceability": true,
  "visual_qa": "completed | pending:main-agent | skipped:no-design-image | skipped:no-browser-tool | failed",
  "visual_qa_reason": "short reason or none",
  "attempted_browser_tool": "built-in browser | chrome-devtools | unavailable | other | none",
  "primary_design_viewport": "1280px or explicit design image width",
  "tab_state_list": ["default", "validation-error", "empty"],
  "user_approved_continue_without_ui_handoff": false
}
```

## Validation focus

- `mockup.html` exists for Construction/developer handoff.
- Figma source metadata was copied when Figma ran.
- Explicit Figma values were not approximated.
- Figma width/height values are not used as direct component prescriptions unless explicitly justified.
- Responsive behavior covers target viewport, minimum supported viewport, scroll containment, and reflow/wrap behavior.
- Figma preview image paths are recorded in metadata or visible notes when images were reviewed.
- Board-style Figma sources have visible state sections or concise state notes.
- MDS traceability attributes and component map exist when MDS is in scope.
- Prototype README includes MDS component mapping when a prototype is generated and MDS is in scope.
- Visual QA is included only when browser validation actually ran against a usable design image.
- Browser Visual QA satisfies `references/html-artifacts.md`, including tab/state capture at the primary design viewport when applicable.
- If design image exists and UI handoff lacks browser capture/comparison evidence, treat Visual QA as `pending:main-agent` even if the subagent forgot to mark it pending.
- If browser validation is needed but cannot run in a subagent, the handoff uses the `visual_qa: pending:main-agent` fields defined above.
