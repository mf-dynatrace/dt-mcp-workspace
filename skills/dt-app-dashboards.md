# Dynatrace Dashboard Skill
> Source: [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — `dt-app-dashboards`

Create, modify, query, and analyze Dynatrace dashboards.

---

## Dashboard Structure

```json
{
  "name": "My Dashboard",
  "type": "dashboard",
  "content": {
    "version": 21,
    "variables": [],
    "tiles": {},
    "layouts": {}
  }
}
```

---

## Tiles

**Markdown tiles:** `{"type": "markdown", "content": "# Title"}`
**Data tiles:** `{"type": "data", "title": "...", "query": "...", "visualization": "..."}`

### Visualizations

| Type | Data Shape | Examples |
|------|-----------|---------|
| Time-series (MUST have time dimension) | `timeseries`/`makeTimeseries` | `lineChart`, `areaChart`, `barChart`, `bandChart` |
| Categorical (no time, `summarize...by:`) | `summarize...by:{field}` | `categoricalBarChart`, `pieChart`, `donutChart` |
| Single value/gauge | Single numeric record | `singleValue`, `meterBar`, `gauge` |
| Tabular/raw | Any data shape | `table`, `raw`, `recordList` |
| Distribution/status | | `histogram`, `honeycomb` |
| Geographic maps | | `choroplethMap`, `dotMap`, `connectionMap`, `bubbleMap` |
| Matrix/correlation | | `heatmap`, `scatterplot` |

---

## Layouts

**Grid:** 20 units wide. Common widths: Full (20), Half (10), Third (6-7), Quarter (5)
**Properties:** `x` (0-19), `y` (0+), `w` (1-20), `h` (1-20)

Each tile ID in `tiles` must have a corresponding entry in `layouts`.

---

## Variables

```json
{
  "version": 2, "key": "ServiceFilter", "type": "query",
  "visible": true, "editable": true,
  "input": "smartscapeNodes SERVICE | fields name",
  "multiple": false, "defaultValue": "*"
}
```

**Single-select:** `fetch logs | filter service.name == $ServiceFilter`
**Multi-select:** `fetch logs | filter in(service.name, array($ServiceFilter))`

---

## Dashboard Creation Workflow

1. Define purpose and load required skills/references
2. Explore available data fields/metrics
3. Plan structure: logic, variables, tiles, layout
4. Design and validate all DQL queries
5. Construct dashboard JSON
6. Validate JSON structure and queries
7. Deploy via Dynatrace API

---

## Best Practices

- Match tile IDs in `tiles` and `layouts`
- Use descriptive variable IDs
- Start with full-width headers (y=0)
- Optimize queries with `limit`/`summarize`
- Set version=21
- **No time-range filters in queries** unless explicitly requested
- Executive pattern: header + KPIs + trends
- Service Health pattern: RED metrics
- Infrastructure pattern: resource metrics + tables
