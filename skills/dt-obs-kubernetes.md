# Kubernetes Infrastructure Skill
> Source: [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — `dt-obs-kubernetes`

Monitor and analyze Kubernetes infrastructure using DQL.

---

## Entity Types

**Workloads:** `K8S_DEPLOYMENT`, `K8S_STATEFULSET`, `K8S_DAEMONSET`, `K8S_JOB`, `K8S_CRONJOB`, `K8S_HORIZONTALPODAUTOSCALER`
**Infrastructure:** `K8S_CLUSTER`, `K8S_NAMESPACE`, `K8S_NODE`, `K8S_POD`
**Configuration:** `K8S_SERVICE`, `K8S_CONFIGMAP`, `K8S_SECRET`, `K8S_PERSISTENTVOLUMECLAIM`, `K8S_PERSISTENTVOLUME`, `K8S_INGRESS`, `K8S_NETWORKPOLICY`

## Core Fields
- `k8s.cluster.name`, `k8s.namespace.name`, `k8s.pod.name`, `k8s.node.name`
- `k8s.workload.name`, `k8s.workload.kind`, `k8s.container.name`
- `k8s.object` — Full JSON configuration for deep inspection
- `tags[label]` — Access labels and annotations

## Key Metrics

| Category | Metrics |
|----------|---------|
| CPU | `dt.kubernetes.container.cpu_usage`, `cpu_throttled`, `limits_cpu`, `requests_cpu` |
| Memory | `dt.kubernetes.container.memory_working_set`, `limits_memory`, `requests_memory` |
| Operations | `dt.kubernetes.container.restarts`, `oom_kills` |
| Node | `dt.kubernetes.node.pods_allocatable`, `cpu_allocatable`, `memory_allocatable`, `dt.kubernetes.pods` |

---

## Entity Disambiguation

- **`K8S_POD`** — K8s-native entities with `k8s.object` JSON. Use this skill.
- **`CONTAINER`** — Host-level container inventory. Use `dt-obs-hosts` skill.
- No direct SERVICE → K8S_POD edge. Correlation key: shared `k8s.workload.name`.

---

## Common Workflows

### Cluster Health
```dql
smartscapeNodes K8S_CLUSTER
| fields k8s.cluster.name, k8s.cluster.version, k8s.cluster.distribution
```

### Node Capacity
```dql
timeseries {
  current_pods = avg(dt.kubernetes.pods),
  max_pods = avg(dt.kubernetes.node.pods_allocatable)
}, by: {k8s.node.name, k8s.cluster.name}
| fieldsAdd pod_capacity_pct = (arrayAvg(current_pods) / arrayAvg(max_pods)) * 100
| filter pod_capacity_pct > 80
```

### OOMKills
```dql
timeseries oom_kills = sum(dt.kubernetes.container.oom_kills),
  by: {k8s.pod.name, k8s.namespace.name, k8s.cluster.name}
| filter arraySum(oom_kills) > 0
| fieldsAdd total_oom_kills = arraySum(oom_kills)
| sort total_oom_kills desc
```

### Over-Provisioned Pods (usage < 30%)
```dql
timeseries {
  cpu_usage = sum(dt.kubernetes.container.cpu_usage),
  cpu_requests = avg(dt.kubernetes.container.requests_cpu)
}, by: {k8s.pod.name, k8s.namespace.name, k8s.cluster.name}
| fieldsAdd usage_pct = (arrayAvg(cpu_usage) / arrayAvg(cpu_requests)) * 100
| filter usage_pct < 30 and arrayAvg(cpu_requests) > 0
```

### Privileged Containers (Security)
```dql
smartscapeNodes K8S_POD | parse k8s.object, "JSON:config"
| expand container = config[spec][containers]
| fieldsAdd container_name = container[name], privileged = container[securityContext][privileged]
| filter privileged == true
```

### DAVIS Problems affecting K8s
```dql
fetch dt.davis.problems, from:now() - 2h
| filter not(dt.davis.is_duplicate) and event.status == "ACTIVE"
| filter matchesPhrase(smartscape.affected_entity.types, "K8S_")
| fields display_id, event.name, event.category, smartscape.affected_entity.ids
```

---

## Limitations

- Pod network metrics (rx_bytes, tx_bytes) NOT available in Grail
- Minimize result set: avoid including `k8s.object` unless necessary
- Large clusters may require pagination or time-range limits
