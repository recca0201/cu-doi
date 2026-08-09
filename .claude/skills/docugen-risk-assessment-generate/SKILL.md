---
name: docugen-risk-assessment-generate
description: Generate comprehensive Risk Security Assessment from project descriptions and create structured Risk Security Assessment documentation
allowed-tools: Read, Write, Bash
argument-hint: Describe your project, features, technology stack, user base, and any specific requirements or constraints
---

# Risk Security Assessment

Generate a Risk Security Assessment from a project description

## Overview

You are an expert in security risk assessment. Given a project description (architecture, components, tech stack, user base, data sensitivity, compliance needs), produce a complete Risk Security Assessment document that:
- Fills the template frontmatter (project, dates, responsible team)
- Populates the overview counts (likelihood and impact summaries)
- Generates a risk table with identified assets/components, risk types, descriptions, severity, likelihood, impact, mitigation action plans, PIC, due dates, status and notes
- Provides severity/likelihood mapping and a filled scoring matrix where appropriate
- Writes the final document to `docs/risk/risk_security_assessment.md`

## Template

Use the template at `references/risk_security_assessment_template.md` as the canonical layout and field names. Preserve the template structure and only replace placeholder values with generated content or stakeholder placeholders like `[to be defined by stakeholders]`.

## Your task

1. Parse the user's project description to extract: components, data flows, sensitive assets, external integrations, expected scale, and compliance/regulatory requirements.
2. Identify and list risks for each discovered component or asset. For each risk produce: risk type, concise description, severity (use template levels), likelihood (use template levels), impact descriptor (derived from score), a short actionable mitigation plan, PIC (placeholder if unknown), due date (placeholder if unknown), status (TODO/DOING/DONE/BLOCKED), and an optional note.
3. Summarize counts by Likelihood and Impact categories and update the overview tables in the template accordingly.
4. Populate the severity×likelihood scoring matrix section if the template expects numerical mappings.
5. Save the completed assessment to `docs/risk/risk_security_assessment.md`. Ensure `docs/risk/` exists or create it.
6. At the end, produce follow-up questions for any missing or ambiguous information (e.g., data classification, SLAs, responsible teams).

## Process Steps

- Parse Project Info
- Discover Components & Assets
- Identify Risks & Assess Severity/Likelihood
- Propose Mitigations and Assignments
- Populate Template and Save Document
- Provide follow-up questions

## Quality Guidelines

- Be specific and testable: each mitigation or control should be verifiable (e.g., "Enable parameterized queries for DB access; validate by code review and SAST scan").
- Use placeholders like `[to be defined by stakeholders]` or `[due date: to be scheduled]` when information is missing.
- Prefer concise lines in the risk table; keep descriptions short but actionable.
- Map severity and likelihood using the exact terms from the template (Negligible, Minor, Moderate, Significant, Severe) and (Rare, Unlikely, Possible, Likely, Almost certain).
- **PIC (Person In Charge) Assignment**: Use standardized role names:
  - ✅ Use: **TA** (Technical Architect) - default for most security risks
  - ✅ Use: **Dev** (Developer), **QA** (Quality Assurance), **PPO** (Product Owner)
  - ✅ Use combinations: **TA/Dev**, **TA/QA**, **Dev/QA**
  - ❌ Avoid: "Backend Team", "DevOps Team", "Security Team", "Full-stack Team"
  - **Default**: Assign most security risks to **TA** unless specific implementation required (e.g., Dev for code changes)

## Output

- Primary: `docs/risk/risk_security_assessment.md` (complete assessment)
- Secondary: a short list of follow-up questions to collect missing parameters

## Constraints

- Follow the template structure exactly.
- Do not invent team names or dates—use stakeholder placeholders when unknown.
- Keep generated mitigation steps pragmatic and prioritized by risk score.
- Use only allowed tools declared at the top of this file.
- **IMPORTANT - Files to Generate**:
  - ✅ ONLY generate `docs/risk/risk_security_assessment.md` (the actual risk assessment document)
  - ❌ DO NOT generate documentation files like `MARKDOWN_STRUCTURE.md`, `USAGE_GUIDE.md`, `README.md`, or similar guide files
  - ❌ DO NOT generate example files, template files, or tutorial files
  - ✅ Include follow-up questions directly in your text response to the user
  - ✅ Optionally create `docs/risk/assessment_questions.md` if user requests questions in a separate file

---

When ready, ask the user for the project description or use provided project context to generate the assessment.