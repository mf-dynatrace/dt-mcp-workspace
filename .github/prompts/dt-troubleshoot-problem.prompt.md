---
agent: agent
description: Troubleshoot an existing Dynatrace problem. Starts with the Root Cause Agent to list problems, scopes log queries to the problem timeframe, classifies actionable errors, and hands off to trace investigation.
---
# Troubleshoot a Dynatrace Problem

## Rules
- **ALWAYS start with problems.** Never do broad log searches. Use root_cause_agent first, then scope all queries to problem context.
- **NEVER query logs without a problem context.** Broad log searches hit scan limits and return 0 results.
- **NEVER suggest checking other environments.** Only mention dev/staging if the user explicitly asks.

## Steps

### 1. List active problems
Use the Root Cause Agent to retrieve all currently active problems. Present as table:
| # | Problem ID | Title | Severity | Status | Start Time | Affected Entities |

If no active problems, check recently closed (last 7 days). If none at all, stop — do NOT run broad log queries.

### 2. Select a problem
Ask: "Which problem would you like to investigate? Please enter the number or Problem ID."

### 3. Scope the investigation
From the selected problem, extract: problemId, startTime, endTime, affected entities.
```
queryFrom = startTime - 5 min
queryTo = endTime + 5 min (or now + 5 min if still active)
```

### 4. Query logs for the problem
Run a **problem-scoped** log query for the affected entities and computed timeframe. If too broad, narrow scope before retrying.

### 5. Classify errors
For each distinct error message:
| Error Message | Count | Actionable? | Reason |
- Actionable: app logic bugs, infra/platform failures, misconfigured auth
- Non-actionable: expected behavior, third-party conditions

### 6. Investigate trace (if trace ID found)
Search log entries for `trace_id` or `dt.trace_id`. Build timeline from spans:
| Span | Service | Operation | Duration | Status | Parent Span |
Identify the **first span where an error occurred** — that is the error origin.

### 7. Summarize findings
- **Root cause hypothesis**
- **Affected services** with entity IDs
- **Top actionable errors** (up to 5) with counts
- **Trace findings**: error location, message, likely cause
- **Recommended next steps**
