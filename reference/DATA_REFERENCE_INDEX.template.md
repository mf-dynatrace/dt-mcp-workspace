# Dynatrace Data Reference Index

> **Purpose:** Central index for all data type references. AI assistants should read this file and relevant references BEFORE making MCP queries.
> **Last Updated:** 2026-03-13
> **Client:** [CLIENT_NAME]
> **Environment:** [TENANT_ID]
> **Semantic Dictionary:** https://docs.dynatrace.com/docs/shortlink/semantic-dictionary — look up valid field names, data objects, and model conventions before writing DQL

---

## 📚 Reference Files

| File | Data Type | Purpose |
|------|-----------|---------|
| [BizEvents_Reference.md](BizEvents_Reference.md) | BizEvents | Event types, fields, volumes, example queries |
| [Spans_Reference.md](Spans_Reference.md) | Spans/Traces | Service entities, span names, latency patterns |
| [Logs_Reference.md](Logs_Reference.md) | Logs | Log sources, levels, common error patterns |
| [Metrics_Reference.md](Metrics_Reference.md) | Metrics | Available metrics, timeseries patterns |
| [Entities_Reference.md](Entities_Reference.md) | Entities | Cached entity IDs, topology, relationships |
| [MCP_Query_Optimization_Guide.md](MCP_Query_Optimization_Guide.md) | Optimization | Query cost rules, best practices |
| [mcp_query_tracking_schema.md](mcp_query_tracking_schema.md) | Telemetry | MCP query tracking event schema |
| [scope_increase.md](scope_increase.md) | Permissions | Token scope gaps & required fixes |
| [AI_Prompt.md](../AI_Prompt.md) | Templates | Task templates and prompts |
| [example/MCP_Query_Usage_Dashboard.json](../example/MCP_Query_Usage_Dashboard.json) | Dashboard | MCP usage monitoring dashboard |

### 🧠 Dynatrace AI Skills (from [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai))

| File | Domain | When to Load |
|------|--------|-------------|
| [skills/dt-dql-essentials.md](skills/dt-dql-essentials.md) | **REQUIRED** — DQL syntax, pitfalls, data objects | Before writing ANY DQL |
| [skills/dt-obs-services.md](skills/dt-obs-services.md) | Service RED metrics, runtime monitoring | Service performance, SLA |
| [skills/dt-obs-frontends.md](skills/dt-obs-frontends.md) | RUM, Web Vitals, user sessions, mobile | Frontend performance |
| [skills/dt-obs-tracing.md](skills/dt-obs-tracing.md) | Distributed traces, spans, failures | Trace analysis |
| [skills/dt-obs-logs.md](skills/dt-obs-logs.md) | Log queries, filtering, patterns | Log analysis |
| [skills/dt-obs-problems.md](skills/dt-obs-problems.md) | Problem analysis, root cause, impact | Davis problems |
| [skills/dt-obs-hosts.md](skills/dt-obs-hosts.md) | Host/process metrics, infrastructure | CPU, memory, disk |
| [skills/dt-obs-kubernetes.md](skills/dt-obs-kubernetes.md) | K8s clusters, pods, nodes, workloads | Kubernetes |
| [skills/dt-obs-aws.md](skills/dt-obs-aws.md) | AWS resources, cost, security | AWS infrastructure |
| [skills/dt-app-dashboards.md](skills/dt-app-dashboards.md) | Dashboard creation/modification | Building dashboards |
| [skills/dt-app-notebooks.md](skills/dt-app-notebooks.md) | Notebook creation/modification | Building notebooks |
| [skills/dt-migration.md](skills/dt-migration.md) | Classic entity → Smartscape migration | Migrating old DQL |

### 📋 Reusable Prompt Templates (`.github/prompts/`)

| Prompt | Command | Use Case |
|--------|---------|----------|
| `dt-daily-standup.prompt.md` | `/dt-daily-standup` | Daily standup report |
| `dt-health-check.prompt.md` | `/dt-health-check` | Production health check |
| `dt-incident-response.prompt.md` | `/dt-incident-response` | Active incident response |
| `dt-investigate-error.prompt.md` | `/dt-investigate-error` | Error investigation |
| `dt-performance-regression.prompt.md` | `/dt-performance-regression` | Deployment regression |
| `dt-troubleshoot-problem.prompt.md` | `/dt-troubleshoot-problem` | Problem troubleshooting |

