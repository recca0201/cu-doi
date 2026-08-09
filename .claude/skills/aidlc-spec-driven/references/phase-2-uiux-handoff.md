# Phase 2 UI Handoff

Use this reference only when `aidlc-docs/specs/{spec-name}/mockup.html` exists or approved requirements contain a supported Figma URL.

## Supported Figma URLs

Supported pattern: `https?://(www\.)?figma\.com/(design|file|proto)/{fileKey}` where `{fileKey}` is alphanumeric (`[A-Za-z0-9]+`). The canonical regex lives in `scripts/spec_workflow.py` as `FIGMA_URL_RE`; when in doubt, trust the script (`mockup-status` applies it) rather than this prose copy.

If another Figma URL type is present, clarify whether it is required for the design. If it is required, ask once for a design/file/proto URL. If it is incidental, document the unsupported link and continue without Figma extraction.

## Mockup Status Vocabulary

`mockup_status` describes the relationship between the spec's `mockup.html` and any Figma source, and drives which handoff work runs before Phase 2 design. This is the single definition; commands and subagent handoffs cite these values rather than redefining them.

| Status | Meaning | Handoff work required |
| --- | --- | --- |
| `pre-existing` | `mockup.html` exists, no supported Figma URL | None — Path A quality checks only |
| `not-applicable` | No `mockup.html`, no supported Figma URL | None — skip UI handoff entirely |
| `pre-existing-fresh` | Figma URL present and `mockup.html` metadata matches its file key/node ID | None — Path A quality checks only |
| `needs-refresh` | Figma URL present but `mockup.html` metadata is missing, stale, or mismatched | Figma source read → `aidlc-uiux-design` refresh |
| `needs-generation` | Figma URL present, `mockup.html` missing | Figma source read → `aidlc-uiux-design` generation |
| `unavailable` | UI handoff failed and the user explicitly approved continuing without a valid mockup | None — document the failure context |

Determine the status deterministically with the workflow script — do not hand-compare metadata:

```bash
python3 .claude/skills/aidlc-spec-driven/scripts/spec_workflow.py mockup-status {spec-name} [--figma-url URL]
```

The script parses the handoff metadata comment, compares file key/node ID against the URL, and prints the status as JSON with its reasoning. It never emits `unavailable` — that state is set by the orchestrating session only after a failed handoff plus explicit user approval.

**Freshness is a local check.** Deciding `pre-existing-fresh` vs `needs-refresh` only compares the URL's file key/node ID against `mockup.html` metadata — no Figma API call is involved. So run `mockup-status` first, and spawn the Figma source read subagent only when the result is `needs-refresh` or `needs-generation`. Spawning a Figma extraction for a fresh mockup wastes a full subagent run and produces nothing the design phase will use.

## Handoff Metadata Contract

`mockup.html` should include a compact AIDLC UI Handoff metadata comment near the top with concrete values rather than placeholder alternatives:

```html
<!--
AIDLC UI Handoff
workflow: aidlc-uiux-design
artifact_type: mockup
figma_source: <url or none>
figma_file_key: <key or none>
figma_node_id: <node-id or none>
figma_extraction: <status>
figma_handoff: <path or none>
design_image_source: <path | user-approved-text-only | none>
visual_qa: <status>
-->
```

`figma_extraction` should match one of these forms:

- `succeeded:<mode>`
- `fallback:<mode-or-reason>`
- `unavailable:<reason>`

Valid mode examples: `file`, `node`, `node-only`, `node-only-fallback`, `node-only-sequential`.

Do not require literal placeholder text like `<url or none>` in generated artifacts. Validate labels and value grammar when present.

## Figma Source Read Contract

Use this contract when spawning the dedicated Figma source read subagent.

**Instructions to pass**:

- Invoke `figma-design` with the supported Figma URL.
- Use a dedicated subagent execution path for the Figma read. Do not use `Explore` for this step.
- Do not WebFetch, browser-open, or manually summarize the Figma URL.
- Read `figma-spec.md`, `figma-spec.json`, and the main preview image.
- If the preview is board-like, dense, component-based, or unclear, extract/read child-frame images.
- Return JSON only plus short blocker notes when needed.

**Run rules to pass (so the subagent survives a long extraction):** Figma node extraction takes 1–4 minutes. The subagent must follow `figma-design`'s Extraction Reliability Contract exactly — pick blocking-with-long-timeout or `--detach`+poll `--status` based on its harness, and it must **never** start a second extraction for the same target, read `figma_client.py` to hand-roll its own script, or treat silence / an early-returning terminal / a missing mid-run artifact as failure. Only a `FAILED` status or a concrete credential/network/API error counts as failure. Do not compose the command with `cd … &&` or output pipes; set the tool's working directory and timeout instead.

**Required Figma handoff JSON fields**:

```json
{
  "status": "success | failed | partial",
  "reason": "short human-readable reason",
  "figma_source_url": "url or none",
  "source_file_key": "key or none",
  "source_node_id": "node-id or none",
  "figma_spec_md_path": "path or none",
  "figma_spec_json_path": "path or none",
  "figma_artifacts_complete": true,
  "figma_extraction_status": "succeeded:<mode> | reused:<mode> | failed:<reason> | partial:<reason>",
  "design_image_source": "primary preview path or none",
  "preview_image_paths": ["path"],
  "child_image_paths": ["path"],
  "visual_scope": "single-screen | multi-screen-board | component-board | dense-board | unclear | none",
  "observed_state_count": 0,
  "child_image_decision": "run | skip | ask-user | failed",
  "merged_state_candidates": ["frame/state names and rationale"],
  "distinct_screen_candidates": ["screen or layout names"],
  "component_candidates": ["component names"],
  "limitations": ["missing artifact or visual uncertainty notes"]
}
```

