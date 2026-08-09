---
name: ddd
description: |
  Domain-Driven Design patterns and practices for modeling complex business domains.
  Use for domain modeling, bounded context analysis (unit decomposition), aggregate design, and strategic design.
  Critical for AI Solutions Architect when decomposing user stories into units.
version: 1.0.0
license: MIT
---

# Domain-Driven Design (DDD)

Apply Domain-Driven Design principles to create robust domain models and decompose user stories into bounded contexts (units).

## Core Capabilities

### 1. Bounded Context (Unit Decomposition)

**CRITICAL**: Primary tool for decomposing user stories into implementable units.

Load: `references/bounded-context.md`

Use when:

- Decomposing user stories into units
- Defining unit boundaries
- Identifying context boundaries
- Establishing clear interfaces between units

### 2. Aggregates and Entities

Load: `references/aggregates.md`

Use when:

- Designing domain models
- Identifying aggregate roots
- Defining aggregate boundaries
- Modeling entity relationships

### 3. Tactical Patterns

Load: `references/tactical-patterns.md`

Use when:

- Designing entities and value objects
- Creating domain services
- Implementing repositories
- Modeling domain events
- Building factories

### 4. Strategic Design

Load: `references/strategic-design.md`

Use when:

- Mapping relationships between contexts
- Defining context integration patterns
- Creating anti-corruption layers
- Planning context evolution

### 5. Ubiquitous Language

Load: `references/ubiquitous-language.md`

Use when:

- Establishing shared vocabulary
- Documenting domain terminology
- Ensuring team alignment
- Creating glossaries

## When to Use This Skill

- **Unit Decomposition** (Inception): Apply bounded context to decompose user stories
- **Domain Modeling** (Construction): Create aggregates, entities, value objects
- **Architecture Design**: Define context boundaries and integration patterns
- **Team Alignment**: Establish ubiquitous language

## Progressive Loading

Start with bounded-context.md for unit decomposition, then load other references as needed.

## Integration

Used by: AI Solutions Architect
Phase: Inception (unit decomposition), Construction (domain modeling)
Dependencies: None
