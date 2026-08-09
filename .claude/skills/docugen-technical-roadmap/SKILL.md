---
name: docugen-technical-roadmap
description: Generate comprehensive Technical Roadmap from project descriptions, milestones, and releases
allowed-tools: Read, Write, Bash
argument-hint: Describe your project, planned releases/milestones, technology stack, team structure, and any specific constraints or goals
---

# Technical Roadmap Generator

Generate a comprehensive Technical Roadmap from project descriptions, releases, and milestones.

## Overview

You are an expert in technical planning and roadmap development. You will analyze project descriptions, planned releases, and milestones to generate a **concise, actionable technical roadmap** that spans multiple quarters and covers critical aspects of software delivery.

The technical roadmap template provides a structured approach to planning and tracking:
- **Environments**: Dev, Test, Staging, and Production setup timeline
- **Proof of Concepts (PoCs)**: Identify technical risks and validation opportunities
- **Non-Functional Requirements (NFRs)**: Security testing, performance testing, technical debt management
- **Integrations**: External system integrations and dependencies
- **Releases**: MVP and subsequent release planning with clear criteria
- **Gantt Chart**: Visual timeline of all activities

### Technical Roadmap Template Structure:

The complete template is available in `references/technical_roadmap_template.md` and includes:
- Project metadata and executive summary (1-2 paragraphs max)
- Quarterly summary table (Q1-Q4)
- Tables for Environments, PoCs, NFRs, Integrations, Releases
- Gantt chart visualization
- Timeline view by quarter (bullet points only)
- Risk summary table
- Decision log (brief entries only)

**IMPORTANT - Keep It Concise:**
- Use tables wherever possible, not prose
- Keep descriptions to 1-2 sentences
- Avoid redundancy between sections
- Focus on actionable information only
- Total document should be 500-800 lines max

---

## Your Task

1. **Analyze the project description** to understand scope, technology stack, and goals
2. **Identify milestones and releases** from the project description or user input
3. **Discover potential PoCs** based on technical risks, new technologies, or unproven integrations
4. **Determine NFR testing frequency** by asking about security and performance testing needs
5. **Identify technical debt** from project context or explicitly ask about known issues
6. **Generate a complete roadmap document** at `docs/roadmap/technical_roadmap.md`
7. **Provide follow-up questions** for any missing information

### Process Steps:

1. **Parse Project Information**: Extract key elements:
   - Project name, goals, and scope
   - Technology stack and architecture approach
   - Team structure and size
   - Timeline and constraints
   - Planned releases or milestones
   - Known integrations or dependencies

2. **Interactive Information Gathering**: ASK the user about:
   - **Release Schedule**: "What releases or milestones are planned? (e.g., MVP in Q2, v1.1 in Q3)"
   - **PoC Needs**: "Are there any technical unknowns or new technologies that need validation through PoCs?"
     - Look for: new frameworks, unproven integrations, scalability concerns, third-party services
   - **Security Testing Frequency**: "How often should security testing be performed? (e.g., monthly scans, quarterly penetration testing, before each release)"
   - **Performance Testing Frequency**: "How often should performance testing be conducted? (e.g., before each release, quarterly, when performance issues arise)"
   - **Technical Debt**: "Are there known technical debt items that need to be addressed?"
     - Examples: code refactoring, dependency upgrades, architectural improvements, performance optimizations
   - **Environment Timeline**: "When should each environment (Dev, Test, Staging, Production) be ready?"
   - **Integrations**: "What external systems or services need to be integrated?"

3. **Identify PoCs Automatically**: Based on project description, suggest PoCs for:
   - New or unfamiliar technologies in the stack
   - Complex integrations with third-party systems
   - Scalability concerns (e.g., "handles 100K users" → PoC for load testing approach)
   - Novel architecture patterns (e.g., microservices, event-driven, serverless)
   - Security concerns (e.g., authentication mechanisms, data encryption approaches)
   - Performance-critical features (e.g., real-time processing, large data volumes)

4. **Generate Roadmap Sections** (Use Tables):

   **Environments Table**: Timeline for Dev → Test → Staging → Production

   **PoCs Table**: For each PoC, include:
   - Name, objective (1 sentence), timeline, owner, success criteria (brief)
   - Limit to 2-4 PoCs maximum

   **NFRs Table**: Combine all NFR activities in a single table:
   - Security testing (scans, reviews, frequency)
   - Performance testing (if needed)
   - Technical debt items (only critical ones)
   - Architecture/security processes (brief entries)

   **Integrations Table**: For each integration:
   - Name, purpose (1 sentence), timeline, owner, status

   **Releases Table**:
   - MVP + 1-2 future releases max
   - Release criteria as checklist (5-7 items max)

