# Frontend Observability Skill
> Source: [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — `dt-obs-frontends`

Monitor web and mobile frontends using Real User Monitoring (RUM) with DQL queries. Targets the new RUM experience only.

---

## Data Sources

- **Metrics**: `timeseries` with `dt.frontend.*` (trends, alerting)
- **Events**: `fetch user.events` (individual page views, requests, clicks, errors)
- **Sessions**: `fetch user.sessions` (session-level aggregates: duration, bounce, counts)

---

## Common Metrics

- `dt.frontend.user_action.count` / `dt.frontend.user_action.duration`
- `dt.frontend.request.count` / `dt.frontend.request.duration` (ms)
- `dt.frontend.error.count`
- `dt.frontend.session.active.estimated_count`
- `dt.frontend.user.active.estimated_count`
- `dt.frontend.web.page.cumulative_layout_shift` (CLS)
- `dt.frontend.web.page.largest_contentful_paint` (LCP)
- `dt.frontend.web.page.interaction_to_next_paint` (INP)
- `dt.frontend.web.navigation.time_to_first_byte` (TTFB)
- `dt.frontend.web.navigation.dom_interactive`

**Timeseries Dimensions:** `frontend.name`, `geo.country.iso_code`, `device.type`, `browser.name`, `os.name`, `user_type`

---

## Common Filters

- `frontend.name` - Filter by frontend name
- `dt.rum.user_type` - Exclude synthetic monitoring
- `geo.country.iso_code` - Geographic filtering
- `device.type` - Mobile, desktop, tablet
- `browser.name` - Browser filtering

---

## Event Characteristics

**⚠️ FILTERING BEST PRACTICE:** Use `characteristics.classifier == "value"` as your PRIMARY filter for cost optimization (single enum check is most efficient). Use the `characteristics.has_*` boolean flags below only as SECONDARY filters when you need compound conditions (e.g., events that are both errors AND have requests). See DATA_REFERENCE_INDEX.md for full guidance.

| Characteristic | Meaning |
|---------------|---------|
| `characteristics.has_page_summary` | Page views (web) |
| `characteristics.has_view_summary` | Views (mobile) |
| `characteristics.has_navigation` | Navigation events |
| `characteristics.has_user_interaction` | Clicks, forms, etc. |
| `characteristics.has_request` | Network request events |
| `characteristics.has_error` | Error events |
| `characteristics.has_crash` | Mobile crashes |
| `characteristics.has_long_task` | Long JavaScript tasks |
| `characteristics.has_csp_violation` | CSP violations |

---

## Session Data (`user.sessions`)

`user.sessions` contains session-level aggregates. **Field names differ from `user.events`** — sessions use underscores where events use dots.

**Session identity:**
- `dt.rum.session.id` — Session ID (NOT `dt.rum.session_id`)
- `frontend.name` - array of frontends in session
- `dt.rum.application.type` — `web` or `mobile`
- `dt.rum.user_type` — `real_user`, `synthetic`, or `robot`

**Session aggregates (underscore naming — NOT dot):**

| Field | Description | ⚠️ NOT this |
|-------|-------------|-------------|
| `navigation_count` | Number of navigations | ~~`navigation.count`~~ |
| `user_interaction_count` | Clicks, form submissions | ~~`user_interaction.count`~~ |
| `user_action_count` | User actions | ~~`user_action.count`~~ |
| `request_count` | XHR/fetch requests | ~~`request.count`~~ |
| `event_count` | Total events in session | ~~`event.count`~~ |
| `page_summary_count` | Page views (web) | ~~`page_summary.count`~~ |

**Error fields (dot naming):** `error.count`, `error.exception_count`, `error.http_4xx_count`, `error.http_5xx_count`, `error.has_crash`

**Session lifecycle:** `start_time`, `end_time`, `duration` (nanoseconds), `end_reason`, `characteristics.is_bounce`, `characteristics.has_replay`

**User identity:**
- `dt.rum.user_tag` — User identifier set via `dtrum.identifyUser()`. Not always populated.
- `dt.rum.instance.id` — Random client-side ID, not PII, persistent via cookie.

---

## Session Query Gotchas

- `fetch user.sessions, from: X, to: Y` only returns sessions that **started** in `[X, Y]` — NOT sessions active during that window.
- Sessions can last 8h+. Extend lookback by at least 8h for correlation queries.
- Session aggregation waits ~30+ min of inactivity before closing — recent events (last ~1h) will not have a matching `user.sessions` entry.
- **Zombie sessions** (events without `user.sessions` record) are by design — sessions with no navigations or interactions are skipped.

**Bounce rate example:**
```dql
fetch user.sessions, from: now() - 24h
| filter dt.rum.user_type == "real_user"
| summarize
    total_sessions = count(),
    bounces = countIf(characteristics.is_bounce == true),
    avg_duration_s = avg(toLong(duration)) / 1000000000
| fieldsAdd bounce_rate_pct = round((bounces * 100.0) / total_sessions, decimals: 1)
```

---

## Performance Thresholds

- **LCP**: Good <2.5s | Poor >4.0s
- **INP**: Good <200ms | Poor >500ms
- **CLS**: Good <0.1 | Poor >0.25
- **Cold Start**: Good <3s | Poor >5s
- **Long Tasks**: >50ms problematic, >250ms severe

---

## Slow Page Load Playbook

**Heuristics:**
- High TTFB → slow backend
- High LCP with normal TTFB → render bottleneck
- High CLS → layout shifts (late-loading content, ads, fonts)
- Long tasks dominate → JavaScript execution bottlenecks

**Backend latency (high TTFB):**
```dql
fetch user.events
| filter frontend.name == "my-frontend" and characteristics.has_request == true
| filter page.url.path == "/checkout"
| summarize avg_ttfb = avg(request.time_to_first_byte), avg_duration = avg(duration)
```

**Long tasks by page:**
```dql
fetch user.events, from: now() - 2h
| filter characteristics.has_long_task == true
| summarize long_task_count = count(), total_blocking_time = sum(duration),
   by: {frontend.name, page.url.path}
| sort total_blocking_time desc | limit 20
```

**Large JavaScript bundles:**
```dql
fetch user.events
| filter frontend.name == "my-frontend"
| filter characteristics.has_request
| filter endsWith(url.full, ".js")
| summarize dls = max(performance.decoded_body_size), by: url.full
| sort dls desc | limit 20
```

---

## Best Practices

1. **Use metrics for trends, events for debugging**
2. **Filter by frontend in multi-app environments** — always use `frontend.name`
3. **Match interval to time range** — 5m for hours, 1h for days, 1d for weeks
4. **Exclude synthetic traffic** — filter `dt.rum.user_type`
5. **Extend `user.sessions` time window** for correlation queries (sessions last 8h+)