### ⚠️ Special Data Scopes — Gen3 RUM

> **⛔ CRITICAL — Valid Gen3 RUM data objects (verified 2026-03-13):**
> - `user.sessions` — session-level aggregates
> - `user.events` — event-level detail (requests, errors, actions, navigations)
>
> **❌ INVALID data objects — these DO NOT EXIST in Gen3 DQL:**
> - `user_action` — DOES NOT EXIST (use `user.events` with `characteristics.classifier == "user_action"`)
> - `user.actions` — DOES NOT EXIST
> - `events` — DOES NOT EXIST for RUM (this is for platform events, not RUM)
> - `user_session` — DOES NOT EXIST (use `user.sessions`)

#### user.sessions (Gen3 Session-Level Analytics)
| Scope | Purpose | Key Fields | Cost |
|-------|---------|------------|------|
| `user.sessions` | Session duration, bounce rate, engagement, errors, device, ISP, geo | `duration`, `user_interaction_count`, `request_count`, `navigation_count`, `error.count`, `error.exception_count`, `error.http_4xx_count`, `error.http_5xx_count`, `end_reason`, `device.type`, `os.name`, `browser.name`, `browser.version`, `device.screen.width`, `device.screen.height`, `browser.window.width`, `browser.window.height`, `client.isp`, `geo.country.iso_code`, `frontend.name`, `dt.rum.application.entities`, `characteristics.is_invalid`, `characteristics.has_replay`, `device.is_rooted` | ~0.14 GB per 3d |

**Scope required:** `storage:user.sessions:read` (Gen3 dot-notation — NOT `user-sessions` with hyphen)

**⚠️ CRITICAL — Application filter gotchas on user.sessions (verified 2026-03-13):**
- `dt.entity.application` is **ALWAYS NULL** on `user.sessions` — DO NOT USE IT
- ✅ Use `frontend.name == "[APP_NAME]"` to filter by application name
- ✅ Use `in(dt.rum.application.entities, "APPLICATION-XXXXXXXXXXXX")` to filter by entity ID
- ❌ `dt.entity.application == "APPLICATION-xxx"` returns 0 results even when sessions exist

**Much cheaper than user.events for session-level analysis!**

#### user.events (Gen3 RUM Events)
| Scope | Purpose | Key Fields | Cost |
|-------|---------|------------|------|
| `user.events` | RUM request events, JS errors, navigations, user interactions, page/view summaries | `characteristics.classifier`, `error.name`, `error.type`, `error.source`, `error.reason`, `error.id`, `error.display_name`, `url.domain`, `url.provider`, `url.full`, `url.path`, `view.detected_name`, `view.url.path`, `page.detected_name`, `page.url.path`, `page.url.domain`, `page.url.full`, `page.title`, `dt.rum.application.entity`, `dt.rum.application.id`, `dt.rum.session.id`, `os.name`, `browser.name`, `browser.version`, `browser.user_agent`, `device.type`, `device.screen.width`, `device.screen.height`, `browser.window.width`, `browser.window.height`, `client.isp`, `geo.country.iso_code`, `frontend.name`, `duration`, `http.response.status_code`, `http.request.method`, `visibility.state`, `performance.initiator_type`, `user_action.type`, `user_action.instance_id`, `interaction.name`, `ui_element.detected_name` | 4-175 GB per 3d (depends on filter & aggregation) |

**Note:** `user.events` provides event-level detail (requests, errors, navigations) while `user.sessions` provides aggregated session metrics.

**⚠️ CRITICAL — Application filter on user.events (verified 2026-03-13):**
- ✅ **PRIMARY (recommended):** `dt.rum.application.entity == "APPLICATION-XXXXXXXXXXXX"` — canonical entity ID-based filter, most precise and unambiguous
- ✅ **ALTERNATIVE:** `frontend.name == "[APP_NAME]"` — human-readable name filter, useful for ad-hoc queries and dashboard variables
- ❌ **WRONG:** `dt.entity.application` — NULL on this table, DO NOT USE

**When to use which:** Use entity ID filter for automation/reusable queries; use name filter for human-readable exploration or when entity ID is not yet known.

