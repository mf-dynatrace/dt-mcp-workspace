# Application Tracing Skill
> Source: [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — `dt-obs-tracing`

Distributed traces, spans, service dependencies, performance analysis, and failure detection.

---

## Core Concepts

**Span kinds:**
- `span.kind: server` - Incoming call to a service
- `span.kind: client` - Outgoing call from a service
- `span.kind: consumer` - Incoming message consumption
- `span.kind: producer` - Outgoing message production
- `span.kind: internal` - Internal operation within a service

**Root spans:** `request.is_root_span == true` represents an incoming call to a service.

### Key Trace Attributes

| Attribute | Description |
|-----------|-------------|
| `trace.id` | Unique trace identifier |
| `span.id` | Unique span identifier |
| `span.parent_id` | Parent span ID (null for root spans) |
| `request.is_root_span` | Boolean, true for request entry points |
| `request.is_failed` | Boolean, true if request failed |
| `duration` | Span duration in nanoseconds |
| `span.timing.cpu` | Overall CPU time of the span |
| `span.timing.cpu_self` | CPU time excluding child spans |
| `dt.smartscape.service` | Service Smartscape node ID |
| `dt.service.name` | Dynatrace service name |
| `endpoint.name` | Endpoint/route name |

---

## Sampling and Extrapolation

One span can represent multiple real operations due to:
- **Aggregation**: Multiple operations in one span (`aggregation.count`)
- **ATM**: Head-based sampling by agent
- **ALR**: Server-side sampling

**Always extrapolate when counting operations:**
```dql
fetch spans
| fieldsAdd sampling.probability = (power(2, 56) - coalesce(sampling.threshold, 0)) * power(2, -56)
| fieldsAdd sampling.multiplicity = 1 / sampling.probability
| fieldsAdd multiplicity = coalesce(sampling.multiplicity, 1)
                * coalesce(aggregation.count, 1)
                * dt.system.sampling_ratio
| summarize operation_count = sum(multiplicity)
```

---

## Common Query Patterns

### Service Performance Summary
```dql
fetch spans
| filter request.is_root_span == true
| summarize
    total_requests = count(),
    failed_requests = countIf(request.is_failed == true),
    avg_duration = avg(duration),
    p95_duration = percentile(duration, 95),
    by: {dt.service.name}
| fieldsAdd error_rate = (failed_requests * 100.0) / total_requests
| sort error_rate desc
```

### Slow Trace Detection
```dql
fetch spans, from:now() - 2h
| filter request.is_root_span == true
| filter duration > 5s
| fields trace.id, span.name, dt.service.name, duration
| sort duration desc | limit 50
```

### Trace ID Lookup
```dql
fetch spans
| filter trace.id == toUid("abc123def456")
| fields span.name, duration, dt.service.name
```

---

## Failure Investigation

### Failure Reason Analysis
```dql
fetch spans
| filter request.is_failed == true and isNotNull(dt.failure_detection.results)
| expand dt.failure_detection.results
| summarize count(), by: { dt.failure_detection.results[reason] }
```

**Failure reasons:** `http_code`, `grpc_code`, `exception`, `span_status`, `custom_rule`

### HTTP Code Failures
```dql
fetch spans
| filter request.is_failed == true
| filter iAny(dt.failure_detection.results[][reason] == "http_code")
| summarize count(), by: { http.response.status_code, endpoint.name }
| sort `count()` desc
```

---

## Exception Analysis

Exceptions are stored as `span.events` within spans:
```dql
fetch spans
| filter iAny(span.events[][span_event.name] == "exception")
| expand span.events
| fieldsFlatten span.events, fields: { exception.type }
| summarize {
    count(),
    trace=takeAny(record(start_time, trace.id))
  }, by: { exception.type }
| fields exception.type, `count()`, trace.id=trace[trace.id]
```

---

## Span Types

### HTTP Spans
```dql
// Server-side (incoming)
fetch spans | filter span.kind == "server" and isNotNull(http.request.method)
| summarize requests = count(), avg_duration = avg(duration), by: { http.request.method, http.route }

// Client-side (outgoing)  
fetch spans | filter span.kind == "client" and isNotNull(http.request.method)
| summarize calls = count(), avg_duration = avg(duration), by: { server.address, http.request.method }
```

### Database Spans
```dql
fetch spans | filter span.kind == "client" and isNotNull(db.system) and isNotNull(db.namespace)
| summarize spans=count(), avg_duration=avg(duration), by: { dt.service.name, db.system, db.namespace }
```
⚠️ Database spans can be aggregated — always use extrapolation for accurate counts.

### Messaging Spans
```dql
fetch spans | filter isNotNull(messaging.system)
| summarize spans = count(), messages = sum(coalesce(messaging.batch.message_count, 1)),
  by: { messaging.system, messaging.destination.name, messaging.operation.type }
```

### RPC Spans
```dql
fetch spans | filter isNotNull(rpc.system)
| summarize calls = count(), avg_duration = avg(duration),
  by: { rpc.system, rpc.service, rpc.method }
```

### Serverless Spans
```dql
fetch spans | filter isNotNull(faas.name) and span.kind == "server"
| summarize invocations = count(), avg_duration = avg(duration), p99_duration = percentile(duration, 99),
  by: { faas.name, cloud.provider }
```

---

## Logs and Traces Correlation
```dql
fetch spans, from:now() - 30m
| join [ fetch logs | fieldsAdd trace.id = toUid(trace_id) ],
  on: { trace.id },
  fields: { content, loglevel }
| fields start_time, trace.id, span.id, loglevel, content | limit 100
```

---

## Request Attributes

Custom request attributes on root spans:
```dql
fetch spans | filter request.is_root_span == true
| filter isNotNull(request_attribute.PaidAmount)
| makeTimeseries sum(request_attribute.PaidAmount)
```

For attributes with special characters: `` `request_attribute.My Customer ID` ``

---

## Best Practices

- **Filter early**: Apply `request.is_root_span == true` and endpoint filters first
- **Use `samplingRatio`**: Reduce data volume (e.g., `samplingRatio:100` reads 1%)
- **Limit results**: Always use `limit` for exploratory queries
- **Percentiles over averages**: Use p95/p99 for performance insights
- **Always extrapolate**: Use multiplicity for accurate operation counts
- **Include trace exemplars**: `takeAny(record(start_time, trace.id))` for drilldown
