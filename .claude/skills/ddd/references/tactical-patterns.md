# Tactical DDD Patterns

## Entities

Objects with unique identity. ID never changes, attributes may change.
Lifecycle tracked (e.g., User, Order).

## Value Objects

Objects defined by attributes, not identity. No ID, immutable, equality by value.
Use for: Addresses, dates, money, coordinates.

## Domain Services

Operations spanning multiple aggregates or not fitting in entities. Stateless.
Example: PaymentProcessingService coordinates Order and Payment aggregates.

## Repositories

Interface for accessing aggregates, abstracting persistence.
One repository per aggregate root (not per entity).

Operations: findById(), save(), query methods.

## Domain Events

Represent domain occurrences. Past tense naming, immutable, timestamped.

**Use for:**

- Eventual consistency between aggregates
- Triggering side effects
- Audit trail
- Integration

Example: OrderPlaced, PaymentProcessed, UserRegistered.

## Factories

Complex object creation ensuring invariants. Use when construction requires multiple steps or validation.

## Modules (Packages)

Group related domain concepts.

**Organization:**

```
domain/
  order/
    Order.ts (aggregate root)
    OrderLine.ts (entity)
    OrderStatus.ts (value object)
    OrderRepository.ts (repository)
    OrderPlaced.ts (domain event)
  payment/
    ...
```

## Pattern Selection Guide

| Need                       | Pattern        |
| -------------------------- | -------------- |
| Unique identity, lifecycle | Entity         |
| Value with no identity     | Value Object   |
| Cross-aggregate operation  | Domain Service |
| Data access abstraction    | Repository     |
| Signal domain change       | Domain Event   |
| Complex object creation    | Factory        |
