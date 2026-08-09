# Ubiquitous Language

## Purpose

Shared vocabulary used consistently by developers and domain experts within bounded context. Eliminates translation between business and technical terms.

## Developing Ubiquitous Language

**1. Collaborate**: Interview stakeholders, listen for domain terms, ask about concepts (not implementation)
**2. Document**: Name, definition, context, aliases, examples for each term
**3. Use Consistently**: Code, conversations, docs, tests use same terms
**4. Evolve**: Refine definitions, introduce new terms, retire obsolete ones

## Example: E-commerce Ubiquitous Language

**Order Management Context:**

| Term         | Definition                              | Example                           |
| ------------ | --------------------------------------- | --------------------------------- |
| Order        | Customer's request to purchase products | Order #12345                      |
| Order Line   | Individual product + quantity in order  | 2x Widget A in Order #12345       |
| Place Order  | Transition order from draft to placed   | User clicks "Place Order"         |
| Order Status | Current state of order                  | Draft, Placed, Shipped, Delivered |
| Fulfillment  | Process of getting order to customer    | Shipping + delivery               |

**Avoid:** Generic terms like "record", "data", "entity" - use domain terms.

## Language in Code

Use domain terms in class/method names. Avoid generic terms like "Record", "Data", "Entity".
Good: `Order.placeOrder()`, `ship()`, `cancel()`
Bad: `OrderRecord.submit()`, `updateStatus()`

## Multiple Contexts, Different Languages

Same term can mean different things in different contexts:

**Product in Product Catalog:**

- SKU, name, description, specifications
- Focus: Search, browse, compare

**Product in Order Management:**

- ProductId, price snapshot, availability
- Focus: Purchase, fulfillment

**Product in Inventory:**

- Stock level, warehouse location
- Focus: Replenishment, allocation

This is correct! Each context has its own model. Use ACL to translate.

## Anti-Patterns

❌ Using technical jargon instead of domain terms
❌ Different terms for same concept
❌ Same term for different concepts (in same context)
❌ Implementing before language is clear
❌ Developers defining language without domain experts

## Output Format

For domain modeling deliverables:

```markdown
## Ubiquitous Language - [Context Name]

| Term    | Definition   | Aliases     | Examples   |
| ------- | ------------ | ----------- | ---------- |
| [Term1] | [Definition] | [Alt names] | [Examples] |
| [Term2] | [Definition] | [Alt names] | [Examples] |

...

## Key Concepts

[Explain important domain concepts, relationships]

## Business Rules

[Express business rules using ubiquitous language]
```

Glossary should be living document, updated as domain understanding evolves.
