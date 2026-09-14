# Dashboard Template

Generic Gen3 dashboard template for RUM page interaction analysis. Substitute `$APP` and `$PAGE` throughout before deploying.

## Deploy Workflow

```bash
# 1. Write the JSON to a file in the dashboards/ directory
# 2. Validate JSON syntax
python3 -c "import json; json.load(open('dashboards/$FILENAME.json')); print('OK')"

# 3. Dry-run first
dtctl apply -f dashboards/$FILENAME.json --dry-run -o yaml

# 4. Deploy
dtctl apply -f dashboards/$FILENAME.json -o yaml
# On success, add the returned id to the JSON so future updates patch in place
```

## Naming Convention
`$ClientName - $PageName Interaction Behaviour`

---

## Dashboard JSON Template

```json
{
  "name": "$ClientName - $PageName Interaction Behaviour",
  "type": "dashboard",
  "content": {
    "version": 21,
    "variables": [],
    "tiles": {
      "0": {
        "type": "markdown",
        "content": "# 🔍 $PageName — Interaction Behaviour\n**App:** $APP | **Page:** $PAGE\n\nReal-user interaction data from Dynatrace Gen3 Grail RUM. Dynatrace does not produce visual X/Y heatmaps but provides richer, at-scale behavioural data: which elements were clicked, what they triggered, where users encountered friction, how performance affected engagement, and geo distribution of errors.\n\n> **Session Replay:** if `characteristics.has_replay` sessions are present, use Dynatrace Session Replay to watch individual journeys as a complement to this aggregated view."
      },
      "1": {
        "title": "",
        "type": "data",
        "query": "data record(a=\"📊 Page Volume & Performance\")",
        "visualization": "singleValue",
        "visualizationSettings": {
          "singleValue": { "labelMode": "none", "isIconVisible": true, "prefixIcon": "PulseIcon", "colorThresholdTarget": "background" },
          "autoSelectVisualization": false,
          "thresholds": [ { "id": 1, "field": "a", "title": "", "isEnabled": true, "rules": [ { "id": 1, "color": "#1976D2", "comparator": "!=", "value": "0" } ] } ]
        },
        "querySettings": { "maxResultRecords": 1000, "defaultScanLimitGbytes": 500, "maxResultMegaBytes": 100, "defaultSamplingRatio": 10, "enableSampling": false },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "2": {
        "type": "data",
        "title": "📄 Page Views",
        "query": "fetch user.events\n| filter frontend.name == \"$APP\" and page.name == \"$PAGE\" and characteristics.has_page_summary\n| summarize page_views = count()",
        "visualization": "singleValue",
        "visualizationSettings": { "singleValue": { "label": "Page Views", "recordField": "page_views", "isIconVisible": false } },
        "querySettings": { "maxResultRecords": 1000, "defaultScanLimitGbytes": 500, "maxResultMegaBytes": 100, "defaultSamplingRatio": 10, "enableSampling": false },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "3": {
        "type": "data",
        "title": "🖱️ Total Clicks",
        "query": "fetch user.events\n| filter frontend.name == \"$APP\" and page.name == \"$PAGE\" and characteristics.has_user_action and interaction.type == \"click\"\n| summarize clicks = count()",
        "visualization": "singleValue",
        "visualizationSettings": { "singleValue": { "label": "Clicks", "recordField": "clicks", "isIconVisible": false } },
        "querySettings": { "maxResultRecords": 1000, "defaultScanLimitGbytes": 500, "maxResultMegaBytes": 100, "defaultSamplingRatio": 10, "enableSampling": false },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "4": {
        "type": "data",
        "title": "⚡ Action Timeouts",
        "description": "Clicks on dead/broken elements that never responded",
        "query": "fetch user.events\n| filter frontend.name == \"$APP\" and page.name == \"$PAGE\" and characteristics.has_user_action and user_action.complete_reason == \"timeout\"\n| summarize timeouts = count()",
        "visualization": "singleValue",
        "visualizationSettings": {
          "singleValue": { "label": "Timeouts", "recordField": "timeouts", "colorThresholdTarget": "background", "isIconVisible": false },
          "thresholds": [ { "id": 1, "field": "timeouts", "title": "", "isEnabled": true, "rules": [
            { "id": 1, "color": { "Default": "#4FD5B0" }, "comparator": "==", "value": 0 },
            { "id": 2, "color": { "Default": "#C62239" }, "comparator": ">", "value": 0 }
          ] } ]
        },
        "querySettings": { "maxResultRecords": 1000, "defaultScanLimitGbytes": 500, "maxResultMegaBytes": 100, "defaultSamplingRatio": 10, "enableSampling": false },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "5": {
        "type": "data",
        "title": "⏱️ LCP P75 (ms)",
        "query": "fetch user.events\n| filter frontend.name == \"$APP\" and page.name == \"$PAGE\" and characteristics.has_page_summary\n| summarize lcp_p75_ns = percentile(web_vitals.largest_contentful_paint, 75)\n| fieldsAdd lcp_ms = round(toDouble(lcp_p75_ns) / 1000000, decimals: 0)\n| fields lcp_ms",
        "visualization": "singleValue",
        "visualizationSettings": {
          "singleValue": { "label": "LCP P75 (ms)", "recordField": "lcp_ms", "colorThresholdTarget": "background", "isIconVisible": false },
          "thresholds": [ { "id": 1, "field": "lcp_ms", "title": "", "isEnabled": true, "rules": [
            { "id": 1, "color": { "Default": "#4FD5B0" }, "comparator": "≤", "value": 2500 },
            { "id": 2, "color": { "Default": "#F8B000" }, "comparator": "≤", "value": 4000 },
            { "id": 3, "color": { "Default": "#C62239" }, "comparator": ">", "value": 4000 }
          ] } ]
        },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "6": {
        "title": "",
        "type": "data",
        "query": "data record(a=\"🖱️ Click Behaviour\")",
        "visualization": "singleValue",
        "visualizationSettings": {
          "singleValue": { "labelMode": "none", "isIconVisible": true, "prefixIcon": "PulseIcon", "colorThresholdTarget": "background" },
          "autoSelectVisualization": false,
          "thresholds": [ { "id": 1, "field": "a", "title": "", "isEnabled": true, "rules": [ { "id": 1, "color": "#2AB6F4", "comparator": "!=", "value": "0" } ] } ]
        },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "7": {
        "type": "data",
        "title": "🖱️ Clicks by Element Type",
        "description": "Distribution of click targets. 'input' = form/search field, 'h3' = product/section title, 'img' = image, 'a' = link, 'button' = explicit button.",
        "query": "fetch user.events\n| filter frontend.name == \"$APP\" and page.name == \"$PAGE\" and characteristics.has_user_action and interaction.type == \"click\"\n| summarize clicks = count(), by:{ui_element.tag_name}\n| sort clicks desc",
        "visualization": "categoricalBarChart",
        "visualizationSettings": {
          "colorModeType": { "colorPalette": "categorical" }
        },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "8": {
        "type": "data",
        "title": "🏷️ Named Element Breakdown",
        "description": "Semantic meaning behind generic element clicks. Only shows elements with a readable auto-detected name. See data-quality.md to improve unnamed coverage.",
        "query": "fetch user.events\n| filter frontend.name == \"$APP\" and page.name == \"$PAGE\" and characteristics.has_user_action and interaction.type == \"click\"\n| filter isNotNull(ui_element.detected_name) and ui_element.detected_name != \"masked\"\n| summarize clicks = count(), by:{ui_element.detected_name}\n| sort clicks desc\n| limit 20",
        "visualization": "categoricalBarChart",
        "visualizationSettings": { "colorModeType": { "colorPalette": "categorical" } },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "9": {
        "type": "data",
        "title": "🔀 What Did Clicks Trigger?",
        "description": "/api/* paths = background calls, /event /g/collect = analytics tags, other paths = page navigations",
        "query": "fetch user.events\n| filter frontend.name == \"$APP\" and page.name == \"$PAGE\" and characteristics.has_user_action and interaction.type == \"click\"\n| summarize clicks = count(), by:{url.path}\n| sort clicks desc\n| limit 15",
        "visualization": "table",
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "10": {
        "title": "",
        "type": "data",
        "query": "data record(a=\"⚠️ Friction, Errors & Performance\")",
        "visualization": "singleValue",
        "visualizationSettings": {
          "singleValue": { "labelMode": "none", "isIconVisible": true, "prefixIcon": "PulseIcon", "colorThresholdTarget": "background" },
          "autoSelectVisualization": false,
          "thresholds": [ { "id": 1, "field": "a", "title": "", "isEnabled": true, "rules": [ { "id": 1, "color": "#C62239", "comparator": "!=", "value": "0" } ] } ]
        },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "11": {
        "type": "data",
        "title": "⏳ Action Completion Failures",
        "description": "timeout = dead zone (no response). interrupted_by_automatic = rapid navigation. page_hide = user left mid-action.",
        "query": "fetch user.events\n| filter frontend.name == \"$APP\" and page.name == \"$PAGE\" and characteristics.has_user_action and user_action.complete_reason != \"completed\"\n| summarize count(), by:{user_action.complete_reason}\n| sort `count()` desc",
        "visualization": "categoricalBarChart",
        "visualizationSettings": { "colorModeType": { "colorPalette": "categorical" } },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "12": {
        "type": "data",
        "title": "🐛 Error Types",
        "query": "fetch user.events\n| filter frontend.name == \"$APP\" and page.name == \"$PAGE\" and characteristics.has_error\n| summarize count(), by:{error.type}\n| sort `count()` desc",
        "visualization": "donutChart",
        "visualizationSettings": {
          "chartSettings": { "circleChartSettings": { "valueType": "relative", "showTotalValue": true }, "legend": { "position": "bottom" } }
        },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "13": {
        "type": "data",
        "title": "🧵 Long Task Severity (JS Blocking)",
        "query": "fetch user.events\n| filter frontend.name == \"$APP\" and page.name == \"$PAGE\" and characteristics.has_long_task\n| fieldsAdd severity = if(duration > 250ms, \"Severe (>250ms)\", else: if(duration > 100ms, \"Critical (>100ms)\", else: \"Problematic (>50ms)\"))\n| summarize task_count = count(), by:{severity}",
        "visualization": "categoricalBarChart",
        "visualizationSettings": { "colorModeType": { "colorCategoryMode": "multi-color", "colorPalette": "categorical", "customCategoryColors": { "Problematic (>50ms)": "#F8B000", "Critical (>100ms)": "#FF6900", "Severe (>250ms)": "#C62239" } } },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "14": {
        "title": "",
        "type": "data",
        "query": "data record(a=\"🗺️ Geo & Audience\")",
        "visualization": "singleValue",
        "visualizationSettings": {
          "singleValue": { "labelMode": "none", "isIconVisible": true, "prefixIcon": "PulseIcon", "colorThresholdTarget": "background" },
          "autoSelectVisualization": false,
          "thresholds": [ { "id": 1, "field": "a", "title": "", "isEnabled": true, "rules": [ { "id": 1, "color": "#7C38BC", "comparator": "!=", "value": "0" } ] } ]
        },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "15": {
        "type": "data",
        "title": "🌍 Error Session Rate by Country",
        "description": "Countries with near-100% error rates and significant session counts may indicate bot/credential-stuffing activity",
        "query": "fetch user.sessions\n| filter in(frontend.name, \"$APP\")\n| filter isNotNull(geo.country.iso_code)\n| summarize total = count(), errors = countIf(error.http_4xx_count > 0 or error.http_5xx_count > 0), by:{geo.country.iso_code}\n| fieldsAdd error_rate = round(errors * 100.0 / total, decimals: 1)\n| filter total >= 3\n| fields geo.country.iso_code, error_rate\n| sort error_rate desc",
        "visualization": "choroplethMap",
        "visualizationSettings": {
          "choropleth": { "dataMapping": { "countryCode": "geo.country.iso_code", "dimension": "error_rate" } },
          "coloring": { "colorRules": [ { "colorMode": "color-palette", "colorPalette": "red" } ] }
        },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "16": {
        "type": "data",
        "title": "📱 Device Type Split",
        "query": "fetch user.sessions\n| filter in(frontend.name, \"$APP\")\n| filter page_summary_count > 0\n| summarize sessions = count(), by:{device.type}\n| sort sessions desc",
        "visualization": "donutChart",
        "visualizationSettings": {
          "chartSettings": { "circleChartSettings": { "valueType": "relative", "showTotalValue": true }, "legend": { "position": "bottom" } }
        },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      },
      "17": {
        "type": "data",
        "title": "📍 Where Users Came From",
        "query": "fetch user.events\n| filter frontend.name == \"$APP\" and page.name == \"$PAGE\" and characteristics.has_navigation\n| filter isNotNull(page.source.url.path)\n| summarize navigations = count(), by:{page.source.url.path}\n| sort navigations desc\n| limit 12",
        "visualization": "categoricalBarChart",
        "visualizationSettings": { "colorModeType": { "colorPalette": "categorical" } },
        "davis": { "enabled": false, "davisVisualization": { "isAvailable": true } }
      }
    },
    "layouts": {
      "0": { "x": 0, "y": 0, "w": 24, "h": 4 },
      "1": { "x": 0, "y": 4, "w": 24, "h": 1 },
      "2": { "x": 0, "y": 5, "w": 6, "h": 4 },
      "3": { "x": 6, "y": 5, "w": 6, "h": 4 },
      "4": { "x": 12, "y": 5, "w": 6, "h": 4 },
      "5": { "x": 18, "y": 5, "w": 6, "h": 4 },
      "6": { "x": 0, "y": 9, "w": 24, "h": 1 },
      "7": { "x": 0, "y": 10, "w": 8, "h": 7 },
      "8": { "x": 8, "y": 10, "w": 8, "h": 7 },
      "9": { "x": 16, "y": 10, "w": 8, "h": 7 },
      "10": { "x": 0, "y": 17, "w": 24, "h": 1 },
      "11": { "x": 0, "y": 18, "w": 8, "h": 7 },
      "12": { "x": 8, "y": 18, "w": 8, "h": 7 },
      "13": { "x": 16, "y": 18, "w": 8, "h": 7 },
      "14": { "x": 0, "y": 25, "w": 24, "h": 1 },
      "15": { "x": 0, "y": 26, "w": 14, "h": 9 },
      "16": { "x": 14, "y": 26, "w": 5, "h": 9 },
      "17": { "x": 19, "y": 26, "w": 5, "h": 9 }
    }
  }
}
```

## Post-Deploy: Add Server-Assigned ID

After `dtctl apply` succeeds, add the returned `id` field to the JSON root so future updates patch the existing dashboard rather than creating a new one:

```json
{
  "id": "<returned-id>",
  "name": "...",
  ...
}
```
