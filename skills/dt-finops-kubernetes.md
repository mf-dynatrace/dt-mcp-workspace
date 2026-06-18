# Kubernetes FinOps Analysis Skill
> Generate FinOps reports for Kubernetes infrastructure using Dynatrace telemetry and industry-standard frameworks

Analyze K8s cost optimization opportunities using the **FinOps Foundation framework** and industry benchmarks.

---

## When to Use This Skill

Use this skill when the user asks for:
- FinOps report for Kubernetes infrastructure
- Cost optimization analysis for K8s clusters
- Kubernetes resource utilization and waste analysis
- Container cost allocation and chargeback/showback
- Infrastructure rightsizing recommendations
- Cloud cost analysis for K8s workloads

**Triggers:**
- "FinOps report"
- "K8s cost analysis"
- "Kubernetes cost optimization"
- "container cost allocation"
- "K8s rightsizing"
- "cloud spend on Kubernetes"

---

## Output Directory

**IMPORTANT:** All generated FinOps reports MUST be saved to the `/report` directory in the workspace.

Filename format: `FinOps_K8s_Report_YYYY-MM-DD.md` or `FinOps_K8s_Report_[ClusterName]_YYYY-MM-DD.md`

---

## FinOps Framework Alignment

> Anchor every report to the **current FinOps Foundation framework structure** (not just the legacy 3-phase model). Use the **Principles** to justify *why*, the **Domains/Capabilities** to organize the *analysis*, and the **Phases** (Inform/Optimize/Operate) plus **Crawl/Walk/Run** maturity to sequence the *recommendations*.

### The 6 FinOps Principles (the "why")
1. **Teams need to collaborate** — FinOps, Engineering, Finance, and Product align on K8s spend.
2. **Business value drives technology decisions** — optimize for value, not just lowest cost.
3. **Everyone takes ownership for their technology usage** — namespace/workload owners are accountable.
4. **FinOps data should be accessible, timely, and accurate** — near-real-time visibility (this is where Dynatrace telemetry shines).
5. **A centralized team drives FinOps** — consistent allocation/tagging standards enforced centrally.
6. **Take advantage of the variable cost model of the cloud** — rightsizing, autoscaling, spot/preemptible.

### The 4 FinOps Domains (the "what" — organize the analysis here)

| Domain | Relevant Capabilities | Maps to K8s report section |
|--------|----------------------|----------------------------|
| **Understand Usage & Cost** | Data Ingestion, Allocation, Reporting & Analytics, Anomaly Management | Visibility Gap, Cost Owner Attribution |
| **Quantify Business Value** | Forecasting, Budgeting, KPIs & Benchmarking, **Unit Economics** | Unit Economics, benchmark comparisons |
| **Optimize Usage & Cost** | Architecting & Workload Placement, Usage Optimization, Rate Optimization, **Sustainability** | Rightsizing, Idle Workloads, Spot/HPA |
| **Manage the FinOps Practice** | Governance/Policy/Risk, Education & Enablement, Invoicing & Chargeback, Automation | Ownership gaps, Operate recommendations |

### Phases & Maturity (the "how" — sequence recommendations here)
- **Phases:** Inform → Optimize → Operate (used for the recommendations buckets).
- **Maturity:** **Crawl → Walk → Run** — never recommend all allocation dimensions at once; establish reporting + tagging discipline (Crawl) before advanced split-cost allocation (Run).

---

## Framework Anchors

### 1. FinOps Foundation (finops.org)

**The authoritative framework for cloud financial management.**

**Key Resources:**

| Resource | URL | What It Provides |
|----------|-----|------------------|
| **Calculating Container Costs** | `finops.org/wg/calculating-container-costs/` | Why traditional cost allocation breaks down with K8s (shared resources, node-level billing); proportional allocation; **satellite/shared costs**; **static vs. runtime costs**; requests-vs-usage trade-offs |
| **FinOps Framework (Principles/Domains/Phases)** | `finops.org/framework/` | Full structure: 6 Principles, 4 Domains, Capabilities, Inform/Optimize/Operate phases, Crawl/Walk/Run maturity, Scopes |
| **Cost Allocation Capability** | `finops.org/wg/cloud-cost-allocation/` | Metadata strategy (required tags like Cost Center, Environment); KPIs for measuring allocation maturity; percentage of tag-compliant costs |
| **Workload Optimization Capability** | `finops.org/framework/capabilities/workload-optimization/` | Rationale and KPIs for rightsizing, autoscaling, and idle-resource elimination |
| **Unit Economics Capability** | `finops.org/framework/capabilities/unit-economics/` | Cost-per-business-metric (per transaction/customer/namespace) — pairs with BizEvents data |
| **Sustainability Capability** | `finops.org/framework/capabilities/sustainability/` | GreenOps tie-in: idle/overprovisioned workloads carry a carbon cost, not just a dollar cost |

