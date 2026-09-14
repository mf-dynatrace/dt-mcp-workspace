---
name: dtws-finops-k8
description: >-
  Kubernetes FinOps analysis using Dynatrace telemetry and the FinOps Foundation framework.
  Produces cost optimization reports covering namespace/workload utilisation, rightsizing,
  idle resource detection, cost attribution gaps, unit economics, and chargeback/showback.
  Supports multi-cluster environments (Azure AKS, AWS EKS, GCP GKE, on-prem OpenShift).
  Output: markdown report saved to report/ directory, structured by the 4 FinOps Domains
  and Inform/Optimize/Operate phases sequenced by Crawl/Walk/Run maturity.
  Trigger: "FinOps report", "K8s cost analysis", "Kubernetes cost optimization",
  "container cost allocation", "K8s rightsizing", "cloud spend on Kubernetes",
  "K8s waste", "cluster utilisation", "namespace cost", "chargeback showback".
  Requires: dt-dql-essentials loaded before any DQL. MCP or dtctl access to the tenant.
  Does NOT replace a dedicated FinOps platform or cloud billing tool. Surfaces signals
  from Dynatrace telemetry; the FinOps practitioner validates and acts.
license: Apache-2.0
---

# Kubernetes FinOps Analysis

Generate FinOps reports for Kubernetes infrastructure using Dynatrace telemetry, anchored to
the **FinOps Foundation framework** and CNCF industry benchmarks.

**Always load `dt-dql-essentials` before writing any DQL from this skill.**

---

## Reference Files

Load on demand as indicated:

| Reference | When to Load |
|---|---|
| `references/framework.md` | Before structuring a report — FinOps principles, domains, phases, cost model |
| `references/dql-queries.md` | Before writing any K8s FinOps DQL — all verified queries with unit notes |
| `references/metric-pitfalls.md` | Before building a cost model — critical unit/reconciliation gotchas |
| `references/report-template.md` | When generating the final report — section structure and benchmarks |
| `references/pricing.md` | When user asks for cost estimates or node pricing — cloud pricing refs + formula |

---

## Workflow

### Step 1 — Gather Context (always do this first)

Prompt the user for the following before running any queries:

1. **Node pricing:** Do you have node pricing data, or should I find indicative pricing online?
   - If online: Where is the K8s cluster deployed? (AWS/Azure/GCP region, or on-prem)
2. **Cluster scope:** Which cluster(s) should be analysed? (or analyse all if not specified)
3. **Time range:** Default last 7 days — confirm or adjust.
4. **Focus areas:** Specific namespaces or workloads? (optional)
5. **Cost allocation tags:** Are tags like `cost-center`, `team`, `environment` already in use?

Load `references/framework.md` while waiting for the user's response.

### Step 2 — Load Required References

Before writing any DQL:
- Load `references/metric-pitfalls.md` — read all pitfalls before touching the cost model.
- Load `references/dql-queries.md` — use only the verified queries here.

### Step 3 — Execute Queries (in order)

1. **Node count + capacity** — use Smartscape or ≤2h window (never a 24h `by:{node}` window).
   See `references/metric-pitfalls.md` §1 for why this matters.
2. **Namespace utilisation** — CPU and memory used ÷ requested ratios (not absolutes).
3. **Cost attribution** — tag coverage per namespace/workload.
4. **Idle workloads** — verify CPU metric units before applying thresholds (pitfalls §3, §4).
5. **OOM kills + CPU throttling** — always run alongside utilisation ("fix before you cut" — pitfalls §7).
6. **Unit economics** — pair allocated cost with BizEvents or service request counts (optional).

After each query: send the tracking event and update the relevant workspace reference file.

### Step 4 — Build the Cost Model

Load `references/pricing.md` and `references/framework.md` (Cost Model section).

- Derive node SKU from allocatable telemetry (pitfalls §4) — do NOT assume a flat node type.
- Identify cloud vs on-prem clusters and price separately (pitfalls §5).
- Allocate: pod compute + proportional satellite/shared costs + idle/unallocated headroom.

### Step 5 — Generate Report

Load `references/report-template.md`. Save to `report/FinOps_K8s_Report_YYYY-MM-DD.md`
(or `report/FinOps_K8s_Report_[ClusterName]_YYYY-MM-DD.md` for single-cluster focus).

Structure by the 4 FinOps Domains. Bucket recommendations under Inform/Optimize/Operate,
sequenced Crawl → Walk → Run.

---

## Skill Dependencies

- `dt-dql-essentials` — DQL syntax and best practices (required)
- `dt-obs-kubernetes` — K8s entity types and metrics (load for entity model details)
- `dt-obs-hosts` — Host-level metrics if node-level detail is needed
