# Figma Handoff Workflow

Use this reference when requirements or related artifacts contain a supported Figma URL.

## Supported URLs

Supported pattern: `https?://(www\.)?figma\.com/(design|file|proto)/\S+`.

If another Figma URL type is present, ask the user for a design/file/proto URL before treating Figma extraction as available.

## Extraction Contract

1. Check whether `temp/figma_<scope>/figma-spec.md` already exists and was generated from the same file key and node ID.
2. Compare the current URL against `## Source Metadata` in `figma-spec.md` or root `file_key` / `node_id` fields in `figma-spec.json`.
3. Invoke `figma-design` with the full URL when extraction is needed. Prefer the one-shot path that writes both `figma-spec.json` and `figma-spec.md`.
4. Treat terminal progress, created folders, and preview images as incomplete until `figma-spec.md` exists or a concrete failure is returned.
5. After `figma-spec.md` exists, read the generated preview image before drafting HTML UI handoff content. This is a separate gate from reading `figma-spec.md`: the markdown carries exact measurements, while the image confirms the visual scope and whether child images are required.
6. Record a Visual Extraction Decision before continuing. This keeps the agent responsible for the visual judgment while making the decision auditable.

Run Figma extraction as a protected handoff that follows `figma-design`'s Extraction Reliability Contract. Node extraction takes 1–4 minutes, so pick the run mode for your harness:

