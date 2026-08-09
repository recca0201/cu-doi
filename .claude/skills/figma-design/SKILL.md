---
name: figma-design
description: >
  Extract supported Figma design/file/proto URLs through the Figma REST API into deterministic AI-readable artifacts: `temp/figma_SCOPE/figma-spec.json`, `figma-spec.md`, preview images, and optional code-format exports. Use this skill whenever a task requires Figma structure, design tokens, component specs, node/frame metadata, preview-image analysis, or a Figma-backed handoff for UI code or AIDLC UI handoff artifacts such as `mockup.html` and visual prototypes. After extraction, always read the generated preview image before downstream design analysis so board-style frames and visual states are not missed. Do not use for generic design critique, screenshots without Figma API access, or FigJam/board links unless the user provides a supported design/file/proto URL.
---

# Figma Design Spec Reader

Read a Figma file or node through the REST API and produce a structured design spec for downstream UI implementation.

## Use This Skill When

Use this skill for supported Figma URLs matching `https?://(www\.)?figma\.com/(design|file|proto)/\S+`, file keys, or node-specific handoffs. If the user provides a FigJam/board URL or another unsupported Figma URL type, ask for a `design`, `file`, or `proto` URL before extraction.

## Inputs And Credentials

Required inputs:
- Figma Personal Access Token with `file:read`; add `variables:read` when Variables are needed.
- Figma URL or file key. For URLs, the file key is the segment in `figma.com/design/<FILE_KEY>/...`.

Recommended one-time setup:

```bash
python3 .claude/skills/figma-design/scripts/setup_token.py
```

Manual setup is also supported:

```bash
cp .claude/skills/figma-design/.env.example .claude/skills/figma-design/.env
# Then edit .env and set FIGMA_TOKEN and optionally FIGMA_FILE_KEY
```

The `.env` file is gitignored. Do not use workspace search tools to verify gitignored credential files because they may silently skip them. Instead, run the extraction script and let it report missing credentials. Do not pass tokens on the command line; command history can leak them.

## Core Workflow

### 1. Extract JSON And Markdown

Prefer the one-shot command. It writes `figma-spec.json`, `figma-spec.md`, and a preview image under `temp/figma_<scope>/`.

This run takes minutes on real screens. Pick the run mode that matches your harness (blocking-with-long-timeout vs `--detach`-and-poll) and follow the run rules in **Extraction Reliability Contract** below — that section is load-bearing, read it before your first run. Never start a second extraction for the same target or hand-roll your own script from `figma_client.py`.

MDS is optional. Do not apply Magenta Design System token/component mapping by default. Use `--mds` only when the user asks to apply MDS/Magenta Design System, or when `aidlc-docs/foundation/uiux-guideline.md` exists and mentions `MDS` or `Magenta Design System`. The extractor auto-detects that foundation guideline for `figma-spec.md`; pass `--no-mds` if the user explicitly asks not to apply MDS.

```bash
python3 .claude/skills/figma-design/scripts/figma_client.py \
  --url "https://www.figma.com/design/FILE_KEY/Name?node-id=4812-38472" \
  --with-spec-md
```

If the user gives only a file key or wants a whole-file extraction:

```bash
python3 .claude/skills/figma-design/scripts/figma_client.py --file FILE_KEY --with-spec-md
```

When a node URL or `--node` is provided, the script first attempts a full-file fetch for complete component/style inventory alongside the node fetch. If Figma returns HTTP 400 because the file is too large, it automatically falls back to node-only mode. Use `--node-only` explicitly only when you already know the file is large or the retry ladder requires it.

### 2. Verify Artifacts

Before continuing, verify that `figma-spec.json` exists. If `figma-spec.md` is missing but `figma-spec.json` exists, generate it directly:

```bash
python3 .claude/skills/figma-design/scripts/extract_spec.py \
  --input temp/figma_<scope>/figma-spec.json
```

