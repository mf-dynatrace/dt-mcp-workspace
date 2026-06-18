# MCP Query Optimization Guide

> **Created:** 2026-03-06  
> **Environment:** [TENANT_ID]  
> **Purpose:** Reduce Grail budget consumption and token costs when using Dynatrace MCP tools

---

## 📊 Query Cost Reference

| Query Type | Typical Data Scanned | Cost Level |
|------------|---------------------|------------|
| BizEvents (7d, filtered by event.type) | 0.5 - 5 GB | 🟢 Low |
| BizEvents (30d, unfiltered) | 10 - 50 GB | 🟡 Medium |
| user.sessions (3d, any filter) | 0.00 - 0.14 GB | 🟢 Very Low |
| user.sessions (7d, any filter) | 0.00 - 0.30 GB | 🟢 Very Low |
| user.events (24h, classifier + entity filter) | 1 - 5 GB | 🟢 Low |
| user.events (24h, page.url.path filter) | 2 - 10 GB | 🟢-🟡 Low-Medium |
| user.events (3d, page.url.domain string filter) | 150 - 175 GB | 🔴 Very High |
| user.events (24h, unfiltered classifier summary) | ~46 GB | 🔴 High |
| user.events (7d, exceptions) | 5 - 15 GB | 🟢-🟡 Low-Medium |
| Spans (24h, single service) | 15 - 20 GB | 🟡 Medium |
| Spans (7d, single service) | 100 - 130 GB | 🔴 High |
| Logs (24h, keyword search) | 10 - 85 GB | 🟡-🔴 Medium-High |
| Metrics timeseries | 0 GB | 🟢 Free (pre-aggregated) |
| Entity search (find_entity_by_name) | 0 GB | 🟢 Free |
| Smartscape queries | 0 GB | 🟢 Free |

### ⚠️ user.events Cost Traps (Verified 2026-03-13)
| Pattern | Cost (3d) | Cost (7d) | Fix |
|---------|-----------|-----------|-----|
| Filter by `page.url.domain` string match | **~174 GB** | **~350 GB** | Use `page.url.path` exact match instead |
| Unfiltered `summarize by:{characteristics.classifier}` | ~120 GB | ~250 GB | Pre-filter by `characteristics.classifier` first |
| Filter by `page.url.path` (exact) | 4-10 GB | 8-15 GB | ✅ Acceptable |
| Pre-filter by `classifier` + path | 2-5 GB | 4-10 GB | ✅ Best approach |
| Use `user.sessions` instead (for session counts) | **0.14 GB** | **0.30 GB** | ✅ Use whenever possible |

---

## ✅ Best Practices for Low-Cost Queries

### 1. Always Start with Entity Lookup (FREE)
```
Use: mcp_dynatrace-mcp_find_entity_by_name
Before querying spans/logs, find the entity ID first.
This costs 0 GB and gives you the correct filter.
```

**Example:** Instead of filtering by name in spans, get the entity ID first:
- ✅ `find_entity_by_name("My Service")` → Returns `SERVICE-XXXXXXXXXXXX`
- ✅ Then filter: `dt.entity.service == "SERVICE-XXXXXXXXXXXX"`

### 2. Use Metrics Over Spans When Possible (FREE vs HIGH COST)
```dql
// ✅ LOW COST - Uses pre-aggregated metrics (0 GB)
timeseries {
  requests = sum(dt.service.request.count)
}, from:now()-7d, interval:1d, filter:{dt.entity.service == "SERVICE-ID"}

// ❌ HIGH COST - Scans raw span data (100+ GB for 7d)
fetch spans, from:now()-7d
| filter dt.entity.service == "SERVICE-ID"
| summarize count()
```

### 3. Reduce Timeframes for Exploratory Queries
```dql
// ✅ Start with 24h for exploration (15-20 GB)
fetch spans, from:now()-24h
| filter dt.entity.service == "SERVICE-ID"
| summarize count(), by:{span.name}

// ❌ Don't start with 7d (100+ GB)
fetch spans, from:now()-7d  // Only use after validating query
```