5. **Gantt Chart**: Generate Mermaid gantt chart with:
   - Sections: Environments, PoCs, Development, Security, Testing, Integration
   - Key milestones marked
   - Critical path highlighted
   - Keep it visual and easy to read

6. **Quarterly Timeline**: Brief bullet points by month (not paragraphs)
   - Format: `- [Owner] Activity name` (one line per activity)
   - Distribute activities across quarters based on project timeline

7. **Risk and Dependency Tables**:
   - Critical risks table: 3-5 key risks with mitigation (brief)
   - Dependencies table: External dependencies only
   - No lengthy descriptions

### Roadmap Quality Guidelines:

- ✅ **Be Concise**: 500-800 lines total, use tables not prose, 1-2 sentences per item
- ✅ **Be Specific**: Use actual months/quarters, not vague "soon" or "later"
- ✅ **Be Visual**: Include Gantt chart, use tables, bullet points, no long paragraphs
- ✅ **Be Realistic**: Base timelines on project size, team capacity, and complexity
- ✅ **Be Selective**: Only include critical PoCs (2-4 max), key risks (3-5 max), important decisions
- ✅ **Use Placeholders**: For undefined details, use `[TBD]` or `[to be defined]`
- ✅ **Interactive Approach**: ASK follow-up questions rather than making assumptions
- ✅ **Standardized Roles**: **TA** (Technical Architect), **Dev** (Developer), **QA** (Quality Assurance), **PPO** (Product Owner)
- ❌ **Avoid**: Redundancy, lengthy descriptions, obvious statements, excessive details

### PoC Identification Triggers:

Look for these signals in the project description that warrant a PoC:
- ❓ "We're considering..." → PoC to evaluate options
- ❓ "New to the team..." → PoC to validate learning curve
- ❓ "High volume/scale..." → PoC to validate scalability approach
- ❓ "Complex integration..." → PoC to validate integration feasibility
- ❓ "Performance critical..." → PoC to validate performance approach
- ❓ "Novel/experimental..." → PoC to reduce technical risk
- ❓ "Not sure if..." → PoC to validate assumptions

### Technical Debt Discovery:

Ask explicitly about these common debt areas:
- **Code Quality**: Are there areas with poor code quality, low test coverage, or technical shortcuts?
- **Architecture**: Are there architectural limitations or patterns that need refactoring?
- **Dependencies**: Are there outdated libraries, frameworks, or dependencies that need upgrading?
- **Performance**: Are there known performance bottlenecks or inefficiencies?
- **Documentation**: Is technical documentation incomplete or outdated?
- **Testing**: Are there gaps in test coverage or testing infrastructure?

---

## Constraints

- **KEEP IT CONCISE**: 500-800 lines max, no lengthy prose, use tables and bullet points
- **Interactive Gathering**: ASK for release plans, PoC needs, testing frequency, and technical debt
- **Proactive PoC Discovery**: Analyze project description to identify 2-4 critical technical risks requiring PoCs
- **Visual Timeline**: ALWAYS include Mermaid Gantt chart showing all major activities and milestones
- **Realistic Timelines**: Base schedules on project scope and team capacity
- **Quarterly Distribution**: Balance work across quarters using month-by-month bullet points
- **Clear Ownership**: Assign each item to appropriate role (TA/Dev/QA/PPO)
- **Selective Content**: Include only critical items - top 3-5 risks, 2-4 PoCs, key integrations only
- **Create Directory Structure**: Ensure `docs/roadmap/` directory exists before creating the file
- **IMPORTANT - Files to Generate**:
  - ✅ ONLY generate `docs/roadmap/technical_roadmap.md` (the actual roadmap document)
  - ❌ DO NOT generate documentation files like `README.md`, `USAGE_GUIDE.md`, or similar guide files
  - ❌ DO NOT generate example files, template files, or tutorial files
  - ✅ Include follow-up questions directly in your text response to the user

---

## Example Workflow

1. User provides project description with tech stack and goals
2. You ask about planned releases/milestones
3. You identify potential PoCs based on technical risks (new tech, complex integrations, scale concerns)
4. You ask about security and performance testing frequency preferences
5. You ask about known technical debt items
6. You ask about environment readiness timeline
7. You generate the complete roadmap with quarterly breakdown
8. You provide follow-up questions for any remaining unknowns
9. You create `docs/roadmap/technical_roadmap.md` with all information

---

When ready, ask the user for the project description and begin the interactive information gathering process.