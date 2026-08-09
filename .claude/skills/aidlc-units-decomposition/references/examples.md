# Unit Decomposition Examples

## Example 1 — Greenfield: Employee Engagement Platform (4 devs)

**Input**: 12 user stories across authentication, profiles, recognition, notifications

**Output**:
- Unit 1: User Authentication (no deps, foundation, 3 stories)
  - Value: "As an employee, I can securely log in so that my data is protected"
- Unit 2: Employee Profile (deps: Unit 1, 4 stories)
  - Value: "As an employee, I can manage my profile so that colleagues can find and recognize me"
- Unit 3: Recognition & Badges (deps: Unit 1 + 2, 3 stories)
  - Value: "As a manager, I can recognize team members with badges so that achievements are visible"
- Unit 4: Notifications (deps: Unit 1, 2 stories — can run in parallel with Unit 3)
  - Value: "As an employee, I can receive recognition alerts so that I know when I've been acknowledged"

**Why Good**: Each unit is 2-4 stories, has clear user value, independently deployable. Units 3 and 4 can be built in parallel.

---

## Example 2 — Greenfield: SaaS Onboarding Flow (2 devs)

**Input**: 10 user stories across sign-up, workspace setup, team invites, billing, and tutorials

**Output** (2 devs → fewer units, sequential focus):
- Unit 1: Account Creation & Sign-up (no deps, 3 stories)
  - Value: "As a new user, I can register and verify my email so that I can access the platform"
- Unit 2: Workspace Setup & Onboarding (deps: Unit 1, 4 stories)
  - Value: "As a new admin, I can configure my workspace and invite my team so that we can start collaborating"
- Unit 3: Billing & Subscription (deps: Unit 1, 3 stories)
  - Value: "As an admin, I can choose and activate a plan so that my team has uninterrupted access"

**Why Good**: With only 2 devs, 3 focused units prevent overwhelm. Workspace and Billing can start in parallel after Unit 1 ships. No notification or analytics scope included — those are future units.

---

## Example 3 — Brownfield: Add Export Feature (single story exception)

**Input**: 1 user story — "As a user, I can export my report to PDF so that I can share it offline"

**Output**:
- Unit 1: PDF Export (no deps, 1 story — brownfield exception applies)
  - Value: "As a user, I can export my report to PDF so that I can share it offline"

**Why Valid**: Brownfield exception — this is a clearly scoped enhancement to existing functionality. The core report feature already exists. One story is sufficient because the unit delivers complete, standalone value.

---

## Example 4 — Cross-cutting Concern (a common trap)

**Input**: Stories include: user login, log all user actions, analytics dashboard, export audit log

**Wrong decomposition**:
- Unit 1: User Authentication (login)
- Unit 2: Audit Logging (log actions + export) ← infrastructure-only trap

**Problem**: "Audit Logging" unit fails the Independent Value Test — if you shipped only logs with no UI, users get nothing.

**Correct decomposition**:
- Unit 1: User Authentication & Activity Logging (login + log actions — merged because logging only has value alongside auth)
- Unit 2: Compliance & Audit Dashboard (analytics dashboard + export audit log — delivers visible value to compliance officers)

---

## Anti-Patterns to Avoid

❌ **Too Small**: "Badge Icon Storage" (1 story, infrastructure-only, no user value)
→ Fix: Merge into "Recognition & Badges" unit

❌ **Too Large**: "Complete Social Platform" (15 stories, multiple capabilities)
→ Fix: Split into Authentication, Profile, Recognition, and Feed units

❌ **No User Value**: "API Gateway Setup" (infrastructure with no feature)
→ Fix: Merge into first feature unit that uses it

❌ **Circular Dependency**: Unit A requires Unit B's auth service, Unit B requires Unit A's user data
→ Fix: Extract shared dependency into a foundation Unit 0, both depend on it

❌ **Scrum Leak**: Calling a unit a "sprint" or sizing by story points
→ Fix: Units are independent deployable slices, not time-boxes. Size by team capacity and cohesion, not velocity.
