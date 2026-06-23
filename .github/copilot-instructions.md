# GitHub Copilot Instructions for Dynatrace MCP Workspace

## 🔄 MANDATORY: Re-Read Instructions After Sync/Pull (DO THIS FIRST)

> **The `Auto-pull latest updates` task runs automatically on folder open** (`git pull --ff-only` + `bash setup.sh`). It can **overwrite these instruction files AFTER** the chat has already loaded them into context — leaving you steering from a stale copy.

**At the very start of every session, BEFORE acting on anything in your initial context, you MUST:**
1. Re-read `.github/copilot-instructions.md` and `CLAUDE.md` from disk with `read_file`. **Do NOT trust the copy loaded into your initial context** — it may predate the auto-pull.
2. Run `git log -1 --format='%H %cd'` to confirm whether `HEAD` moved since the workspace opened (the auto-pull may still have been running when your context was captured).
3. If the on-disk content differs from what was in your initial context, **discard the stale version and follow the freshly-read files**.
4. Re-read again if you observe a mid-session sync (auto-pull task output appears, files show as modified, or the user mentions a pull/sync). Treat the on-disk files as the single source of truth at all times.

**Never assume your initial context is current — always confirm against the on-disk files first.**

---

## ⚡ SESSION CONSTANTS

| Constant | Value | Source |
|----------|-------|--------|
| `user.id` | **(resolve at session start — see below)** | `.env` → `MCP_USER_ID` |
| `budget.total_gb` | `"1000"` | `.env` → `DT_GRAIL_QUERY_BUDGET_GB` |
| `query.source` | `"MCP"` | Fixed |

---

## ⛔ MANDATORY: Read `.env` Feature Flags BEFORE Anything Else

**At the very start of every session, BEFORE any MCP tool call, you MUST:**

1. **Read the `.env` file** in the workspace root using `read_file`
2. **Extract ALL feature flags** and store them for the entire session:

| `.env` Variable | Values | Default | What It Controls |
|-----------------|--------|---------|------------------|
| `MCP_GRAIL_ONLY` | `yes` / `no` | `yes` | When `yes`: use ONLY Gen 3 Grail DQL. When `no`: Gen 2 USQL & classic APIs are also allowed (requires `DT_GEN2_API_TOKEN`). |
| `MCP_USE_USER_VARIABLE` | `yes` / `no` | `yes` | When `yes`: resolve `MCP_USER_ID` and include `user.id` on all tracking events. When `no`: skip user identity resolution entirely. |
| `MCP_SEND_TRACKING_EVENTS` | `yes` / `no` | `yes` | When `yes`: send a CUSTOM_INFO tracking event after **every** MCP query. When `no`: skip all tracking events. |
| `MCP_USER_ID` | email | *(none)* | The user email for tracking events. Only read when `MCP_USE_USER_VARIABLE=yes`. |

3. **If `.env` does not exist**, treat all flags as their defaults (`yes`).
4. **If a flag is missing or empty**, treat it as its default (`yes`).

### Resolving `user.id` (only when `MCP_USE_USER_VARIABLE=yes`)

When `MCP_USE_USER_VARIABLE=yes`:
1. Extract the value of `MCP_USER_ID` from `.env`
2. If `MCP_USER_ID` is missing/empty: **ASK the user** for their email address
3. **NEVER fall back to placeholders** like "unknown", "copilot-session", or "test_user"
4. Store it as `user.id` for the entire session

When `MCP_USE_USER_VARIABLE=no`:
- **Skip** user identity resolution entirely
- Do **not** include `user.id` on any tracking events
- Do **not** ask the user for their email

**⛔ NEVER skip reading `.env`. NEVER guess flag values.**

## ✅ MANDATORY COMPLIANCE CHECKLIST (Before Any Execution)

Complete all items below before executing any query, command, or code change:

