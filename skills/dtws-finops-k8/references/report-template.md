# FinOps K8s Report Template

> Report structure for Kubernetes FinOps analysis.
> Save output to: `report/FinOps_K8s_Report_YYYY-MM-DD.md`
> Or: `report/FinOps_K8s_Report_[ClusterName]_YYYY-MM-DD.md` for single-cluster focus.

---

## CNCF Benchmarks (reference in every report)

| Benchmark | Value | Source |
|---|---|---|
| Orgs with overprovisioning issues | **70%** | CNCF FinOps Microsurvey |
| Orgs lacking accountability/ownership | **45%** | CNCF FinOps Microsurvey |
| Orgs with unused resources | **43%** | CNCF FinOps Microsurvey |
| Orgs below 60% allocation accuracy | most | FinOps Foundation |

---

## Report Sections

### 1. Executive Summary
- Total cluster spend (if node pricing available)
- % wasted due to overprovisioning
- Top 3 highest-impact recommendations
- Data timeframe and cluster scope

### 2. Domain: Understand Usage & Cost

#### 2a. Infrastructure Snapshot
- Cluster count, platform (AKS/EKS/GKE/on-prem), node count (point-in-time)
- Total allocatable CPU (cores) and memory (GB/TB)
- Inferred node SKU(s) per cluster

#### 2b. Cost Attribution Coverage
- % of namespaces with cost-center/team/owner tags
- List of namespaces missing allocation tags
- Compare to 60% allocation accuracy baseline

#### 2c. Cost Model Breakdown
- Pod compute costs (by namespace, proportional to requests)
- Satellite/shared cost estimate (observability, control-plane, storage, network)
- Idle/unallocated headroom (capacity paid for, not requested)

### 3. Domain: Quantify Business Value

#### 3a. Unit Economics
- Cost per transaction / per customer / per namespace
- Efficient-but-expensive namespaces (high cost, high throughput)
- Wasteful namespaces (high cost, low throughput)

### 4. Domain: Optimize Usage & Cost

#### 4a. CPU Overprovisioning
- Table: namespace, cpu_requested, cpu_used, cpu_util_pct, cpu_waste_pct
- Highlight namespaces below 20% utilisation
- Compare to 70% CNCF benchmark

#### 4b. Memory Overprovisioning
- Table: namespace, mem_requested, mem_used, mem_util_pct, mem_waste_pct
- Flag namespaces with memory_used > memory_requested (eviction risk)

#### 4c. OOM Kills and CPU Throttling
- Workloads with OOM kills in the analysis period
- Workloads with sustained CPU throttling
- Recommendation: raise limits/requests before rightsizing-down

#### 4d. Idle / Unused Workloads
- Pods with near-zero CPU and memory usage
- Estimated savings from termination
- Sustainability note: idle capacity = wasted carbon as well as wasted spend

#### 4e. Rate Optimisation Opportunities
- Spot/preemptible instance candidates
- Reserved/committed-use opportunities
- Duplicate APM agent consolidation (if detected)

### 5. Domain: Manage the FinOps Practice

#### 5a. Ownership Gaps
- Namespaces/workloads with no cost owner
- Compare to 45% CNCF accountability benchmark

#### 5b. Recommendations

Bucket by phase, sequence by maturity:

**Inform (Crawl) — Establish Visibility**
- [ ] Item 1
- [ ] Item 2

**Optimize (Walk) — Act on the Data**
- [ ] Item 1
- [ ] Item 2

**Operate (Run) — Sustain and Automate**
- [ ] Item 1
- [ ] Item 2

### 6. Appendix
- DQL queries used
- Node pricing assumptions and source
- Data freshness / last query timestamps
- Framework references (FinOps Foundation, CNCF, OpenCost, FOCUS)

---

## Key Metrics Checklist

Every report must include:
- [ ] Utilisation Rate: `actual_usage / requested_resources`
- [ ] Waste Percentage: `(requested - actual) / requested * 100`
- [ ] Allocation Coverage: `% of pods/namespaces with cost owner tags`
- [ ] Cost per Namespace (with node pricing)
- [ ] Unit Economics (where BizEvents or service request data available)
