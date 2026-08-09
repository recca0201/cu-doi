# Mermaid Diagramming Skill

## Overview

The Mermaid Diagramming skill provides templates and patterns for creating visual diagrams using Mermaid syntax to enhance documentation and communication across AI-DLC workflows.

**Purpose**: Enable visual communication through diagrams embedded in markdown documents.

**Used By**: All agents (AI Delivery Manager, AI Solutions Architect, AI Design Orchestrator, AI Orchestration Engineer, AI Quality Orchestrator, AI Assistant Product Owner)

## Supported Diagram Types

### 1. Gantt Charts (Roadmaps & Timelines)

**Used By**: AI Delivery Manager  
**Purpose**: Project roadmaps, sprint planning, milestone tracking

```mermaid
gantt
    title Product Roadmap
    dateFormat YYYY-MM-DD

    section Foundation
    Codebase Analysis    :done, f1, 2025-01-16, 2d
    Design System        :done, f2, after f1, 1d

    section Inception
    User Stories         :active, i1, 2025-01-19, 2d
    Unit Decomposition   :i2, after i1, 1d
    Roadmap Creation     :i3, after i2, 1d

    section Construction
    Bolt 1: Backend      :c1, after i3, 5d
    Bolt 2: Frontend     :c2, after c1, 4d
    Bolt 3: Integration  :c3, after c2, 3d
```

### 2. Sequence Diagrams (API Flows & Interactions)

**Used By**: AI Solutions Architect, AI Orchestration Engineer  
**Purpose**: API interactions, service communication, user flows

```mermaid
sequenceDiagram
    participant Client
    participant Gateway
    participant Auth
    participant Service
    participant DB

    Client->>Gateway: POST /api/v1/notifications
    Gateway->>Auth: Validate Token
    Auth-->>Gateway: User ID
    Gateway->>Service: Create Notification
    Service->>DB: INSERT notification
    DB-->>Service: notification_id
    Service->>Gateway: 201 Created
    Gateway-->>Client: notification_id
```

### 3. Class Diagrams (Domain Models & DDD)

**Used By**: AI Solutions Architect  
**Purpose**: Domain models, entity relationships, DDD aggregates

```mermaid
classDiagram
    class NotificationAggregate {
        <<AggregateRoot>>
        +NotificationId id
        +UserId recipientId
        +NotificationEvent event
        +DateTime timestamp
        +NotificationStatus status
        +markAsRead()
        +archive()
    }

    class NotificationEvent {
        <<ValueObject>>
        +EventType type
        +EntityId sourceId
        +EventData data
    }

    class NotificationRepository {
        <<Repository>>
        +findById(id)
        +findByRecipient(userId)
        +save(notification)
    }

    NotificationAggregate *-- NotificationEvent
    NotificationRepository --> NotificationAggregate
```

### 4. Flowcharts (Processes & User Flows)

**Used By**: AI Design Orchestrator, AI Quality Orchestrator  
**Purpose**: User flows, business processes, test flows

```mermaid
flowchart TD
    Start([User Visits App]) --> Auth{Authenticated?}
    Auth -->|No| Login[Login Page]
    Auth -->|Yes| Dashboard[Dashboard]

    Login --> Validate{Valid?}
    Validate -->|No| Login
    Validate -->|Yes| Dashboard

    Dashboard --> Action{User Action}
    Action -->|View Notifications| Notif[Notification Center]
    Action -->|View Profile| Profile[Profile Page]
    Action -->|Logout| Logout[Logout]

    Logout --> End([End Session])
```

### 5. Entity Relationship Diagrams (Database Models)

**Used By**: AI Solutions Architect, AI Orchestration Engineer  
**Purpose**: Database schema, entity relationships