- [ ] Re-read `.github/copilot-instructions.md` and `CLAUDE.md` from disk (auto-pull may have updated them — do NOT trust initial context)
- [ ] Read `.env` and resolve feature flags
- [ ] Resolve `user.id` when `MCP_USE_USER_VARIABLE=yes`
- [ ] Read `custom-instructions.md` (if present) for user overrides
- [ ] Read all files in `skills/` directory in full
- [ ] Read `reference/DATA_REFERENCE_INDEX.md` and `reference/Entities_Reference.md`
- [ ] Read `reference/MCP_Query_Optimization_Guide.md`
- [ ] Confirm required data is not already documented in reference files
- [ ] **If using `dtctl`**: verify it is connected to the tenant in `.env` (`DT_ENVIRONMENT_URL`) before any deploy/publish operation

---

## ⛔ SEND TRACKING EVENT AFTER EVERY MCP QUERY (when `MCP_SEND_TRACKING_EVENTS=yes`)

> **If `MCP_SEND_TRACKING_EVENTS=no` in `.env`:** Skip this entire section. Do NOT send any tracking events.

**When tracking is enabled, this is NOT OPTIONAL. After EVERY MCP query (execute_dql, list_problems, find_entity_by_name, etc.), you MUST send a tracking event.**

**IMPORTANT:** `send_event` sends CUSTOM_INFO events (queryable via `fetch events`), NOT BizEvents. The dashboard queries `fetch events | filter event.name == "MCP Query Execution"`.

### How to Send the Tracking Event
After each MCP tool call that returns results, use `send_event` with:

```
Tool: mcp_dynatrace-mcp_send_event
eventType: CUSTOM_INFO
title: "MCP Query Execution"
properties:
  event.type: "mcp.query.execution"
  query.dql: "<the DQL query or tool name used>"
  query.bytes_scanned: "<GB scanned from response, e.g. 0.84>"
  query.records_scanned: "<records scanned from response>"
  query.records_returned: "<number of records returned>"
  query.source: "MCP"
  query.tool: "<tool name, e.g. execute_dql, list_problems, find_entity_by_name>"
  query.success: "<true or false>"
  query.data_object: "<primary data object: logs, spans, bizevents, metrics, entities, problems>"
  user.id: "<value from .env MCP_USER_ID — OMIT this field if MCP_USE_USER_VARIABLE=no>"
  budget.total_gb: "1000"
  budget.consumed_gb: "<session total from response>"
  budget.percentage_used: "<percentage from response>"
  query.cost_usd: "<bytes_scanned * 0.05>"
```

### Extracting Values from MCP Responses
Every MCP `execute_dql` response includes these values — extract and send them:
```
📊 DQL Query Results
- Scanned Records: 6,723,074        → query.records_scanned = "6723074"
- Scanned Bytes: 0.84 GB            → query.bytes_scanned = "0.84"
- Session total: 0.84 GB / 1000 GB  → budget.consumed_gb = "0.84"
- 0.1% used                         → budget.percentage_used = "0.1"
```

For FREE tools (find_entity_by_name, list_problems, list_vulnerabilities, timeseries):
```
query.bytes_scanned: "0"
query.cost_usd: "0"
query.data_object: "entities" (or "problems", "vulnerabilities", "metrics")
```

### Why This Is Mandatory
- Tracks ALL MCP query usage across users and sessions
- Enables the MCP Query Usage Dashboard (`example/MCP_Query_Usage_Dashboard.json`)
- Provides cost visibility and budget monitoring
- Identifies expensive queries for optimization
- **Without this, there is NO visibility into MCP usage or costs**

### If send_event Fails
- Log the failure but DO NOT stop the current task
- Continue with the user's request
- Note: This should not block workflow — it's fire-and-forget telemetry

---

## ⛔ MANDATORY: UPDATE DOCS AFTER EVERY MCP QUERY

**THIS IS NOT OPTIONAL. After EVERY MCP query that returns new data, you MUST:**
1. Send the tracking event (see above)
2. Update the relevant reference file IMMEDIATELY (before continuing)
3. Do not wait until the end of the task
4. Do not wait for the user to ask

**If you skip this step, all learnings are lost and the next session wastes budget re-discovering the same data.**

### Why Updates Get Missed (And How to Prevent)
| Reason Updates Get Skipped | Prevention |
|---------------------------|------------|
| Focused on answering user question | Set mental checkpoint: "Answer + Update + Event" |
| Multiple queries in quick succession | Batch update after each query group |
| Query returned "expected" data | Still document - confirms patterns |
| Ran out of context/forgot | This instruction file exists to remind you |
| User asked follow-up quickly | Pause briefly to document before responding |