### 4. Filter BizEvents by event.type First
```dql
// ✅ EFFICIENT - Filter early (0.5 GB)
fetch bizevents, from:now()-7d
| filter event.type == "com.example.payment"
| filter customField == "value"
| summarize count()

// ❌ INEFFICIENT - No event.type filter scans everything
fetch bizevents, from:now()-7d
| filter customField == "value"
| summarize count()
```

### 5. Use Aggregations, Not Raw Data
```dql
// ✅ Returns summary (small response, few tokens)
fetch logs, from:now()-24h
| filter loglevel == "ERROR"
| summarize count = count(), by:{loglevel}

// ❌ Returns raw logs (large response, many tokens)
fetch logs, from:now()-24h
| filter loglevel == "ERROR"
| limit 1000
```

---

## 🎯 Query Patterns for Common Use Cases

### Entity Discovery (FREE)
```dql
// Find service by name
Use: find_entity_by_name("service-name")

// Explore topology
smartscapeNodes "SERVICE"
| filter matchesPhrase(displayName, "service-name")
```

### Service Health (FREE)
```dql
timeseries {
  requests = sum(dt.service.request.count),
  failures = sum(dt.service.request.failure_count)
}, from:now()-7d, interval:1d, filter:{dt.entity.service == "SERVICE-ID"}
```

### BizEvents Summary (LOW COST)
```dql
fetch bizevents, from:now()-7d
| summarize count = count(), by:{event.type}
| sort count desc
| limit 20
```

### Error Analysis (MEDIUM COST)
```dql
fetch logs, from:now()-24h
| filter loglevel == "ERROR"
| summarize count = count(), by:{loglevel}
```

---

## 📉 Token Cost Reduction Strategies

### 1. Use `recordLimit` Parameter
```javascript
// Set lower limits for exploration
mcp_dynatrace-mcp_execute_dql({
  dqlStatement: "fetch bizevents...",
  recordLimit: 10  // Default is 100, reduce for exploration
})
```

### 2. Select Only Needed Fields
```dql
// ✅ Returns only needed fields
fetch bizevents, from:now()-7d
| filter event.type == "com.example.payment"
| fields timestamp, amount, result
| limit 20

// ❌ Returns all fields (many columns per record)
fetch bizevents, from:now()-7d
| filter event.type == "com.example.payment"
| limit 20
```

### 3. Use Semantic Dictionary for Field Discovery
```dql
// Find available fields before querying (0 cost)
fetch dt.semantic_dictionary.models
| filter data_object == "logs"
```

### 4. Batch Related Questions
Instead of making 5 separate queries, combine into one:
```dql
// ✅ Single query with multiple aggregations
fetch bizevents, from:now()-7d
| summarize 
    eventType1 = countIf(event.type == "type1"),
    eventType2 = countIf(event.type == "type2"),
    eventType3 = countIf(event.type == "type3")
```

---

## 🔄 Query Workflow for New Analysis

### Step 1: Read Reference Files FIRST (NO QUERIES!)
```
1. Check Entities_Reference.md for cached entity IDs
2. Check BizEvents_Reference.md for known event types
3. Check Spans_Reference.md for span patterns
4. Check Logs_Reference.md for error patterns
```

### Step 2: Entity Discovery (0 cost - if needed)
```
1. Use find_entity_by_name to get entity IDs
2. Use smartscapeNodes to understand topology
3. ⚠️ UPDATE Entities_Reference.md with new IDs!
```

### Step 3: Metric Overview (0 cost)
```
1. Query available metrics with metric.series
2. Use timeseries for trend data
3. ⚠️ UPDATE Metrics_Reference.md with baselines!
```

### Step 4: BizEvents Summary (low cost)
```
1. Start with event.type summary
2. Add filters incrementally
3. Use 24h timeframe initially
4. ⚠️ UPDATE BizEvents_Reference.md with new types!
```

