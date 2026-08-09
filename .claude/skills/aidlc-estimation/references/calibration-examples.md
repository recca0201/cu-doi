# BCP Calibration Examples

Worked examples from past requirements-only estimates. They exist to make independent runs converge on **how to reason**, not on a fixed number.

## How to use this file

**Pattern-match the reasoning, not the numbers.** Each example below records how a specific spec was counted and why. A different project — even one that looks structurally similar — will almost always land on different counts because its entities, boundaries, and variability are different. If you copy "seven Domain Entities" onto an unrelated spec because the words rhyme, you have overfit and the estimate will be wrong.

Use these examples to answer questions like:
- "What kinds of things did a past estimator group together vs. split apart?"
- "When did a parameter set get treated as significant (XL) variability vs. minor (M)?"
- "What got excluded from a count and why?"

Then apply that *judgment* to the artifact in front of you, re-deriving counts from its own evidence. The domain-agnostic rules in [complexity-ruler.md](complexity-ruler.md) always take precedence; these examples only illustrate them.

---

## Example A: AI audio → SOAP summarization API (baseline)

A backend API that accepts an uploaded audio file, runs speech-to-text, and returns a structured (SOAP) clinical summary. Requirements-only (no `design.md`).

**Domain Entities — landed on ~7:** summarize request, uploaded audio, STT request/result, transcription, SOAP summary, response envelope, error response. The summarization request/prompt/model settings were grouped under STT/SOAP processing rather than counted separately, because they had no independent lifecycle in the requirements.

**New Domain Entities — ~3 new API schema groups:** the request schema, the SOAP/summary payload schema, and the response/error contract. Individual fields were folded into their owning schema rather than counted one-by-one.

**Solution Variabilities — XL:** configurable model names, prompt behavior, accepted input formats, and edge-case substitutions together change provider/output behavior enough to count as significant variability.

**Boundaries — XL:** the service exchanges *ethereal* runtime information — audio payloads, transient transcripts, request-scoped model outputs — rather than durable records.

*Why this matters as a pattern:* the lesson is "group fields into owning schemas; treat request/model settings as part of the processing entity unless separately persisted; AI provider/prompt/format knobs are usually significant variability; runtime payloads are ethereal boundaries." The specific count of 7 is incidental.

---

## Example B: Long-audio chunking support (enhancement)

An enhancement to Example A that splits long audio into chunks, transcribes them, and merges results.

**Domain Entities — group chunk internals into stable concepts:** uploaded audio, audio chunk, chunking configuration, chunk STT request/result, merged transcription, SOAP/summary response, error/retryable error. `chunk_index` and chunk transcript text were **not** counted separately from the audio chunk entity, because they are attributes of it rather than independently persisted records.

**New Domain Entities — usually a modification, not a greenfield:** long-audio support typically modifies the existing summarize API and adds *one* new chunk-processing concept, unless the requirements define durable chunk records or separate schemas.

**Solution Variabilities — XL:** chunking strategy, VAD/segmentation parameters, concurrency, retry classification, and model-temperature settings together substantially change the processing strategy.

*Why this matters as a pattern:* "attributes belong to their owning entity (don't inflate counts with `*_index`/buffer fields); an enhancement usually modifies one entity and adds one concept; a cluster of pipeline-tuning parameters is significant variability."

---

## Example C: CI/CD pipeline spec

A spec that defines a build/test/deploy pipeline with branch protection and a staging deployment.

**Domain Entities — count stable pipeline concepts, not tool commands:** pipeline, quality check / check result, protected branch, staging deployment, deployment metadata/log output. Each tool invocation (lint, test, build) was **not** split into its own entity.

**New Domain Entities — process/configuration, not domain records:** a CI/CD pipeline is a process/configuration capability, not a New Domain Entity, unless the requirements define a durable deployment record/schema. Deployment metadata/log output alone is not a new domain entity.

**Boundaries — usually M, not XL:** source-control, runner, staging, notification, and log exchanges move *durable/perennial* information (CI status, deployment status, logs), so they are M unless the pipeline explicitly processes transient business payloads.

**Background Processes — one process:** a multi-stage pipeline is one Background Process unless separate triggers/schedules or independently deployable workers are specified.

**Roles/Permissions — S:** branch protection, merge blocking, or CI gates that change a contributor's ability to merge count as **S** same-depth permission behavior, even when the only named persona is "Developer."

*Why this matters as a pattern:* "infrastructure/automation specs describe capabilities and configuration, not new business entities; their boundaries are usually durable (M); a pipeline is one background process; merge-gating is a same-depth permission change."

---

## Cross-cutting reminders these examples reinforce

- Group attributes and sub-fields into their **owning entity/schema**; don't count `*_id`, `*_index`, buffers, or settings separately unless they are independently persisted.
- Distinguish **new domain concepts** from **modifications of existing behavior** — enhancements usually modify, not add.
- A **cluster of behavior-changing parameters** (AI model/prompt/format knobs, chunking/segmentation/concurrency settings) is usually XL Solution Variability; simple config values (env names, thresholds) are M.
- **Runtime/transient payloads** are ethereal boundaries (XL); **status/logs/stored config** are perennial boundaries (M).
- **Infrastructure, CI/CD, and config-only specs** rarely introduce New Domain Entities and rarely have runtime Interface Elements.
