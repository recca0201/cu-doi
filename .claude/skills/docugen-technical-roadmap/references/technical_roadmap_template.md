---
project: [Project Name]
created_date: [YYYY-MM-DD]
updated_date: [YYYY-MM-DD]
year: [YYYY]
responsible_team: [Team Name]
status: Draft
---

# Technical Roadmap - [Project Name]

**Project**: [Project Name]
**Period**: [Date Range]
**Owner**: [Team/Person]
**Last Updated**: [Date]
**Version**: 1.0

---

## Executive Summary

[1-2 paragraph summary of project scope, timeline, and key deliverables]

---

## Quarterly Summary

| Quarter | Focus | Key Deliverables |
|---------|-------|------------------|
| Q1 (JAN-MAR) | [Theme] | [2-3 key items] |
| Q2 (APR-JUN) | [Theme] | [2-3 key items] |
| Q3 (JUL-SEP) | [Theme] | [2-3 key items] |
| Q4 (OCT-DEC) | [Theme] | [2-3 key items] |

---

## 1. Environments

### Development Environments Setup

| Environment | Purpose | Timeline | Status | Notes |
|-------------|---------|----------|--------|-------|
| **Dev** | Development and feature testing | [Month/Quarter] | [TODO/DOING/DONE/BLOCKED] | [Configuration, access, dependencies] |
| **Test** | QA and integration testing | [Month/Quarter] | [TODO/DOING/DONE/BLOCKED] | [Testing strategy, data requirements] |
| **Stg** | Staging and pre-production validation | [Month/Quarter] | [TODO/DOING/DONE/BLOCKED] | [Production-like setup, validation criteria] |
| **Prd** | Production environment | [Month/Quarter] | [TODO/DOING/DONE/BLOCKED] | [Release criteria, monitoring, rollback plan] |

---

## 2. Proof of Concepts (PoCs)

| # | PoC Name | Objective | Timeline | Success Criteria | Owner | Status |
|---|----------|-----------|----------|------------------|-------|--------|
| 1 | [Name] | [1 sentence objective] | [Month] | [Brief criteria] | [TA/Dev] | [Planned] |
| 2 | [Name] | [1 sentence objective] | [Month] | [Brief criteria] | [TA/Dev] | [Planned] |

---

## 3. Non-Functional Requirements (NFRs)

| Category | Activity | Frequency | Timeline | Owner | Notes |
|----------|----------|-----------|----------|-------|-------|
| **Security** | Security scans (SAST/DAST) | [Monthly/Before release] | [Months] | [TA/QA] | [Tool: e.g., Gitleaks] |
| **Security** | Vulnerability assessment | [Quarterly] | [Months] | [TA/QA] | [Scope] |
| **Security** | Security review | [Before release] | [Months] | [TA] | [Prompt injection, data leakage] |
| **Performance** | Load testing | [Before release] | [Months] | [QA] | [If needed] |
| **Performance** | Performance profiling | [As needed] | [Months] | [Dev] | [Bottlenecks] |
| **Tech Debt** | Code refactoring | [Ongoing] | [Quarter] | [Dev] | [Brief description] |
| **Tech Debt** | Dependency upgrades | [Quarterly] | [Months] | [Dev] | [Critical only] |
| **Architecture** | Architecture review | [Start + milestones] | [Months] | [TA] | [Design docs] |
| **Architecture** | Design documentation | [Ongoing] | [Quarter] | [TA/Dev] | [Deliverables] |

---

## 4. Integrations

| # | Integration Name | Purpose | Timeline | Owner | Status | Notes |
|---|------------------|---------|----------|-------|--------|-------|
| 1 | [System/Service] | [Brief purpose] | [Month] | [Dev/TA] | [Planned] | [API/auth notes] |
| 2 | [System/Service] | [Brief purpose] | [Month] | [Dev/TA] | [Planned] | [API/auth notes] |

---

## 5. Releases

| Release | Target Date | Key Features | Status |
|---------|-------------|--------------|--------|
| **MVP v1.0** | [Month Year] | [2-3 core features] | [Planned] |
| **v1.1** | [Month Year] | [1-2 enhancements] | [Planned] |

**MVP Release Criteria:**
- [ ] All critical features complete
- [ ] Security scan passed
- [ ] Performance validated (if applicable)
- [ ] Documentation complete
- [ ] Production environment ready
- [ ] Stakeholder approval

---

## 6. Gantt Chart

```mermaid
gantt
    title [Project Name] - Timeline
    dateFormat YYYY-MM-DD

    section Environments
    Dev Environment             :[env-status], env1, [start-date], [duration]
    Test Environment            :[env-status], env2, [start-date], [duration]
    Staging Environment         :env3, [start-date], [duration]
    Production Environment      :env4, [start-date], [duration]

    section PoCs
    PoC 1: [Name]              :poc1, [start-date], [duration]
    PoC 2: [Name]              :poc2, [start-date], [duration]

    section Development
    [Phase 1]                   :dev1, [start-date], [duration]
    [Phase 2]                   :dev2, [start-date], [duration]

    section Security
    Security Setup              :sec1, [start-date], [duration]
    Security Testing            :sec2, [start-date], [duration]
    Pre-Release Security Review :sec3, [start-date], [duration]

    section Testing
    QA Testing                  :test1, [start-date], [duration]
    UAT                         :crit, test2, [start-date], [duration]

    section Milestones
    [Milestone 1]               :milestone, m1, [date], 0d
    [Milestone 2]               :milestone, m2, [date], 0d
    MVP Release                 :crit, milestone, m3, [date], 0d
```

---

## 7. Timeline View by Quarter

### Q1 ([Months])
- [Owner] Activity 1
- [Owner] Activity 2
- [Owner] Activity 3

### Q2 ([Months])
- [Owner] Activity 1
- [Owner] Activity 2
- [Owner] Activity 3

### Q3 ([Months])
- [Owner] Activity 1
- [Owner] Activity 2

### Q4 ([Months])
- [Owner] Activity 1
- [Owner] Activity 2

---

## 8. Risks & Dependencies

### Critical Risks (Top 3-5)

| Risk | Impact | Mitigation | Owner |
|------|--------|------------|-------|
| [Brief risk description] | [H/M/L] | [Brief mitigation] | [TA/Dev] |
| [Brief risk description] | [H/M/L] | [Brief mitigation] | [TA/Dev] |

### External Dependencies

| Dependency | Provider | Timeline | Status |
|------------|----------|----------|--------|
| [System/service] | [Provider] | [Expected date] | [Status] |

---

## 9. Key Decisions

| Date | Decision | Rationale | Owner |
|------|----------|-----------|-------|
| [Date] | [Brief decision] | [Brief rationale] | [TA/PPO] |
| [Date] | [Brief decision] | [Brief rationale] | [TA/PPO] |

---

## 10. Follow-Up Actions

### Immediate (Current Quarter)
- [ ] [Action] - [Owner] - [Due date]

### Next Quarter
- [ ] [Action] - [Owner] - [Due date]

---

## 11. Open Questions

- [ ] [Question requiring stakeholder input]
- [ ] [Question requiring stakeholder input]

---

**Abbreviations**: TA (Technical Architect), Dev (Developer), QA (Quality Assurance), PPO (Product Owner)