### Step 4b: RUM Session/Event Analysis (variable cost — follow rules!)
```
1. For session counts/metrics: Use user.sessions (VERY CHEAP: <0.3 GB for 7d)
2. For event detail: Use user.events with pre-filters:
   a. ALWAYS filter by characteristics.classifier FIRST
   b. Then filter by page.url.path (exact match) — NOT page.url.domain
   c. Add dt.rum.application.entity filter to narrow further
3. For custom actions (GTM tags): classifier == "user_action" AND user_action.type == "custom"
4. For BizEvents from dtrum.sendBizEvent(): Query bizevents table, NOT user.events
5. ⚠️ NEVER filter user.events by URL domain string match (costs 174+ GB per 3d!)
```

### Step 5: Spans/Logs Deep Dive (do last, high cost)
```
1. Only if metrics don't answer the question
2. Always filter by entity ID
3. Use shortest timeframe needed
4. Aggregate, don't fetch raw data
5. ⚠️ UPDATE Spans_Reference.md or Logs_Reference.md!
```

---

## 🏢 Known Entity IDs (Cache Here)

| Entity Name | Entity ID | Description |
|-------------|-----------|-------------|
| *(Add as discovered)* | | |

---

## ⚠️ High-Volume Event Types (Use Carefully)

| Event Type | Typical Volume | Recommendation |
|------------|---------------|----------------|
| *(Add as discovered)* | | |

---

## 📝 Session Cost Log

Track query costs to learn patterns:

### 2026-03-13 — ISO GTM Tag Verification Session
| Query | Data Scanned | Notes |
|-------|-------------|-------|
| `fetch events` filter ISO | 0.01 GB | Platform events — wrong table for RUM |
| `fetch bizevents` filter ISO event.type | 0.00 GB | No data — tag not firing |
| `fetch user.events` matchesPhrase ISO | 8.21 GB | Expensive full-scan, 0 results |
| `fetch user.events` URL domain filter | 174.21 GB | **EXTREMELY EXPENSIVE** — never do page.url.domain string filter |
| `fetch user.events` URL path + domain bookings | 174.22 GB | Same — domain filter dominates cost |
| `fetch user.events` classifier summary on bookings path | 10.68 GB | Good pattern — path + summarize by classifier |
| `fetch user.events` classifier == user_action on path | 2.57 GB | Best pattern — path + classifier pre-filter |
| `fetch user.events` custom actions | 8.21 GB | entity + classifier + user_action.type filter |
| `fetch user.sessions` all apps | 0.14 GB | Very cheap — always prefer |
| **Session Total** | **~475 GB** | Most cost from domain string filters — AVOID |

---

## ❌ Common Costly Mistakes (Learn from Experience)

### ❌ Mistake #1: Querying 7d Spans Without Filter
```dql
// ❌ COST: 300+ GB
fetch spans, from:now()-7d
| summarize count()
```

**Solution:** Always filter by entity and use metrics instead:
```dql
// ✅ COST: 0 GB
timeseries { requests = sum(dt.service.request.count) },
from:now()-7d, interval:1d
```

### ❌ Mistake #2: Repeating Entity Lookups
```dql
// ❌ Multiple queries for same entity (inefficient)
find_entity_by_name("My Service")  // Query 1
find_entity_by_name("My Service")  // Query 2
```

**Solution:** Cache entity IDs in Entities_Reference.md and reuse them!

### ❌ Mistake #3: Not Filtering BizEvents by event.type
```dql
// ❌ Scans ALL events
fetch bizevents, from:now()-7d
| filter customField == "value"
```

**Solution:** Filter by event.type FIRST:
```dql
// ✅ Scans only specific event type
fetch bizevents, from:now()-7d
| filter event.type == "specific.event.type"
| filter customField == "value"
```

### ❌ Mistake #4: Fetching Raw Logs Without loglevel Filter
```dql
// ❌ COST: 85 GB
fetch logs, from:now()-24h
| filter contains(content, "error")
```

**Solution:** Always filter by loglevel first:
```dql
// ✅ COST: 10 GB
fetch logs, from:now()-24h
| filter loglevel == "ERROR"
| filter contains(content, "keyword")
```

### ❌ Mistake #5: Using Spans When Metrics Exist
```dql
// ❌ COST: 125 GB
fetch spans, from:now()-7d
| filter dt.entity.service == "SERVICE-ID"
| summarize count()
```

