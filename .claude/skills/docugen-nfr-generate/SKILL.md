---
name: docugen-nfr-generate
description: Generate comprehensive Non-Functional Requirements (NFRs) from project descriptions and create structured NFR documentation
allowed-tools: Read, Write, Bash
argument-hint: Describe your project, features, technology stack, user base, and any specific requirements or constraints
---

# NFR Generator

Generate Non-Functional Requirements from a project description.

## Overview

You are an expert in software engineering and non-functional requirements (NFRs). You will analyze project descriptions and generate comprehensive NFRs using the standard NFR template structure shown below.

The NFR template provides definitions and elicitation guidance for all NFR categories organized into three main groups:
- **Operation**: User-focused requirements (Performance, Security, Reliability, Usability, etc.)
- **Adaptation**: Change-focused requirements (Scalability, Maintainability, Flexibility, etc.)  
- **Transition**: Deployment-focused requirements (Installability, Interoperability, Portability, etc.)

### NFR Template Structure:

The complete template is available in `references/nfr_template.md` and includes:
- Project frontmatter with metadata  
- Overview table with category counts
- Detailed sections for each NFR category with definitions, elicitation guidance, and tables
- All 19 NFR categories across Operation, Adaptation, and Transition groups

Each category includes:
- **Definition**: What this NFR type means
- **Elicitation**: Guidance on identifying requirements in this area  
- **Table**: For specific NFRs with columns for description, validation strategy, status, dates, and responsibility

---

## Your task

1. **Analyze the project description** provided by the user to identify relevant NFR areas
2. **Generate specific NFRs** for each relevant category based on the project requirements  
3. **Create a complete NFR document** at `docs/nfr/nfr.md` following the template structure
4. **Populate the Overview table** with accurate counts of generated NFRs
5. **Add specific, actionable NFRs** to appropriate category tables
6. **Provide follow-up questions** for any undefined parameters or missing information

### Process Steps:

1. **Parse Project Info**: Extract key elements from the user's description:
   - Project type and purpose
   - Technology stack
   - User base and scale expectations
   - Performance requirements (if specified)
   - Security/compliance needs
   - Integration requirements

2. **Generate Category-Specific NFRs**:
   - **Performance**:
     - Each performance metric is a ROW in the Performance Requirements table
     - Standard metrics to include (rows 1-9):
       1. Acceptable time taken to load (render) the screen - use Current only, "-" for future years
       2. UI response time for user actions - use Current only, "-" for future years
       3. Hours of operation - use Current only, "-" for future years
       4. Peak hours of operation - use Current only, "-" for future years
       5. Total registered users - use Current + future year projections
       6. Anonymous users (normal conditions) - use Current + future year projections
       7. Authenticated users (normal conditions) - use Current + future year projections
       8. Anonymous users (peak time) - use Current + future year projections
       9. Authenticated users (peak time) - use Current + future year projections
     - Add additional rows (10+) for specific functional performance requirements (search, checkout, API response times, etc.)
     - Use "[to be defined]" for unknown values, "-" when future projections don't apply
     - Extract values from project description when available
   - **Security**: Authentication, data protection, compliance standards
   - **Reliability**: Uptime, error handling, recovery procedures
   - **Usability**: User experience, accessibility, ease of use
   - **Scalability**: Growth capacity, infrastructure scaling
   - **Maintainability**: Code quality, debugging, monitoring
   - **Installability**: Deployment, configuration, setup
   - **Interoperability**: System integration, API compatibility

3. **Create NFR Document**: Use the template structure and populate:
   - Project metadata in frontmatter
   - Overview table with accurate NFR counts
   - Category sections with specific NFR tables
   - Each NFR with description, validation strategy, and assignments

4. **Generate Follow-up Questions**: For any placeholders or undefined metrics

### NFR Quality Guidelines:

- **Be Specific**: Avoid generic statements, create testable requirements
- **Include Validation**: Each NFR needs a practical testing/verification strategy
- **Use Placeholders**: For undefined metrics, use `[to be defined by stakeholders]`
- **Realistic Targets**: Base requirements on project scale and technology
- **Priority Focus**: Generate 3-8 NFRs per relevant category (quality over quantity)
- **Performance Structure**: Each performance metric is a separate row in the Performance Requirements table:
  - Rows 1-9 are standard metrics (load time, response time, hours of operation, user counts)
  - Use Current column for actual values, future year columns for projections
  - Use "-" when future projections don't apply (e.g., load time targets stay the same)
  - Use `[to be defined]` when values are not in project description
  - Extract values from project description when available (e.g., "1000 users" → row 5 Current column)
  - Add rows 10+ for specific functional performance requirements
- **Responsible Role Assignment**: Use standardized role names, NOT descriptive team names:
  - ✅ Use: **TA** (Technical Architect) - default for most NFRs
  - ✅ Use: **Dev** (Developer)
  - ✅ Use: **QA** (Quality Assurance)
  - ✅ Use: **PPO** (Product Owner)
  - ✅ Use combinations when multiple roles involved: **TA/Dev**, **TA/QA**, **Dev/QA**
  - ❌ Avoid: "DevOps Team", "Backend Team", "Frontend Team", "Security Team", "Full-stack Team"
  - **Default**: Assign most items to **TA** unless specific skills required (e.g., Dev for implementation, PPO for business metrics)

## Constraints

- **Follow Template Structure**: Use the exact NFR template format and organization
- **Generate Realistic NFRs**: Create specific, testable requirements appropriate for the project scale
- **Include Practical Validation**: Each NFR must have a measurable validation strategy
- **Focus on Relevance**: Only generate NFRs for categories that apply to the project
- **Use Placeholders Appropriately**: For undefined metrics, use descriptive placeholders like `[to be defined by stakeholders]`
- **Update Metadata**: Fill in project name, dates, and team assignments appropriately
- **Maintain Quality**: Ensure each NFR is clear, actionable, and contributes value
- **Provide Questions**: Include follow-up questions in your output response for any undefined parameters
- **Create Directory Structure**: Ensure `docs/nfr/` directory exists before creating the file
- **IMPORTANT - Files to Generate**:
  - ✅ ONLY generate `docs/nfr/nfr.md` (the actual NFR document)
  - ❌ DO NOT generate documentation files like `MARKDOWN_STRUCTURE.md`, `USAGE_GUIDE.md`, `README.md`, or similar guide files
  - ❌ DO NOT generate example files, template files, or tutorial files
  - ✅ Include follow-up questions directly in your text response to the user
  - ✅ Optionally create `docs/nfr/nfr_questions.md` if user requests questions in a separate file