### Minimum Documentation Per Session
At the END of every session, verify you have documented:
- [ ] Any new entity IDs discovered
- [ ] Any new span patterns or volumes
- [ ] Any new error patterns in logs
- [ ] Any performance baselines (latency, error rates)
- [ ] Any new event types or fields
- [ ] ALL MCP queries were tracked via send_event *(only if `MCP_SEND_TRACKING_EVENTS=yes`)*

---

## Context
This workspace contains Dynatrace configurations for [CLIENT_NAME].
- **Dynatrace Environment:** [TENANT_ID]
- **Primary Data:** BizEvents, Logs, Spans, Metrics
- **Business Context:** [INDUSTRY]

## 🚀 SESSION STARTUP PROTOCOL

### Step 0a: Re-Read Instruction Files From Disk (ALWAYS DO THIS FIRST)
```
1. read_file .github/copilot-instructions.md AND CLAUDE.md (do NOT trust initial context)
2. git log -1 --format='%H %cd' to detect if auto-pull moved HEAD
3. If on-disk content differs from initial context → follow the on-disk version
```
See the "Re-Read Instructions After Sync/Pull" section at the top of this file for full details.

### Step 0: Read `.env` and Resolve Feature Flags (ALWAYS DO THIS FIRST)
```
1. Read .env file
2. Extract: MCP_GRAIL_ONLY, MCP_USE_USER_VARIABLE, MCP_SEND_TRACKING_EVENTS
3. If MCP_USE_USER_VARIABLE=yes → resolve MCP_USER_ID (ask user if missing)
4. Store all values for the session
```

### Step 0.5: Ensure Reference Files Exist (Auto-Heal)
If any `reference/*.md` file is missing (first run or fresh clone), **auto-create it** from the matching `reference/*.template.md` file:
```
For each reference/*.template.md:
  If reference/<name>.md does NOT exist → copy template to create it
If custom-instructions.md does NOT exist → copy custom-instructions.template.md to create it
```
This is equivalent to running `bash setup.sh`. Reference files are gitignored (tenant-specific data) — templates are tracked.

### Step 0.75: Read Custom Instructions (If Present)
If `custom-instructions.md` exists in the workspace root, **read it now**. Its contents are user-defined overrides that **take precedence** over defaults for the same topic (e.g., timeframes, entity focus, output format, exclusion rules). If the file is missing or only contains template comments, skip this step.

### Step 1: Read Reference Files FIRST (Before ANY Queries)
```
1. reference/DATA_REFERENCE_INDEX.md - Central index and quick lookups
2. reference/Entities_Reference.md - Cached entity IDs (avoid lookups)
3. skills/dt-dql-essentials/SKILL.md - REQUIRED before writing any DQL
4. Read ALL SKILL.md files in skills/ subdirectories before executing any query, command, or code change
   Skills may reference files in their own references/ subdirectory — load those on demand
5. Relevant data type reference for your task:
   - reference/BizEvents_Reference.md - Event types
   - reference/Spans_Reference.md - Trace patterns
   - reference/Logs_Reference.md - Error patterns
   - reference/Metrics_Reference.md - Free metric queries
6. reference/MCP_Query_Optimization_Guide.md - Cost rules
```

### Step 2: Check if Data Already Exists
Before making ANY MCP query, verify:
- Is the entity ID in `reference/Entities_Reference.md`?
- Is the event type in `reference/BizEvents_Reference.md`?
- Is the span pattern in `reference/Spans_Reference.md`?
- Is the error pattern in `reference/Logs_Reference.md`?

### Step 3: Query Only for NEW Information
Only use MCP tools for data NOT already documented.

### Step 4: SEND TRACKING EVENT After Every Query *(if `MCP_SEND_TRACKING_EVENTS=yes`)*
**⛔ NON-NEGOTIABLE when enabled:** After EVERY MCP tool call, send a tracking event using `send_event` (CUSTOM_INFO).
**If `MCP_SEND_TRACKING_EVENTS=no`:** Skip this step entirely.

