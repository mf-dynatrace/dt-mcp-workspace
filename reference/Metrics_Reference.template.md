# Metrics Reference

> **Purpose:** Document available metrics for FREE queries instead of expensive span/log queries
> **Last Updated:** 2026-03-06
> **Cost:** Metrics queries are FREE (pre-aggregated data)
> **Semantic Dictionary:** https://docs.dynatrace.com/docs/shortlink/semantic-dictionary — look up metric keys and conventions

---

## ✅ Why Use Metrics?

| Data Source | 7d Query Cost | Use For |
|-------------|--------------|---------|
| Metrics (timeseries) | **0 GB** | Counts, trends, SLOs |
| Spans | 100-125 GB | Deep trace analysis only |
| Logs | 50-85 GB | Error investigation only |

**ALWAYS try metrics first before spans or logs!**

---

## 📊 Service Metrics

### Built-in Service Metrics
| Metric Key | Description | Aggregation |
|------------|-------------|-------------|
| `dt.service.request.count` | Total HTTP requests | sum |
| `dt.service.request.failure_count` | Failed requests | sum |
| `dt.service.request.response_time` | Response time | avg, percentile |

### Custom Metrics
| Metric Key | Description | Source |
|------------|-------------|--------|
| *(Add as discovered)* | | |

---

## 📈 Metric Query Patterns

### Request Count Timeseries
```dql
timeseries {
  requests = sum(dt.service.request.count)
}, from:now()-7d, interval:1d, filter:{dt.entity.service == "SERVICE-XXXXXXXXXXXX"}
```

### Request Count with Failures
```dql
timeseries {
  requests = sum(dt.service.request.count),
  failures = sum(dt.service.request.failure_count)
}, from:now()-7d, interval:6h, filter:{dt.entity.service == "SERVICE-XXXXXXXXXXXX"}
```

### Error Rate Calculation
```dql
timeseries {
  requests = sum(dt.service.request.count),
  failures = sum(dt.service.request.failure_count)
}, from:now()-7d, interval:1d, filter:{dt.entity.service == "SERVICE-XXXXXXXXXXXX"}
| fieldsAdd errorRate = failures[] / requests[] * 100
```

### Multiple Services Comparison
```dql
timeseries {
  requests = sum(dt.service.request.count)
}, from:now()-7d, interval:1d, filter:{dt.entity.service in ["SERVICE-XXX", "SERVICE-YYY"]}
```

---

## 📊 Host Metrics

| Metric Key | Description | Aggregation |
|------------|-------------|-------------|
| `dt.host.cpu.usage` | CPU usage percentage | avg |
| `dt.host.memory.usage` | Memory usage percentage | avg |
| `dt.host.disk.used` | Disk space used | max |
| `dt.host.network.bytes.received` | Network bytes in | sum |
| `dt.host.network.bytes.sent` | Network bytes out | sum |

### Host CPU Query
```dql
timeseries {
  cpu = avg(dt.host.cpu.usage)
}, from:now()-7d, interval:1h, filter:{dt.entity.host == "HOST-XXXXXXXXXXXX"}
```

---

## 🔍 Metric Discovery Queries

### Find Available Metrics for an Entity
```dql
fetch metric.series, from:now()-7d
| filter dt.entity.service == "SERVICE-XXXXXXXXXXXX"
| summarize count = count(), by:{metric.key}
| sort count desc
| limit 30
```

### List All Service Metrics
```dql
fetch metric.series, from:now()-24h
| filter startsWith(metric.key, "dt.service.")
| summarize count = count(), by:{metric.key}
| sort count desc
```

### List All Host Metrics
```dql
fetch metric.series, from:now()-24h
| filter startsWith(metric.key, "dt.host.")
| summarize count = count(), by:{metric.key}
| sort count desc
```

---

## 🏢 Metric Dimensions

Metrics can be split by dimensions:

| Dimension | Description | Example |
|-----------|-------------|---------|
| `dt.entity.service` | Service entity | SERVICE-XXXX |
| `dt.entity.host` | Host entity | HOST-XXXX |
| `request.name` | Request/endpoint name | /api/endpoint |
| `http.status_code` | HTTP response code | 200, 404, 500 |

### Query with Dimension Split
```dql
timeseries {
  requests = sum(dt.service.request.count)
}, from:now()-24h, interval:1h, 
filter:{dt.entity.service == "SERVICE-XXXXXXXXXXXX"},
by:{http.status_code}
```

---

## 📊 Dashboard Metric Tiles

### Request Count Tile
```json
{
  "title": "🌐 Total Requests (7d)",
  "type": "data",
  "query": "timeseries {\n  requests = sum(dt.service.request.count)\n}, from:now()-7d, filter:{dt.entity.service == \"SERVICE-XXXXXXXXXXXX\"}\n| fieldsAdd total = arraySum(requests[])",
  "visualization": "singleValue"
}
```

### Request Trend Chart
```json
{
  "title": "📈 Request Trend",
  "type": "data",
  "query": "timeseries {\n  requests = sum(dt.service.request.count)\n}, from:now()-7d, interval:6h, filter:{dt.entity.service == \"SERVICE-XXXXXXXXXXXX\"}",
  "visualization": "areaChart"
}
```

---

## 📝 Update Log

### 2026-03-06 - Initial Setup
- **Source:** Workspace initialization
- **Finding:** Reference file created
- **Data:** Template ready for population

<!--
Example update entry:

### [DATE] - Metric Discovery
- **Source:** metric.series query for SERVICE-XXXX
- **Finding:** 15 metrics available for service
- **Data:** dt.service.request.count, dt.service.request.failure_count, etc.
-->

---

## 🔄 How to Update This File

When you discover metrics:
1. Add to appropriate section (service, host, custom)
2. Document metric key, description, and recommended aggregation
3. Add sample baselines if useful
4. Add to Update Log with source query