### 2. CNCF (Cloud Native Computing Foundation)

**Industry benchmarks and best practices.**

| Resource | URL | What It Provides |
|----------|-----|------------------|
| **FinOps Microsurvey** | `cncf.io` (surveys) | **70%** of orgs cite overprovisioning as top cost driver; **45%** lack ownership; **43%** have unused resources |
| **Resource Requests/Limits Best Practices** | `cncf.io/blog/2022/10/20/kubernetes-best-practice-how-to-correctly-set-resource-requests-and-limits/` | Technical grounding for rightsizing recommendations; covers HPA, cluster autoscaler, why incorrect limits cause waste and instability |

### 3. FinOps FOCUS Spec (v1.3+)

**The standard for split cost allocation.**

- **FOCUS 1.3** added split cost allocation columns specifically for shared K8s resources
- Enables practitioners to see the methodology behind cost splits, not just the output
- Critical for chargeback/showback at team level

**Reference:** `focus.finops.org`

### 4. OpenCost (CNCF)

**The vendor-neutral, open-source standard for Kubernetes cost monitoring.**

| Resource | URL | What It Provides |
|----------|-----|------------------|
| **OpenCost** | `opencost.io` | CNCF spec/model for allocating K8s costs (compute, storage, network, shared) down to namespace/pod/label; FOCUS-aligned. Use as the conceptual model behind the Dynatrace DQL allocation queries below. |

### 5. Kubernetes Technical Backing (rightsizing actions)

| Resource | URL | What It Provides |
|----------|-----|------------------|
| **VPA (Vertical Pod Autoscaler)** | `kubernetes.io/docs/concepts/workloads/autoscaling/` | Technical basis for request/limit rightsizing recommendations |
| **HPA (Horizontal Pod Autoscaler)** | `kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/` | Technical basis for scaling/burst recommendations |
| **Managing Resources for Containers** | `kubernetes.io/docs/concepts/configuration/manage-resources-containers/` | Requests vs. limits semantics; **cores vs. millicores** units |

---

## Cost Model: What to Allocate (per FinOps Container WG)

Pod compute alone is **not** the full picture. A credible K8s FinOps report accounts for:

- **Pod compute costs** — CPU + memory by requests *and* actual usage (report both; they have different trade-offs).
- **Satellite / shared costs** — control-plane/management nodes, persistent storage (PVs), network egress, plus observability, security, and licensing tooling running in-cluster. Allocate these proportionally.
- **Static vs. runtime costs** — reserved/committed node capacity (static) vs. consumption-driven scaling (runtime).
- **Idle / unallocated** — capacity paid for but not requested by any workload (cluster headroom). Surface this explicitly rather than hiding it.

**Default allocation method — proportional resource consumption:**
```
Workload share of shared cost = (workload's requested resources) / (cluster total requested) × shared cost pool
```
Use this for namespace/team chargeback when one-to-one tagging cannot cover shared clusters.

---

## Report Structure

### Industry-Aligned Flow

Organize the **analysis** under the 4 FinOps Domains and map Dynatrace telemetry to industry benchmarks. Organize the **recommendations** under the Inform/Optimize/Operate phases (sequenced by Crawl/Walk/Run maturity).

#### Domain: Understand Usage & Cost

**1. Visibility Gap** *(Capability: Allocation)*
- What % of K8s spend is unattributed?
- **Benchmark:** Most orgs start below 60% allocation accuracy (FinOps Foundation)
- **Dynatrace Data:** Namespace/pod labels vs. missing cost owner tags

**2. Ownership Gaps** *(Capability: Allocation / Governance)*
- Namespaces or workloads with no cost owner
- **Benchmark:** 45% of orgs lack accountability (CNCF)
- **Dynatrace Data:** Missing `tags[cost-center]`, `tags[team]`, `tags[environment]`

#### Domain: Quantify Business Value

