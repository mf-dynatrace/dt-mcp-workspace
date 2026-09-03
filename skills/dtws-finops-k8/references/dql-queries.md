# K8s FinOps DQL Queries

> Verified DQL queries for Kubernetes FinOps analysis.
> Read `metric-pitfalls.md` before using any of these queries.
> Always load `dt-dql-essentials` before writing or modifying DQL.

---

## 1. Node Count and Capacity (point-in-time)

**Use Smartscape or a ≤2h window. Never use a 24h `by:{node}` window — see pitfalls §1.**

```dql
// Authoritative point-in-time node count
smartscapeNodes "K8S_NODE" | summarize nodes = count()
```

```dql
// Current capacity per cluster (≤2h window avoids churn from autoscaler)
timeseries cpu = avg(dt.kubernetes.node.cpu_allocatable),
           mem = avg(dt.kubernetes.node.memory_allocatable),
  by:{k8s.cluster.name, k8s.node.name}, from:now()-2h, interval:2h
| fieldsAdd c = arrayAvg(cpu), m = arrayAvg(mem)
| summarize nodes = count(), cores_milli = sum(c), mem_bytes = sum(m),
            avg_core_per_node = avg(c), by:{k8s.cluster.name}
```

---

## 2. Namespace CPU Utilisation (used ÷ requested ratio)

**Report ratios, not absolutes. See pitfalls §2 on why mixing container + node families breaks.**

```dql
timeseries {
  cpu_requested = avg(dt.kubernetes.container.requests_cpu),
  cpu_used = avg(dt.kubernetes.container.cpu_usage)
}, by:{k8s.namespace.name}, from:now()-7d
| fieldsAdd cpu_util_pct = cpu_used / cpu_requested * 100
| fieldsAdd cpu_waste_pct = (cpu_requested - cpu_used) / cpu_requested * 100
| sort cpu_waste_pct desc
```

---

## 3. Namespace Memory Utilisation (used ÷ requested ratio)

```dql
timeseries {
  mem_requested = avg(dt.kubernetes.container.requests_memory),
  mem_used = avg(dt.kubernetes.container.memory_working_set)
}, by:{k8s.namespace.name}, from:now()-7d
| fieldsAdd mem_util_pct = mem_used / mem_requested * 100
| fieldsAdd mem_waste_pct = (mem_requested - mem_used) / mem_requested * 100
| sort mem_waste_pct desc
```

---

## 4. Cost Attribution — Missing Tags

```dql
// Namespaces missing cost allocation tags
fetch dt.entity.cloud_application_namespace
| fields k8s.namespace.name, tags
| filter isNull(tags[cost-center]) or isNull(tags[team])
| summarize untagged_namespaces = count()
```

```dql
// Workload-level tag coverage
fetch dt.entity.cloud_application
| fields k8s.workload.name, k8s.workload.kind, k8s.namespace.name, tags
| summarize count(), by:{k8s.workload.kind, tags[cost-center]}
```

> ⚠️ Namespace `tags` often carry only platform/operational labels (openshift/istio/security).
> Treat absence of `cost-center`/`team`/`owner` as 0% allocation even when `isNotNull(tags)` is true.

---

## 5. Idle Workloads

```dql
// Pods with near-zero CPU usage over 7d
// IMPORTANT: verify unit of cpu_usage BEFORE applying threshold — see pitfalls §3
timeseries avg_cpu = avg(dt.kubernetes.container.cpu_usage),
  by:{k8s.namespace.name, k8s.pod.name}, from:now()-7d
| fieldsAdd arr_cpu = arrayAvg(avg_cpu)
| sort arr_cpu asc
```

> ⚠️ Express the idle threshold **relative to requests** (e.g. `arr_cpu / requests_cpu < 0.05`)
> rather than as an absolute. An absolute threshold like `< 0.01` is only valid if the metric is
> in cores; it will over- or under-report if the unit is millicores or nanocores.

---

## 6. OOM Kills (collapse with arraySum — see pitfalls §6)

```dql
timeseries oom = sum(dt.kubernetes.container.oom_kills),
  by:{k8s.namespace.name, k8s.pod.name}, from:now()-30d, interval:30d
| fieldsAdd total_oom = arraySum(oom)
| filter total_oom > 0
| sort total_oom desc
```

---

## 7. CPU Throttling

```dql
timeseries throttle = avg(dt.kubernetes.container.cpu_throttling),
  by:{k8s.namespace.name, k8s.pod.name}, from:now()-7d
| fieldsAdd avg_throttle = arrayAvg(throttle)
| filter avg_throttle > 0.1
| sort avg_throttle desc
```

---

## 8. Memory Used vs. Requested (detect under-provisioning)

```dql
// Flag pods where memory used exceeds requested — eviction risk
timeseries {
  mem_requested = avg(dt.kubernetes.container.requests_memory),
  mem_used = avg(dt.kubernetes.container.memory_working_set)
}, by:{k8s.namespace.name, k8s.pod.name}, from:now()-7d
| fieldsAdd over_provisioned = mem_used > mem_requested
| filter over_provisioned == true
| sort mem_used desc
```

---

## 9. Unit Economics (pair with BizEvents or service request counts)

```dql
// Namespace compute utilisation — combine with node pricing + business volume in the report layer
timeseries {
  cpu_requested = avg(dt.kubernetes.container.requests_cpu),
  cpu_used = avg(dt.kubernetes.container.cpu_usage),
  mem_requested = avg(dt.kubernetes.container.requests_memory),
  mem_used = avg(dt.kubernetes.container.memory_working_set)
}, by:{k8s.namespace.name}, from:now()-7d
```

> Combine allocated cost (node price × proportional requests) with a business denominator —
> BizEvents count or `dt.service.request.count` — to produce cost per transaction / per customer.

---

## 10. Duplicate APM Agents (rate-optimisation finding)

```dql
// Detect co-deployed APM stacks by tag inspection
fetch dt.entity.cloud_application_namespace
| fields k8s.namespace.name, tags
| filter isNotNull(tags[APPD_INSTRUMENTATION_METHOD]) and isNotNull(tags[dynakube.internal.dynatrace.com/version])
| summarize count(), by:{k8s.namespace.name}
```

> Redundant agents (e.g. AppDynamics + Dynatrace co-deployed) cost licensing AND per-pod compute.
> Flag consolidation as a rate-optimisation finding.

---

## Query Cost Notes

| Query | Approx Cost | Notes |
|---|---|---|
| `smartscapeNodes` | FREE | Always use for point-in-time counts |
| `timeseries` metrics (node/container) | FREE | Preferred for all utilisation analysis |
| `fetch dt.entity.*` | FREE | Entity lookups via Smartscape |
| `fetch spans` with entity filter (24h) | ~15–20 GB | Only if trace-level analysis needed |
