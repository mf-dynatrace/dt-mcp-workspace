# MCP Query Tracking - Event Schema

## Overview
When `MCP_SEND_TRACKING_EVENTS=yes` in `.env` (default), `send_event` (CUSTOM_INFO) is called after each MCP query execution. These events land in `fetch events` (**not** `fetch bizevents`).

**When `MCP_SEND_TRACKING_EVENTS=no`:** This entire schema is not used. No tracking events are sent.

## Event Schema

### Event Identification
- **event.type:** `CUSTOM_INFO` (set by `send_event` eventType)
- **event.name:** `MCP Query Execution` (set by `send_event` title)
- **event.kind:** `DAVIS_EVENT` (auto-set by Events API v2)
- **event.provider:** `EVENTS_REST_API_INGEST` (auto-set)

### Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `event.type` | string | Event type identifier | `"mcp.query.execution"` |
| `query.dql` | string | DQL query executed (truncate if >1000 chars) | `"fetch logs, from: now()-24h..."` |
| `query.bytes_scanned` | string | Data scanned in GB | `"0.84"` |
| `query.records_scanned` | string | Number of records processed | `"6723074"` |
| `query.records_returned` | string | Number of records returned | `"100"` |
| `user.id` | string | User executing the query (from MCP_USER_ID env). **Omit if `MCP_USE_USER_VARIABLE=no`.** | `"user@company.com"` |
| `budget.total_gb` | string | Total budget in GB | `"1000"` |
| `budget.consumed_gb` | string | Budget consumed so far in session | `"0.84"` |
| `budget.percentage_used` | string | Percentage of budget used | `"0.1"` |
| `query.source` | string | Source of query | `"MCP"` |
| `query.tool` | string | Specific MCP tool used | `"execute_dql"` |
| `query.cost_usd` | string | Estimated cost in USD (bytes_scanned * 0.05) | `"0.042"` |
| `query.success` | string | Whether query succeeded | `"true"` |
| `query.data_object` | string | Primary data object queried | `"logs"` |

### Optional Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `query.id` | string | Dynatrace query ID | `"2d2b3abc-6eec-4cc8-8f6e-cf8f284336b2"` |
| `query.timeframe_start` | string | Query timeframe start | `"now()-24h"` |
| `query.timeframe_end` | string | Query timeframe end | `"now()"` |
| `query.error` | string | Error message if query failed | `"UNKNOWN_DATA_OBJECT"` |
| `entity.filter` | string | Entity filter used | `"dt.entity.service == \"SERVICE-123\""` |

## Example Event Properties

When calling `send_event`, all tracking data goes into the `properties` object:

```json
{
  "eventType": "CUSTOM_INFO",
  "title": "MCP Query Execution",
  "properties": {
    "event.type": "mcp.query.execution",
    "query.dql": "fetch logs | filter loglevel == \"ERROR\" | limit 100",
    "query.bytes_scanned": "0.84",
    "query.records_scanned": "6723074",
    "query.records_returned": "100",
    "user.id": "user@company.com",
    "budget.total_gb": "1000",
    "budget.consumed_gb": "0.84",
    "budget.percentage_used": "0.1",
    "query.source": "MCP",
    "query.tool": "execute_dql",
    "query.cost_usd": "0.042",
    "query.success": "true",
    "query.data_object": "logs"
  }
}
```

## Implementation Notes

### Via Copilot / MCP Tool
The `send_event` MCP tool is used directly after each query:
1. AI executes an MCP tool (execute_dql, list_problems, etc.)
2. Extracts usage metrics from the response
3. Calls `send_event` with eventType `CUSTOM_INFO`, title `MCP Query Execution`, and all tracking properties
4. Events land in `fetch events` (NOT `fetch bizevents`)

### Cost Calculation
Assuming $0.05 per GB scanned (adjust based on actual Dynatrace pricing):
```
cost_usd = bytes_scanned_gb * 0.05
```

### FREE Tools (No Data Scanned)
For these tools, set `query.bytes_scanned: "0"` and `query.cost_usd: "0"`:
- `find_entity_by_name`
- `list_problems`
- `list_vulnerabilities`
- `timeseries` queries

### Important: Events vs BizEvents
| Aspect | send_event (what we use) | BizEvents API |
|--------|--------------------------|---------------|
| **API** | Events API v2 | BizEvents Ingest API |
| **Query with** | `fetch events` | `fetch bizevents` |
| **event.type** | `CUSTOM_INFO` | Custom (e.g. `mcp.query.execution`) |
| **Identifier** | `event.name == "MCP Query Execution"` | `event.type == "mcp.query.execution"` |
| **Auth** | Platform Token (dt0s16) | Classic API Token (dt0c01) |

## Dashboard Queries

Events are queried via `fetch events` (NOT `fetch bizevents`):

### Total Queries
```dql
fetch events
| filter event.type == "CUSTOM_INFO" and event.name == "MCP Query Execution"
| summarize queries = count()
```

### Total Data Scanned Over Time
```dql
fetch events
| filter event.type == "CUSTOM_INFO" and event.name == "MCP Query Execution"
| makeTimeseries data_scanned_gb = sum(toDouble(query.bytes_scanned)), bins:50
```

### Top Users by Consumption
```dql
fetch events
| filter event.type == "CUSTOM_INFO" and event.name == "MCP Query Execution"
| summarize total_gb = sum(toDouble(query.bytes_scanned)), queries = count(), by: {user.id}
| sort total_gb desc
```

### Most Expensive Queries
```dql
fetch events
| filter event.type == "CUSTOM_INFO" and event.name == "MCP Query Execution"
| sort toDouble(query.bytes_scanned) desc
| limit 10
| fields timestamp, user.id, query.dql, query.bytes_scanned, query.cost_usd
```

### Budget Tracking
```dql
fetch events
| filter event.type == "CUSTOM_INFO" and event.name == "MCP Query Execution"
| sort timestamp desc
| limit 1
| fields budget.consumed_gb, budget.percentage_used
```

## See Also
- `example/MCP_Query_Usage_Dashboard.json` - Pre-built dashboard for MCP usage monitoring
- `CLAUDE.md` - AI instructions including mandatory tracking protocol