**3. Unit Economics** *(Capability: Unit Economics / KPIs & Benchmarking)*
- Cost per business metric — e.g. cost per 1k transactions, per namespace, per customer — not just raw waste %.
- **Dynatrace Data:** Allocated cost (from node pricing) ÷ business volume from **BizEvents** or service request counts.
- Surfaces *value*, not just spend: a "high cost" namespace may be highly efficient per transaction.

#### Domain: Optimize Usage & Cost

**4. Rightsizing Findings** *(Capability: Workload Optimization)*
- CPU/memory requested vs. actual utilization
- **Benchmark:** 70% of orgs have overprovisioning issues (CNCF)
- **Dynatrace Data:** `dt.kubernetes.container.cpu_usage` vs. `requests_cpu`, `limits_cpu`

**5. Unused / Idle Resources** *(Capability: Usage Optimization)*
- Idle workloads, terminated pods still consuming resources, unallocated cluster headroom
- **Benchmark:** 43% of orgs have unused resources (CNCF)
- **Dynatrace Data:** Pods with 0 requests, low CPU/memory utilization over 7d
- **Sustainability angle:** idle/overprovisioned capacity is wasted carbon as well as wasted spend.

#### Domain: Manage the FinOps Practice

**6. Recommendations** *(Capabilities: Governance, Education, Chargeback, Automation)*
Bucket by phase, and sequence by **Crawl → Walk → Run** maturity:
- **Inform (Crawl):** Improve cost visibility — add tags, enable allocation, establish reporting.
- **Optimize (Walk):** Rightsizing, HPA/VPA tuning, spot/preemptible instance usage, proportional shared-cost allocation.
- **Operate (Run):** Policy enforcement, automated governance, budget alerts, ongoing reviews, FOCUS-based split chargeback.

---

## Required User Inputs

**ALWAYS prompt the user for these before generating a report:**

1. **Node Pricing:**
   - Ask: "Do you have node pricing data, or should I find indicative pricing online?"
   - If online: "Where is the K8s cluster deployed? (AWS/Azure/GCP region, or on-prem provider)"

2. **Cluster Context:**
   - Cluster name(s) to analyze
   - Time range (default: last 7 days)
   - Specific namespaces or workloads to focus on (optional)

3. **Cost Attribution:**
   - Are there existing cost allocation tags? (e.g., `cost-center`, `team`, `environment`)
   - What metadata fields should be used for cost attribution?

---

## Dynatrace DQL Queries for FinOps

### 1. Namespace Resource Requests vs. Actuals

```dql
// CPU overprovisioning by namespace
timeseries {
  cpu_requested = avg(dt.kubernetes.container.requests_cpu),
  cpu_used = avg(dt.kubernetes.container.cpu_usage)
}, by:{k8s.namespace.name}, from:now()-7d
| fieldsAdd cpu_waste_percent = (cpu_requested - cpu_used) / cpu_requested * 100
| sort cpu_waste_percent desc
```

```dql
// Memory overprovisioning by namespace
timeseries {
  mem_requested = avg(dt.kubernetes.container.requests_memory),
  mem_used = avg(dt.kubernetes.container.memory_working_set)
}, by:{k8s.namespace.name}, from:now()-7d
| fieldsAdd mem_waste_percent = (mem_requested - mem_used) / mem_requested * 100
| sort mem_waste_percent desc
```

### 2. Cost Owner Attribution

```dql
// Namespaces missing cost allocation tags
fetch dt.entity.cloud_application_namespace
| fields k8s.namespace.name, tags
| filter isNull(tags[cost-center]) or isNull(tags[team])
| summarize untagged_namespaces = count()
```

### 3. Idle Workloads

```dql
// Pods with near-zero CPU usage over 7d
timeseries avg_cpu = avg(dt.kubernetes.container.cpu_usage), 
by:{k8s.namespace.name, k8s.pod.name}, from:now()-7d
| filter avg_cpu < 0.01  // see unit note below
| sort avg_cpu asc
```

> ⚠️ **Threshold units — verify before trusting `avg_cpu < 0.01`.** This filter assumes `dt.kubernetes.container.cpu_usage` is reported in **cores** (so `0.01` = 10 millicores ≈ "1% of a core"). If the metric is in **millicores** or **nanocores** in your tenant, this threshold is wrong by orders of magnitude and will over- or under-report idle pods. Confirm the unit first (run the query without the filter and inspect magnitudes, or compare against `requests_cpu` for the same pod), then express the threshold *relative to requests* rather than as an absolute, e.g. `avg_cpu / requests_cpu < 0.05`.

