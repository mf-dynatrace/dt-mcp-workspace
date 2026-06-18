# Application Services Skill
> Source: [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — `dt-obs-services`

Monitor application service performance, health, and runtime-specific metrics using DQL.

---

## 1. Service Performance (RED Metrics)

Monitor service **Rate, Errors, Duration** using metrics-based timeseries queries.

**Key Metrics:**
- `dt.service.request.response_time` - Response time (microseconds)
- `dt.service.request.count` - Request count
- `dt.service.request.failure_count` - Failed request count

**Quick Example:**
```dql
timeseries {
  p95 = percentile(dt.service.request.response_time, 95),
  total_requests = sum(dt.service.request.count),
  failures = sum(dt.service.request.failure_count)
}, by: {dt.service.name}
| fieldsAdd p95_ms = p95[] / 1000, error_rate_pct = (failures[] * 100.0) / total_requests[]
```

---

## 2. Advanced Service Analysis (Spans)

Span-based queries for SLA compliance, health scoring, custom error classification.

```dql
fetch spans, from: now() - 1h | filter request.is_root_span == true
| fieldsAdd meets_sla = if(request.is_failed == false AND duration < 3s, 1, else: 0)
| summarize total = count(), sla_compliant = sum(meets_sla), by: {dt.service.name}
| fieldsAdd sla_compliance_pct = (sla_compliant * 100.0) / total
```

---

## 3. Service Messaging Metrics

**Key Metrics:**
- `dt.service.messaging.publish.count` - Messages sent to queues or topics
- `dt.service.messaging.receive.count` - Messages received from queues or topics
- `dt.service.messaging.process.count` - Messages successfully processed
- `dt.service.messaging.process.failure_count` - Messages that failed processing

```dql
timeseries {
  published = sum(dt.service.messaging.publish.count),
  received = sum(dt.service.messaging.receive.count),
  processed = sum(dt.service.messaging.process.count),
  failed = sum(dt.service.messaging.process.failure_count)
}, by: {dt.service.name}
```

---

## 4. Service Mesh Monitoring

**Key Metrics:**
- `dt.service.request.service_mesh.response_time` - Mesh response time (μs)
- `dt.service.request.service_mesh.count` - Mesh request count
- `dt.service.request.service_mesh.failure_count` - Mesh failure count

```dql
timeseries {
  direct_p95 = percentile(dt.service.request.response_time, 95),
  mesh_p95 = percentile(dt.service.request.service_mesh.response_time, 95)
}, by: {dt.service.name}
| fieldsAdd mesh_overhead_ms = (mesh_p95[] - direct_p95[]) / 1000
```

---

## 5. Runtime-Specific Monitoring

| Runtime | Key Metrics |
|---------|-------------|
| **Java/JVM** | Heap/pools/metaspace memory, GC impact/suspension/pause, thread count/leaks, class loading |
| **Node.js** | Event loop utilization, V8 heap, GC collection time, RSS memory |
| **.NET CLR** | Memory by generation, GC collection/suspension, thread pool, JIT compilation |
| **Python** | Active threads, heap blocks, GC by generation, collected objects |
| **PHP** | OPcache hit ratio/memory, GC effectiveness, JIT buffer, interned strings |
| **Go** | Goroutines count/leaks, GC suspension/collection, heap by state, scheduler workers |

---

## Query Construction Patterns

**1. Metrics-based (timeseries)** — Standard monitoring, dashboards, alerting
```
timeseries <metric> = <aggregation>(<metric_name>), by: {dimensions}
```

**2. Span-based (fetch spans)** — Complex filtering, custom logic, detailed analysis
```
fetch spans | filter request.is_root_span == true | fieldsAdd ... | summarize ...
```

**3. Comparison queries** — Use `append` for baseline comparison, `shift: -15m` for time-shifted baselines

---

## User Request → Capability Mapping

| User Request | Capability | 
|--------------|------------|
| "service performance", "response time", "error rate" | Service Performance (RED) |
| "SLA tracking", "health scoring" | Advanced Service Analysis |
| "service mesh", "Istio", "mesh overhead" | Service Mesh Monitoring |
| "messaging", "queue", "topic", "publish" | Service Messaging Metrics |
| "JVM GC", "Java memory", "heap" | Runtime (Java) |
| "Node.js event loop", "V8 heap" | Runtime (Node.js) |
| ".NET CLR", "GC generation" | Runtime (.NET) |
| "Python GC", "thread count" | Runtime (Python) |
| "OPcache", "PHP GC" | Runtime (PHP) |
| "goroutines", "Go GC" | Runtime (Go) |