### Step 5: UPDATE Reference Files IMMEDIATELY After Queries
**⛔ NON-NEGOTIABLE:** After discovering new data, update the relevant reference file BEFORE continuing with other tasks!

## 🔄 SELF-UPDATING PROTOCOL (MANDATORY)

**After EVERY MCP query that returns useful data, IMMEDIATELY update the relevant file:**

| Discovery | Update File | Priority |
|-----------|-------------|----------|
| New entity ID | `reference/Entities_Reference.md` | ⛔ IMMEDIATE |
| New span pattern or field availability | `reference/Spans_Reference.md` | ⛔ IMMEDIATE |
| New event type | `reference/BizEvents_Reference.md` | ⛔ IMMEDIATE |
| New error pattern | `reference/Logs_Reference.md` | ⛔ IMMEDIATE |
| New metric | `reference/Metrics_Reference.md` | ⛔ IMMEDIATE |
| Query cost insight | `reference/MCP_Query_Optimization_Guide.md` | ⛔ IMMEDIATE |
| Permission/scope error | `reference/scope_increase.md` | ⛔ IMMEDIATE |

### Update Format
```markdown
### [DATE]
- **Source:** [Query or tool that discovered this]
- **Finding:** [What was learned]
- **Data:** [Specific values, IDs, patterns]
```

### Examples of What MUST Be Documented:
- Entity IDs discovered via `find_entity_by_name`
- Span names and which fields are available on each
- Field availability differences (e.g., `server.address` only on HTTP endpoint spans)
- Volume/count baselines
- Performance baselines (avg duration, p95, etc.)
- Failure patterns and error codes

## ⛔ CRITICAL: MCP Query Cost Guardrails — READ BEFORE EVERY QUERY

> **These rules are INLINED here because LLMs must not skip them by deferring to a file read.**
> The full guide is `reference/MCP_Query_Optimization_Guide.md` but the rules below are the binding constraints.

### 🚨 HARD STOPS — Queries you must NEVER write

| ❌ Forbidden Pattern | Why | Cost |  
|----------------------|-----|------|
| `fetch spans, from:now()-7d` without entity filter | Scans ALL spans for 7 days | 300+ GB |
| `fetch user.events` + `page.url.domain == "…"` string filter | Domain string scan dominates | 174+ GB per 3d |
| `fetch logs` without `loglevel` filter | Unfiltered log scan | 85+ GB per 24h |
| `fetch spans` without `dt.entity.service` filter | Spans across all services | 100+ GB per 24h |
| `fetch user.events` with no `characteristics.classifier` pre-filter | Full event scan | 120+ GB per 7d |
| `fetch bizevents` without `event.type` filter | Scans all BizEvent types | 10–50 GB |

**If your query matches any row above, STOP and rewrite it before executing.**

### Query Cost Reference (use this to choose your approach)

| Query Type | Cost | Use When |
|------------|------|----------|
| `find_entity_by_name`, `list_problems`, `timeseries` | **FREE** | Always try first |
| `user.sessions` (any filter, 7d) | **<0.3 GB** | Session counts, RUM overview |
| BizEvents + `event.type` filter (7d) | **0.5–5 GB** | Business event analysis |
| `user.events` + `classifier` + `page.url.path` (24h) | **2–5 GB** | RUM event detail |
| Logs + `loglevel == "ERROR"` (24h) | **10–15 GB** | Error investigation |
| Spans + entity filter (24h) | **15–20 GB** | Trace deep-dive only |
| Spans + entity filter (7d) | **100–130 GB** | Use metrics instead |

### Pre-Query Checklist (run mentally before every `execute_dql`)

1. **Is there a FREE alternative?** (`timeseries`, `find_entity_by_name`, `list_problems`) → Use it.
2. **Is the entity ID cached?** → Check `reference/Entities_Reference.md` before calling `find_entity_by_name` again.
3. **Is the timeframe minimal?** → Start at 24h; only extend if necessary.
4. **Are filters applied first?** → `event.type`, `loglevel`, `characteristics.classifier`, `dt.entity.*` before any other filter.
5. **Are you using `summarize` not `limit 1000`?** → Aggregate; never fetch raw rows.
6. **user.events domain filter?** → NEVER. Use `page.url.path` (exact) instead.

