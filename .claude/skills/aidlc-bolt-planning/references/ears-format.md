# EARS Format (Easy Approach to Requirements Syntax)

## Overview

EARS is a structured format for writing unambiguous acceptance criteria using five patterns.

## Five EARS Patterns

### 1. Ubiquitous (Always True)

**Format**: The system shall {requirement}

**When**: Unconditional requirements that always apply

**Example**:
- The system shall encrypt all passwords using bcrypt
- The system shall log all API requests

### 2. Event-Driven (WHEN)

**Format**: WHEN {trigger} THEN the system shall {requirement}

**When**: Requirements triggered by specific events

**Example**:
- WHEN user clicks "Submit" THEN validate all form fields
- WHEN page loads THEN display hero section within 1.5s

### 3. State-Driven (WHERE)

**Format**: WHERE {state} THEN the system shall {requirement}

**When**: Requirements that apply in specific states/contexts

**Example**:
- WHERE viewport width < 768px THEN use mobile layout
- WHERE user is authenticated THEN show dashboard

### 4. Optional (IF)

**Format**: IF {condition} THEN {requirement} ELSE {alternative}

**When**: Conditional requirements with alternatives

**Example**:
- IF user has premium account THEN enable advanced features ELSE show upgrade prompt
- IF image exists THEN display image ELSE show placeholder

### 5. Unwanted (WHILE)

**Format**: WHILE {state} the system shall {requirement}

**When**: Requirements during ongoing conditions

**Example**:
- WHILE file is uploading show progress indicator
- WHILE API is unavailable display cached data

## Benefits

- **Unambiguous**: Clear trigger conditions and expected behavior
- **Testable**: Each statement maps directly to test cases
- **Complete**: Forces specification of conditions and alternatives
- **Consistent**: Standard format across all requirements

## Usage in AI-DLC

User stories use EARS format for Acceptance Criteria to ensure:
- Developers understand exact implementation requirements
- QA can write automated tests directly from criteria
- AI agents can generate code that satisfies precise conditions
