# Logs Reference

> **Purpose:** Document log patterns and common errors to avoid expensive repeat queries
> **Last Updated:** *(Update after first session)*
> **Cost Warning:** Log queries can be expensive (10-85 GB for 24h). Always filter by loglevel first.
> **Semantic Dictionary:** https://docs.dynatrace.com/docs/shortlink/semantic-dictionary — look up `logs` fields and conventions

---

## ⚠️ Query Cost Warning

| Query Pattern | 24h Cost | 7d Cost | Recommendation |
|--------------|----------|---------|----------------|
| Keyword search (no loglevel filter) | 85 GB | 300+ GB | 🔴 Always add loglevel filter |
| With loglevel filter | 10-15 GB | 50-70 GB | ⚠️ Acceptable for 24h |
| Aggregation only | 5-10 GB | 20-40 GB | ✅ Preferred |
| Entity-filtered logs | 3-8 GB | 15-30 GB | ✅ Best practice |

---

## 📊 Log Level Distribution

| Log Level | Count (24h) | % of Total | Colour Code |
|-----------|-------------|------------|-------------|
| ERROR | | | 🔴 Red |
| WARN | | | 🟠 Orange |
| INFO | | | 🟢 Green |
| DEBUG | | | 🟣 Purple |
| NONE | | | ⚪ Grey |

*(Populate with actual data from your environment)*

**Key Insight:** Focus on ERROR and WARN for issues.

---

## 🔥 Top Error Services (Track Over Time)

### *(Date)*
| Rank | Service | Entity ID | Error Count (24h) | Error Type |
|------|---------|-----------|------------------|------------|
| 🔴 #1 | *(Add as discovered)* | `SERVICE-XXXXXXXXXXXX` | | |
| 🔴 #2 | *(Add as discovered)* | `SERVICE-XXXXXXXXXXXX` | | |
| 🟠 #3 | *(Add as discovered)* | `SERVICE-XXXXXXXXXXXX` | | |

**Trend Analysis:**
- *(Document trends as discovered)*

---

## 🚨 Common Error Patterns

*(Document error patterns as discovered during sessions)*

### Template for Error Patterns
```markdown
### [DATE] — [Error Category] ([Application/Service], [Timeframe])

**Total errors:** [count]

#### Error Type Breakdown
| Error Type | Provider | Count |
|------------|----------|-------|
| *(Add as discovered)* | | |

#### Top Errors
| Error | Domain/Source | Count | Sessions | Reason |
|-------|-------------|-------|----------|--------|
| *(Add as discovered)* | | | | |
```

---

## 📊 Efficient Log Queries

### ✅ Best Practice - Aggregated Errors (5-10 GB)
```dql
fetch logs, from:now()-24h
| filter loglevel == "ERROR"
| summarize count = count(), by:{dt.entity.service}
| sort count desc
| limit 20
```

### ✅ Entity-Filtered Error Details (3-8 GB)
```dql
fetch logs, from:now()-24h
| filter loglevel == "ERROR"
| filter dt.entity.service == "SERVICE-XXXXXXXXXXXX"
| summarize count = count(), by:{content}
| sort count desc
| limit 20
```

### ❌ Never Do This
```dql
// This costs 85+ GB for 24h!
fetch logs, from:now()-24h
| filter contains(content, "error")
| limit 1000
```

---

## 🔧 Available Log Fields

| Field | Description | Filter Use |
|-------|-------------|-----------|
| `content` | Log message text | Full-text search (expensive) |
| `loglevel` | ERROR, WARN, INFO, DEBUG, NONE | ✅ Always filter first |
| `log.source` | Source of the log | Filter by source |
| `dt.entity.service` | Service entity ID | ✅ Filter by service |
| `dt.entity.host` | Host entity ID | Filter by host |
| `timestamp` | Log timestamp | Timeframe |
| `status` | HTTP status code (if applicable) | Filter by status |

---

## 📝 Error Pattern Discovery Log

| Date | Error Pattern | Service | Count | Impact | Resolved? |
|------|---------------|---------|-------|--------|-----------|
| *(Add as discovered)* | | | | | |