### Correct Alternatives for Common Mistakes

```dql
// ❌ WRONG — 300+ GB
fetch spans, from:now()-7d | summarize count()

// ✅ RIGHT — 0 GB (free metrics)
timeseries { requests = sum(dt.service.request.count) }, from:now()-7d,
filter:{dt.entity.service == "SERVICE-XXXX"}
```

```dql
// ❌ WRONG — 174 GB per 3d
fetch user.events | filter page.url.domain == "www.example.com"

// ✅ RIGHT — 2–5 GB
fetch user.events, from:now()-24h
| filter characteristics.classifier == "user_action"
| filter page.url.path == "/checkout/"
| summarize count = count(), by:{user_action.type}
```

### Query Priority (Cheapest First)
| Priority | Tool/Query Type | Cost |
|----------|----------------|------|
| 1st | `find_entity_by_name` | FREE |
| 2nd | `list_problems`, `list_vulnerabilities` | FREE |
| 3rd | `timeseries` metrics | FREE |
| 4th | `user.sessions` with any filter | VERY LOW (<0.3 GB for 7d) |
| 5th | BizEvents with event.type filter | LOW |
| 6th | `user.events` with classifier + entity pre-filter | LOW-MEDIUM |
| 7th | Logs with loglevel filter + 24h | MEDIUM |
| 8th | Spans with entity filter + 24h | MEDIUM |
| LAST | Spans 7d, unfiltered logs, user.events URL domain filter | HIGH - AVOID |

### ⛔ Gen3 RUM Data Object Rules (MUST FOLLOW — verified 2026-03-13)

**Valid data objects:** `user.sessions`, `user.events`, `bizevents`
**❌ INVALID (DQL syntax error):** `user_action`, `user.actions`, `events` (for RUM), `user_session`

**Application entity filters — USE THE CORRECT FIELD:**
| Table | ✅ PRIMARY (canonical, entity ID) | ✅ ALTERNATIVE (human-readable name) | ❌ WRONG (returns 0) |
|-------|-----------------------------------|-------------------------------------|---------------------|
| `user.sessions` | `in(dt.rum.application.entities, "APPLICATION-xxx")` | `frontend.name == "App Name"` | `dt.entity.application == "APPLICATION-xxx"` |
| `user.events` | `dt.rum.application.entity == "APPLICATION-xxx"` | `frontend.name == "App Name"` | `dt.entity.application == "APPLICATION-xxx"` |

**Filtering guidance:** Prefer entity ID filters for production queries/automation; use name filters for ad-hoc exploration.

**user.events field gotchas:**
- NO `action.name` field — use `name` (often null for auto-detected actions)
- NO `error.message` — use `error.name`
- NO `error.type == "javascript"` — use `characteristics.classifier == "error"`
- NO `event.type` on user.events — use `characteristics.classifier`
- Custom actions (dtrum.enterAction): `characteristics.classifier == "user_action"` AND `user_action.type == "custom"`
- BizEvents from dtrum.sendBizEvent(): in `bizevents` table, NOT `user.events`

**user.events cost rules:**
- ❌ `page.url.domain` string filter = **~174 GB per 3d** — NEVER DO THIS
- ⚠️ `page.url.path` exact match = ~4-10 GB per 3d — acceptable
- ✅ `characteristics.classifier` pre-filter + path = ~2-5 GB per 3d — best approach
- ✅ `user.sessions` for session counts = **<0.3 GB** — always prefer

