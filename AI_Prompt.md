# Dynatrace AI Assistant Instructions

> **Environment:** [TENANT_ID]  
> **Client:** [CLIENT_NAME]  
> **IMPORTANT:** Always read `.env` feature flags and `reference/MCP_Query_Optimization_Guide.md` before making any Dynatrace MCP queries

---

## 🏷️ Feature Flags (from `.env`)

Before starting any task, ensure the AI has read `.env` and resolved these flags:

| Flag | Default | Effect |
|------|---------|--------|
| `MCP_GRAIL_ONLY` | `yes` | `yes` = Gen 3 Grail DQL only. `no` = Gen 2 USQL & classic APIs also available. |
| `MCP_USE_USER_VARIABLE` | `yes` | `yes` = resolve `MCP_USER_ID` for tracking. `no` = skip user identity. |
| `MCP_SEND_TRACKING_EVENTS` | `yes` | `yes` = send CUSTOM_INFO event after every query. `no` = skip tracking. |

---

## 🚨 CRITICAL: MCP Query Cost Optimization

Before using ANY Dynatrace MCP tools, follow these rules to minimize Grail budget consumption:

### Query Cost Hierarchy (Use in Order)
1. **FREE:** `find_entity_by_name`, `list_problems`, `list_vulnerabilities`, metrics timeseries
2. **LOW (0-5 GB):** BizEvents with `event.type` filter + additional filters + 7d
3. **MEDIUM (10-20 GB):** Logs with loglevel filter + 24h, Spans with entity filter + 24h
4. **HIGH (100+ GB):** Spans 7d, Logs without filters - AVOID unless necessary

### Mandatory Practices
- **Always use `find_entity_by_name` FIRST** to get entity IDs (costs 0 GB)
- **Use `timeseries` for metrics** instead of `fetch spans` (free vs 100+ GB)
- **Start with 24h timeframe**, only extend to 7d after validating query
- **Filter BizEvents by `event.type` BEFORE other filters**
- **Use `summarize` aggregations** - never fetch raw data for exploration
- **Set `recordLimit: 10-20`** for exploration queries

### Known Entity IDs (Cache These)
| Entity Name | Entity ID | Type |
|-------------|-----------|------|
| *(Populate from reference/Entities_Reference.md)* | | |

### High-Volume Events (Add Extra Filters)
| Event Type | Volume | Required Filters |
|------------|--------|------------------|
| *(Populate from reference/BizEvents_Reference.md)* | | |

---

## Standard Task Templates

### Template 1: New Customer Dashboard
You are a Dynatrace Solutions Engineer. Your customer is [CLIENT_NAME] and their website is www.[CLIENT_WEBSITE].  
You need to research what business KPIs are important to them.
With that research data, you need to create a demonstration Dynatrace Dashboard and injection javascript for business events that will run every hour in a dynatrace workflow.  
The dashboard must be a Gen 3 Dashboard, not a dynatrace classic dashboard. Use the examples in the example directory of my workspace for proper json and javascript syntax.
Change the colours of the dashboard to match the branding colours of the company.

### Template 2: Error Analysis Dashboard
Analyse the application errors and exceptions.
You need to research what errors are occurring and their business impact.
With that research data, you need to create a demonstration Dynatrace Dashboard.
The dashboard must be a Gen 3 Dashboard, not a dynatrace classic dashboard. Use the examples in the example directory of my workspace for proper json and javascript syntax.
Change the colours of the dashboard to match the branding colours of the company.

### Template 3: Service Performance Dashboard
Create a service performance dashboard for [SERVICE_NAME].
Include: request volume, response times, error rates, and trends.
Use brand colours from their website.
Add service dependencies and topology insights.
Focus on SLO-relevant metrics.

### Template 4: Infrastructure Overview Dashboard
Create an infrastructure health dashboard.
Include: host metrics (CPU, memory, disk), container health, Kubernetes status.
Highlight anomalies and capacity concerns.
Use appropriate thresholds for traffic light indicators.

### Template 5: Business Analytics Dashboard
Create a business-aligned analytics dashboard for [USE_CASE].
**IMPORTANT:** Read reference/BizEvents_Reference.md and reference/Entities_Reference.md FIRST before any queries.
Research available BizEvents data:
1. Use cached entity IDs from reference/Entities_Reference.md (avoid find_entity_by_name)
2. Query BizEvents with `event.type` filter first
3. Start with 24h timeframe for exploration
Include: key business KPIs, conversion funnels, revenue metrics.
Add trend analysis and comparisons.

### Template 6: Brand/Product Comparison Dashboard
Create a multi-brand or multi-product comparison dashboard.
**IMPORTANT:** Read reference/BizEvents_Reference.md and reference/Entities_Reference.md FIRST before any queries.
Compare: revenue, orders, conversion rates, error rates across brands/products.
Use consistent color coding and visualizations.
Highlight top and bottom performers.
Include sparklines for trend visibility.

---

## Reference Documents & Reading Order

### ALWAYS Read First (Before ANY Queries)
1. **reference/DATA_REFERENCE_INDEX.md** - Central index and quick lookups
2. **reference/Entities_Reference.md** - Cached entity IDs (avoid repeat lookups)
3. **reference/MCP_Query_Optimization_Guide.md** - Cost rules and best practices

### Read Based on Task Type
- **BizEvents analysis:** reference/BizEvents_Reference.md
- **Service performance:** reference/Spans_Reference.md + reference/Metrics_Reference.md
- **Error investigation:** reference/Logs_Reference.md
- **Infrastructure:** reference/Entities_Reference.md

### Use for Examples
- **example/ directory** - Gen 3 Dashboard JSON and JavaScript syntax

---
- `reference/MCP_Query_Optimization_Guide.md` - Full query optimization guide with examples
- `reference/BizEvents_Reference.md` - All available BizEvent types and fields
- `reference/Spans_Reference.md` - Span patterns and service baselines
- `reference/Logs_Reference.md` - Log patterns and error signatures
- `reference/Metrics_Reference.md` - Available metrics (FREE queries)
- `reference/Entities_Reference.md` - Cached entity IDs
- `reference/scope_increase.md` - Token scope gaps & required permission fixes
- `reference/mcp_query_tracking_schema.md` - MCP telemetry event schema
- `example/` directory - Gen 3 Dashboard JSON and JavaScript syntax examples (if available)

---

## Dashboard Best Practices

### Gen 3 Dashboard Requirements
- Use `"version": 20` in JSON
- Apply brand colours from company websites
- Include data source indicators (BizEvents, Spans, Logs, Metrics)
- Use appropriate visualizations for data type

### Standard Dashboard Sections
1. **Header** - Brand logo/name, time selector
2. **KPI Summary Row** - Key business metrics (single values)
3. **Trend Charts** - Primary metrics over time
4. **Breakdown Charts** - By dimension/category
5. **Service Performance** - From spans/metrics
6. **Error Analysis** - From logs/exceptions
7. **Health Indicators** - Traffic lights, thresholds