### 3b. Unit Economics (cost per business metric)

```dql
// Allocated cost per namespace vs. business volume (pair with node pricing + BizEvents/service counts).
// Compute waste% per namespace here; divide allocated $ by transaction volume in the report layer.
timeseries {
  cpu_requested = avg(dt.kubernetes.container.requests_cpu),
  cpu_used = avg(dt.kubernetes.container.cpu_usage),
  mem_requested = avg(dt.kubernetes.container.requests_memory),
  mem_used = avg(dt.kubernetes.container.memory_working_set)
}, by:{k8s.namespace.name}, from:now()-7d
```
> Combine the allocated cost (node price × proportional requests) with a business denominator — BizEvents count or `dt.service.request.count` — to produce **cost per transaction / per customer / per namespace**. This satisfies the *Quantify Business Value → Unit Economics* capability.

### 4. Node Capacity vs. Utilization

```dql
// Cluster-wide capacity analysis
timeseries {
  pods_allocatable = avg(dt.kubernetes.node.pods_allocatable),
  pods_actual = avg(dt.kubernetes.pods),
  cpu_allocatable = avg(dt.kubernetes.node.cpu_allocatable),
  cpu_used = avg(dt.kubernetes.node.cpu_usage),
  memory_allocatable = avg(dt.kubernetes.node.memory_allocatable),
  memory_used = avg(dt.kubernetes.node.memory_working_set)
}, by:{k8s.cluster.name}, from:now()-7d
```

### 5. Workload-Level Cost Attribution

```dql
// Cost attribution by workload type
fetch dt.entity.cloud_application
| fields k8s.workload.name, k8s.workload.kind, k8s.namespace.name, tags
| summarize count(), by:{k8s.workload.kind, tags[cost-center]}
```

---

## ⚠️ Dynatrace Metric & Query Pitfalls (verified 2026-06-15, Boots/iqe85018)

These were learned the hard way — read before building the cost model, or you will publish wrong node counts and costs.

### 1. Node count & capacity — use a SHORT window or Smartscape, never a 24h `by:{node}` window
The cluster autoscaler creates/destroys nodes continuously. A `timeseries ... by:{k8s.node.name}, from:now()-24h` returns every node-name that **ever existed** in the window, so `count()` and `sum(allocatable)` are **inflated** (one tenant showed 187 vs the true 142 — a ~30% over-count that flowed straight into a ~35% cost over-statement).

```dql
// ✅ Authoritative point-in-time node count
smartscapeNodes "K8S_NODE" | summarize nodes = count()

// ✅ Current capacity per cluster — short window (≤2h) avoids churn
timeseries cpu = avg(dt.kubernetes.node.cpu_allocatable),
           mem = avg(dt.kubernetes.node.memory_allocatable),
  by:{k8s.cluster.name, k8s.node.name}, from:now()-2h, interval:2h
| fieldsAdd c = arrayAvg(cpu), m = arrayAvg(mem)
| summarize nodes = count(), cores_milli = sum(c), mem_bytes = sum(m),
            avg_core_per_node = avg(c), by:{k8s.cluster.name}
```

### 2. Units don't reconcile across metric families — report RATIOS, not absolutes
- **Node** metrics: `dt.kubernetes.node.cpu_allocatable` is **millicores**, `memory_allocatable` is **bytes**.
- **Container** `requests_cpu`/`cpu_usage`/`requests_memory`/`memory_working_set` sums **do NOT** reconcile in units with node allocatable (container sums came back ~10–30× node capacity — physically impossible).
- ✅ **Use `used ÷ requested` ratios** for utilisation/waste% (unit-consistent within the container family). ❌ Do **not** compute "requests vs node capacity" commitment % by mixing the two families.

### 3. There is NO node-level usage metric
Node level exposes only `*_allocatable`, `pods_allocatable`, `nodes`, `conditions`. There is **no** `dt.kubernetes.node.cpu_usage` / `memory_working_set`. Derive utilisation from container-level usage (with the ratio caveat above).

### 4. Derive node SKU from telemetry — never assume a flat node type
Compute `avg_core_per_node` and `avg_mem_per_node` from allocatable (query above) and map to the cloud SKU (e.g. ~30 allocatable cores + ~124 GB ⇒ a 32-vCPU/128 GB VM after system reservation). Assuming a small uniform SKU (e.g. 8-vCPU) understated true compute cost by 3–4× in one tenant. Per-node pricing must match the **inferred** size.