## UI Handoff JSON Contract

When a Figma URL is present and no valid `mockup.html` exists, the handoff runs in two subagent stages before Phase 2 design:

1. A dedicated Figma source read subagent invokes `figma-design`, reads `figma-spec.md` / `figma-spec.json` / preview images, and returns Figma handoff JSON.
2. `ai-design-orchestrator` invokes `aidlc-uiux-design`, consumes the Figma handoff JSON, and returns UI handoff JSON.

Require `ai-design-orchestrator` to return a JSON object with these fields:

```json
{
  "status": "success | failed | skipped",
  "reason": "short human-readable reason",
  "html_artifact_type": "prototype | mockup | both | none",
  "html_status": "created | skipped | needs_design_image | failed",
  "mockup_path": "path or none",
  "mockup_exists": true,
  "metadata_valid": true,
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

For successful Construction handoff, `status` must be `success`, `mockup_exists` must be `true`, and `metadata_valid` should be `true` unless a documented context fallback is approved.

If UI handoff generation fails and `mockup.html` is required, Phase 2 may proceed only after the user explicitly approves continuing without it. In that case, `status` is `failed`, `user_approved_continue_without_ui_handoff` is `true`, and `reason` explains the failure.

## Role Separation

Phase 2 design consumes UI handoff artifacts; it does not create them.

- The dedicated Figma source read subagent + `figma-design` own Figma extraction, preview image reading, child-image decisions, and visual-scope classification.
- `ai-design-orchestrator` + `aidlc-uiux-design` own `mockup.html` creation, compact state/spec synthesis, browser Visual QA handoff, and fallback synthesis from the Figma handoff.
- `aidlc-spec-driven` Phase 2 owns reading the handoff, validating the contract, extracting only implementation-critical UI constraints into `design.md`, and carrying unresolved issues forward.
- Do not invoke `figma-design` directly from Phase 2 design to create UI handoff artifacts. If Figma extraction fails, retry through the dedicated Figma source read subagent; do not use `Explore` for that retry. If UI handoff generation fails, retry through `ai-design-orchestrator` / `aidlc-uiux-design`, provide missing credentials/artifacts, or approve continuing without UI handoff.

## Path A: Existing `mockup.html` (`pre-existing` / `pre-existing-fresh`)

1. Read `mockup.html` completely.
2. Validate the handoff metadata and MDS traceability when applicable.
3. If requirements contain a supported Figma URL, run `mockup-status` with `--figma-url`. On `needs-refresh`, switch to Path B before drafting `design.md`; on `pre-existing-fresh`, continue without any Figma extraction.
4. Run the quality checks below.
5. Extract only implementation-critical constraints into `design.md`.

## Path B: Figma URL, No Fresh `mockup.html` (`needs-refresh` / `needs-generation`)

1. Spawn a dedicated Figma source read subagent and instruct it to invoke `figma-design` with spec name, requirements path/content, and Figma URL.
2. Require Figma handoff JSON with artifact paths, preview image paths, visual scope, child-image decision, merge candidates, and limitations.
3. Spawn `ai-design-orchestrator` and instruct it to invoke `aidlc-uiux-design` with spec name, requirements path/content, Figma URL, and the Figma handoff JSON.
4. Require the UI handoff JSON contract above.
5. Proceed only on successful handoff, or on documented failure with explicit user approval to continue without `mockup.html`.
6. Before spawning or continuing Phase 2 design, require browser QA to be completed with per-state capture/comparison evidence, or formally documented as `skipped:no-browser-tool` with attempted tool, reason, design image source, primary design viewport, and unvalidated tab/state list.
7. Run the quality checks below before drafting `design.md`.

## Quality Checks Before `design.md`

- If handoff path points to existing `figma-spec.json` and `figma-spec.md`, reject stale `fallback:partial-artifact`; use `succeeded:<mode>` or a specific non-partial fallback mode.
- If Figma frame images exist, `mockup.html` metadata or visible notes should reference the preview image paths.
- If the Figma source is a board or has multiple screen/state frames, `mockup.html` should represent implementation-relevant states directly with tabs, compact state deltas, or visible `data-state` sections.
- If design-system mapping exists, `data-mds-confidence` or mapping tables should include `confirmed`, `candidate`, or `unavailable`, and uncertainty should not be hidden behind slash alternatives.
- If Figma copy differs from requirements copy, the discrepancy should be carried into `design.md` open questions or lean notes in `mockup.html`.
- If icons, illustrations, or exported images are used, `mockup.html` or prototype README should identify the source.
- If a design image exists, browser QA evidence must show the generated HTML was opened, each relevant state tab was captured, captures were compared to the original design image, and visible HTML/CSS gaps were fixed or documented before Phase 2.

If a quality check fails, do not silently ignore it. Either refresh `mockup.html` through `aidlc-uiux-design`, or document the limitation in `design.md` and open questions.

## Design Extract Rules

- Link to `mockup.html` as the UI source of truth.
- Extract only constraints that affect architecture, interfaces, implementation boundaries, or task planning.
- Do not duplicate full visible layout, component trees, accessibility notes, token tables, detailed validation flows, or business rules already represented in `mockup.html` or `requirements.md`.
- Preserve design-system confidence from `mockup.html`. Do not present slash alternatives such as `Dialog / Modal` as equal choices unless the handoff marks them as candidates.
- Carry unresolved copy, Figma, design-system, and asset ambiguity into `## Open Questions` or `## Design Decisions`.
