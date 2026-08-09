# Troubleshooting

## Agent / Harness Issues

### The terminal returned but I see no output / no "Complete" line
**Cause:** Your command runner returned before the extraction finished. This is normal for GitHub Copilot's terminal and Cursor's auto-backgrounding on commands that take minutes. The process is very likely still running.

**Fix:** Do not re-run and do not assume failure. Poll the run status:
```bash
python3 .claude/skills/figma-design/scripts/figma_client.py --status "temp/.figma-run/<slug>"
```
Exit `3` = still running (poll again in ~20–30s), `0` = complete, `1` = failed. If you started with `--detach`, the exact `--status` command and the `<slug>` were printed when the run began. In harnesses that return early, prefer starting the run with `--detach` from the outset.

### "An extraction for this target is already running (pid …)"
**Cause:** The lock file detected another live run for the same target. This is the guardrail preventing duplicate extractions (which double Figma's rate-limited API load).

**Fix:** Poll `--status` and wait for that run — do not start another. Use `--force` only if you have positively confirmed the other process is dead (e.g. it crashed and its pid no longer exists). A stale lock (dead pid, or older than 30 minutes) is reclaimed automatically on the next run.

### It's been 60–120s with no new file — did it hang?
**Cause:** Node fetches and style/component batch fetches have quiet phases. The script prints a `still working…` heartbeat roughly every 20s to show it is alive.

**Fix:** Watch for the heartbeat (or poll `--status`). A missing *new artifact* is not a hang. Do not kill the process, glob `temp/`, or read `figma_client.py` to build a workaround.

---

## Rate Limiting (429)

### HTTP 429 / "Rate limited"
**Cause:** Figma's per-minute quota for the file/nodes/images endpoints (the most-restricted tier) was exceeded — usually from parallel batches or a duplicate concurrent run.

**Behavior:** The script honors the `Retry-After` header automatically, waiting and retrying up to a cap (180s). You will see `Rate limited (429 …); waiting Ns then retrying`. No action needed while it retries.

**Fix if it aborts:** If `Retry-After` exceeds the cap, the run stops with an actionable message. Reduce concurrency/pacing with `--max-rpm 10`, ensure no duplicate run is active, and retry later.

### "type=low" in a 429 message / only ~6 requests work per month
**Cause:** The token's Figma seat is **View/Collab**, which is limited to roughly 6 file/node/image requests per *month*. This is a seat problem, not a code problem.

**Fix:** Use a Personal Access Token from a **Dev or Full seat** on a paid plan. Note that PATs now expire after 90 days — regenerate if the token is old.

---

## Authentication Errors

### HTTP 403 Forbidden
**Cause:** PAT is invalid, expired, or lacks the required scope.

**Fix:**
1. Go to *Figma → Account Settings → Security → Personal Access Tokens*
2. Create a new token with `file:read` scope (add `variables:read` if you need Variables)
3. Copy the token immediately — Figma only shows it once
4. Run `python3 .claude/skills/figma-design/scripts/setup_token.py` to save it with masked input

### HTTP 401 Unauthorized
**Cause:** Token passed incorrectly.

**Fix:** Run `python3 .claude/skills/figma-design/scripts/setup_token.py`, or set `FIGMA_TOKEN` in the environment / `.claude/skills/figma-design/.env`. Ensure the token has no trailing spaces. The script sends it as `X-Figma-Token`, not `Authorization: Bearer`.

---

## File Access Errors

### HTTP 404 Not Found
**Cause:** Wrong file key, or you don't have access to the file.

**Fix:**
- Extract the file key from the Figma URL: `figma.com/design/FILEKEYHERE/...`
- Ensure your Figma account has viewer or editor access to the file
- If the file is in an organization, your PAT must belong to a user with access

### HTTP 403 on a shared file
**Cause:** The file requires organization membership even for "anyone with link" sharing.

**Fix:** Ask the file owner to add you as a viewer in Figma, or use an organization member's PAT.

---

## Empty or Missing Data

### Components list is empty
**Cause A:** The file has no master components — only instances from a library.

**Fix:** Fetch the component library file instead. Find the library file key via *Figma → Assets panel → right-click component → Go to main component*.

**Cause B:** The `--component` name doesn't match exactly (case-sensitive).

**Fix:** Run without `--component` first to see all component names, then use the exact name.

### Styles list is empty
**Cause:** The file uses a shared style library. Styles are defined in a different file and linked here.

**Fix:** Find the library file and run against that. Or use `--variables` if the file uses Variables instead of named styles.

### Variables section is empty
**Cause A:** The file doesn't use Figma Variables (uses named styles instead).

**Cause B:** Your PAT lacks `variables:read` scope.

**Cause C:** The file is on a Starter plan (Variables require Pro+).

**Fix for B:** Regenerate the PAT with `variables:read` scope, then run `python3 .claude/skills/figma-design/scripts/setup_token.py` to update the stored token.

### Colors appear as empty hex values
**Cause:** Some styles use gradient fills, not solid fills. The extractor only resolves `SOLID` fills.

**Fix:** This is expected — gradient styles show `—`. For gradients, inspect the node manually in Figma.

---

## Script Errors

### ModuleNotFoundError / import errors
The scripts use only Python standard library. No `pip install` needed.

**Fix:** Ensure Python 3.7+ is installed: `python3 --version`

### JSONDecodeError on output
**Cause:** The Figma API returned an error response (not JSON) that the script didn't catch.

**Fix:** Add `--verbose` debug output temporarily by editing `figma_client.py` line with `figma_get` to print the raw response.

### Style resolution is slow on large files
**Cause:** Files with many named styles require multiple batched `/nodes` API calls. The script batches style node fetches in groups of 50 and merges the results, so large design systems can take longer than a small file.

**Fix:** Let the command run — the heartbeat and `--status` show it is progressing. Only if `--status` reports `FAILED` should you retry with `--node-only --with-spec-md` to reduce the extraction scope.

---

## Output Quality Issues

### Component spec is missing layout values (all zeros)
**Cause:** The component doesn't use auto-layout. Padding/gap are only set on auto-layout frames.

**Interpretation:** The component uses absolute positioning. Look at `absoluteBoundingBox` for size; children positions are absolute.

### Typography shows `—` for line height
**Cause:** The text style uses `AUTO` line height (Figma's "auto" mode doesn't have a fixed pixel value).

**Fix:** This is intentional — use `line-height: normal` or the browser default for auto line height.

### Variant names are repeated (e.g., "Size=sm, Size=sm")
**Cause:** Multiple frames in the file share the same name as the component.

**Fix:** Use `--component` with the exact component name from the Assets panel to target the correct one.