When the user explicitly asks for MDS/Magenta Design System mapping, add `--mds` to `figma_client.py --with-spec-md` or to the direct `extract_spec.py` command. When the foundation guideline is the only MDS signal, no flag is required because `extract_spec.py` detects it.

Read `figma-spec.md` before reporting success. Confirm it includes `## Source Metadata` with source URL, file key, node ID, extraction mode, and Figma last-modified timestamp. If any metadata value is `none`, use the corresponding root field in `figma-spec.json` when available.

### 3. Read The Preview Image

Read the preview image before downstream UI analysis. Use the path from the `**Preview:**` line in `figma-spec.md`. If that line is absent, inspect the output directory for `.png`, `.jpg`, or `.webp` files. If no image exists, state `No preview image found` in the handoff and continue with `figma-spec.md`; do not pretend the visual read happened.

Record this Visual Extraction Decision:

```markdown
Visual Extraction Decision:
- preview_path: <path read, or none>
- visual_classification: single-screen | multi-screen-board | component-board | unclear
- screen_count_observed: <approximate visible screens/cards/states>
- child_extraction_decision: run | skip | ask-user
- reason: <one sentence>
```

Use the image only to determine visual scope and state coverage. Use `figma-spec.md`/`figma-spec.json` for tokens, measurements, and node metadata.

### 4. Extract Child Images When Needed

Run child extraction if the preview looks like a board, is visually dense, shows variants/states side-by-side, or is unclear. Uncertainty should become `child_extraction_decision: run`, not a silent skip.

Signs sub-extraction is needed:
- Several dialogs, screens, component variants, or state cards appear side-by-side.
- Labels such as `Default`, `Expanded`, `Error`, or sticky notes name states between cards.
- Individual screens are too small or packed to inspect accurately.
- The target appears to be a component board, component set, section, group, or wrapper containing screen-like children.

Signs sub-extraction can be skipped:
- One dialog or page fills most of the image.
- Visual details are readable without zooming.
- No side-by-side variants, states, repeated components, or sibling screens are visible or suggested by `figma-spec.md`.

Child extraction command:

```bash
python3 .claude/skills/figma-design/scripts/figma_client.py \
  --url "https://www.figma.com/design/FILE_KEY/Name?node-id=XXXX-YYYY" \
  --node-only \
  --child-images \
  --with-spec-md
```

Read each downloaded child image and write a one-line visual description for each state or screen. If `--child-images` was requested but no child images were saved, report an incomplete visual handoff instead of silently continuing.

### 5. Use The Spec

Treat `temp/figma_<scope>/figma-spec.md` as the primary Figma extraction artifact. Downstream code generation, `mockup.html`, and visual prototypes should use both `figma-spec.md` and the preview-image decision.

Example downstream prompt:

```text
Using the spec in `temp/figma_<scope>/figma-spec.md`, implement the [ComponentName] component in React/Vue/Flutter.
```

## Extraction Reliability Contract

Node extraction of a real screen commonly takes **1–4 minutes** (a large board can produce a 15MB `figma-spec.json`). During that time the script is working even when it prints nothing new for a stretch. The single most damaging failure mode is an agent concluding "it failed" from silence and then **re-running the command or hand-rolling its own script** — that races two extractions into `temp/` and doubles the Figma API load. Figma's `files`/`nodes`/`images` endpoints are all on the most-restricted rate-limit tier, so a duplicate run is not free.

To make the run observable regardless of how your harness handles long commands, every extraction writes a machine-readable ground truth next to a per-target coordination directory (`temp/.figma-run/<slug>/`):
- `run-status.json` — current phase, pid, `done`, `exit_code`, and output paths (written atomically).
- `.done` / `.failed` — terminal sentinel files carrying the exit code.
- `.figma-run.lock` — a second run for the same target refuses to start and tells you to poll instead.

You never guess. Ask the status:

```bash
python3 .claude/skills/figma-design/scripts/figma_client.py --status "temp/.figma-run/<slug>"
```

`--status` exits `0` when the run completed successfully, `3` while it is still running, `1` when it failed or has not started. It also prints the status JSON (phase + `outputs`).

