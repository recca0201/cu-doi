# Aggregates - Domain Model Building Blocks

## Purpose

Aggregates are clusters of entities and value objects treated as a single unit for data changes. They enforce business rules and maintain consistency.

## Aggregate Design Principles

### 1. Identify Aggregate Roots

The aggregate root is the only entity accessible from outside. It enforces all business rules.

**Criteria for aggregate root:**

- Has unique identity
- Controls access to aggregate internals
- Enforces invariants
- Published in bounded context interface

### 2. Define Aggregate Boundaries

**Keep aggregates small:**

- Include only entities/value objects needed to enforce invariants
- Avoid deep object graphs
- Consider eventual consistency for loosely related data

**Example:** Order aggregate

- Root: Order entity
- Inside: OrderLine entities (can't exist without Order)
- Outside: Product (referenced by ID, not included)

### 3. Enforce Invariants

Business rules that must always be true. Example: Order total = sum of order lines.

Implementation: Methods on root enforce invariants, maintain consistency.

### 4. Reference by ID

Aggregates reference other aggregates by ID, not direct references. Maintains boundaries, enables independent lifecycle.

## Aggregate Patterns

**One Entity**: Entity is its own aggregate root (e.g., User)
**Root + Children**: Root with owned entities (e.g., Order + OrderLines)
**Root + Value Objects**: Root with value objects (e.g., Customer + Address)

## Design Process

1. **Identify entities** from domain model
2. **Group related entities** that need to change together
3. **Choose aggregate root** (main entity with identity)
4. **Define boundaries** (what's inside vs referenced)
5. **Document invariants** (business rules to enforce)
6. **Specify operations** (methods on root that maintain invariants)

## Common Mistakes

❌ Too large: Including too many entities (performance issues)
❌ Too coupled: Aggregates referencing each other directly
❌ Weak boundaries: Not enforcing access through root
❌ Ignoring invariants: Not documenting business rules

## Output Format

For Construction Phase domain modeling:

```
Aggregate: [Name]
Root: [Entity name]
Entities: [List child entities]
Value Objects: [List value objects]
Invariants:
  - [Business rule 1]
  - [Business rule 2]
Operations:
  - [Operation 1]: [Purpose]
  - [Operation 2]: [Purpose]
References: [Other aggregates referenced by ID]
```