### Mandatory Rules
```
✅ DO: Read .env feature flags at session start (ALWAYS)
✅ DO: Send a tracking event after EVERY MCP query (if MCP_SEND_TRACKING_EVENTS=yes)
✅ DO: Read reference files before querying
✅ DO: Use cached entity IDs from reference/Entities_Reference.md
✅ DO: Use timeseries for service metrics (FREE)
✅ DO: Filter BizEvents by event.type FIRST
✅ DO: Start with 24h timeframe, extend only if needed
✅ DO: Use summarize/aggregations, not raw data
✅ DO: Update reference files after discovering new data
✅ DO: Only use Gen 3 Grail DQL queries (if MCP_GRAIL_ONLY=yes)
✅ DO: Use user.sessions (not user.events) for session-level counts (<0.3 GB)
✅ DO: Pre-filter user.events by characteristics.classifier BEFORE any other filter
✅ DO: Use dt.rum.application.entity (PRIMARY, canonical) or frontend.name (ALTERNATIVE) on user.events
✅ DO: Use in(dt.rum.application.entities,...) (PRIMARY) or frontend.name (ALTERNATIVE) on user.sessions
✅ DO: Check reference/Entities_Reference.md for correct RUM filter patterns

❌ DON'T: Skip reading .env feature flags
❌ DON'T: Send tracking events when MCP_SEND_TRACKING_EVENTS=no
❌ DON'T: Ask for user email when MCP_USE_USER_VARIABLE=no
❌ DON'T: Use Gen 2 APIs / USQL when MCP_GRAIL_ONLY=yes
❌ DON'T: Query 7d spans without entity filter (costs 100+ GB)
❌ DON'T: Search logs without loglevel filter
❌ DON'T: Fetch raw data with limit 1000
❌ DON'T: Repeat entity lookups - use cached IDs
❌ DON'T: Query for data already in reference files
❌ DON'T: Use user_action, user.actions, or events as data objects (INVALID in Gen3)
❌ DON'T: Filter user.events by page.url.domain string match (costs 174+ GB per 3d)
❌ DON'T: Use dt.entity.application on user.sessions or user.events (always NULL)
❌ DON'T: Use action.name field (doesn't exist — use name or ui_element.detected_name)
```

### Cached Entity IDs (from reference/Entities_Reference.md)
| Entity Name | Entity ID | Type |
|-------------|-----------|------|
| [APP_NAME] | APPLICATION-XXXXXXXXXXXX | RUM Application |
| [APP_NAME] Frontend | FRONTEND-XXXXXXXXXXXX | Frontend |

### High-Volume Event Types (Require Extra Filters)
| Event Type | Volume | Required Filters |
|------------|--------|------------------|
| *(Add high-volume events as discovered)* | | |

## 🔒 dtctl Tenant Safety

> **⛔ ALWAYS verify the active dtctl tenant matches `.env` before any deploy, publish, or write operation.**

Run the following check before using `dtctl` to deploy dashboards, notebooks, workflows, or any other resource:

```bash
# Check which tenant dtctl is currently connected to
dtctl env list
# or
dtctl env current
```

**Cross-reference the output URL against `DT_ENVIRONMENT_URL` in `.env`.** If they do not match, switch the context or abort — **never publish to the wrong tenant**.

### Switching dtctl Tenant Context
If the active tenant is wrong, switch before proceeding:
```bash
dtctl env use <env-name>
```

Then re-verify before continuing.

---

## Dashboard Creation Standards

### Gen 3 Dashboard Requirements
- Use `"version": 20` in JSON
- Follow examples in `example/` directory (if available)
- Apply brand colours from company websites
- Include data source indicators (BizEvents, Spans, Logs, Metrics)

### Standard Dashboard Sections
1. Header with brand logo/name
2. KPI summary row (key business metrics)
3. Trend charts (primary metrics over time)
4. Breakdown charts (by dimension/category)
5. Service performance (from spans/metrics)
6. Log analysis (errors, warnings)

---

## 📊 Report Output Standards

**MANDATORY:** All generated reports (FinOps, analysis, investigation summaries) MUST be saved to the `/report` directory in the workspace.

**Filename conventions:**
- FinOps reports: `FinOps_K8s_Report_YYYY-MM-DD.md` or `FinOps_K8s_Report_[ClusterName]_YYYY-MM-DD.md`
- Investigation reports: `Investigation_[Topic]_YYYY-MM-DD.md`
- Analysis reports: `Analysis_[Subject]_YYYY-MM-DD.md`

**Report structure:**
- Use Markdown format
- Include generation date and data timeframe
- Reference relevant DQL queries used
- Link to supporting dashboards or notebooks (if created)
- Include executive summary at the top
- Document methodology and data sources

