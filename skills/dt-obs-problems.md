# Problem Analysis Skill
> Source: [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — `dt-obs-problems`

Analyze Dynatrace AI-detected problems including root cause, impact assessment, and correlation.

---

## Problem Categories

| Category | Description | Example |
|----------|-------------|---------|
| **AVAILABILITY** | Infrastructure or service unavailable | Web service returns no data |
| **ERROR** | Increased error rates beyond baseline | API error rate jumped from 0.1% to 15% |
| **SLOWDOWN** | Performance degradation | Response time increased from 200ms to 5000ms |
| **RESOURCE** | Resource saturation | Container memory at 95%, causing OOM kills |
| **CUSTOM** | Custom anomaly detections | Business KPI dropped below threshold |

## Problem Lifecycle
```
Detection → ACTIVE → Under Investigation → CLOSED
```

---

## Common Field Name Mistakes

| ❌ WRONG | ✅ CORRECT | Description |
|---------|-----------|-------------|
| `title` | `event.name` | Problem title/description |
| `status` | `event.status` | Problem lifecycle status |
| `severity` | `event.category` | Problem type/category |
| `start` | `event.start` | Problem start time |
| `event.status == "OPEN"` | `event.status == "ACTIVE"` | OPEN does not exist! |

---

## Standard Query Pattern

```dql
fetch dt.davis.problems, from:now() - 2h
| filter not(dt.davis.is_duplicate) and event.status == "ACTIVE"
| fields event.start, display_id, event.name, event.category
| sort event.start desc | limit 20
```

---

## Key Fields Reference

```dql
fetch dt.davis.problems, from:now() - 1h
| filter not(dt.davis.is_duplicate)
| fields
    event.start,                          // Problem start timestamp
    event.end,                            // Problem end timestamp (if closed)
    display_id,                           // Human-readable problem ID (P-XXXXX)
    event.name,                           // Problem title
    event.description,                    // Detailed description
    event.category,                       // Problem type
    event.status,                         // ACTIVE or CLOSED
    dt.davis.affected_users_count,        // Number of affected users
    smartscape.affected_entity.ids,       // Array of affected entity IDs
    dt.davis.root_cause_entity,           // Root cause entity
    root_cause_entity_id,                 // Root cause entity ID
    root_cause_entity_name,               // Human-readable root cause name
    dt.davis.is_duplicate,                // Duplicate detection
    dt.davis.is_rootcause                 // Root cause vs. symptom
| limit 10
```

---

## Entity Filter Rules

**DO** use array-safe filters with both deprecated and Smartscape fields:
```dql
| filter in(dt.entity.service, "SERVICE-00E66996F1555897") or in(dt.smartscape.service, toSmartscapeId("SERVICE-00E66996F1555897"))
```

**DON'T** use scalar equality (not array-safe):
```dql
// Wrong: | filter dt.entity.service == "SERVICE-00E66996F1555897"
```

---

## Root Cause Analysis

### Basic Root Cause Query
```dql
fetch dt.davis.problems, from:now() - 24h
| filter not(dt.davis.is_duplicate) and event.status == "ACTIVE"
| fields display_id, event.name, event.description, root_cause_entity_id, root_cause_entity_name, smartscape.affected_entity.ids
```

### Recurring Root Causes
```dql
fetch dt.davis.problems, from:now() - 24h
| filter not(dt.davis.is_duplicate) and isNotNull(root_cause_entity_id)
| summarize
    problem_count = count(),
    first_occurrence = min(event.start),
    last_occurrence = max(event.start),
    by:{root_cause_entity_id, root_cause_entity_name}
| filter problem_count > 3
| sort problem_count desc
```

### Problem Blast Radius
```dql
fetch dt.davis.problems, from:now() - 7d
| filter not(dt.davis.is_duplicate) and isNotNull(root_cause_entity_id)
| fieldsAdd affected_count = arraySize(smartscape.affected_entity.ids)
| summarize
    avg_affected = avg(affected_count),
    max_affected = max(affected_count),
    problem_count = count(),
    by:{root_cause_entity_name}
| sort avg_affected desc
```

---

## Best Practices

1. **Always filter duplicates**: `not(dt.davis.is_duplicate)`
2. **Use correct status values**: `"ACTIVE"` or `"CLOSED"`, never `"OPEN"`
3. **Specify time ranges**: Always include time bounds
4. **Include display_id**: Essential for identification and linking
5. **Filter early**: Apply `not(dt.davis.is_duplicate)` immediately after fetch
6. **Always filter `isNotNull(root_cause_entity_id)`** when querying root causes
