# Spans Reference

> **Purpose:** Document span/trace data patterns to avoid expensive repeat queries
> **Last Updated:** 2026-03-06
> **Cost Warning:** Span queries are EXPENSIVE (16-125 GB). Use metrics timeseries instead when possible.
> **Semantic Dictionary:** https://docs.dynatrace.com/docs/shortlink/semantic-dictionary — look up `spans` fields and conventions

---

## ⚠️ Query Cost Warning

| Timeframe | Typical Cost | Recommendation |
|-----------|-------------|----------------|
| 24h + entity filter | 16 GB | ⚠️ OK for targeted analysis |
| 7d + entity filter | 125 GB | 🔴 Use metrics instead |
| 7d no filter | 300+ GB | ❌ NEVER DO THIS |

**ALWAYS prefer `timeseries` metrics over `fetch spans`!**

---

## 🌐 Service Spans

### Service: [SERVICE_NAME]
**Entity ID:** `SERVICE-XXXXXXXXXXXX`  
**Purpose:** [Service description]

### Span Names & Volumes
| span.name | Count (24h) | Errors | Avg Duration | P95 Duration | Notes |
|-----------|-------------|--------|--------------|--------------|-------|
| *(Add as discovered)* | | | | | |

### Performance Baselines
| Metric | Value | Threshold |
|--------|-------|-----------|
| Total Requests (24h) | | |
| Avg Response Time | | < X ms (green) |
| P95 Response Time | | < X ms (amber) |
| Error Rate | | < X% (green) |

### Important Notes
- [Any false positive patterns]
- [Key span characteristics]
- [HTTP endpoint patterns if applicable]

---

## 📊 Efficient Span Queries

### ✅ Use This (Metrics - FREE)
```dql
timeseries {
  requests = sum(dt.service.request.count),
  failures = sum(dt.service.request.failure_count)
}, from:now()-7d, interval:1d, filter:{dt.entity.service == "SERVICE-XXXXXXXXXXXX"}
```

### ⚠️ Use Sparingly (24h only)
```dql
fetch spans, from:now()-24h
| filter dt.entity.service == "SERVICE-XXXXXXXXXXXX"
| summarize 
    requests = count(),
    avgLatencyMs = avg(duration) / 1000000,
    p95LatencyMs = percentile(duration, 95) / 1000000,
    by:{span.name}
```

### ❌ Never Do This
```dql
// This costs 125+ GB!
fetch spans, from:now()-7d
| filter dt.entity.service == "SERVICE-XXXXXXXXXXXX"
| summarize count()
```

---

## 🔧 Available Span Fields

### Common Fields
| Field | Type | Example |
|-------|------|---------|
| `span.name` | string | "GET", "POST", "MethodName" |
| `duration` | long (ns) | 117000000 (117ms) |
| `dt.entity.service` | entity ID | "SERVICE-XXXXXXXXXXXX" |
| `span.kind` | string | "SERVER", "INTERNAL", "CLIENT" |
| `otel.status_code` | string | "OK", "ERROR" |
| `http.method` | string | "GET", "POST" |
| `http.status_code` | int | 200, 404, 500 |
| `http.url` | string | "/api/endpoint" |

### Filtering Patterns
```dql
// By HTTP method
| filter span.name == "GET" or span.name == "POST"

// By status
| filter otel.status_code == "ERROR"

// By latency (slow requests > 1s)
| filter duration > 1000000000

// By HTTP status code
| filter http.status_code >= 500
```

---

## ⚠️ CRITICAL: HTTP vs Internal Spans

**There are often TWO span types for each request - use the correct one!**

| Span Type | span.name Example | Available Fields |
|-----------|-------------------|------------------|
| **HTTP Endpoint** | `POST /api/resource` | `server.address`, `http.request.header.*`, `url.path` |
| **Internal Method** | `ControllerName/method` | Basic fields only (duration, request.is_failed) |

**Rule:** If you need HTTP headers, user agent, or request attributes, you MUST use the HTTP endpoint span name!

---

## 📊 Span Discovery Queries

### Find All Services (Start Here)
```dql
fetch spans, from:now()-1h
| summarize count = count(), by:{dt.entity.service}
| sort count desc
| limit 20
```

### Find Span Names for a Service
```dql
fetch spans, from:now()-24h
| filter dt.entity.service == "SERVICE-XXXXXXXXXXXX"
| summarize count = count(), by:{span.name}
| sort count desc
| limit 20
```

### Analyze Span Performance
```dql
fetch spans, from:now()-24h
| filter dt.entity.service == "SERVICE-XXXXXXXXXXXX"
| filter span.name == "your-span-name"
| summarize 
    count = count(),
    avgDuration = avg(duration)/1000000,  // Convert ns to ms
    p95Duration = percentile(duration, 95)/1000000,
    errorCount = countIf(otel.status_code == "ERROR")
```

### Find Slow Spans
```dql
fetch spans, from:now()-24h
| filter dt.entity.service == "SERVICE-XXXXXXXXXXXX"
| filter duration > 1000000000  // > 1 second
| fields timestamp, span.name, duration
| sort duration desc
| limit 50
```

### Find Available Fields for a Span
```dql
fetch spans, from:now()-1h
| filter dt.entity.service == "SERVICE-XXXXXXXXXXXX"
| filter span.name == "your-span-name"
| limit 1
// Then examine the returned fields
```

### Error Rate by Span
```dql
fetch spans, from:now()-24h
| filter dt.entity.service == "SERVICE-XXXXXXXXXXXX"
| summarize 
    total = count(),
    errors = countIf(otel.status_code == "ERROR"),
    errorRate = errors * 100.0 / total,
    by:{span.name}
| sort errors desc
```

---

## 📝 Update Log

### 2026-03-06 - Initial Setup
- **Source:** Workspace initialization
- **Finding:** Reference file created
- **Data:** Template ready for population

<!--
Example update entry:

### [DATE] - Service Discovery
- **Source:** Span query for SERVICE-XXXX
- **Finding:** Discovered 15 span names
- **Data:** Top spans: GET (500K), POST (100K), internal.method (50K)
-->

---

## 🔄 How to Update This File

When you discover span patterns:
1. Add service to appropriate section
2. Document span names with volumes and latencies
3. Note which fields are available on which span types
4. Record performance baselines
5. Add to Update Log with source query
