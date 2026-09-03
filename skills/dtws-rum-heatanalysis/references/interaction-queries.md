# Interaction Analysis Queries

All queries use `$APP` and `$PAGE` as placeholders — substitute with actual `frontend.name` and `page.name` values before executing.

**Always add `filter dt.rum.user_type == "real_user"` if synthetic/bot traffic needs to be excluded.**

---

## Page Health Overview (single query — run first)

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE"
| summarize
    page_views = countIf(characteristics.has_page_summary),
    errors = countIf(characteristics.has_error),
    long_tasks = countIf(characteristics.has_long_task),
    clicks = countIf(characteristics.has_user_action and interaction.type == "click"),
    add_to_basket = countIf(characteristics.has_user_action and contains(url.path, "/basket"))
```

---

## Core Web Vitals for This Page

Scoped to `has_page_summary` events only — web vitals fields are only available on page/view summary events.

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE" and characteristics.has_page_summary
| summarize
    lcp_p75_ns = percentile(web_vitals.largest_contentful_paint, 75),
    fcp_p75_ns = percentile(web_vitals.first_contentful_paint, 75),
    inp_p75_ns = percentile(web_vitals.interaction_to_next_paint, 75),
    cls_p75 = percentile(web_vitals.cumulative_layout_shift, 75)
| fieldsAdd
    lcp_ms = round(toDouble(lcp_p75_ns) / 1000000, decimals: 0),
    fcp_ms = round(toDouble(fcp_p75_ns) / 1000000, decimals: 0),
    inp_ms = round(toDouble(inp_p75_ns) / 1000000, decimals: 0)
| fields lcp_ms, fcp_ms, inp_ms, cls_p75
```

---

## Click Volume by Element Type

The starting point — equivalent to "where are users clicking" in a heatmap tool.

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE"
| filter characteristics.has_user_action and interaction.type == "click"
| summarize clicks = count(), by:{ui_element.tag_name}
| sort clicks desc
```

**Typical distribution:**
- `div` — highest count (generic containers, product cards, layout wrappers)
- `a` — explicit link clicks
- `input` — form field / search box interactions
- `img` — product image clicks
- `h3`/`h2` — heading / product title clicks
- `button` — explicit button interactions
- `svg`/`path` — icon clicks

---

## Named Element Breakdown (drill into 'div' and other generic tags)

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE"
| filter characteristics.has_user_action and interaction.type == "click"
| filter ui_element.tag_name == "div"
| filter isNotNull(ui_element.detected_name) and ui_element.detected_name != "masked"
| summarize clicks = count(), by:{ui_element.detected_name}
| sort clicks desc
| limit 20
```

---

## Element Name Data Quality

Shows what proportion of clicks have a readable element name vs are masked or unnamed.

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE"
| filter characteristics.has_user_action and interaction.type == "click"
| fieldsAdd quality = if(
    isNotNull(ui_element.detected_name) and ui_element.detected_name != "masked",
    "Named (readable)",
    else: if(ui_element.detected_name == "masked", "Masked (privacy)", else: "Unnamed (structural)"))
| summarize clicks = count(), by:{quality}
```

---

## What Did Clicks Trigger? (destination API / URL path)

Reveals the intent behind a click — which API calls or navigations were triggered.

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE"
| filter characteristics.has_user_action and interaction.type == "click"
| summarize clicks = count(), by:{url.path}
| sort clicks desc
| limit 20
```

**Interpretation guide:**
- `/api/...` paths = background API calls triggered by the click (search, basket, etc.)
- `/event`, `/g/collect`, `/collect` = analytics/tag-manager telemetry (not page navigations)
- `/sitesearch`, `/product/...`, `/checkout/...` = actual page navigations

---