### 5. Identify cloud vs on-prem and price separately
Infer platform from cluster naming **and** namespaces: `*-aks-*` ⇒ Azure AKS; `openshift-vsphere-infra` / `openshift-*` ⇒ OpenShift on vSphere (**on-prem**, not metered cloud spend). Apply cloud list pricing only to cloud nodes; report on-prem capacity separately (capex/opex or "equivalent rehost" cost), never blend Azure pricing onto on-prem OpenShift nodes.

### 6. OOM / throttle queries return huge arrays — collapse them
`timeseries oom = sum(...oom_kills), by:{pod}, from:now()-30d` returns long per-bucket arrays that blow the token limit and are easy to misread (a per-6h value of ~50 is **not** the 30d total). Collapse with `arraySum()` / `arrayAvg()`, or set `interval:` to the full window:

```dql
timeseries oom = sum(dt.kubernetes.container.oom_kills),
  by:{k8s.namespace.name, k8s.pod.name}, from:now()-30d, interval:30d
| fieldsAdd total_oom = arraySum(oom) | filter total_oom > 0 | sort total_oom desc
```

### 7. "Fix before you cut" — cross-check OOM kills and CPU throttling before recommending rightsizing-down
Over-provisioning and **under**-provisioning coexist. Always run the OOM and throttle queries alongside utilisation:
- **OOM kills** (e.g. a crash-looping pod at thousands of kills/30d) and **memory used > requested** (e.g. observability namespaces at >100% of request) mean **raise** requests/limits, not cut.
- **High CPU throttling** means limits are too tight — raise limits even though CPU *usage* looks low.
Recommend cuts only where utilisation is low **and** there is no OOM/throttle signal.

### 8. Check for duplicate APM / observability agents (a real rate-optimisation finding)
Namespace `tags` often reveal **multiple** APM stacks co-deployed (e.g. `APPD_INSTRUMENTATION_*` for AppDynamics **and** `dynakube.internal.dynatrace.com/*` for Dynatrace). Redundant agents cost licensing **and** per-pod compute — flag consolidation. Also: namespace `tags` carry only platform/operational labels (openshift/istio/security) — treat absence of `cost-center`/`team`/`owner` as 0% allocation coverage even when `isNotNull(tags)` is true.

---

## Node Pricing Resources

When the user asks for indicative pricing (no custom data provided):

### AWS EKS
- **On-Demand:** `aws.amazon.com/ec2/pricing/on-demand/`
- **Spot Instances:** `aws.amazon.com/ec2/spot/pricing/`
- **Savings Plans:** `aws.amazon.com/savingsplans/pricing/`

### Azure AKS
- **VM Pricing:** `azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/`
- **Spot VMs:** `azure.microsoft.com/en-us/pricing/spot-vms/`

### Google GKE
- **Machine Types:** `cloud.google.com/compute/all-pricing`
- **Preemptible VMs:** `cloud.google.com/compute/docs/instances/preemptible`

### Generic Formula (when exact pricing unavailable)
```
Pod Cost = (Node Hourly Cost × Pod Resource Requests) / Node Total Capacity
```

**Example:**
- Node: 16 vCPU, 64 GB RAM, $0.50/hour
- Pod: 2 vCPU request, 8 GB request
- Pod Cost: ($0.50 × 2/16) + ($0.50 × 8/64) = $0.0625 + $0.0625 = $0.125/hour

---

## Report Best Practices

### Structure (organized by FinOps Domain)
1. **Executive Summary**
   - Total cluster spend (if available)
   - % wasted due to overprovisioning
   - Top 3 recommendations

2. **Understand Usage & Cost**
   - % of resources with cost owner tags; gaps in cost attribution (vs. 60% industry baseline)
   - Cost model breakdown: pod compute + satellite/shared + idle/unallocated headroom

3. **Quantify Business Value**
   - Unit economics: cost per transaction / customer / namespace
   - Highlight efficient-but-expensive namespaces vs. wasteful ones

4. **Optimize Usage & Cost**
   - CPU/memory overprovisioning by namespace (vs. 70% benchmark)
   - Idle workloads (candidates for termination); sustainability/carbon note
   - Rate optimization: spot/preemptible, committed-use opportunities

