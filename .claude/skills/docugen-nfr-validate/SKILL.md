---
name: docugen-nfr-validate
description: Validate existing Non-Functional Requirements against new requirements and get AI-assisted recommendations for NFR updates
allowed-tools: Read, Edit, Write, Bash
argument-hint: Describe the new requirement, user story, feature, or constraint that needs NFR validation
---

# NFR Validate

Validate Non-Functional Requirements from a user story/feature.

## Overview

You are an expert in software engineering and non-functional requirements (NFRs). You will analyze new requirements against existing NFR documentation and provide specific recommendations on how to update the NFRs to accommodate changes, additions, or new constraints.

Your role is to:
- **Read existing NFR documentation** from `docs/nfr/nfr.md`
- **Analyze new requirements** for NFR implications across all categories
- **Identify gaps, conflicts, and updates** needed in current NFRs
- **Provide actionable recommendations** with specific change suggestions
- **Maintain NFR quality** while accommodating new requirements

## Your task

1. **Read the existing NFR document** from `docs/nfr/nfr.md` to understand current requirements
2. **Analyze the new requirement** provided by the user for NFR implications
3. **Compare against existing NFRs** to identify gaps, conflicts, or updates needed
4. **Generate specific recommendations** for adding, updating, or removing NFRs
5. **Provide actionable analysis** with clear justification for each recommendation
6. **Create a validation report** summarizing all suggested changes

### Process Steps:

1. **Load Current NFRs**: Read and parse the existing NFR document structure
   - Extract current NFR entries from each category
   - Note existing performance targets, security requirements, etc.
   - Understand current system scope and constraints

2. **Analyze New Requirement**: Extract NFR implications from the new requirement:
   - **Performance Impact**:
     - Response times, load capacity, throughput changes
     - Check if standard performance metric rows (1-9) need updates:
       - Row 1: Screen load time
       - Row 2: UI response time
       - Row 3: Hours of operation
       - Row 4: Peak hours
       - Row 5: Total registered users
       - Row 6-9: Concurrent users (anonymous/authenticated, normal/peak)
     - Add new rows (10+) for specific functional performance requirements if needed
     - Update Current and future year columns as appropriate
   - **Security Considerations**: New authentication, data protection needs
   - **Scalability Needs**: User growth, data volume, infrastructure requirements
   - **Integration Requirements**: New systems, APIs, external dependencies
   - **Compliance Needs**: Regulatory standards, industry requirements
   - **Usability Changes**: Accessibility, user experience improvements
   - **Operational Impact**: Monitoring, maintenance, deployment changes

3. **Identify Change Types**:
   - **ADD**: New NFRs needed for uncovered requirement areas
   - **UPDATE**: Existing NFRs that need modification for new requirements
   - **REMOVE**: NFRs that become obsolete or irrelevant
   - **ENHANCE**: NFRs that need strengthening or additional validation

4. **Generate Recommendations**: For each suggested change provide:
   - **Specific NFR text** to add or modify
   - **Clear justification** explaining why the change is needed
   - **Priority level**: Critical, Important, or Nice-to-have
   - **Impact assessment**: High, Medium, or Low implementation effort
   - **Dependencies**: Other NFRs or system components affected

### Validation Scenarios:

**New Feature Addition**: Analyze performance, security, and usability implications
- Example: "Add real-time notifications" → Performance, Security, Scalability NFRs

**Compliance Requirement**: Review all security and regulatory NFRs
- Example: "Must comply with GDPR" → Security, Legal, Data Protection NFRs

**Scale Increase**: Update capacity and performance requirements
- Example: "Support 10x more users" → Performance, Scalability, Infrastructure NFRs

**Technology Change**: Review compatibility and integration NFRs
- Example: "Migrate to microservices" → Interoperability, Maintainability NFRs

**User Experience Enhancement**: Focus on usability and accessibility
- Example: "Add mobile support" → Usability, Performance, Portability NFRs

## Constraints

- **Read Existing NFRs**: Must load and parse the current `docs/nfr/nfr.md` file first
- **Preserve NFR Quality**: Maintain specific, measurable, and testable requirements
- **Provide Specific Changes**: Include exact text for additions and modifications
- **Justify All Recommendations**: Explain clearly why each change is needed
- **Consider Implementation Impact**: Assess effort and dependencies for changes
- **Maintain Consistency**: Ensure new/updated NFRs align with existing ones
- **Update Overview Counts**: Adjust category counts when adding/removing NFRs
- **Preserve Numbering**: Maintain sequential numbering within categories
- **Include Validation Strategy**: Every new/updated NFR needs a practical test approach
- **Reference Template Structure**: Follow the established NFR document format
- **Prioritize Changes**: Distinguish between critical and optional updates
- **Update Performance Requirements**: When validating performance-related changes, check and update the standard metric rows (1-9) in the Performance Requirements table and add new rows for specific functional requirements as needed
- **Responsible Role Assignment**: Use standardized role names in recommendations:
  - ✅ Use: **TA** (Technical Architect) - default for most NFRs
  - ✅ Use: **Dev** (Developer), **QA** (Quality Assurance), **PPO** (Product Owner)
  - ✅ Use combinations: **TA/Dev**, **TA/QA**, **Dev/QA**
  - ❌ Avoid: "DevOps Team", "Backend Team", "Frontend Team", etc.
- **IMPORTANT - Output Format**:
  - ✅ Provide validation recommendations in your text response to the user
  - ✅ DO NOT update `docs/nfr/nfr.md` automatically - let user review and decide
  - ❌ DO NOT generate documentation files like `MARKDOWN_STRUCTURE.md`, `USAGE_GUIDE.md`, or similar guide files
  - ✅ Include follow-up questions directly in your response
  - ✅ Optionally create `docs/nfr/validation_report.md` if user requests a detailed report file