## User Action Type Split (same-page vs navigating away)

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE"
| filter characteristics.has_user_action
| summarize count(), by:{user_action.type}
```

- `same_view` — user interacted but stayed on the page (filter, refine, basket action)
- `hard_navigation` — clicked something that loaded a new page
- `api` — background XHR/fetch action with no visible navigation
- `soft_navigation` — SPA route change within the same page shell

---

## Action Completion Failures (friction signals)

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE"
| filter characteristics.has_user_action and user_action.complete_reason != "completed"
| summarize count(), by:{user_action.complete_reason}
```

**Reason meanings:**
- `timeout` — user triggered something that never responded (dead zones, broken interactions)
- `interrupted_by_automatic` — rapid navigation before the action finished (users refining quickly)
- `page_hide` — user left the page mid-action (possible frustration or distraction)
- `interrupted_by_api` — developer called `dtrum.leaveAction()` before natural completion

High `timeout` counts on a specific element = broken/dead zone on the page.

---

## Rage Click Detection (session-window heuristic)

No native field — this heuristic counts 3+ clicks on the same element within a 2-second window per session.

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE"
| filter characteristics.has_user_interaction and interaction.type == "click"
| summarize click_count = count(), by:{dt.rum.session.id, ui_element.name, bin(timestamp, 2s)}
| filter click_count >= 3
| summarize rage_click_clusters = count(), sessions_affected = countDistinct(dt.rum.session.id)
```

**Note:** Replace the threshold (3 clicks / 2s) if your application has a known valid multi-click pattern (e.g. quantity +/- buttons).

---

## Error Type Breakdown on the Page

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE"
| filter characteristics.has_error
| summarize count(), by:{error.type}
| sort `count()` desc
```

- `request` — failed XHR/fetch calls (network issues, 4xx/5xx API responses)
- `exception` — JavaScript exceptions thrown on the page
- `csp` — Content Security Policy violations (blocked third-party scripts)
- `crash` — mobile app crash
- `anr` — Android Not Responding

---

## Long Tasks (JS Main Thread Blocking)

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE"
| filter characteristics.has_long_task
| fieldsAdd severity = if(duration > 250ms, "Severe (>250ms)",
    else: if(duration > 100ms, "Critical (>100ms)", else: "Problematic (>50ms)"))
| summarize task_count = count(), by:{severity}
```

Severe long tasks (>250ms) block user input and make the page feel frozen. High counts = JS bundle needs splitting or heavy computation needs a web worker.

---

## Navigation Source (Where Users Came From)

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE"
| filter characteristics.has_navigation
| filter isNotNull(page.source.url.path)
| summarize navigations = count(), by:{page.source.url.path}
| sort navigations desc
| limit 15
```

---

## Device Type Split

```dql
fetch user.sessions, from:now()-2h
| filter in(frontend.name, "$APP")
| filter page_summary_count > 0
| summarize sessions = count(), by:{device.type}
| sort sessions desc
```

Mobile-dominant traffic means all interaction friction is mobile friction first — design and fix for mobile.

---

## Session Replay Availability

```dql
fetch user.sessions, from:now()-2h
| filter in(frontend.name, "$APP")
| summarize
    total = count(),
    with_replay = countIf(characteristics.has_replay)
| fieldsAdd replay_pct = round(with_replay * 100.0 / total, decimals: 1)
```

If `replay_pct == 0`, Session Replay is not enabled. Enable it in the RUM configuration to complement this interaction data with visual session playback.

---

## Cost Guidance

| Query | Approx. cost | Notes |
|---|---|---|
| `timeseries dt.frontend.*` (metrics) | 0 GB | Free — always try first for volume KPIs |
| `user.sessions` with frontend filter | <0.15 GB / 2h | Very cheap |
| `user.events` with `frontend.name` + `characteristics.has_X` filter, 1h | 2–5 GB | Acceptable |
| `user.events` without `characteristics.has_X` filter | 15–20 GB / 1h | Expensive — always add a characteristic filter |
| `user.events` without `frontend.name` filter | 500+ GB | NEVER do this |