## 📖 Dynatrace Semantic Dictionary
> Reference for all data objects, fields, and relationships:
> **https://docs.dynatrace.com/docs/shortlink/semantic-dictionary**
>
> Use this to look up valid field names, data object types (e.g. `user.events`, `user.sessions`), and model conventions before writing DQL queries.

## 🔒 Token Security

**⛔ NEVER display full API token values on screen.** When running `curl` or any command that uses a token:
- Always reference tokens via their **environment variable** (e.g. `$DT_GEN2_API_TOKEN`), never paste the raw value
- If a command output or error message contains a token, **redact it** before displaying to the user
- In code examples, use `$ENV_VAR` references or placeholders like `<your-token>` — never the actual value
- When reading `.env`, extract values silently — do NOT echo token values back to the user

## ⚠️ Permission Error Handling
When a DQL query returns `NOT_AUTHORIZED_FOR_TABLE` or similar permission errors:
1. **Do NOT retry** — the scope is missing from the token
2. **Log it immediately** in `reference/scope_increase.md` with the exact error, failed query, and required scope
3. **Work around it** using alternative data sources if possible
4. **Inform the user** that a scope increase is needed
---

## 🔀 Gen 2 API Access (only when `MCP_GRAIL_ONLY=no`)

> **If `MCP_GRAIL_ONLY=yes` (default):** Ignore this entire section. Use ONLY Gen 3 Grail DQL queries via MCP tools.

When `MCP_GRAIL_ONLY=no`, the following Gen 2 capabilities are available:

### 🔑 Gen 2 Token
| Token | Env Variable | Scopes | Use For |
|-------|-------------|--------|---------|
| Gen 2 API Token | `DT_GEN2_API_TOKEN` | `ReadConfig`, `DTAQLAccess`, `settings.read` | USQL queries, session/action properties, Gen 2 config reads |

### Using the Gen 2 Token
```bash
# USQL queries (against classic URL)
curl -G -H "Authorization: Api-Token $DT_GEN2_API_TOKEN" --data-urlencode "query=SELECT ..." "$DT_CLASSIC_ENVIRONMENT/api/v1/userSessionQueryLanguage/table"
# Settings 2.0
curl -H "Authorization: Api-Token $DT_GEN2_API_TOKEN" "$DT_CLASSIC_ENVIRONMENT/api/v2/settings/objects?schemaIds=...&scopes={appId}"
```

**Notes:**
- The `application` filter in USQL uses the Gen 2 **display name**, not the entity ID
- Use a Python script rather than raw curl to avoid shell escaping issues with USQL
- Requires `DTAQLAccess` scope on the token

---

## 🏷️ Feature Flag Quick Reference

| Flag | Default | Effect When `yes` | Effect When `no` |
|------|---------|-------------------|------------------|
| `MCP_GRAIL_ONLY` | `yes` | Only Gen 3 Grail DQL via MCP tools | Gen 2 USQL & classic APIs also available |
| `MCP_USE_USER_VARIABLE` | `yes` | Resolve `MCP_USER_ID`, include on events | Skip user identity, omit `user.id` |
| `MCP_SEND_TRACKING_EVENTS` | `yes` | Send CUSTOM_INFO event after every query | Skip all tracking events |
## 🧠 Dynatrace AI Skills (from [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai))

Skills are portable knowledge packages that provide domain-specific DQL context. **Read the relevant skill file before writing queries for that domain.**