- **Command runner blocks and supports a long timeout (e.g. Claude Code's Bash tool):** run `figma_client.py … --with-spec-md` blocking, with the tool timeout set to at least `600000ms` (`900000ms` for large boards, `--child-images`, or `--export-images`). Do not use `cd … &&`, shell `timeout`, or output pipes (`| head`) — set the tool's working directory and timeout instead.
- **Command runner returns early, returns empty output, or has no long-timeout setting (e.g. GitHub Copilot's terminal, Cursor auto-backgrounding):** do not fight it. Start the run with `--detach`, then poll `python3 .claude/skills/figma-design/scripts/figma_client.py --status "temp/.figma-run/<slug>"` every ~20–30s (each poll is instant) until it reports `COMPLETE` or `FAILED`. `--detach` prints the exact `--status` command to use.

In every harness: never start a second extraction for the same target (the run lock refuses it — poll `--status` instead of re-running or passing `--force`), never read `figma_client.py` to hand-roll your own extraction, and never treat silence, an early-returning terminal, or a missing mid-run artifact as failure. `--status` is an instant status-file read, not a `sleep && ls` directory-glob loop — the latter is still discouraged. A killed process or command timeout is an incomplete extraction state, not permission to continue without Figma; only a `FAILED` status or a concrete credential/permission/network/API error counts as failure.

Before drafting `mockup.html` or a visual prototype, one of these gate conditions must be true:

- `figma-spec.md` exists, was read, and matches the current Figma file key and node ID.
- `figma-spec.json` exists, `extract_spec.py` was attempted, and the remaining degraded state is documented as `fallback:partial-artifact`.
- `figma-design` returned a concrete credential, permission, network, or API error, and the handoff metadata records `Figma Extraction: unavailable:<reason>`.
- The user explicitly approved continuing without Figma after being told extraction is incomplete.

## Artifact States

- **Complete**: `figma-spec.json` and `figma-spec.md` exist. Read `figma-spec.md` and continue. Set `Figma Extraction: succeeded:<mode>` where `<mode>` is `file`, `node`, `node-only`, `node-only-fallback`, or `node-only-sequential` from `## Source Metadata`.
- **Complete with fallback mode**: `figma-spec.json` and `figma-spec.md` exist, but extraction used a fallback strategy such as full-file HTTP 400 → node-only. Set `Figma Extraction: fallback:<mode>` only when the fallback materially limits available file-wide components/styles; otherwise use `succeeded:<mode>`.
- **Recoverable partial**: `figma-spec.json` exists but `figma-spec.md` is missing. Run `extract_spec.py` against the JSON to produce `figma-spec.md`; after it succeeds, this becomes **Complete**, not partial.
- **Usable partial fallback**: `figma-spec.json` is readable but markdown generation fails. Read JSON directly, generate the HTML handoff, and set `Figma Extraction: fallback:partial-artifact`.
- **Failed**: no artifact exists and the script returned a concrete credential, network, or API error. Continue without Figma only after recording `Figma Extraction: unavailable:<reason>`.

Use `partial-artifact` only when either `figma-spec.json` or `figma-spec.md` is missing/degraded. Do not label a successful `figma-spec.json` + `figma-spec.md` extraction as partial just because the Figma script used node-only or sequential fetching.

Only after `--status` reports `FAILED` or you hit a concrete error, retry with this ladder (run each step blocking or `--detach`+poll per your harness) before falling back:

1. Run `figma_client.py --url "<figma-url>" --with-spec-md`.
2. If it failed without producing `figma-spec.json`, run `figma_client.py --url "<figma-url>" --node-only --with-spec-md`.
3. If `figma-spec.json` exists but `figma-spec.md` is missing, run `extract_spec.py --input <path-to-figma-spec.json>`.
4. If the agent's Visual Extraction Decision is `run`, run `figma_client.py --url "<figma-url>" --node-only --child-images --with-spec-md`, then read the refreshed `figma-spec.md`.
5. If all retry attempts fail without a concrete credential, permission, network, or API error, stop and ask the user whether to wait longer, narrow the Figma node, or continue without Figma. Do not silently substitute local requirements for the Figma handoff.

## Required Reading Order

After successful extraction, read these `figma-spec.md` sections before writing `mockup.html` or a visual prototype:

1. `## Source Metadata`
2. `## Design Tokens`
3. `## Components`
4. `## Target Node`

Figma explicit values are the visual source of truth for visual intent. Reproduce stated fills, typography, padding, gaps, and radii accurately. Treat stated dimensions as reference measurements: record them when useful for proportions or target viewport fidelity, but convert detailed component widths/heights into responsive implementation guidance unless a fixed size is explicitly required. Use `uiux-guideline.md` only for values Figma did not provide.

Then perform the visual read gate in the next section. Do not treat `figma-spec.md` alone as sufficient for board-style or multi-state nodes, because the preview image is what reveals whether more frame-level images are needed.

## Image Handling

1. Read the preview path listed in `**Preview:**` in `figma-spec.md`.
2. If no preview is listed, inspect `temp/figma_<scope>/` for `.png` or `.jpg` files.
3. If no images exist, note `No preview image found` and proceed without a visual summary.
4. Record this Visual Extraction Decision:
   - `preview_path`: image path read, or `none`
   - `visual_classification`: `single-screen`, `multi-screen-board`, `component-board`, or `unclear`
   - `screen_count_observed`: approximate number of visible screens/cards/states
   - `child_extraction_decision`: `run`, `skip`, or `ask-user`
   - `reason`: one sentence explaining the decision
5. Choose `run` when the main preview shows multiple screens/cards/dialogs, side-by-side states or component variants, labels such as `Default`/`Hover`/`Error`/`Expanded`, a layout too zoomed out to inspect accurately, or an unclear scope. If uncertain, prefer `run` over `skip`.
6. Choose `skip` only when the preview clearly shows one focused screen/component, details are readable, no side-by-side variants/states are visible, and `figma-spec.md` does not suggest sibling screens/components requiring separate visual review.
7. If the decision is `run`, rerun `figma-design` with `--node-only --child-images --with-spec-md` unless child images already exist from the current extraction. Read each child PNG after confirming it exists.
8. If child-image extraction fails or saves no images after a `run` decision, document `incomplete visual handoff` and ask the user whether to narrow the node, wait longer, or proceed with only the main preview.

When per-screen images exist, `mockup.html` metadata or prototype README must reference the preview image paths that informed the HTML. Use relative image paths so reviewers and downstream agents can verify exactly which frame image informed each state.

For board-style Figma nodes with multiple states, represent the implementation-relevant states directly in HTML using visible sections such as `data-state="default"`, `data-state="error"`, or `data-state="expanded"`. Add concise notes only for state differences that are not visually obvious.

## Fallbacks

If `figma-design` fails, use a Figma MCP or equivalent integration only when available. Do not assume a specific tool name. If no Figma integration and no usable partial artifact exists, continue with local requirements and design-system context only, clearly marking Figma extraction unavailable.

Do not use WebFetch or browser-open for Figma URLs.

Do not mark Figma extraction unavailable because the extraction is slow, the output directory is still empty, or only a preview image exists. Those are incomplete states that require the retry ladder or user confirmation.
