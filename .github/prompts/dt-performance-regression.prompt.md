---
agent: agent
description: Analyze whether a recent deployment caused a performance regression and recommend rollback or hotfix.
---
# Performance Regression Analysis

## Rules
- **ALWAYS confirm the service name with the user before querying.**
- **NEVER query without a scoped timeframe and entity.**
- **STOP at Step 2 if no regression threshold is exceeded.**

## Step 1 — Establish the investigation window
Ask the user: "When did the suspected regression start?"
Default to the **last 24 hours** if no specific time.

Find the latest deployment event for the service. Use deployment timestamp as regression boundary:
- **Before:** `[deploymentTime - 35min, deploymentTime - 5min]`
- **After:** `[deploymentTime + 5min, deploymentTime + 35min]`

If no deployment found, use midpoint of investigation window.

## Step 2 — Compare metrics before and after
Query P95 response time, error rate, and throughput for each window.

**Regression thresholds:**
| Signal | Threshold |
|--------|-----------|
| P95 response time | >20% increase or absolute >2s |
| Error rate | >1 percentage point increase |
| Throughput | >20% drop (without corresponding traffic drop) |

If NO threshold exceeded → report "No Regression Detected" and stop.

## Step 3 — Identify regressed endpoints
Query span P95 durations by endpoint for the after window. Flag top 5 worst.

## Step 4 — Fetch distributed traces
For top 1-3 regressed endpoints, fetch slow spans. Build timeline, identify bottleneck span.

## Step 5 — Connect to workspace code changes
Search workspace for the bottleneck span's operation name in routes/controllers/handlers.

## Step 6 — Check for active Davis Problem
Check for any active/recently closed Davis Problem affecting this service.

## Step 7 — Recommend: rollback or hotfix
**Rollback** when: multiple endpoints regressed, error rate spiked >5pp, no specific code change found.
**Hotfix** when: isolated to 1-2 endpoints, specific code change correlates, fix is low-risk.
