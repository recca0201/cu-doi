---
project: ""
date_created:
last_updated:
version: "1.0"
status: "active"
responsible_team: ""
---

# Risk Security Assessment

## Info

| Field | Value |
|---|---|
| Date | |
| Component count | |

### Likelihood
| Likelihood | Count |
|---|---|
| Almost certain | 0 |
| Likely | 0 |
| Possible | 0 |
| Unlikely | 0 |
| Rare | 0 |

### Impact
| Impact | Count |
|---|---|
| Extreme | 0 |
| Very High | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |


---
# Risk Assessment

| ASSET/COMPONENT/FUNCTION | RISK TYPE | RISK DESCRIPTION | RISK SEVERITY | RISK LIKELIHOOD | IMPACT | ACTION PLAN | PIC | DUE DATE | STATUS | NOTE |
|---|---|---|---|---|---|---|---|---|---|---|
| Input text | SQL Injection | There is a vulnerability of concatenating the string instead of using SQL parameters | Negligible | Rare | Low |  |  |  |  |  |
| API | XSS | The keyword parameter in query string is not neutralized before displaying in No result page | Negligible | Rare | Low |  |  |  |  |  |
| User information update form | CSRF | There is no anti-forgery token on the update form | Negligible | Rare | Low |  |  |  |  |  |
| Error page show sensitive information | Sensitive Information Exposure Error | There is no logic to hide sensitive information on error page | Negligible | Rare | Low |  |  |  |  |  |
| Permission | Incorrect Permission Assignment | Incorrect permission granted to the user | Negligible | Rare | Low |  |  |  |  |  |
| Outdated library | Vulnerable and outdated components | If the program is insecure, unsupported, or outdated, there may be vulnerability-related hazards. This includes application/web server, OS, applications, DBMS, APIs, libraries, and runtimes. | Negligible | Rare | Low |  |  |  |  |  |
| Update file function | Unrestricted File Upload | File extensions are not validated before saving | Negligible | Rare | Low |  |  |  |  |  |
| User Password | Identification and Authentication Failures | There is no logic to enforce strong passwords | Negligible | Rare | Low |  |  |  |  |  |
| Web server | DDoS | There is no throttling mechanism to prevent DDoS | Negligible | Rare | Low |  |  |  |  |  |

# Definition


### SEVERITY × LIKELIHOOD (Risk Score)

| SEVERITY \ LIKELIHOOD | 1 | 2 | 3 | 4 | 5 |
|---|---:|---:|---:|---:|---:|
| 1 | 1 | 2 | 3 | 4 | 5 |
| 2 | 2 | 4 | 6 | 8 | 10 |
| 3 | 3 | 6 | 9 | 12 | 15 |
| 4 | 4 | 8 | 12 | 16 | 20 |
| 5 | 5 | 10 | 15 | 20 | 25 |

### Severity levels

| Severity | Value |
|---|---:|
| Negligible | 1 |
| Minor | 2 |
| Moderate | 3 |
| Significant | 4 |
| Severe | 5 |

### Likelihood levels

| Likelihood | Value |
|---|---:|
| Rare | 1 |
| Unlikely | 2 |
| Possible | 3 |
| Likely | 4 |
| Almost certain | 5 |

### Impact score → Descriptor

| Impact Score | Descriptor |
|---:|---|
| 1 | Low |
| 2 | Low |
| 3 | Low |
| 4 | Medium |
| 5 | Medium |
| 6 | Medium |
| 8 | High |
| 9 | High |
| 10 | High |
| 12 | Very High |
| 15 | Very High |
| 16 | Very High |
| 20 | Extreme |
| 25 | Extreme |

### Status mapping

| Status ||
|---|---|
| TODO |
| DOING |
| DONE |
| BLOCKED |