### Choose the run mode for your harness

**If your command runner blocks until the process exits AND lets you set a long timeout (e.g. Claude Code's Bash tool):** run it blocking with the tool's timeout set to at least `600000` ms (900000 for large boards, `--child-images`, or `--export-images`). Do not use `cd ... &&`, shell `timeout`, or output pipes (`| head`) — set the tool's working directory and timeout instead. A valid run ends with `Complete.`, `Output:`, and (with `--with-spec-md`) `Markdown:`.

**If your command runner may return before the process finishes, returns empty output, or has no long-timeout setting (e.g. GitHub Copilot's terminal, Cursor auto-backgrounding):** do not fight it. Start the run detached and poll the status file:

```bash
python3 .claude/skills/figma-design/scripts/figma_client.py \
  --url "https://www.figma.com/design/FILE_KEY/Name?node-id=4812-38472" \
  --with-spec-md --detach
```

`--detach` prints the exact `--status` command to poll and returns immediately. Poll `--status` every ~20–30s (each poll is instant) until it reports `COMPLETE` or `FAILED`. Read `temp/.figma-run/<slug>/detach.log` for the full run log if it fails.

### Rules that hold in every harness

- **Never start a second extraction for the same target.** If you see "already running (pid …)", that is the lock working — poll `--status`, do not re-run and do not pass `--force` unless you have positively confirmed the other run is dead.
- **Silence is not failure.** No new output for 30–120s means the fetch is in a quiet phase. The script emits a `still working…` heartbeat line roughly every 20s; absence of a *new artifact* is never proof of failure.
- **Do not inspect or re-implement the script as a workaround.** Do not read `figma_client.py` to write your own extraction, glob `temp/` for partial files, or retry with different flags to "see if that works." The status file already tells you what is happening.
- **A concrete error is the only failure signal.** Treat extraction as unavailable only when `--status` reports `FAILED` or you see a real credential/permission/network/API error (403/404/429 with a message). Slowness, a returned-early terminal, or a missing artifact mid-run are not failures.

Large-file fallback is an expected success path: `HTTP 400` / `Request too large` followed by `falling back to node-only mode` is normal — the same run continues and finishes. Do not intervene.

Retry ladder — only after `--status` reports `FAILED` or a concrete error:

1. Run the full URL with `--with-spec-md` (blocking or `--detach` per your harness).
2. If it failed without producing `figma-spec.json`, retry with `--node-only --with-spec-md`.
3. If `figma-spec.json` exists but `figma-spec.md` is missing, run `extract_spec.py --input <figma-spec.json> --output <figma-spec.md>` directly.
4. If the preview shows a board with multiple child frames/states, rerun with `--node-only --child-images --with-spec-md`.
5. Treat extraction as unavailable only after a concrete credential, permission, network, or API error.

For error-specific guidance, use `references/troubleshooting.md`.

## Definition Of Done

A Figma read is complete only when:
- `figma-spec.json` exists.
- `figma-spec.md` exists and has been read.
- The preview image has been read, or the handoff explicitly says `No preview image found`.
- A Visual Extraction Decision is recorded.
- Child images are extracted and read when the preview is board-like, dense, multi-state, or unclear.

Do not claim Figma was read, summarize the design, or continue downstream as if extraction succeeded until these conditions are satisfied or the script returned a concrete credential/network/API error.

## Common Commands

```bash
# Full URL with Markdown handoff
python3 .claude/skills/figma-design/scripts/figma_client.py --url "..." --with-spec-md

# Whole file using .env defaults
python3 .claude/skills/figma-design/scripts/figma_client.py --with-spec-md

# Specific node by file key and node ID
python3 .claude/skills/figma-design/scripts/figma_client.py --file FILE_KEY --node 4812-38472 --with-spec-md

# Explicit node-only extraction
python3 .claude/skills/figma-design/scripts/figma_client.py --url "..." --node-only --with-spec-md

# Include hidden nodes
python3 .claude/skills/figma-design/scripts/figma_client.py --url "..." --include-hidden --with-spec-md

# Custom JSON output path
python3 .claude/skills/figma-design/scripts/figma_client.py --url "..." --output path/to/custom.json
```

Hidden nodes are stripped by default. Add `--include-hidden` only when hidden placeholder or conditional states must be inspected.

## Spec Format

The Markdown spec contains:
- `## Source Metadata` - source URL, file key, node ID, extraction mode, and Figma last-modified timestamp.
- `## Design Tokens` - authoritative colors, typography, spacing, radii, and effects.
- `## Components` - properties, layout, variants, and internal structure.
- `## Target Node` - selected frame/component tree with dimensions and fills.
- `## Screens / Frames` - top-level frame inventory and dimensions.

Use `references/spec-format.md` for field-level interpretation rules. Do not re-derive schema details from memory when exact behavior matters.

## Optional Capabilities

### Targeted Filtering

Use output filters after file fetch when you need a narrower spec:

```bash
python3 .claude/skills/figma-design/scripts/figma_client.py --component "Button" --with-spec-md
python3 .claude/skills/figma-design/scripts/figma_client.py --frame "Login Screen" --with-spec-md
```

`--component` and `--frame` filter output; they do not reduce API fetch scope. Use node-targeted extraction (`--url` with `node-id` or `--node`) to make the fetch narrower.

### Variables And Tokens

Fetch Figma Variables when the file uses them and the token has `variables:read`:

```bash
python3 .claude/skills/figma-design/scripts/figma_client.py --url "..." --variables --with-spec-md
```

Variables are merged into the tokens section by `extract_spec.py`.

### Icons, Images, And Code Formats

```bash
# SVG icons embedded in the spec
python3 .claude/skills/figma-design/scripts/figma_client.py --export-icons --with-spec-md
python3 .claude/skills/figma-design/scripts/figma_client.py --export-icons "arrow-right,close,search" --with-spec-md

# PNG/JPG frame exports
python3 .claude/skills/figma-design/scripts/figma_client.py --export-images --with-spec-md
python3 .claude/skills/figma-design/scripts/figma_client.py --export-images "Hero Banner,Empty State" --export-dir ./src/assets --with-spec-md

# Token/code exports from an existing JSON spec
python3 .claude/skills/figma-design/scripts/extract_spec.py --input temp/figma_<scope>/figma-spec.json --format css
python3 .claude/skills/figma-design/scripts/extract_spec.py --input temp/figma_<scope>/figma-spec.json --format tailwind
python3 .claude/skills/figma-design/scripts/extract_spec.py --input temp/figma_<scope>/figma-spec.json --format tokens
```

## Optional MDS References

The skill includes Magenta Design System lookup files for opt-in extractor and downstream UI work:
- `references/mds-tokens.json` maps colors, spacing, sizes, and radii to MDS CSS variables.
- `references/mds-components.json` lists MDS React components and variant props.

Use these references only when the user requests MDS/Magenta Design System or the project foundation guideline at `aidlc-docs/foundation/uiux-guideline.md` mentions `MDS` or `Magenta Design System`. Otherwise, preserve the native Figma tokens and measurements without rewriting them to MDS.

Regenerate these references after source MDS changes:

```bash
python3 .claude/skills/figma-design/scripts/generate_mds_reference.py
python3 .claude/skills/figma-design/scripts/generate_mds_components.py
```

## Handoff Summary

When extraction is complete, report:
- Artifacts: `figma-spec.json`, `figma-spec.md`, preview image path, and child image paths if any.
- Visual Extraction Decision: the five required fields.
- Scope: file, node, component, or frame targeted.
- Limitations: missing preview, missing child images, credential/API errors, or intentionally skipped hidden nodes.

## References

- `references/spec-format.md` - Full spec schema and interpretation rules.
- `references/figma-api.md` - Figma REST endpoints and response shapes.
- `references/troubleshooting.md` - Common credential, access, missing-data, and output-quality issues.
