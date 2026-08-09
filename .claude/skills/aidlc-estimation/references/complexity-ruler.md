# BCP Complexity Ruler

Complete reference for all 10 complexity dimensions with T-shirt sizing criteria.

## Table of Contents

- [T-Shirt Sizing Scale](#t-shirt-sizing-scale)
- [10 Complexity Dimensions](#10-complexity-dimensions) — per-dimension definitions and size criteria (Business Rules, Interface Elements + counting standards, Roles/Permissions, Solution Variabilities, Domain Entities, New Domain Entities, Boundaries, Background Processes, Notifications, Audits)
- [Calculation Formula](#calculation-formula)
- [Dimension Calculation Protocol](#dimension-calculation-protocol) — general steps, per-dimension calculation rules, counting stability rules
- [Dimension Calibration Rules (All Estimates)](#dimension-calibration-rules-all-estimates) — ambiguity tie-breakers per dimension; **read before scoring any estimate**
- [Calculator Validation Rules](#calculator-validation-rules) — allowed sizes and formula checks per dimension
- [Quick Reference Table](#quick-reference-table)

## T-Shirt Sizing Scale

| Size | Points | Fibonacci Sequence |
|------|--------|-------------------|
| XS   | 1      | Extra Small       |
| S    | 2      | Small             |
| M    | 3      | Medium            |
| L    | 5      | Large             |
| XL   | 8      | Extra Large       |
| N/A  | 0      | Not Applicable    |

## 10 Complexity Dimensions

### 1. Business Rules
**Definition:** Any kind of business instruction with clear trigger and interruption points.

| Size | Criteria |
|------|----------|
| XS (1) | Direct instructions, simple formulas or validations (valid email, mandatory field, greater than, lower than, etc) |
| S (2) | Iterative processes with few phases/steps and no decision points |
| M (3) | Iterative processes with few phases/steps and few decision points |
| L (5) | Not specified in standard ruler |
| XL (8) | Iterative processes with many phases/steps and/or many decision points |

**Occurrences:** Count the number of distinct business rule sets
**Example:** Approval workflow with 3 decision points = 1 occurrence × XL = 8 points

---

### 2. Interface Elements
**Definition:** Interface elements that represent business concepts.

| Size | Criteria |
|------|----------|
| XS (1) | Not specified in standard ruler |
| S (2) | Add and/or Remove up to 5 static interface elements in an existing business context (functionality, service). Examples: text fields, checkboxes, radios, simple tables, parameters |
| M (3) | Add and/or Remove up to 5 static interface elements in a new business context (functionality, service). Examples: text fields, checkboxes, radios, simple tables, parameters |
| L (5) | Add and/or Remove up to 5 dynamic interface elements in an existing business context (functionality). Examples: tabs, dynamic behaviors, modals, dynamic grids/tables (selecting, filtering and/or sorting) |
| XL (8) | Add and/or Remove up to 5 dynamic interface elements in a new business context (functionality). Examples: tabs, dynamic behaviors, modals, dynamic grids/tables (selecting, filtering and/or sorting) |

**Occurrences:** Calculated as `ROUNDUP(Total_Elements / 5, 0)`
**Example:** 16 static elements in existing context = ROUNDUP(16/5) = 4 occurrences × S (2) = 8 points

---

#### Interface Elements Counting Standards

**Critical for accuracy:** Use standardized counting rules to avoid granularity inconsistencies.

##### Counting Unit Definition

**One element = One interactive or data-presenting component that serves a distinct user purpose**

##### Counting Hierarchy Rules

**Level 1: Interactive Input Controls (Count These)**
- Text input fields (username, email, search box)
- Dropdowns/select boxes
- Checkboxes (group of related checkboxes = 1)
- Radio button groups (entire group = 1)
- Date/time pickers
- File upload controls
- Sliders/range inputs
- Toggle switches

**Level 2: Action Controls (Count These)**
- Buttons (primary, secondary, icon buttons)
- Links that trigger actions (not navigation)
- Split buttons/dropdown buttons

**Level 3: Data Display Components (Count These)**
- Tables (entire table = 1, regardless of columns)
- Lists (entire list = 1, unless multiple distinct lists)
- Cards displaying data (per card type, not per card instance)
- Charts/graphs (per chart)
- Data grids with interaction (sorting/filtering)

**Level 4: Container/Layout Elements (Do NOT Count)**
- Forms (containers for inputs)
- Panels/sections
- Tabs container (count tab controls themselves)
- Accordions container (count accordion controls)
- Modal wrapper (count modal content)
- Layout divs/containers

**Level 5: Decorative/Supplementary (Do NOT Count)**
- Labels for inputs (part of the input)
- Icons within buttons (part of the button)
- Help text/tooltips (part of the component)
- Validation messages (part of the input)
- Dividers/separators

##### Decision Rules

**Rule 1: Count the smallest meaningful interactive unit**
- ✅ Username input (1), Password input (1) = 2 elements
- ❌ NOT: Username label (1), Username input (1), validation message (1) = 3 elements

**Rule 2: Related controls = 1 element**
- ✅ "Gender: ○ Male ○ Female ○ Other" = 1 element (radio group)
- ❌ NOT: 3 elements (one per radio)
- ✅ "Notifications: ☑ Email ☑ SMS ☑ Push" = 1 element (checkbox group)

**Rule 3: Repeated instances = 1 element**
- ✅ Product card component shown 100 times = 1 element (card pattern)
- ❌ NOT: 100 elements
- ✅ Data table with 50 rows = 1 element (table)

**Rule 4: Complex components count by sub-controls**
- ✅ Date range picker (start date + end date) = 2 elements
- ✅ Multi-step wizard (3 steps with 5 inputs each) = 15 elements

**Rule 5: Dynamic behavior doesn't change element count**
- ✅ Dropdown (whether simple or searchable) = 1 element
- ✅ Table (whether static or with sorting/filtering) = 1 element
  - Note: Sorting/filtering affects static vs dynamic sizing, not count

##### Common UI Pattern Reference

| Pattern | Element Count | Rationale |
|---------|--------------|-----------|
| **Simple login form** | 3 | Username (1) + Password (1) + Login button (1) |
| **Login with social** | 5 | Username (1) + Password (1) + Login btn (1) + Google btn (1) + Facebook btn (1) |
| **User profile form** | 8-12 | Name, email, phone, address, city, state, zip, country, avatar upload, bio, birthday, gender |
| **Search with filters** | 5-10 | Search input (1) + Date range (2) + Category dropdown (1) + Status checkboxes (1) + Sort dropdown (1) + Search btn (1) |
| **Data table with actions** | 3-5 | Table (1) + Action buttons (1-3) + Pagination (1) |
| **Dashboard** | 8-15 | Count: charts, KPI cards, filter controls, action buttons |
| **Multi-step wizard (3 steps)** | Sum of all step inputs | Step 1 (5) + Step 2 (8) + Step 3 (4) = 17 elements |
| **Modal/dialog** | Count only modal content | Same rules apply to modal content elements |

##### Calibration Examples

**Example 1: E-commerce Product Page**

Elements to count:
- Quantity selector (1)
- Size dropdown (1)
- Color selector (1)
- Add to cart button (1)
- Add to wishlist button (1)
- Share button (1)
- Reviews tab (1)
- Q&A tab (1)
- **Total: 8 elements**

Do NOT count:
- Product images (display only, no interaction)
- Product title/description (static content)
- Price display (static content)
- Breadcrumbs (navigation, not action)
- Related products carousel (repeated pattern = 0)

**Example 2: Admin User Management Screen**

Elements to count:
- Search input (1)
- Role filter dropdown (1)
- Status filter dropdown (1)
- Date range picker (2)
- User data table (1)
- Edit button (1)
- Delete button (1)
- Add user button (1)
- Export button (1)
- Pagination controls (1)
- **Total: 11 elements**

**Example 3: Mobile Banking Transfer**

Elements to count:
- From account dropdown (1)
- To account input (1)
- Amount input (1)
- Currency dropdown (1)
- Transfer date picker (1)
- Note/memo input (1)
- Save as template checkbox (1)
- Transfer button (1)
- Schedule button (1)
- **Total: 9 elements**

##### Estimation Workflow Integration

**Step 1: List all UI components**
Write down everything you see in the design/requirements.

**Step 2: Apply counting rules**
Filter out containers, labels, decorative elements.

**Step 3: Group related controls**
Radio groups, checkbox groups, related inputs.

**Step 4: Count unique patterns**
For repeated elements, count pattern once.

**Step 5: Apply static vs dynamic sizing**
After getting accurate count, apply S/M/L/XL based on element behavior and context.

##### Confidence Level Guidance

**High Confidence (can count exactly):**
- Wireframes/mockups with all elements shown
- Detailed design specs with component list
- Existing similar screen to reference

**Medium Confidence (reasonable estimate):**
- Requirements mention key inputs but not exhaustive
- Can infer standard patterns (e.g., "login form" → 3 elements)
- Have foundation docs with UI patterns

**Low Confidence (significant assumptions):**
- User story mentions "form" without details
- No wireframes or design specs yet
- Unclear scope ("various filters")

---

### 3. Roles/Permissions
**Definition:** Number of different permission sets specified by the Backlog Item for existing roles in the application.

| Size | Criteria |
|------|----------|
| XS (1) | Same permissions for all users |
| S (2) | Permission sets in the same depth level (e.g: Internal or External, Consultant or Operator) |
| M (3) | Permission sets encompassing two or more depth levels (e.g.: External User: Operator or Contract Analyst, Internal User: Contract Analyst or Credit Analyst) |
| L (5) | Not specified in standard ruler |
| XL (8) | Not specified in standard ruler |

**Occurrences:** Count = 1 (single assessment per story)
**Example:** Multi-level permissions = 1 × M (3) = 3 points

---

### 4. Solution Variabilities
**Definition:** Solutions accomplishing the same business objective that may vary (slightly or significantly) influenced by a parameter.

| Size | Criteria |
|------|----------|
| XS (1) | Single solution for the business flow |
| S (2) | Not specified in standard ruler |
| M (3) | Common solution with small changes of behavior according to a parameter value |
| L (5) | Not specified in standard ruler |
| XL (8) | Solution varies significantly according to a parameter value |

**Occurrences:** Count = 1 (single assessment per story)
**Example:** Parameter-driven significant variation = 1 × XL (8) = 8 points

---

### 5. Domain Entities
**Definition:** Amount of business relevant entities involved in a Backlog Item domain.

| Size | Criteria |
|------|----------|
| XS (1) | 1 entity |
| S (2) | 2 or 3 entities |
| M (3) | 4 or 5 entities |
| L (5) | 6 or 7 entities |
| XL (8) | more than 7 entities |

**Occurrences:** Count = 1 (single assessment per story)
**Formula:** `IF(count > 7, "XL", IF(count >= 6, "L", IF(count >= 4, "M", IF(count >= 2, "S", "XS"))))`
**Example:** 8 entities = 1 × XL (8) = 8 points

---

### 6. New Domain Entities
**Definition:** Number of Entities incorporated into the business domain or modified by the Backlog Item.

| Size | Criteria |
|------|----------|
| XS (1) | Not specified in standard ruler |
| S (2) | Add new attributes or relationships for up to 3 existing entities |
| M (3) | Not specified in standard ruler |
| L (5) | Add to business context up to 3 new entities |
| XL (8) | Not specified in standard ruler |

**Occurrences:** Calculated as `ROUNDUP(Total_New_Entities / 3, 0)`
**Example:** 4 new entities = ROUNDUP(4/3) = 2 occurrences × L (5) = 10 points

---

### 7. Boundaries
**Definition:** Interactions that a Backlog Item has to sources/destinations affected by ownership, validity and the durability of the information exchanged.

| Size | Criteria |
|------|----------|
| XS (1) | DB and/or UI or do not cross boundaries (self-contained) |
| S (2) | Reading, writing, exchanging information with a physical device |
| M (3) | Remote Business Services exchanging perennial information |
| L (5) | Not specified in standard ruler |
| XL (8) | Remote Business Service with ethereal exchange information |

**Occurrences:** Count = 1 (single assessment per story)
**Example:** External API with temporary data = 1 × XL (8) = 8 points

---

### 8. Background Processes
**Definition:** Stealth processes (not triggered by and with no user's knowledge) that do not prevent the use of the system during its execution.

| Size | Criteria |
|------|----------|
| XS (1) | Not specified in standard ruler |
| S (2) | Process triggered by a system event (e.g.: credit evaluation when all the required approvals are in place) |
| M (3) | Scheduled process (e.g.: bid process ending at 11 am everyday) |
| L (5) | Scheduled process triggered manually (e.g.: manually ending a nomination cycle) |
| XL (8) | External independent process (e.g.: a new application development that will run outside the system) |

**Occurrences:** Count the number of distinct background processes
**Example:** 4 scheduled processes = 4 occurrences × M (3) = 12 points

---

### 9. Notifications
**Definition:** Any kind of notification requirement in a Backlog Item.

| Size | Criteria |
|------|----------|
| XS (1) | Sending e-mail, system tray notification, SMS or hardware notification |
| S (2) | Not specified in standard ruler |
| M (3) | Not specified in standard ruler |
| L (5) | Not specified in standard ruler |
| XL (8) | Not specified in standard ruler |

**Occurrences:** Count the number of distinct notification types/triggers
**Example:** 3 email notifications = 3 occurrences × XS (1) = 3 points

---

### 10. Audits
**Definition:** Identification information trail (date and responsible) for business manipulations on Domain Entities.

| Size | Criteria |
|------|----------|
| XS (1) | Audit trail for 1 entity |
| S (2) | Not specified in standard ruler |
| M (3) | Not specified in standard ruler |
| L (5) | Not specified in standard ruler |
| XL (8) | Not specified in standard ruler |

**Occurrences:** Count the number of entities requiring audit trails
**Example:** 3 audited entities = 3 occurrences × XS (1) = 3 points

---

## Calculation Formula

```
Total BCP = Σ (Occurrences × T-Shirt_Points) for all 10 dimensions
```

## Dimension Calculation Protocol

Use this protocol for every estimate. It prevents the two common sources of instability: counting different things across runs, and choosing a size before the counted unit is clear.

### General Steps

1. **Name the counted unit** for the dimension before scoring.
2. **Collect evidence** from the artifact, foundation docs, or codebase. Cite source IDs or file paths.
3. **Calculate quantity** only for dimensions that require a quantity (`qty`): Interface Elements, Domain Entities, New Domain Entities.
4. **Calculate occurrences** from the dimension rule. Do not reuse acceptance-criteria count as occurrences unless the dimension explicitly counts rule/process/notification/audit occurrences.
5. **Select complexity size** using the dimension criteria. If the standard ruler has no criteria for a size, do not use that size.
6. **Calculate points** as `occurrences × size points`.
7. **Record confidence** based on evidence quality, not on whether the number looks reasonable.

### Per-Dimension Calculation Rules

| Dimension | Counted unit | Occurrences | Size decision | Point rule |
|-----------|--------------|-------------|---------------|------------|
| Business Rules | Distinct rule set: validation group, decision workflow, formula, state transition, or policy that can change independently | Number of distinct rule sets | XS/S/M/XL by phase and decision density; group related SHALL lines in one flow instead of counting every sentence separately | occurrences × size points |
| Interface Elements | Unique interactive or data-presenting component pattern | `ROUNDUP(qty / 5, 0)` | S/M/L/XL by static vs dynamic behavior and existing vs new business context | occurrences × size points |
| Roles/Permissions | Permission model for the artifact | 1 | XS for same permissions, S for one depth level, M for two or more depth levels | 1 × size points |
| Solution Variabilities | Variant model for achieving the same business objective | 1 | XS for single flow, M for small parameter-driven behavior changes, XL for significantly different behavior by parameter/context | 1 × size points |
| Domain Entities | Business-relevant entities involved, including referenced/read entities used for decisions | 1 | Derived only from qty: 1=XS, 2-3=S, 4-5=M, 6-7=L, >7=XL | 1 × derived size points |
| New Domain Entities | Entities newly added to the domain or existing entities with new attributes/relationships | `ROUNDUP(qty / 3, 0)` | S for modifications to existing entities, L for new entities; if mixed, use L and explain | occurrences × size points |
| Boundaries | Boundary model for ownership, durability, or exchange across UI/DB/API/service/device/system edges | 1 | XS for DB/UI/self-contained, S for physical device exchange, M for remote perennial business information, XL for remote ethereal/temporary exchange | 1 × size points |
| Background Processes | Distinct async, scheduled, batch, worker, automated, or system-triggered process that can fail/change independently | Number of distinct processes | S/M/L/XL by trigger and execution ownership in the standard criteria | occurrences × size points |
| Notifications | Distinct trigger + channel + recipient/template combination | Number of distinct notification combinations | XS only when applicable | occurrences × 1 |
| Audits | Entity requiring audit/history/traceability for business manipulation | Number of audited entities | XS only when applicable | occurrences × 1 |

### Counting Stability Rules

- Count **business concepts**, not implementation files, unless the artifact is explicitly estimating implementation tasks.
- Count **unique patterns**, not repeated instances. A table with many rows is one interface element; repeated cards are one card pattern.
- Count **independent change reasons**. If two requirements always change together, they are usually one rule set or process.
- Mandatory dimensions cannot be N/A; use XS with explicit rationale when the artifact is self-contained or single-flow.
- Optional dimensions should be N/A with zero points when evidence is absent. Do not invent points to avoid zeros.
- When evidence is incomplete, keep the best evidence-supported number and lower confidence. Do not add padding for uncertainty.

### Dimension Calibration Rules (All Estimates)

Apply these rules to **every estimate** — story, unit, or spec, whether or not `design.md` and `tasks.md` exist. Most estimation variance comes from two sources: counting different things across runs (granularity drift) and resolving the same ambiguity differently (e.g. "is this boundary perennial or ethereal?"). These rules pin down both so independent estimators converge. When `design.md`/`tasks.md` provide explicit counts, use those counts — but the grouping and sizing judgments below still apply.

**Requirements-only estimates:** when only `requirements.md` exists, additionally follow the tie-breakers marked *(requirements-only)*, prefer the lower evidence-supported count on ambiguity, and lower confidence instead of inflating points.

These rules are **domain-agnostic principles**. For worked examples that show how they were applied to specific specs (an AI summarize API, long-audio chunking, a CI/CD pipeline), see [calibration-examples.md](calibration-examples.md) — pattern-match the reasoning there, not the numbers. Re-derive every count from the artifact in front of you; do not transplant another spec's entity count onto yours because the wording looks similar.

#### Business Rules

- Group rules by explicit functional section or cohesive workflow, not by every `SHALL` sentence.
- A user story with numbered subsections usually has one rule set per subsection. If there are no subsections, use one rule set per acceptance-criteria cluster.
- **Do not use acceptance-criteria count as a stand-in for occurrence count.** Many ACs can describe one rule set; the question is how many independently changeable rule sets exist, not how many lines the spec contains.
- Use **M** for rule sets with a few phases/steps and a few decision points. When detail is thin, M is the default sizing *(requirements-only)*.
- Use **XL** only when one rule set itself has many phases/steps or many decision points. Do not use XL only because the artifact has many acceptance criteria; increase occurrences instead.
- If two counts are plausible, prefer the count produced by section headings and lower confidence.

#### Interface Elements

- Count runtime UI/API contract elements only: user-facing controls, API endpoints, request fields, response fields, schema fields, data tables, or action controls.
- Do not count implementation/configuration artifacts as Interface Elements: `pyproject.toml`, lock files, Dockerfile, `.dockerignore`, CI commands, linter rules, README links, architecture documents, topology diagrams, IAM descriptions, environment tables, or operational runbooks.
- **Backend-only or infrastructure-only specs with no runtime API or UI contract should score this dimension N/A (0 points).** Only count Interface Elements when the spec explicitly defines a runtime API contract (endpoints, request/response fields, schema fields) or delivers user-facing UI.
- Backend/API specs can have Interface Elements when they explicitly define endpoints, request fields, response fields, or schema fields.
- Infrastructure, CI/CD, coding-standard, and documentation-only specs are N/A unless they define a runtime API/UI contract.
- For backend API contracts without UI design, use static sizing (`S` existing context, `M` new context) unless dynamic filtering/sorting/modal/table behavior is explicit.

#### Roles/Permissions

- User story personas are not permission sets by themselves.
- Use **XS** when all users/personas follow the same permission model or no access differences are specified.
- Use **S** only when explicit same-depth permission sets are required.
- Use **M** only when explicit multi-depth role hierarchy or access matrix behavior is required.
- IAM/service roles count only when the artifact changes permission behavior relevant to the backlog item; otherwise cite them under Boundaries or Domain Entities, not Roles/Permissions.
- Branch protection, merge blocking, or CI gates that change contributor merge ability count as **S** same-depth permission behavior, even if the only named persona is Developer.

#### Solution Variabilities

- Use **XS** when the artifact describes one fixed behavior with no meaningful parameter-driven path.
- Use **M** when parameters tune the same flow without changing the main algorithm, orchestration topology, or external contract.
- The deciding question for XS vs M is whether any parameter selects between runtime behaviors or external targets at all — an env var choosing which model/provider handles a step is **M** even when the application's branching logic is identical. The deciding question for M vs XL is whether parameter values change the strategy, topology, or contract rather than tuning the same flow.
- Use **XL** when parameter values can substantially change the processing strategy, orchestration topology, provider behavior, or user-visible outcome. A cluster of behavior-changing parameters (e.g. AI model/prompt/format knobs, or chunking/segmentation/concurrency/retry settings) usually qualifies — see [calibration-examples.md](calibration-examples.md).
- Environment names, branch names, thresholds, and simple configuration values are **M** unless they produce materially different behavior.

#### Domain Entities

- Count named business/API concepts, not every technical field or implementation helper.
- API request metadata such as `request_id` belongs to its owning request entity unless it has its own lifecycle or persistence.
- Error response and success response are separate entities only when both schemas are explicitly specified.
- Logs/performance baseline are operational evidence, not Domain Entities, unless the artifact defines a stored business record for them.
- For infrastructure/automation specs (e.g. CI/CD), count stable capability concepts rather than splitting every tool command into its own entity.
- When the entity count lands on a size boundary (e.g. 5 vs 6), use the higher count only if every entity has an explicit independent lifecycle in the artifact. Otherwise use the lower count and Medium confidence.
- See [calibration-examples.md](calibration-examples.md) for how these grouping rules played out on specific specs — reuse the reasoning, re-derive the count.

#### New Domain Entities

- Count new or materially modified business/domain concepts, persistent records, API schemas, or durable data structures.
- Do not count constants, limits, environment variables, linter rules, CI steps, documentation sections, Docker files, or individual attributes as separate entities.
- Group attributes into their owning entity. Sub-fields, indexes, and in-memory buffers belong to the same entity unless separate persistent records are specified.
- If the artifact modifies existing behavior without introducing a new domain concept, use **S** for modified existing entities.
- Use **L** only for genuinely new domain entities; if design is missing and new-vs-modified is unclear, count the minimum evidence-supported quantity and set Medium/Low confidence.
- Group related fields into their owning schema (request fields → request schema, payload fields → payload schema, status/error fields → response/error contract) rather than counting fields individually.
- CI/CD pipelines are process/configuration capability, not New Domain Entities, unless the requirements define a durable deployment record/schema. Deployment metadata/log output alone is not a new domain entity.
- See [calibration-examples.md](calibration-examples.md) for worked groupings (API schema groups, enhancement-modifies-one-entity, pipeline-is-not-an-entity) — match the reasoning, not the counts.

#### Boundaries

- Score one boundary model for the artifact, not one point per external system.
- The deciding question for M vs XL is **whether the exchanged payload persists as a durable record after the request completes** — not whether the output is valuable to the caller. A transcription returned synchronously and never stored is ethereal even though it is the business deliverable.
- Use **M** for remote services that exchange durable/perennial information: CI status, deployment status, logs, prompt templates, stored configuration, or infrastructure metadata.
- Use **XL** for remote service exchange of ethereal/temporary runtime information: audio payloads, transient transcripts, request-scoped model outputs, streaming data, or short-lived orchestration messages.
- CI/CD source-control, runner, staging, notification, and log exchanges are usually **M**, not XL, unless the artifact explicitly processes transient business payloads through the pipeline.

#### Background Processes

- Count processes that run outside direct user request handling or direct developer command execution.
- CI/CD pipelines, scheduled jobs, queue workers, deployment triggers, budget alerts, and system-event automations can count.
- Async work inside a synchronous request lifecycle does not count as Background Processes; capture its complexity in Business Rules and Boundaries instead.
- A multi-stage CI/CD pipeline is one background process unless separate triggers/schedules or independently deployable workers are specified.
- Budget alerts count as Notifications first. Count them as Background Processes only when the artifact requires a distinct monitoring job implementation.

#### Notifications and Audits

- Count Notifications only when a recipient/channel or alert trigger is explicitly required.
- Budget alert threshold requirements count as one Notification even when recipient/channel details are deferred.
- Logs are not Audits by default. Count Audits only when the artifact requires traceability/history of business entity manipulation with actor/date/responsible information.
- If a requirement only says "log errors" or "include request_id in logs", keep Audits N/A and cite logging under Business Rules or Boundaries.

## Calculator Validation Rules

| Dimension | Allowed sizes | Calculator rule |
|-----------|---------------|-----------------|
| Business Rules | XS, S, M, XL, N/A | Points = occurrences × size points |
| Interface Elements | S, M, L, XL, N/A | Occurrences = `ROUNDUP(qty / 5, 0)` when not N/A |
| Roles/Permissions | XS, S, M | Mandatory, non-N/A |
| Solution Variabilities | XS, M, XL | Mandatory, non-N/A |
| Domain Entities | XS, S, M, L, XL | Mandatory; complexity is derived from qty: 1=XS, 2-3=S, 4-5=M, 6-7=L, >7=XL |
| New Domain Entities | S, L, N/A | Occurrences = `ROUNDUP(qty / 3, 0)` when not N/A |
| Boundaries | XS, S, M, XL | Mandatory, non-N/A |
| Background Processes | S, M, L, XL, N/A | Points = occurrences × size points |
| Notifications | XS, N/A | Points = occurrences × size points |
| Audits | XS, N/A | Points = occurrences × size points |


## Quick Reference Table

| # | Dimension | Typical Range | Mandatory |
|---|-----------|---------------|-----------|
| 1 | Business Rules | 1-8 pts |  |
| 2 | Interface Elements | 2-8 pts per 5 elements |  |
| 3 | Roles/Permissions | 1-3 pts | ✓ |
| 4 | Solution Variabilities | 1-8 pts | ✓ |
| 5 | Domain Entities | 1-8 pts | ✓ |
| 6 | New Domain Entities | 2-5 pts per 3 entities | Optional |
| 7 | Boundaries | 1-8 pts | ✓ |
| 8 | Background Processes | 2-8 pts per process | Optional |
| 9 | Notifications | 1 pt per notification | Optional |
| 10 | Audits | 1 pt per entity | Optional |