```mermaid
erDiagram
    USERS ||--o{ NOTIFICATIONS : receives
    USERS {
        uuid id PK
        string email
        string name
        datetime created_at
    }

    NOTIFICATIONS ||--|| NOTIFICATION_EVENTS : contains
    NOTIFICATIONS {
        uuid id PK
        uuid recipient_id FK
        uuid event_id FK
        datetime timestamp
        enum status
        boolean is_read
    }

    NOTIFICATION_EVENTS {
        uuid id PK
        enum event_type
        uuid source_id
        jsonb event_data
        datetime created_at
    }

    BADGES ||--o{ NOTIFICATION_EVENTS : triggers
    ANNOUNCEMENTS ||--o{ NOTIFICATION_EVENTS : triggers
```

### 6. Component/Architecture Diagrams

**Used By**: AI Solutions Architect  
**Purpose**: System architecture, component dependencies

```mermaid
graph TB
    subgraph "Frontend"
        UI[React UI]
        WSClient[WebSocket Client]
    end

    subgraph "Backend"
        API[REST API]
        WSServer[WebSocket Server]
        NotifService[Notification Service]
    end

    subgraph "Data"
        DB[(PostgreSQL)]
        Cache[(Redis)]
    end

    UI --> API
    UI --> WSClient
    WSClient --> WSServer
    API --> NotifService
    WSServer --> NotifService
    NotifService --> DB
    NotifService --> Cache
```

### 7. State Diagrams

**Used By**: AI Design Orchestrator, AI Solutions Architect  
**Purpose**: State machines, workflow states

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> InReview : Submit
    InReview --> Approved : Approve
    InReview --> Rejected : Reject
    Rejected --> Draft : Revise
    Approved --> Published : Publish
    Published --> Archived : Archive
    Archived --> [*]
```

### 8. Pie & Bar Charts (Metrics & Statistics)

**Used By**: AI Quality Orchestrator, AI Delivery Manager  
**Purpose**: Test coverage, quality metrics, progress tracking

```mermaid
pie title Test Coverage by Type
    "Unit Tests" : 45
    "Integration Tests" : 30
    "E2E Tests" : 15
    "Not Covered" : 10
```

### 9. User Journey Maps

**Used By**: AI Design Orchestrator  
**Purpose**: User experience flows, customer journeys

```mermaid
journey
    title User Notification Experience
    section Login
      Navigate to app: 5: User
      Enter credentials: 3: User
      Authenticate: 5: System
    section Notifications
      Receive notification: 5: System
      View in UI: 4: User
      Mark as read: 5: User
      Archive notification: 4: User
```

### 10. Git Graph (Version Control)

**Used By**: AI Orchestration Engineer  
**Purpose**: Branch strategies, release flows

```mermaid
gitgraph
    commit id: "Initial commit"
    branch develop
    checkout develop
    commit id: "Add foundation"
    branch feature/notifications
    checkout feature/notifications
    commit id: "Add domain model"
    commit id: "Add API"
    checkout develop
    merge feature/notifications
    checkout main
    merge develop tag: "v1.0.0"
```

## Diagram Templates by Use Case

### Template 1: Product Roadmap

```mermaid
gantt
    title {Project Name} Roadmap
    dateFormat YYYY-MM-DD

    section Phase 0: Foundation
    {Task 1}    :done, {id}, {start-date}, {duration}
    {Task 2}    :active, {id}, after {prev-id}, {duration}

    section Phase 1: Inception
    {Task 3}    :{status}, {id}, after {prev-id}, {duration}

    section Phase 2: Construction
    Bolt 1      :{status}, {id}, after {prev-id}, {duration}
    Bolt 2      :{status}, {id}, after {prev-id}, {duration}
```

### Template 2: API Sequence

```mermaid
sequenceDiagram
    participant {Client}
    participant {Service1}
    participant {Service2}
    participant {Database}

    {Client}->>{Service1}: {Request}
    {Service1}->>{Service2}: {Operation}
    {Service2}->>{Database}: {Query}
    {Database}-->>{Service2}: {Result}
    {Service2}-->>{Service1}: {Response}
    {Service1}-->>{Client}: {Final Response}
