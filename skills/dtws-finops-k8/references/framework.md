# FinOps Framework Reference

> FinOps Foundation framework alignment for Kubernetes cost analysis.
> Source: finops.org — load this before structuring any FinOps report.

---

## The 6 FinOps Principles (the "why")

1. **Teams need to collaborate** — FinOps, Engineering, Finance, and Product align on K8s spend.
2. **Business value drives technology decisions** — optimise for value, not lowest cost.
3. **Everyone takes ownership for their technology usage** — namespace/workload owners are accountable.
4. **FinOps data should be accessible, timely, and accurate** — near-real-time visibility (Dynatrace telemetry).
5. **A centralised team drives FinOps** — consistent allocation/tagging standards enforced centrally.
6. **Take advantage of the variable cost model of the cloud** — rightsizing, autoscaling, spot/preemptible.

---

## The 4 FinOps Domains (organise the analysis here)

| Domain | Relevant Capabilities | Maps to Report Section |
|---|---|---|
| **Understand Usage & Cost** | Data Ingestion, Allocation, Reporting & Analytics, Anomaly Management | Visibility Gap, Cost Owner Attribution |
| **Quantify Business Value** | Forecasting, Budgeting, KPIs & Benchmarking, Unit Economics | Unit Economics, benchmark comparisons |
| **Optimize Usage & Cost** | Workload Placement, Usage Optimization, Rate Optimization, Sustainability | Rightsizing, Idle Workloads, Spot/HPA |
| **Manage the FinOps Practice** | Governance/Policy/Risk, Education, Invoicing & Chargeback, Automation | Ownership gaps, Operate recommendations |

---

## Phases & Maturity (sequence recommendations here)

- **Phases:** Inform → Optimize → Operate
- **Maturity:** Crawl → Walk → Run — never recommend all dimensions at once; establish
  reporting + tagging discipline (Crawl) before advanced split-cost allocation (Run).

---

## Cost Model: What to Allocate

Pod compute alone is **not** the full picture. A credible K8s FinOps report covers:

- **Pod compute costs** — CPU + memory by requests *and* actual usage (report both).
- **Satellite / shared costs** — control-plane nodes, persistent storage (PVs), network egress,
  observability, security, and licensing tooling running in-cluster. Allocate proportionally.
- **Static vs. runtime costs** — reserved/committed node capacity (static) vs. consumption-driven scaling (runtime).
- **Idle / unallocated headroom** — capacity paid for but not requested. Surface explicitly.

**Default allocation — proportional resource consumption:**
```
Workload share of shared cost = (workload's requested resources) / (cluster total requested) × shared cost pool
```

---

## Domain Analysis Detail

### Understand Usage & Cost

**Visibility Gap** *(Allocation)*
- What % of K8s spend is unattributed?
- Benchmark: Most orgs start below 60% allocation accuracy (FinOps Foundation)
- Dynatrace: Namespace/pod labels vs. missing cost owner tags

**Ownership Gaps** *(Allocation / Governance)*
- Namespaces or workloads with no cost owner
- Benchmark: 45% of orgs lack accountability (CNCF)
- Dynatrace: Missing `tags[cost-center]`, `tags[team]`, `tags[environment]`

### Quantify Business Value

**Unit Economics** *(Unit Economics / KPIs & Benchmarking)*
- Cost per business metric — e.g. cost per 1k transactions, per namespace, per customer.
- Dynatrace: Allocated cost (node pricing × proportional requests) ÷ business volume
  from BizEvents or `dt.service.request.count`.
- Surfaces *value*, not just spend: a "high cost" namespace may be highly efficient per transaction.

### Optimize Usage & Cost

**Rightsizing Findings** *(Workload Optimization)*
- CPU/memory requested vs. actual utilisation
- Benchmark: 70% of orgs have overprovisioning issues (CNCF)
- Dynatrace: `dt.kubernetes.container.cpu_usage` vs. `requests_cpu`

**Unused / Idle Resources** *(Usage Optimization)*
- Idle workloads, terminated pods still consuming resources, unallocated cluster headroom
- Benchmark: 43% of orgs have unused resources (CNCF)
- Sustainability angle: idle/overprovisioned capacity is wasted carbon as well as wasted spend.

### Manage the FinOps Practice

**Recommendations — bucket by phase, sequence by Crawl/Walk/Run:**
- **Inform (Crawl):** Improve cost visibility — add tags, enable allocation, establish reporting.
- **Optimize (Walk):** Rightsizing, HPA/VPA tuning, spot/preemptible, proportional shared-cost allocation.
- **Operate (Run):** Policy enforcement, automated governance, budget alerts, FOCUS-based chargeback.

---

## Framework Sources

| Source | URL | Provides |
|---|---|---|
| FinOps Framework | `finops.org/framework/` | Principles, Domains, Phases, Maturity |
| Calculating Container Costs | `finops.org/wg/calculating-container-costs/` | K8s allocation; requests vs. usage trade-offs |
| Cost Allocation WG | `finops.org/wg/cloud-cost-allocation/` | Metadata strategy; tagging KPIs |
| Workload Optimization | `finops.org/framework/capabilities/workload-optimization/` | Rightsizing / autoscaling KPIs |
| Unit Economics | `finops.org/framework/capabilities/unit-economics/` | Cost-per-business-metric |
| Sustainability | `finops.org/framework/capabilities/sustainability/` | GreenOps / carbon tie-in |
| CNCF FinOps Microsurvey | `cncf.io` (surveys) | Industry benchmarks (70%/45%/43%) |
| CNCF K8s Best Practices | `cncf.io/blog/` | Rightsizing technical grounding |
| OpenCost | `opencost.io` | CNCF open standard for K8s cost allocation |
| FOCUS Spec | `focus.finops.org` | Split cost allocation columns (v1.3+ for K8s) |
| K8s Autoscaling (VPA/HPA) | `kubernetes.io/docs/concepts/workloads/autoscaling/` | Rightsizing technical backing |
| K8s Resource Management | `kubernetes.io/docs/concepts/configuration/manage-resources-containers/` | Cores vs. millicores |
