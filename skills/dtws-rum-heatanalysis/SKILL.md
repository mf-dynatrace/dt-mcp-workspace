---
name: dtws-rum-heatanalysis
description: >-
  RUM page interaction analysis — the Dynatrace equivalent of a heatmap tool (Hotjar/Crazy Egg).
  Analyses real-user click behaviour, element interaction, action completion/failure, error
  correlation, navigation flows, Core Web Vitals, geo distribution, and long task (JS blocking)
  patterns for any page on any RUM application in any Dynatrace tenant.
  Produces a Dynatrace dashboard (version 21, deployed via dtctl), a markdown report, or a PDF
  report. If the desired output is not specified, prompt the user to choose before proceeding.
  Trigger: "heatmap", "page interaction", "what did users click", "user behaviour on page",
  "click analysis", "interaction report", "what elements are users clicking", "rage clicks on page",
  "how users interact with", "user engagement on page", "interaction dashboard", "page behaviour report".
  Requires: dt-dql-essentials loaded before any DQL. MCP or dtctl query access to the tenant.
  Does NOT cover synthetic monitoring, backend services, or infrastructure.
license: Apache-2.0
---

# RUM Page Interaction Analysis (Heatmap Equivalent)

Analyse user click behaviour, element interactions, action failures, error patterns, navigation
flows, Core Web Vitals, and geo distribution for a specific page using Dynatrace Gen3 Grail RUM.

**Always load `dt-dql-essentials` before writing DQL from this skill.**

---

## Output Format

**If the user has not specified an output format, ask before doing anything else:**

> "What output would you like?
> 1. **Dashboard** — deployed to the Dynatrace tenant via `dtctl apply`
> 2. **Markdown report** — saved to the local `report/` directory
> 3. **PDF report** — saved to `report/` as both `.md` and `.pdf` (rendered via pandoc + headless Chrome)"

Load the appropriate reference once the choice is made:
- Dashboard → `references/dashboard-template.md`
- Markdown or PDF report → `references/report-template.md`

---

## Capability vs Visual Heatmap Tools

| Heatmap Tool (Hotjar / Crazy Egg) | Dynatrace (this skill) |
|---|---|
| Visual X/Y pixel click density map | ❌ No coordinate capture |
| Scroll depth heatmap | ❌ No scroll depth field |
| Mouse movement / hover zones | ❌ Not captured |
| Which elements were clicked (ranked) | ✅ `ui_element.tag_name`, `ui_element.detected_name` |
| What clicks triggered (destination API/URL) | ✅ `url.path` per action |
| Session replay (watch individual journeys) | ✅ `characteristics.has_replay` |
| Rage clicks | ✅ Custom session-window heuristic |
| Error correlation | ✅ Far better than heatmap tools |
| Performance + interaction correlation | ✅ Unique to Dynatrace |
| Geo breakdown of interactions | ✅ `geo.country.iso_code` on `user.sessions` |
| All users, real-time, not sampled | ✅ Full-fidelity at scale |
| Backend call correlation | ✅ Unique to Dynatrace |

---

## Workflow

### Step 1 — Confirm output format
Ask if not specified. See Output Format section above.

### Step 2 — Discover Frontend Names (free, 0 GB)
```dql
timeseries count = sum(dt.frontend.request.count, scalar: true), by:{frontend.name}
| fields frontend.name
```
Ask which application if multiple are returned.

### Step 3 — Discover Top Pages (moderate cost, 1h window)
```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and characteristics.has_page_summary
| summarize page_views = count(), by:{page.name}
| sort page_views desc
| limit 20
```
Ask which page to analyse, or pick the highest-traffic page if unspecified.

