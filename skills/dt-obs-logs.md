# Log Analysis Skill
> Source: [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — `dt-obs-logs`

Query, filter, and analyze Dynatrace log data using DQL.

---

## Log Data Model

- **timestamp**: When the log entry was created
- **content**: The log message text
- **status**: Log level (ERROR, FATAL, WARN, INFO, etc.) — also accessible via `loglevel`
- **dt.process_group.id**: Associated process group entity
- **dt.process_group.detected_name**: Human-readable process group name

---

## Core Workflows

### Log Searching
```dql
fetch logs, from:now() - 1h
| filter status == "ERROR"
| fields timestamp, content, process_group = dt.process_group.detected_name
| sort timestamp desc | limit 100
```

### Multi-Severity Filtering
```dql
fetch logs, from:now() - 2h
| filter in(status, {"ERROR", "FATAL", "WARN"})
| summarize count(), by: {dt.process_group.id, dt.process_group.detected_name}
| sort `count()` desc
```

### Content Search
```dql
// Simple substring
fetch logs, from:now() - 1h | filter contains(content, "database")

// Full-text phrase
fetch logs, from:now() - 1h | filter matchesPhrase(content, "connection timeout")
```

### Error Rate Calculation
```dql
fetch logs, from:now() - 2h
| summarize
    total_logs = count(),
    error_logs = countIf(status == "ERROR"),
    by: {time_bucket = bin(timestamp, 5m)}
| fieldsAdd error_rate = (error_logs * 100.0) / total_logs
| sort time_bucket asc
```

### Top Error Messages
```dql
fetch logs, from:now() - 24h
| filter status == "ERROR"
| summarize error_count = count(), by: {content}
| sort error_count desc | limit 20
```

### Pattern Analysis
```dql
fetch logs, from:now() - 2h
| filter status == "ERROR"
| fieldsAdd
    has_exception = if(matchesPhrase(content, "exception"), true, else: false),
    has_timeout = if(matchesPhrase(content, "timeout"), true, else: false)
| summarize
    count(),
    exception_count = countIf(has_exception == true),
    timeout_count = countIf(has_timeout == true),
    by: {process_group = dt.process_group.detected_name}
```

### Structured / JSON Log Parsing
```dql
fetch logs, from:now() - 1h
| filter status == "ERROR"
| parse content, "JSON:log"
| fieldsAdd level = log[level], message = log[msg], error = log[error]
| fields timestamp, level, message, error
| sort timestamp desc | limit 50
```

---

## Best Practices

1. **Always specify time ranges** — `from:now() - <duration>`
2. **Apply filters early** — severity and entity before aggregation
3. **Use appropriate search** — `contains()` for simple, `matchesPhrase()` for exact
4. **Limit results** — `| limit 100`
5. **Sort meaningfully** — timestamp for recent, count for top errors
6. **Name entities** — `dt.process_group.detected_name` or `getNodeName()`
7. **Use time buckets for trends** — `bin(timestamp, 5m)`