**Solution:** Use free metrics:
```dql
// ✅ COST: 0 GB
timeseries { requests = sum(dt.service.request.count) },
from:now()-7d, interval:1d, filter:{dt.entity.service == "SERVICE-ID"}
```

### ❌ Mistake #6: Using `user_action` as a Data Object (Verified 2026-03-13)
```dql
// ❌ DQL-SYNTAX-ERROR: "user_action isn't a valid data object"
fetch user_action, from:now()-7d
| filter name == "ISO Checkout Summary"
```

**Solution:** Use `user.events` with `characteristics.classifier` filter:
```dql
// ✅ CORRECT: Find user actions in the user.events table
fetch user.events, from:now()-7d
| filter characteristics.classifier == "user_action"
| filter user_action.type == "custom"
| summarize count = count(), by:{name, ui_element.detected_name}
| sort count desc
```

### ❌ Mistake #7: Filtering user.events by URL Domain String (Verified 2026-03-13)
```dql
// ❌ COST: ~174 GB for 3d — EXTREMELY EXPENSIVE
fetch user.events, from:now()-3d
| filter page.url.domain == "www.[CLIENT_WEBSITE]"
| summarize count()
```

**Solution:** Filter by URL path (exact match) with classifier pre-filter:
```dql
// ✅ COST: ~2-5 GB for 3d
fetch user.events, from:now()-3d
| filter page.url.path == "/your/bookings/"
| filter characteristics.classifier == "user_action"
| summarize count = count(), by:{user_action.type}
```

### ❌ Mistake #8: Using dt.entity.application on user.sessions (Verified 2026-03-13)
```dql
// ❌ Returns 0 results — dt.entity.application is ALWAYS NULL
fetch user.sessions, from:now()-3d
| filter dt.entity.application == "APPLICATION-XXXXXXXXXXXX"
| summarize sessions = count()
```

**Solution:** Use `frontend.name` or `in(dt.rum.application.entities, ...)`:
```dql
// ✅ Returns correct session count
fetch user.sessions, from:now()-3d
| filter frontend.name == "[APP_NAME]"
| summarize sessions = count()
```

### ❌ Mistake #9: Using action.name field on user.events (Verified 2026-03-13)
```dql
// ❌ action.name does NOT exist on Gen3 user.events — always null
fetch user.events, from:now()-24h
| filter action.name == "ISO Checkout Summary"
```