| Skill | Domain | When to Load |
|-----------|--------|-------------|
| `skills/dt-dql-essentials/SKILL.md` | **REQUIRED** — DQL syntax, pitfalls, data objects | Before writing ANY DQL query |
| `skills/dt-obs-services/SKILL.md` | Service RED metrics, runtime monitoring | Service performance, SLA, messaging |
| `skills/dt-obs-frontends/SKILL.md` | RUM, Web Vitals, user sessions, mobile | Frontend performance, user behavior |
| `skills/dt-obs-tracing/SKILL.md` | Distributed traces, spans, failures | Trace analysis, failure investigation |
| `skills/dt-obs-logs/SKILL.md` | Log queries, filtering, patterns | Log analysis, error investigation |
| `skills/dt-obs-problems/SKILL.md` | Problem analysis, root cause, impact | Davis problems, incident response |
| `skills/dt-obs-hosts/SKILL.md` | Host/process metrics, infrastructure | CPU, memory, disk, network monitoring |
| `skills/dt-obs-kubernetes/SKILL.md` | K8s clusters, pods, nodes, workloads | Kubernetes troubleshooting |
| `skills/dt-finops-kubernetes/SKILL.md` | K8s FinOps, cost optimization, resource utilization, rightsizing | K8s cost analysis, FinOps reports |
| `skills/dt-obs-aws/SKILL.md` | AWS resources, cost, security | AWS infrastructure analysis |
| `skills/dt-obs-azure/SKILL.md` | Azure cloud resources, cost, networking | Azure infrastructure |
| `skills/dt-obs-gcp/SKILL.md` | GCP cloud resources, cost, networking | GCP infrastructure |
| `skills/dt-obs-predictive-analytics/SKILL.md` | Trend detection, forecasting, anomaly scoring | Predictive analysis |
| `skills/dt-alerting/SKILL.md` | Alerting config, anomaly detectors, notifications | Alert setup |
| `skills/dt-js-runtime/SKILL.md` | Dynatrace JS runtime, SDKs, automation | App/workflow development |
| `skills/dt-app-dashboards/SKILL.md` | Dashboard creation/modification | Building dashboards |
| `skills/dt-app-notebooks/SKILL.md` | Notebook creation/modification | Building notebooks |
| `skills/dt-migration/SKILL.md` | Classic entity → Smartscape migration | Migrating old DQL queries |

Each skill directory may contain a `references/` subdirectory with detailed sub-topics. SKILL.md will indicate when to load these with "Load [filename] when:" directives.

### Skill Loading Protocol
1. **Always** read the relevant `SKILL.md` files before executing any query, command, or code change
2. **Always** load `skills/dt-dql-essentials/SKILL.md` before writing DQL
3. Load domain-specific skills based on the user's request
4. When a SKILL.md says "Load [file] when:", read that file from the skill's `references/` subdirectory on demand
5. Reference the Dynatrace Semantic Dictionary for field validation: https://docs.dynatrace.com/docs/shortlink/semantic-dictionary

---

## 📋 Reusable Prompt Templates

Prompt files in `.github/prompts/` work as VS Code slash commands:

| Prompt | Command | Use Case |
|--------|---------|----------|
| `dt-daily-standup.prompt.md` | `/dt-daily-standup` | Daily standup report for services |
| `dt-health-check.prompt.md` | `/dt-health-check` | Production health check |
| `dt-incident-response.prompt.md` | `/dt-incident-response` | Active incident response |
| `dt-investigate-error.prompt.md` | `/dt-investigate-error` | Error investigation (problems → logs → traces) |
| `dt-performance-regression.prompt.md` | `/dt-performance-regression` | Deployment regression analysis |
| `dt-troubleshoot-problem.prompt.md` | `/dt-troubleshoot-problem` | Problem troubleshooting with scoped queries |

---

## File References
- `reference/DATA_REFERENCE_INDEX.md` - **START HERE** - Central index
- `reference/Entities_Reference.md` - Cached entity IDs
- `reference/BizEvents_Reference.md` - Event type documentation
- `reference/Spans_Reference.md` - Span/trace patterns
- `reference/Logs_Reference.md` - Log and error patterns
- `reference/Metrics_Reference.md` - Free metric queries
- `reference/MCP_Query_Optimization_Guide.md` - Full optimization guide
- `reference/scope_increase.md` - **Token scope gaps & required permission fixes**
- `AI_Prompt.md` - Task templates and instructions
- `skills/` - **Dynatrace AI Skills** (DQL essentials, observability, platform)
- `.github/prompts/` - **Reusable prompt templates** (slash commands)
- `example/` - Dashboard JSON and JavaScript syntax examples (if available)
- `example/MCP_Query_Usage_Dashboard.json` - MCP usage tracking dashboard
- `reference/mcp_query_tracking_schema.md` - Event schema for MCP telemetry (CUSTOM_INFO events, NOT BizEvents)