```

### Template 3: Domain Model

```mermaid
classDiagram
    class {AggregateRoot} {
        <<AggregateRoot>>
        +{Id} id
        +{Properties}
        +{Methods}()
    }

    class {Entity} {
        <<Entity>>
        +{Properties}
        +{Methods}()
    }

    class {ValueObject} {
        <<ValueObject>>
        +{Properties}
    }

    class {Repository} {
        <<Repository>>
        +find()
        +save()
    }

    {AggregateRoot} *-- {Entity}
    {AggregateRoot} *-- {ValueObject}
    {Repository} --> {AggregateRoot}
```

### Template 4: User Flow

```mermaid
flowchart TD
    Start([{Entry Point}]) --> Step1[{Action}]
    Step1 --> Decision1{Decision?}
    Decision1 -->|Yes| Step2[{Action}]
    Decision1 -->|No| Step3[{Alternative}]
    Step2 --> End([{Exit Point}])
    Step3 --> End
```

### Template 5: Database Schema

```mermaid
erDiagram
    {ENTITY1} ||--o{ {ENTITY2} : {relationship}
    {ENTITY1} {
        {type} {field1} PK
        {type} {field2}
        {type} {field3}
    }

    {ENTITY2} {
        {type} {field1} PK
        {type} {field2} FK
        {type} {field3}
    }
```

### Template 6: System Architecture

```mermaid
graph TB
    subgraph "{Tier1 Name}"
        {Component1}[{Name}]
        {Component2}[{Name}]
    end

    subgraph "{Tier2 Name}"
        {Component3}[{Name}]
        {Component4}[{Name}]
    end

    subgraph "{Tier3 Name}"
        {Component5}[({Name})]
    end

    {Component1} --> {Component3}
    {Component2} --> {Component4}
    {Component3} --> {Component5}
    {Component4} --> {Component5}
```

## Best Practices

### Diagram Clarity

1. **Keep It Simple**: One diagram, one concept
2. **Use Consistent Naming**: Match code/documentation
3. **Add Context**: Include title and labels
4. **Limit Complexity**: Max 10-15 nodes per diagram
5. **Use Subgraphs**: Group related components

### Styling Guidelines

**Colors**:

- Use sparingly for emphasis
- Maintain accessibility (contrast)
- Be consistent across diagrams

**Labels**:

- Clear and concise
- Use domain language
- Avoid abbreviations unless well-known

**Arrows**:

- Solid for strong relationships
- Dashed for weak/optional
- Different arrow types for different meanings

### Integration in Documentation

**Placement**:

````markdown
## Architecture Overview

[Explanatory text about the architecture]

```mermaid
[diagram code]
```
````

**Key Components**:

- Component A: [description]
- Component B: [description]

```

**Accessibility**:
- Add alt text descriptions
- Provide text alternative
- Explain diagram purpose

## Common Patterns by Agent

### AI Delivery Manager
- Gantt charts for roadmaps
- Pie charts for progress tracking
- Flowcharts for process workflows

### AI Solutions Architect
- Class diagrams for domain models
- Sequence diagrams for API flows
- ER diagrams for database schema
- Component diagrams for architecture

### AI Design Orchestrator
- Flowcharts for user flows
- User journey maps
- State diagrams for UI states

### AI Orchestration Engineer
- Sequence diagrams for implementation
- ER diagrams for database
- Git graphs for branching strategy

### AI Quality Orchestrator
- Flowcharts for test flows
- Pie charts for coverage
- State diagrams for test states

### AI Assistant Product Owner
- Flowcharts for feature flows
- User journey maps
- Simple dependency graphs

## Success Criteria

- [ ] Diagram accurately represents concept
- [ ] Clear and easy to understand
- [ ] Consistent with other diagrams
- [ ] Properly labeled
- [ ] Renders correctly in markdown
- [ ] Accessible (alt text provided)
- [ ] Maintained and updated

## References

- Mermaid documentation: https://mermaid.js.org/
- Diagram templates by type
- Agent-specific diagram examples
- Best practices guide

---

*Mermaid Diagramming Skill v1.0.0*
```
