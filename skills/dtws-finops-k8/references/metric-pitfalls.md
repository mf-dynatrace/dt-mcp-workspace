# Dynatrace K8s Metric Pitfalls

> Critical gotchas verified through live tenant analysis.
> Read ALL of these before building a cost model or the results will be wrong.

---

## §1 — Node count: use Smartscape or a ≤2h window, never a 24h `by:{node}` window

The cluster autoscaler creates and destroys nodes continuously. A `timeseries ... by:{k8s.node.name},
from:now()-24h` returns every node-name that **ever existed** in that window, so `count()` and
`sum(allocatable)` are **inflated** — enough to materially over-state cost.

**Use instead:**
```dql
// Point-in-time node count
smartscapeNodes "K8S_NODE" | summarize nodes = count()

// Current capacity — ≤2h window
timeseries cpu = avg(dt.kubernetes.node.cpu_allocatable), ...
  by:{k8s.cluster.name, k8s.node.name}, from:now()-2h, interval:2h
```

---

## §2 — Units do NOT reconcile between container and node metric families

- **Node** metrics: `dt.kubernetes.node.cpu_allocatable` → **millicores**; `memory_allocatable` → **bytes**.
- **Container** metrics: `requests_cpu`, `cpu_usage`, `requests_memory`, `memory_working_set` — sums
  do **NOT** reconcile with node allocatable (container sums can exceed node capacity by an order of
  magnitude or more — physically impossible).

**Rule:** Use `used ÷ requested` ratios within the container family. Never compute
"container requests vs node capacity" commitment % by mixing both families.

---

## §3 — There is NO node-level usage metric

Node metrics expose only `*_allocatable`, `pods_allocatable`, `nodes`, and `conditions`.
There is **no** `dt.kubernetes.node.cpu_usage` or `memory_working_set`.

Derive node utilisation from container-level usage (with the ratio caveat in §2).

---

## §4 — Derive node SKU from telemetry — never assume a flat node type

Compute `avg_core_per_node` and `avg_mem_per_node` from allocatable and map to the cloud SKU
(e.g. ~30 allocatable cores + ~124 GB ⇒ 32-vCPU/128 GB VM after system reservation).

Assuming a small uniform SKU (e.g. 8-vCPU) can understate true compute cost by several times over.
Per-node pricing must match the **inferred** size.

---

## §5 — Identify cloud vs on-prem and price separately

Infer platform from cluster naming AND namespaces:
- `*-aks-*` → Azure AKS
- `openshift-vsphere-infra` / `openshift-*` → OpenShift on vSphere (on-prem, not metered cloud spend)

Apply cloud list pricing only to cloud nodes. Report on-prem capacity separately (capex/opex or
"equivalent rehost" cost). Never blend Azure pricing onto on-prem OpenShift nodes.

---

## §6 — OOM / throttle queries return huge arrays — collapse them

`timeseries oom = sum(...oom_kills), by:{pod}, from:now()-30d` returns long per-bucket arrays.
A per-6h value of ~50 is **not** the 30-day total. Collapse with `arraySum()` or set
`interval:` to the full window:

```dql
timeseries oom = sum(dt.kubernetes.container.oom_kills),
  by:{k8s.namespace.name, k8s.pod.name}, from:now()-30d, interval:30d
| fieldsAdd total_oom = arraySum(oom)
| filter total_oom > 0
| sort total_oom desc
```

---

## §7 — "Fix before you cut" — check OOM + throttling before recommending rightsizing-down

Over-provisioning and **under**-provisioning coexist. Always run OOM and throttle queries
alongside utilisation:

- **OOM kills** and **memory used > requested** → **raise** requests/limits, not cut.
- **High CPU throttling** → limits are too tight; raise limits even if CPU *usage* looks low.

Recommend cuts only where utilisation is low **and** there is no OOM/throttle signal.

---

## §8 — Check for duplicate APM / observability agents

Namespace `tags` often reveal multiple APM stacks co-deployed (e.g. `APPD_INSTRUMENTATION_*`
for AppDynamics AND `dynakube.internal.dynatrace.com/*` for Dynatrace). Redundant agents cost
licensing AND per-pod compute — flag consolidation as a rate-optimisation finding.

Also: namespace `tags` carry only platform/operational labels (openshift/istio/security) in
many clusters — treat absence of `cost-center`/`team`/`owner` as 0% allocation coverage even
when `isNotNull(tags)` is true.

---

## §9 — CPU idle threshold units must be verified before use

`dt.kubernetes.container.cpu_usage` may be reported in cores, millicores, or nanocores
depending on the environment's OTel pipeline configuration. An absolute threshold like `< 0.01`
is only valid in cores. Always verify by inspecting a known pod's values against its
`requests_cpu` before applying any absolute filter.