### Step 4 — Run Core Analysis Queries
Load `references/interaction-queries.md`. Run in this order:
1. Page health overview
2. Core Web Vitals (page-scoped)
3. Click volume by element type
4. Named element breakdown
5. Element name data quality
6. Click destinations (URL/API)
7. User action type split
8. Action completion failures
9. Rage click detection
10. Error type breakdown
11. Long task severity
12. Navigation source (referrer pages)
13. Geo distribution and error rate by country
14. Device type split
15. Session replay availability

### Step 5 — Produce Output
Load the relevant template reference and populate from query results.
For PDF generation steps, see `references/report-template.md`.

---

## Key Fields Reference

| Field | Source | Description |
|---|---|---|
| `frontend.name` | `user.events`, `user.sessions` | Application identifier — always filter this first |
| `page.name` | `user.events` | Normalised page URL path |
| `view.name` | `user.events` | SPA route or mobile screen |
| `ui_element.detected_name` | `user.events` | Auto-detected element name (aria-label, text, or custom) |
| `ui_element.name` | `user.events` | Raw element name captured by OneAgent |
| `ui_element.tag_name` | `user.events` | HTML tag type (`div`, `a`, `button`, `input`, `img`, etc.) |
| `interaction.type` | `user.events` | `click`, `scroll`, `key_press`, `zoom`, `touch` |
| `user_action.type` | `user.events` | `same_view`, `hard_navigation`, `api`, `soft_navigation` |
| `user_action.complete_reason` | `user.events` | `completed`, `timeout`, `interrupted_by_automatic`, `page_hide` |
| `url.path` | `user.events` | API/URL path triggered by the click |
| `page.source.url.path` | `user.events` (navigation events) | Referrer page path |
| `error.type` | `user.events` | `request`, `exception`, `csp`, `crash`, `anr` |
| `geo.country.iso_code` | `user.sessions` | ISO 3166-1 alpha-2 country code |
| `device.type` | `user.sessions`, `user.events` | `mobile`, `desktop`, `tablet` |
| `browser.name` | `user.sessions`, `user.events` | Browser name |
| `dt.rum.session.id` | `user.events` | Session ID for rage-click or journey correlation |
| `characteristics.has_replay` | `user.sessions` | Whether session replay was captured |

---

## DQL Gotchas

1. **Duration division silently returns null — use `toDouble()` first:**
   ```dql
   // ❌ null result   | fieldsAdd ms = round(avg(duration) / 1000000, decimals: 1)
   // ✅ correct
   | summarize avg_ns = avg(duration)
   | fieldsAdd ms = round(toDouble(avg_ns) / 1000000, decimals: 1)
   ```

2. **`makeTimeseries` rejects expression-based aggregations:**
   ```dql
   // ❌ DQL-SYNTAX-ERROR   | makeTimeseries avg_ms = toDouble(avg(duration)) / 1000000
   // ✅ correct
   | makeTimeseries avg_ns = avg(duration)
   | fieldsAdd avg_ms = toDouble(avg_ns[]) / 1000000
   ```

3. **Multi-value `in()` — don't use parenthesised list syntax:**
   ```dql
   // ❌   | filter x in ("a", "b")
   // ✅   | filter in(x, "a", "b")
   ```

4. **`countDistinctIf` does not exist:**
   ```dql
   // ❌   summarize x = countDistinctIf(session.id, error.count > 0)
   // ✅   | filter error.count > 0 | summarize x = countDistinct(session.id)
   ```

5. **Unfiltered `fetch user.events` can cost 500+ GB** — always apply `frontend.name ==` AND a `characteristics.has_X` filter before any aggregation.

6. **`geo.country.name` is often empty** — use `if()` lookup by `geo.country.iso_code` instead.

---

## References

| File | Load When |
|---|---|
| [references/interaction-queries.md](references/interaction-queries.md) | Running any analysis query |
| [references/dashboard-template.md](references/dashboard-template.md) | Output is a dashboard |
| [references/report-template.md](references/report-template.md) | Output is markdown or PDF |
| [references/data-quality.md](references/data-quality.md) | Assessing element name coverage or advising improvements |
