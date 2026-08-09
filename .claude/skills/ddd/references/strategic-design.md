# Strategic DDD - Context Mapping

## Purpose

Strategic design manages relationships between bounded contexts (units) and plans their evolution.

## Context Map Patterns

### 1. Shared Kernel

Two contexts share subset of domain model.

**When:** Teams closely collaborate, need exact same model for shared concepts
**Risk:** Changes affect both contexts
**Example:** Order and Shipping share Address model

### 2. Customer-Supplier

Downstream depends on upstream. Upstream considers downstream needs.

**When:** Clear dependency, collaborative teams
**Example:** Order Management (downstream) depends on Product Catalog (upstream)
**Integration:** Upstream provides API, considers downstream requirements

### 3. Conformist

Downstream conforms to upstream model without influence.

**When:** Upstream team doesn't consider downstream needs
**Example:** Internal system conforming to external API
**Integration:** Downstream adapts to upstream changes

### 4. Anti-Corruption Layer (ACL)

Downstream protects itself from upstream with translation layer.

**When:** Upstream model not suitable, prevent pollution
**Example:** Modern system integrating with legacy system via adapter/translator

### 5. Published Language

Integration via standardized, well-documented format.

**When:** Multiple contexts need to integrate
**Example:** JSON schema, XML schema, Protocol Buffers
**Benefits:** Decoupling, versioning support

### 6. Open Host Service

Upstream provides standardized API for all downstream consumers.

**When:** Multiple downstreams, stable interface needed
**Example:** REST API, GraphQL endpoint
**Pattern:** Versioned API with backward compatibility

### 7. Separate Ways

Contexts are completely independent.

**When:** No integration needed, duplication acceptable
**Example:** Separate microservices with no data sharing
**Benefits:** Maximum autonomy, no coupling

## Partnership

Mutual dependency, teams coordinate closely. Shared success criteria.

## Applying to Unit Dependencies

1. List all units
2. Identify dependencies
3. Choose pattern: ACL (protection), Customer-Supplier/Partnership (collaboration), Published Language (standard), Separate Ways (independent)
4. Document integration

## Example

Product Catalog → Order Management (Published Language)
Order → Payment (Customer/Supplier), Legacy Inventory (ACL)
Shipping ↔ Order (Partnership), Analytics → Order (Conformist)

## Output Format

For unit dependency documentation:

```
Context Map:

Unit: [Name]
Dependencies:
  - [Upstream Unit] via [Pattern]
    Integration: [API/Events/Shared DB]
    Protection: [ACL if needed]

Consumers (Downstream):
  - [Downstream Unit] via [Pattern]
    Interface: [API exposed]
```