**⚠️ CRITICAL — URL filtering costs (verified 2026-03-13):**
- Filtering by `page.url.domain` or `view.url.domain` (string contains) costs **~174 GB per 3d** — VERY EXPENSIVE
- Filtering by `page.url.path` (exact match) costs **~4-10 GB per 3d** — much cheaper
- **ALWAYS pre-filter by `characteristics.classifier` FIRST** to reduce scan volume
- **NEVER use `contains(toString(field), ...)` on URL fields** without a classifier pre-filter

**⚠️ CRITICAL — Gen3 RUM Field Gotchas (verified 2026-03-07, updated 2026-03-13):**
- There is **NO** `error.message` field — use `error.name` instead
- There is **NO** `error.type == "javascript"` — error types are: `request`, `exception`, `csp`
- There is **NO** `event.type` field on user.events (it's always null) — use `characteristics.classifier` to filter event kinds
- There is **NO** `action.name` field — user action names are in `name` field (often null for auto-detected actions)
- `characteristics.classifier` values: `request`, `user_interaction`, `other`, `error`, `navigation`, `visibility_change`, `view_summary`, `page_summary`, `user_action`, `invalid`
- **FILTERING PATTERN:** Use `characteristics.classifier` as PRIMARY filter (most cost-efficient). Use `characteristics.has_*` boolean flags only as SECONDARY filters when you need compound conditions (e.g., events that are both errors AND requests). Single enum filter is more optimizer-friendly than multiple boolean checks.
- **User actions:** filter `characteristics.classifier == "user_action"`, then check `user_action.type` (`xhr`, `custom`, `load`), `interaction.name`, `ui_element.detected_name`
- **Custom actions** (from `dtrum.enterAction()`): `characteristics.classifier == "user_action"` AND `user_action.type == "custom"`
- To find JS errors: `characteristics.classifier == "error"` then further filter by `error.type` and `error.source`
- `error.source` values: `fetch`, `xhr`, `exception`, `promise_rejection`, `console`
- `url.provider` distinguishes `first_party` vs `third_party` resources
- Unfiltered `summarize by:{characteristics.classifier}` costs ~46 GB for 24h — always pre-filter by classifier
- Filtered `characteristics.classifier == "error"` scans reduce to ~0.9-2.2 GB for 24h

#### Where RUM BizEvents Live (verified 2026-03-13)
- `dtrum.sendBizEvent()` sends events to the **`bizevents`** table, NOT `user.events`
- Query with: `fetch bizevents | filter event.type == "com.example.type"`
- The RUM user action wrapping the BizEvent appears in `user.events` as `characteristics.classifier == "user_action"` with `user_action.type == "custom"`
- **BizEvents and user actions are in SEPARATE tables** — query both if checking GTM deployment

#### Standard Data Objects
| Scope | Purpose | Key Fields |
|-------|---------|------------|
| `bizevents` | Business events | `event.type`, custom fields |
| `spans` | Distributed traces | `span.name`, `duration`, `dt.entity.service` |
| `logs` | Log messages | `content`, `loglevel`, `log.source` |

---

## 🔄 Self-Updating Protocol

### When to Update Reference Files
AI assistants MUST update relevant reference files when:
1. **New entity discovered** → Add to `Entities_Reference.md`
2. **New event type found** → Add to `BizEvents_Reference.md`
3. **New span/service discovered** → Add to `Spans_Reference.md`
4. **Query cost insight gained** → Add to `MCP_Query_Optimization_Guide.md`
5. **New error pattern identified** → Add to `Logs_Reference.md`

### Update Format
```markdown
## 2026-03-06 Update
- **Source:** [Query or analysis that discovered this]
- **Finding:** [What was learned]
- **Data:** [Specific values, IDs, patterns]
```

---

## 🚀 AI Session Startup Protocol

### Step 0: Read `.env` Feature Flags (ALWAYS FIRST)
```
1. Read .env file
2. Extract: MCP_GRAIL_ONLY, MCP_USE_USER_VARIABLE, MCP_SEND_TRACKING_EVENTS
3. If MCP_USE_USER_VARIABLE=yes → resolve MCP_USER_ID
4. Store all flags for the session
```

### Step 1: Read Reference Files (NO QUERIES YET)
```
1. Read this index file
2. Read Entities_Reference.md (for cached entity IDs)
3. Read relevant data type reference for your task
4. Read MCP_Query_Optimization_Guide.md
```

### Step 2: Check if Information Already Exists
Before making ANY MCP query, check:
- Is the entity ID already in `Entities_Reference.md`?
- Is the event type documented in `BizEvents_Reference.md`?
- Is this query pattern in `MCP_Query_Optimization_Guide.md`?

### Step 3: Query Only for New Information
Only make MCP queries for data NOT already in reference files.

### Step 4: Update Reference Files
After gaining new insights, update the relevant reference file.

---

## 📊 Quick Lookups

### Entity IDs (Cached)
| Entity Name | Entity ID | Type | Last Verified |
|-------------|-----------|------|---------------|
| [APP_NAME] | APPLICATION-XXXXXXXXXXXX | RUM Application | 2026-03-10 |

### High-Volume Event Types
| Event Type | Volume | Required Filters |
|------------|--------|------------------|
| *(Add high-volume events as discovered)* | | |

### Query Cost Quick Reference
| Data Type | 24h Cost | 3d Cost | 7d Cost | Recommendation |
|-----------|----------|---------|---------|----------------|
| Metrics timeseries | 0 GB | 0 GB | 0 GB | ✅ Always prefer |
| BizEvents (filtered by event.type) | 0.5 GB | 1 GB | 2 GB | ✅ Good |
| user.sessions (any filter) | <0.1 GB | 0.14 GB | ~0.3 GB | ✅ Very cheap, use for session counts |
| user.events (classifier + entity) | 1-5 GB | 3-10 GB | 5-15 GB | ✅ Good with pre-filters |
| user.events (URL path filter) | 2-10 GB | 4-30 GB | 8-50 GB | ⚠️ Always add classifier first |
| user.events (URL domain string filter) | 50-75 GB | 150-175 GB | 300+ GB | ❌ AVOID — extremely expensive |
| user.events (unfiltered classifier summary) | ~46 GB | ~120 GB | ~250 GB | ❌ AVOID — always pre-filter |
| Logs (loglevel filter) | 10 GB | 25 GB | 50 GB | ⚠️ Use 24h |
| Spans (entity filter) | 16 GB | 50 GB | 125 GB | ⚠️ Use 24h or metrics |
| Spans (unfiltered) | 50 GB | 150 GB | 300+ GB | ❌ Never |

---

## 📊 MCP Query Tracking

### After Every MCP Query *(only when `MCP_SEND_TRACKING_EVENTS=yes`)*
AI assistants MUST send a tracking event after EVERY MCP query using `send_event`:
- **eventType:** `CUSTOM_INFO`
- **title:** `MCP Query Execution`
- **user.id:** Value from `.env` MCP_USER_ID *(omit if `MCP_USE_USER_VARIABLE=no`)*

**When `MCP_SEND_TRACKING_EVENTS=no`:** Skip all tracking events entirely.

See [mcp_query_tracking_schema.md](mcp_query_tracking_schema.md) for full event schema.

### Dashboard
Import `example/MCP_Query_Usage_Dashboard.json` to monitor:
- Total queries and data scanned
- Cost tracking and budget usage
- Top users by consumption
- Most expensive queries

---

## 🔧 Environment Info
- **Dynatrace Tenant:** [TENANT_ID]
- **Customer:** [CLIENT_NAME]
- **Industry:** [INDUSTRY]
- **Key Services/Applications:** [APP_NAME] (APPLICATION-XXXXXXXXXXXX), www.[CLIENT_WEBSITE], tickets.[CLIENT_WEBSITE] ([TICKET_PROVIDER] ticketing), bookings.example.com

---

## 🏷️ Feature Flag Quick Reference

These flags are read from `.env` at session start and control AI behaviour:

| Flag | Default | Effect When `yes` | Effect When `no` |
|------|---------|-------------------|------------------|
| `MCP_GRAIL_ONLY` | `yes` | Only Gen 3 Grail DQL via MCP tools | Gen 2 USQL & classic APIs also available |
| `MCP_USE_USER_VARIABLE` | `yes` | Resolve `MCP_USER_ID`, include on events | Skip user identity, omit `user.id` |
| `MCP_SEND_TRACKING_EVENTS` | `yes` | Send CUSTOM_INFO event after every query | Skip all tracking events |
