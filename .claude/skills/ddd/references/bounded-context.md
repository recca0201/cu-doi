# Bounded Context - Unit Decomposition

## Purpose

**Bounded Context is the primary DDD concept for decomposing user stories into implementable units.**

A bounded context defines a boundary within which a domain model is consistent and unambiguous. Use this to identify natural unit boundaries.

## Identifying Bounded Contexts (Units)

### Step 1: Analyze User Stories

Review user stories for natural groupings based on:

- **Business capabilities** (e.g., "User Management", "Notifications", "Billing")
- **Data ownership** (which stories work with same data)
- **Team ownership** (which stories can be built independently)
- **Ubiquitous language** (where terminology is consistent)

### Step 2: Define Context Boundaries

Each bounded context becomes a unit. Criteria:

- Has clear business purpose
- Owns its data/entities
- Can be developed independently (or with minimal dependencies)
- Has well-defined interfaces to other contexts

### Step 3: Map Context Relationships

Types of relationships:

- **Shared Kernel**: Contexts share subset of domain model
- **Customer-Supplier**: Downstream context depends on upstream
- **Conformist**: Downstream conforms to upstream model
- **Anti-Corruption Layer**: Downstream protects itself from upstream changes
- **Published Language**: Integration via standardized protocol
- **Separate Ways**: Contexts are independent

### Step 4: Document Unit Boundaries

For each unit (bounded context):

- **Name**: Clear, business-aligned name
- **Purpose**: Business capability it supports
- **Entities**: Main domain entities owned
- **Dependencies**: Other units it depends on (with relationship type)
- **Interfaces**: APIs/events exposed to other units

## Example: E-commerce System

User stories analyzed → Bounded contexts identified:

1. **Product Catalog Context**
   - Stories: Browse products, search, filter
   - Entities: Product, Category, Specification
   - Dependencies: None
   - Interfaces: Product search API, product details API

2. **Order Management Context**
   - Stories: Place order, track order, cancel order
   - Entities: Order, OrderLine, ShippingInfo
   - Dependencies: Product Catalog (ACL), Payment (Customer-Supplier)
   - Interfaces: Order API, order status events

3. **Payment Context**
   - Stories: Process payment, refunds
   - Entities: Payment, Transaction, PaymentMethod
   - Dependencies: None (Separate Ways)
   - Interfaces: Payment processing API, payment events

Each context = 1 unit for implementation.

## Decision Criteria

**Split into separate units if:**

- Different business capabilities
- Different data ownership
- Can be developed in parallel
- Different scaling requirements
- Different teams

**Keep in same unit if:**

- Tight coupling in business logic
- Shared transactions required
- Same team ownership
- Always deployed together

## Output

For Inception Phase unit decomposition:

- List of units (bounded contexts)
- Unit boundaries and responsibilities
- Dependencies between units (with relationship types)
- Interfaces/contracts between units
- Suggested implementation sequence (based on dependencies)
