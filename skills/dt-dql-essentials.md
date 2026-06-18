# DQL Essentials Skill
> Source: [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — `dt-dql-essentials`

DQL is a pipeline-based query language. Queries chain commands with `|` to filter, transform, and aggregate data. DQL has unique syntax that differs from SQL — load this skill before writing any DQL query.

---

## Syntax Pitfalls

| ❌ Wrong | ✅ Right | Issue |
|----------|---------|-------|
| `filter field in ["a", "b"]` | `filter in(field, "a", "b")` | No array literal syntax |
| `by: severity, status` | `by: {severity, status}` | Multiple grouping fields require curly braces |
| `contains(toLowercase(field), "err")` | `contains(lower(field), "err")` or `contains(field, "err", caseSensitive: false)` | There's no function for `toLowerCase` in DQL |
| `filter name == "*serv*9*"` | `filter contains(name, "serv")` | Mid-string wildcards not allowed; use `contains()` |
| `matchesValue(field, "prod")` on string field | `contains(field, "prod")` | `matchesValue()` is for array fields only |
| `toLowercase(field)` | `lower(field)` | The correct function in DQL is called `lower` |
| `arrayAvg(field[])` or `arraySum(field[])` | `arrayAvg(field)` or `field[]` | `field[]` = element-wise (array→array); `arrayAvg(field)` = collapse to scalar. Never mix both. |
| `my_field` after `lookup` or `join` | `lookup.my_field` / `right.my_field` | `lookup` prefixes fields with `lookup.`; `join` prefixes right-side fields with `right.` |
| Chained `lookup` losing fields | `fieldsRename` between lookups | Each `lookup` **removes all existing `lookup.*` fields**. Rename after each lookup to preserve results |
| `substring(field, 0, 200)` | `substring(field, from: 0, to: 200)` | DQL functions use **named parameters** — positional args cause `TOO_MANY_POSITIONAL_PARAMETERS` |
| `filter log.level == "ERROR"` | `filter loglevel == "ERROR"` | Log severity field is `loglevel` (no dot) — `log.level` does not exist |
| `sort count() desc` | `` sort `count()` desc `` | Fields with special characters must use backticks |

---

## Fetch Command → Data Model

Each data model has a specific fetch command — using the wrong one returns no results.

| Fetch Command | Data Model | Key Fields / Notes |
|---------------|------------|--------------------|
| `fetch spans` | Distributed tracing | `span.*`, `service.*`, `http.*`, `db.*`, `code.*`, `exception.*` |
| `fetch logs` | Log events | `log.*`, `k8s.*`, `host.*` — message body is `content`, severity is `loglevel` (NOT `log.level`) |
| `fetch events` | Davis / infra events | `event.*`, `dt.smartscape.*` |
| `fetch bizevents` | Business events | `event.*`, custom fields |
| `fetch securityEvents` | Security events | `vulnerability.*`, `event.*` |
| `fetch user.sessions` | RUM sessions | `dt.rum.*`, `browser.*`, `geo.*` |
| `fetch user.events` | RUM individual events | page views, clicks, requests, errors |
| `timeseries` | Metrics | NOT `fetch` — uses `timeseries avg(metric.key)` syntax |

Legacy compatibility: `dt.entity.*` still works in older queries, but it is deprecated. Use `dt.smartscape.*` and `smartscapeNodes` for all new queries.

Metric-key note: keys containing **hyphens** are parsed as subtraction. Use backticks: `` timeseries sum(`my.metric-name`) ``

---

## Data Objects

DQL queries start with `fetch <data_object>` or `timeseries`. There is **no `fetch dt.metric`** or `fetch dt.metrics` — metrics are queried with `timeseries`.

**Core data objects for `fetch`:**

| Data Object | Description |
|-------------|-------------|
| `logs` | Log entries |
| `spans` | Distributed traces / spans |
| `events` | Platform events |
| `bizevents` | Business events |
| `user.events` | RUM individual events (page views, clicks, requests, errors) |
| `user.sessions` | RUM session-level aggregates |
| `user.replays` | Session replay recordings |
| `security.events` | Security events |
| `application.snapshots` | Application snapshots |
| `dt.smartscape.<type>` | Smartscape entity fields (e.g., `dt.smartscape.host`, `dt.smartscape.service`) |
| `dt.davis.problems` | DAVIS-detected problems |
| `dt.davis.events` | DAVIS events |

**Metrics** — use `timeseries`, not `fetch`:
```dql
timeseries cpu = avg(dt.host.cpu.usage), by: {dt.smartscape.host}
```

**Topology** — use `smartscapeNodes`, not `fetch`:
```dql
smartscapeNodes "HOST"
```

**Discover available data objects:**
```dql
fetch dt.system.data_objects | fields name, display_name, type
```

---

## Metric Discovery

To search for available metrics by keyword, use `metric.series`:

```dql
fetch metric.series, from: now() - 1h
| filter contains(metric.key, "replay")
| summarize count(), by: {metric.key}
| sort `count()` desc
```

---

## Entity Field Patterns

Entity fields in DQL are scoped to specific entity types — not universal like SQL columns.

- `entity.id` **does not exist** — use a typed field such as `dt.smartscape.host`.

| Entity | ID field |
|--------|----------|
| Host | `dt.smartscape.host` |
| Service | `dt.smartscape.service` |
| Process | `dt.smartscape.process` |
| Kubernetes cluster | `dt.smartscape.k8s_cluster` |

- For topology traversal and relationships, use `smartscapeNodes` instead of `fetch`.

---

## Smartscape Entity Patterns

Use `smartscapeNodes` for topology queries. Node types are uppercase strings and differ from field names.

| Entity | Field name | `smartscapeNodes` type |
|--------|-----------|----------------------|
| Host | `dt.smartscape.host` | `"HOST"` |
| Service | `dt.smartscape.service` | `"SERVICE"` |
| K8s cluster | `dt.smartscape.k8s_cluster` | `"K8S_CLUSTER"` |

Use `toSmartscapeId()` for ID conversion from strings (required!).

---

## matchesValue() Usage

Use `matchesValue()` for **array fields** such as `dt.tags`:

```dql
| filter matchesValue(dt.tags, "env:production")
```

- **Not** for string fields with special characters — use `contains()` for those
- `matchesValue()` on a scalar string field does not behave like a wildcard or fuzzy match

---

## Chained Lookup Pattern

Each `lookup` command **removes all existing fields starting with `lookup.`** before adding new ones. When chaining multiple lookups, use `fieldsRename` after each to preserve the result:

```dql
fetch bizevents
// Step 1: First lookup
| lookup [fetch bizevents
    | filter event.type == "product_catalog"
    | fields product_id, category],
  sourceField: product_id, lookupField: product_id

// Step 2: Rename BEFORE next lookup
| fieldsRename product_category = lookup.category

// Step 3: Second lookup — lookup.* is now clean
| lookup [fetch bizevents
    | filter event.type == "warehouse_stock"
    | fields category, warehouse_region],
  sourceField: product_category, lookupField: category
```

---

## makeTimeseries Command

`makeTimeseries` converts event-based data (logs, spans, bizevents) into a time-bucketed metric series. It is **not** the same as the `timeseries` command — `timeseries` queries pre-ingested metric data; `makeTimeseries` builds a series from signals in a pipeline.

**Basic syntax:**
```dql
fetch logs
| makeTimeseries count = count(), by: {loglevel}, interval: 5m
```

**Key parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `<agg> = <expr>` | Yes | Aggregation to compute per bucket (e.g. `count()`, `avg(duration)`) |
| `interval:` | No | Bucket size — e.g. `1m`, `5m`, `1h` |
| `by:` | No | Optional grouping dimensions (same `{}` syntax as `summarize`) |
| `from:` / `to:` | No | Explicit time range |
| `bins:` | No | Number of time buckets (alternative to `interval:`) |
| `time:` | No | Field to use as the timestamp; defaults to `timestamp` |
| `spread:` | No | Timeframe expression for bucket calculation |
| `nonempty:` | No | Boolean; when `true`, fills missing time buckets with null |

**Example — error rate timeseries from logs:**
```dql
fetch logs
| makeTimeseries
    total = count(),
    errors = countIf(loglevel == "ERROR"),
    interval: 5m,
    by: {k8s.cluster.name}
| fieldsAdd error_rate = errors / total * 100
```

---

## Timeframe Specification

Access to data requires specification of a timeframe. Can use `from:` and `to:` (if one is omitted it defaults to `now()`), or `timeframe:`.

### Examples
```dql
from:now()-1h@h, to:now()@h     // last complete hour
from:now()-1d@d, to:now()@d     // yesterday complete
from:now()@M                    // this month so far
from:now()-2h@h                 // go back 2 hours, align to hour
```

### Absolute timestamps
Use ISO 8601 format:
```dql
from:"2024-01-15T08:00:00Z", to:"2024-01-15T09:00:00Z"
```

---

## Modifying Time

### Key concepts
- **timestamp** — nanoseconds since epoch, exposed as date/time
- **timeframe** — a pair of 2 timestamps (start and end)
- **duration** — nanoseconds, exposed as scaled duration (ms, minutes, days)

### Rules
- `timestamp - timestamp → duration`
- `duration / duration → double` (e.g. `2h / 1m` = `120.0`)
- `scalar * duration → duration` (e.g. `no_of_h * 1h → duration`)
- ✅ Use time functions for extraction (support calendar/DST)
- ❌ Avoid `formatTimestamp` for extracting time components
- ❌ Avoid converting to double/long with division/modulo

---

## DQL Commands Reference

`append`, `data`, `dedup`, `describe`, `expand`, `fetch`, `fields`, `fieldsAdd`, `fieldsFlatten`, `fieldsKeep`, `fieldsRemove`, `fieldsRename`, `fieldsSnapshot`, `fieldsSummary`, `filter`, `filterOut`, `join`, `joinNested`, `limit`, `load`, `lookup`, `makeTimeseries`, `metrics`, `parse`, `search`, `smartscapeEdges`, `smartscapeNodes`, `sort`, `summarize`, `timeseries`, `traverse`

## DQL Aggregation Functions

`avg`, `collectArray`, `collectDistinct`, `correlation`, `count`, `countDistinct`, `countDistinctApprox`, `countDistinctExact`, `countIf`, `max`, `median`, `min`, `percentRank`, `percentile`, `percentileFromSamples`, `percentiles`, `stddev`, `sum`, `takeAny`, `takeFirst`, `takeLast`, `takeMax`, `takeMin`, `variance`

## DQL String Functions

`concat`, `contains`, `endsWith`, `indexOf`, `lastIndexOf`, `like`, `lower`, `matchesPattern`, `matchesPhrase`, `matchesRegex`, `matchesValue`, `replacePattern`, `replaceString`, `splitString`, `startsWith`, `stringLength`, `substring`, `trim`, `upper`

## DQL Boolean Functions

`exists`, `in`, `isFalseOrNull`, `isNotNull`, `isNull`, `isTrueOrNull`

## DQL Array Functions

`arrayAvg`, `arrayConcat`, `arrayCumulativeSum`, `arrayDelta`, `arrayDiff`, `arrayDistinct`, `arrayFirst`, `arrayFlatten`, `arrayIndexOf`, `arrayLast`, `arrayMax`, `arrayMedian`, `arrayMin`, `arrayMovingAvg`, `arraySize`, `arraySlice`, `arraySort`, `arraySum`, `arrayToString`
