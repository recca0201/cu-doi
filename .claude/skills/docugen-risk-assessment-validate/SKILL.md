---
name: docugen-risk-assessment-validate
description: Validate existing Risk Security Assessments against changes or new features and provide AI-assisted recommendations
allowed-tools: Read, Edit, Write, Bash
argument-hint: Provide the change, feature, or project context to validate against the existing risk assessment
---

# Risk Security Assessment Validate

Validate an existing Risk Security Assessment document against new requirements, feature changes, or updated project context.

## Overview

You are an expert in security risk assessment. This skill loads the existing assessment at `docs/risk/risk_security_assessment.md`, compares it with a provided change or project update, and produces:
- A list of suggested edits (ADD / UPDATE / REMOVE / REPRIORITIZE)
- Concrete mitigation and validation recommendations
- Adjusted likelihood/impact counts and suggested status changes
- Follow-up questions for missing information

## Your task

1. Load the current assessment from `docs/risk/risk_security_assessment.md`.
2. Parse the provided change/feature/project context to identify affected components, data flows, and assets.
3. Identify which existing risks are affected, which new risks arise, and which items may be obsolete.
4. For each recommendation produce:
   - Action: `ADD` / `UPDATE` / `REMOVE` / `REPRIORITIZE`
   - Target row (asset/component) or new risk entry
   - Rationale (concise)
   - Suggested severity & likelihood (using template terms)
   - Mitigation steps (practical, testable)
   - Validation strategy (how to verify the mitigation)
   - Priority (Critical / Important / Nice-to-have)
   - Dependencies and suggested PIC / due date placeholders
5. Provide an updated overview counts section and highlight any changes to the scoring matrix or status mappings.
6. Output a short actionable report and a proposed patch (markdown) to update `docs/risk/risk_security_assessment.md`.

## Process Steps

- Load current assessment (`docs/risk/risk_security_assessment.md`)
- Parse change/feature description
- Map impacts to assets and existing risks
- Generate recommendations and validation steps
- Produce follow-up questions for unresolved items
- Offer a draft updated assessment snippet or full replacement

## Quality Guidelines

- Preserve original template structure and wording where possible.
- Use exact severity and likelihood terms from the template (Negligible, Minor, Moderate, Significant, Severe) and (Rare, Unlikely, Possible, Likely, Almost certain).
- Make mitigation steps verifiable (e.g., specific config changes, scans, tests).
- Use placeholders like `[to be defined by stakeholders]` and `[due date: to be scheduled]` when unknown.
- Prioritize recommendations by risk score and business impact.
- **PIC (Person In Charge) Assignment**: Use standardized role names in recommendations:
  - ✅ Use: **TA** (Technical Architect) - default for most security risks
  - ✅ Use: **Dev** (Developer), **QA** (Quality Assurance), **PPO** (Product Owner)
  - ✅ Use combinations: **TA/Dev**, **TA/QA**, **Dev/QA**
  - ❌ Avoid: "Backend Team", "DevOps Team", "Security Team"

## Output

- Primary: A validation report (markdown) summarizing recommendations and the proposed edits to `docs/risk/risk_security_assessment.md`.
- Secondary: A short list of follow-up questions for stakeholders.

## Constraints

- Must load the existing assessment first.
- Do not overwrite the existing file without explicit confirmation; provide a proposed patch instead.
- Use only the allowed tools declared in this file.
- **IMPORTANT - Output Format**:
  - ✅ Provide validation recommendations in your text response to the user
  - ✅ DO NOT update `docs/risk/risk_security_assessment.md` automatically - let user review and decide
  - ❌ DO NOT generate documentation files like `MARKDOWN_STRUCTURE.md`, `USAGE_GUIDE.md`, or similar guide files
  - ✅ Include follow-up questions directly in your response
  - ✅ Optionally create `docs/risk/validation_report.md` if user requests a detailed report file

---

When ready, provide the change/feature or project context to validate, or ask to run a sample based on repository contents.