**Solution:** Use `name` field (but note it's often null for auto-detected XHR actions):
```dql
// ✅ For custom actions from dtrum.enterAction():
fetch user.events, from:now()-24h
| filter characteristics.classifier == "user_action" and user_action.type == "custom"
| summarize count = count(), by:{name}
```

---

## 📊 Dashboard Tile Generation Rules (Gen 3, Version 20)

> **Discovered:** 2026-03-10 during Ecommerce Funnel dashboard build  
> **Critical:** Follow these rules when generating dashboard JSON to avoid visualization errors

### Line Charts — Time-Series Data

**Problem:** `summarize ... by:{timeframe = bin(timestamp, 1d)}` produces `timeframe` with type "Undefined". Line charts reject it with "Select a timestamp or timeframe field".

**Solution:** Always use `makeTimeseries` which produces a properly-typed `timeframe` column.

```dql
// ❌ BROKEN — bin() produces Undefined type
| summarize sessions = count(), by:{funnel_step, timeframe = bin(timestamp, 1d)}

// ❌ BROKEN — toTimestamp wrapper still produces null
| summarize sessions = count(), by:{funnel_step, time_bucket = bin(timestamp, 1d)}
| fieldsAdd timeframe = toTimestamp(time_bucket)

// ✅ WORKS — makeTimeseries produces native timeframe column
| makeTimeseries sessions = count(), by:{funnel_step}, interval:1d
```

**Visualization settings for line charts:**
```json
{
  "fieldMapping": {
    "leftAxisValues": ["sessions"],
    "leftAxisDimensions": ["funnel_step"],
    "timestamp": "timeframe"
  }
}
```

**makeTimeseries limitations:**
- Supports: `count()`, `sum()`, `avg()`, `min()`, `max()`, `percentile()`
- Does NOT support: `countDistinct()` — use `count()` as proxy, or use `sum()` with a flag field
- Array operations on output: use `[]` suffix, e.g. `| fieldsAdd p75_ms = p75_ns[] / 1000000`

**Pattern for conversion rate (avoiding countDistinct):**
```dql
| fieldsAdd is_homepage = if(page.url.path == "/your-location/", 1, else: 0),
           is_confirmation = if(page.url.path == "/thank-you/", 1, else: 0)
| makeTimeseries homepage_views = sum(is_homepage), 
                 confirmation_views = sum(is_confirmation), interval:1d
| fieldsAdd conversion_rate = (confirmation_views[] / homepage_views[]) * 100
```

### Bar Charts — Categorical Data (Non-Time-Based)

**Problem:** `barChart` visualization always requires a `timestamp` field in its data mapping, even for categorical bar charts. Without it: "Select a timestamp or timeframe field".

**Solution:** Append `| fieldsAdd timeframe = now()` to the query and add `"timestamp": "timeframe"` to fieldMapping.

```dql
// ✅ WORKS — categorical bar chart with dummy timeframe
| summarize sessions = toDouble(countDistinct(dt.rum.session.id)), by:{funnel_step}
| sort funnel_step asc
| fieldsAdd timeframe = now()
```

**Visualization settings for categorical bar charts:**
```json
{
  "fieldMapping": {
    "timestamp": "timeframe",
    "categoryAxisValues": ["funnel_step"],
    "leftAxisValues": ["sessions"]
  },
  "categoricalBarChartSettings": {
    "layout": "horizontal"
  }
}
```

**categoricalBarChartSettings rules:**
- Only use `"layout"` property (values: `"horizontal"`, `"grouped"`, `"stacked"`)
- Do NOT include `"categoryAxis"`, `"valueAxis"`, or `"categoryAxisTickLayout"` — these cause conflicts
- Field assignments belong in `fieldMapping`, not in `categoricalBarChartSettings`

### Bar Charts — Time-Based (Daily Bars)

**Problem:** Same as line charts — `bin()` produces Undefined type.

**Solution:** Use `makeTimeseries` with `interval:1d`.

```dql
// ✅ WORKS — time-based bar chart
| makeTimeseries confirmations = count(), interval:1d
```

**Visualization settings for time-based bar charts:**
```json
{
  "fieldMapping": {
    "timestamp": "timeframe",
    "leftAxisValues": ["confirmations"]
  }
}
```

### DQL Function Gotchas

| Issue | Broken Pattern | Working Pattern |
|-------|---------------|-----------------|
| `countDistinctIf` doesn't exist | `countDistinctIf(condition)` | `countDistinct(if(condition, field, null))` |
| `if()` returns variant type | Bar chart shows "Data not suitable" | Wrap in `toString()` for categories, `toDouble()` for values |
| `bin()` produces Undefined type | `timeframe = bin(timestamp, 1d)` | Use `makeTimeseries ... interval:1d` |
| Unmapped fields show as "Unsuitable" | Query outputs fields not in fieldMapping | Only output fields used by the visualization |

### Quick Reference: Tile Type → DQL Pattern

| Tile Type | Visualization | DQL Approach | Required fieldMapping |
|-----------|--------------|--------------|----------------------|
| KPI card | `singleValue` | `summarize` | `recordField` in singleValue settings |
| Categorical bar | `barChart` | `summarize` + `fieldsAdd timeframe = now()` | `timestamp`, `categoryAxisValues`, `leftAxisValues` |
| Time-based bar | `barChart` | `makeTimeseries` | `timestamp`, `leftAxisValues` |
| Line chart | `lineChart` | `makeTimeseries` | `timestamp`, `leftAxisValues`, optionally `leftAxisDimensions` |
| Table | `table` | `summarize` | None (auto-mapped) |
| Markdown | `markdown` | N/A | N/A |

---

## 🎓 Learning from Sessions

As you use this workspace, document patterns:
1. What queries cost most?
2. What alternative approaches work better?
3. What entity IDs get reused frequently?
4. What event types have highest volume?

Update the reference files after EVERY session to build institutional knowledge!