5. **Manage the FinOps Practice**
   - Namespaces/workloads missing owners (vs. 45% accountability gap)
   - Recommendations bucketed **Inform/Optimize/Operate**, sequenced **Crawl/Walk/Run**:
     - **Inform (Crawl):** Tagging strategy, cost allocation setup, reporting
     - **Optimize (Walk):** Rightsizing actions, HPA/VPA tuning, spot adoption, proportional shared-cost allocation
     - **Operate (Run):** Policy enforcement, automated reviews, budget alerts, FOCUS-based chargeback

### Key Metrics to Include
- **Utilization Rate:** `actual_usage / requested_resources`
- **Waste Percentage:** `(requested - actual) / requested * 100`
- **Allocation Coverage:** `% of pods with cost owner tags`
- **Cost per Namespace/Workload:** Calculated from node pricing (incl. proportional shared costs)
- **Unit Economics:** allocated cost ÷ business volume (cost per transaction/customer)

### Benchmarks to Reference
- **60%** allocation accuracy threshold (FinOps Foundation)
- **70%** overprovisioning rate (CNCF)
- **45%** lack ownership (CNCF)
- **43%** unused resources (CNCF)

---

## Skill Dependencies

This skill builds on:
- `dt-obs-kubernetes.md` — K8s entity types, metrics, and queries
- `dt-dql-essentials.md` — DQL syntax and best practices
- `dt-obs-hosts.md` — Host-level resource metrics (if needed)

---

## Example Usage

**User:** "Create a FinOps report for our Kubernetes cluster"

**Agent Actions:**
1. Read this skill file
2. Read `dt-obs-kubernetes.md` for K8s data model
3. Prompt user:
   - "Do you have node pricing data?"
   - "Where is the cluster deployed?"
   - "What is the cluster name?"
4. Get the **point-in-time** node count/capacity (Smartscape or ≤2h window — NOT a 24h `by:{node}` window; see Pitfalls §1), and identify cloud vs on-prem per cluster (Pitfalls §5)
5. Execute DQL queries (namespace utilization as **ratios**, cost attribution, idle workloads, unit economics) AND the OOM + throttle queries — "fix before you cut" (Pitfalls §2, §6, §7)
6. Calculate waste percentages and compare to benchmarks; verify CPU metric units before applying idle thresholds; check for duplicate APM agents (Pitfalls §8)
7. Build the cost model: **derive node SKU from allocatable telemetry** (Pitfalls §4), price cloud nodes by inferred size, report on-prem separately (pod compute + proportional satellite/shared costs)
7. Generate report in `/report/FinOps_K8s_Report_YYYY-MM-DD.md`, organized by the **4 FinOps Domains**
8. Structure recommendations by **Inform/Optimize/Operate**, sequenced by **Crawl/Walk/Run** maturity

---

## Reference Links

**FinOps Foundation:**
- Framework (Principles/Domains/Phases): https://www.finops.org/framework/
- Container Costs WG: https://www.finops.org/wg/calculating-container-costs/
- Cost Allocation: https://www.finops.org/wg/cloud-cost-allocation/
- Workload Optimization Capability: https://www.finops.org/framework/capabilities/workload-optimization/
- Unit Economics Capability: https://www.finops.org/framework/capabilities/unit-economics/
- Sustainability Capability: https://www.finops.org/framework/capabilities/sustainability/

**CNCF / Open Source:**
- FinOps Surveys: https://www.cncf.io/reports/
- K8s Best Practices: https://www.cncf.io/blog/
- OpenCost (K8s cost allocation standard): https://www.opencost.io/

**Kubernetes Docs (rightsizing backing):**
- Autoscaling (VPA/HPA): https://kubernetes.io/docs/concepts/workloads/autoscaling/
- Managing Resources for Containers (cores vs. millicores): https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

**FOCUS Spec:**
- Specification: https://focus.finops.org/

**Cloud Provider Pricing:**
- AWS: https://aws.amazon.com/ec2/pricing/
- Azure: https://azure.microsoft.com/en-us/pricing/
- GCP: https://cloud.google.com/pricing/

**Dynatrace (optional — sustainability/carbon angle):**
- Carbon Impact app — pairs idle/overprovisioned findings with CO₂ estimates (verify availability in your tenant)

---

## Update Protocol

When discovering new FinOps patterns or queries:
1. Document new DQL queries in this file
2. Add industry benchmarks as they are published
3. Update reference links if URLs change
4. Store cloud provider pricing snapshots in `reference/` if needed
