# Dynatrace Workspace - AI Instructions

> **IMPORTANT:** This file is automatically read by AI assistants at session start.
> **CRITICAL:** Read reference files BEFORE making any MCP queries!

---

## 🔌 MCP Server Connection (How Claude Connects)

> **If the Dynatrace MCP tools are missing in a session, this is almost always why.**

Claude Code reads MCP server definitions from **`.mcp.json` at the workspace root** — **NOT** from the `mcpServers` key in `.claude/settings.json`. (That key is Claude *Desktop* format and is silently ignored by Claude Code / the VS Code extension.)

**Required files (already included in this workspace):**

| File | Used By | Purpose |
|------|---------|---------|
| `.mcp.json` | **Claude Code** (CLI / desktop / VS Code extension) | Server definition Claude Code actually reads |
| `.claude/settings.json` | Claude Code | `enableAllProjectMcpServers: true` — auto-approves the server (skips the per-project trust prompt) |
| `.vscode/mcp.json` | VS Code + GitHub Copilot | Server definition for Copilot (uses native `envFile`) |
| `.env` | both | Credentials, sourced by the server at launch |

**`.mcp.json` contents:**
```json
{
  "mcpServers": {
    "dynatrace-mcp-server": {
      "command": "bash",
      "args": ["-c", "set -a && source .env && set +a && exec npx -y @dynatrace-oss/dynatrace-mcp-server@latest"]
    }
  }
}
```

**If the Dynatrace MCP tools are missing in a session:**
1. Confirm `.mcp.json` exists at the workspace root (not just `.claude/settings.json`).
2. In the VS Code extension, run **Developer: Reload Window** (`Cmd/Ctrl+Shift+P`) — `.mcp.json` is only read at session start. In the CLI, restart `claude` from the workspace root.
3. Approve `dynatrace-mcp-server` if prompted (or rely on `enableAllProjectMcpServers: true`).
4. Verify with `/mcp`, or by asking *"What environment am I connected to?"* (calls `get_environment_info`).

> **Windows:** `command: "bash"` requires Git Bash on PATH (bundled with Git for Windows). If unavailable, pre-export the `.env` variables into your shell before launching `claude` (see INSTALL.md).

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

- [ ] Read `.env` and resolve feature flags
- [ ] Resolve `user.id` when `MCP_USE_USER_VARIABLE=yes`
- [ ] Read all files in `skills/` directory in full
- [ ] Read `reference/DATA_REFERENCE_INDEX.md` and `reference/Entities_Reference.md`
- [ ] Read `reference/MCP_Query_Optimization_Guide.md`
- [ ] Confirm required data is not already documented in reference files

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

## 🚀 SESSION STARTUP PROTOCOL

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
```
This is equivalent to running `bash setup.sh`. Reference files are gitignored (tenant-specific data) — templates are tracked.

### Step 1: Read These Files FIRST (No Queries Yet!)
```
1. reference/DATA_REFERENCE_INDEX.md - Central index, quick lookups
2. reference/Entities_Reference.md - Cached entity IDs
3. skills/dt-dql-essentials/SKILL.md - REQUIRED before writing any DQL
4. Read ALL SKILL.md files in skills/ subdirectories before executing any query, command, or code change
   Skills may reference files in their own references/ subdirectory — load those on demand
5. [Relevant data type reference for your task]
6. reference/MCP_Query_Optimization_Guide.md - Cost rules
```

### Step 2: Check if Data Already Exists
Before ANY MCP query, check reference files for:
- Entity IDs → `reference/Entities_Reference.md`
- Event types → `reference/BizEvents_Reference.md`
- Span patterns → `reference/Spans_Reference.md`
- Error patterns → `reference/Logs_Reference.md`
- Metrics → `reference/Metrics_Reference.md`

### Step 3: Query Only for NEW Information
Only use MCP tools for data NOT already documented.

### Step 4: SEND TRACKING EVENT After Every Query *(if `MCP_SEND_TRACKING_EVENTS=yes`)*
**⛔ NON-NEGOTIABLE when enabled:** After EVERY MCP tool call, send a tracking event using `send_event` (CUSTOM_INFO). See the mandatory protocol at the top of this file.
**If `MCP_SEND_TRACKING_EVENTS=no`:** Skip this step entirely.

### Step 5: UPDATE Reference Files IMMEDIATELY After Queries
**⛔ NON-NEGOTIABLE:** After discovering new data, update the relevant reference file BEFORE continuing with other tasks!

---

## 🔄 SELF-UPDATING PROTOCOL (MANDATORY)

**After EVERY MCP query, IMMEDIATELY update:**

| When You Discover | Update This File | Priority |
|-------------------|------------------|----------|
| New entity ID | `reference/Entities_Reference.md` | ⛔ NOW |
| New span pattern or field availability | `reference/Spans_Reference.md` | ⛔ NOW |
| New event type | `reference/BizEvents_Reference.md` | ⛔ NOW |
| New error pattern | `reference/Logs_Reference.md` | ⛔ NOW |
| New metric | `reference/Metrics_Reference.md` | ⛔ NOW |
| Query cost insight | `reference/MCP_Query_Optimization_Guide.md` | ⛔ NOW |
| Permission/scope error | `reference/scope_increase.md` | ⛔ NOW |

### What MUST Be Documented:
- Entity IDs discovered via `find_entity_by_name`
- Span names and which fields are available on each
- Field availability differences (e.g., `server.address` only on HTTP endpoint spans)
- Volume/count baselines
- Performance baselines (avg duration, p95, etc.)
- Failure patterns and error codes

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

---

## 📦 Cached Entity IDs (Build This List)

### Services
| Service Name | Entity ID | Notes |
|--------------|-----------|-------|
| *(Add as discovered via find_entity_by_name)* | | |

**Rule:** Once an entity ID is documented here, NEVER query for it again! Reuse it!

---

## Quick Reference: Query Cost Rules

### FREE Queries (Use First)
```
find_entity_by_name, list_problems, list_vulnerabilities, timeseries metrics
```

### VERY LOW Cost (<0.3 GB) — User Sessions
```dql
// User sessions are extremely cheap — always prefer for session-level data
fetch user.sessions, from:now()-7d
| filter frontend.name == "[APP_NAME]"
| summarize sessions = count(), avg_duration = avg(duration)
```

### LOW Cost (0-5 GB)
```dql
fetch bizevents, from:now()-7d
| filter event.type == "com.example.payment"  // ALWAYS filter event.type first
| filter customField == "value"
| summarize count()
```

### MEDIUM Cost (2-10 GB) — User Events (with correct filters)
```dql
// ALWAYS pre-filter by characteristics.classifier FIRST
fetch user.events, from:now()-24h
| filter page.url.path == "/your/bookings/"
| filter characteristics.classifier == "user_action"
| summarize count = count(), by:{user_action.type, interaction.name}
| sort count desc
```

### HIGH Cost (100+ GB) - AVOID
```dql
// DON'T DO THIS - costs 100+ GB
fetch spans, from:now()-7d
| summarize count()

// DON'T DO THIS - costs 174+ GB per 3d
fetch user.events, from:now()-3d
| filter page.url.domain == "www.[CLIENT_WEBSITE]"
| summarize count()
```

### CORRECT Pattern
```dql
// DO THIS - use metrics (FREE)
timeseries { requests = sum(dt.service.request.count) }, 
from:now()-7d, filter:{dt.entity.service == "SERVICE-XXXXXXXXXXXX"}
```

### ⛔ Gen3 RUM Quick Reference (verified 2026-03-13)

**Valid RUM data objects:** `user.sessions`, `user.events`
**❌ INVALID (DQL error):** `user_action`, `user.actions`, `events`

**Application filter cheat sheet:**
| Table | ✅ PRIMARY (canonical) | ✅ ALTERNATIVE (name-based) | ❌ Wrong (returns 0) |
|-------|---------------------------|------------------------------|---------------------|
| `user.sessions` | `in(dt.rum.application.entities, "APPLICATION-xxx")` | `frontend.name == "[APP_NAME]"` | `dt.entity.application` |
| `user.events` | `dt.rum.application.entity == "APPLICATION-xxx"` | `frontend.name == "[APP_NAME]"` | `dt.entity.application` |

**Prefer entity ID filters** (`dt.rum.application.entity`) **for automation/reusable queries; use name filters** (`frontend.name`) **for ad-hoc exploration.**

**Custom action detection (GTM tags):**
```dql
// BizEvents from dtrum.sendBizEvent()
fetch bizevents | filter event.type == "your.event.type"
// Custom user actions from dtrum.enterAction()
fetch user.events | filter characteristics.classifier == "user_action" and user_action.type == "custom"
```

---

## 🧠 Dynatrace AI Skills (from [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai))

Skills are portable knowledge packages providing domain-specific DQL context. **Read the relevant skill before writing queries.**

| Skill | Domain | When to Load |
|-----------|--------|-------------|
| `skills/dt-dql-essentials/SKILL.md` | **REQUIRED** — DQL syntax, pitfalls, data objects | Before writing ANY DQL |
| `skills/dt-obs-services/SKILL.md` | Service RED metrics, runtime monitoring | Service performance, SLA |
| `skills/dt-obs-frontends/SKILL.md` | RUM, Web Vitals, user sessions, mobile | Frontend performance |
| `skills/dt-obs-tracing/SKILL.md` | Distributed traces, spans, failures | Trace analysis |
| `skills/dt-obs-logs/SKILL.md` | Log queries, filtering, patterns | Log analysis |
| `skills/dt-obs-problems/SKILL.md` | Problem analysis, root cause, impact | Davis problems |
| `skills/dt-obs-hosts/SKILL.md` | Host/process metrics, infrastructure | CPU, memory, disk |
| `skills/dt-obs-kubernetes/SKILL.md` | K8s clusters, pods, nodes, workloads | Kubernetes |
| `skills/dt-obs-aws/SKILL.md` | AWS resources, cost, security | AWS infrastructure |
| `skills/dt-obs-azure/SKILL.md` | Azure cloud resources, cost, networking | Azure infrastructure |
| `skills/dt-obs-gcp/SKILL.md` | GCP cloud resources, cost, networking | GCP infrastructure |
| `skills/dt-obs-predictive-analytics/SKILL.md` | Trend detection, forecasting, anomaly scoring | Predictive analysis |
| `skills/dt-alerting/SKILL.md` | Alerting config, anomaly detectors, notifications | Alert setup |
| `skills/dt-js-runtime/SKILL.md` | Dynatrace JS runtime, SDKs, automation | App/workflow development |
| `skills/dt-app-dashboards/SKILL.md` | Dashboard creation/modification | Building dashboards |
| `skills/dt-app-notebooks/SKILL.md` | Notebook creation/modification | Building notebooks |
| `skills/dt-migration/SKILL.md` | Classic entity → Smartscape migration | Migrating old DQL |

Each skill directory may contain a `references/` subdirectory with detailed sub-topics. SKILL.md will indicate when to load these with "Load [filename] when:" directives.

### Skill Loading Protocol
1. **Always** read the relevant `SKILL.md` files before executing any query, command, or code change
2. **Always** load `skills/dt-dql-essentials/SKILL.md` before writing DQL
3. Load domain-specific skills based on the user's request
4. When a SKILL.md says "Load [file] when:", read that file from the skill's `references/` subdirectory on demand
5. Reference the Semantic Dictionary for field validation: https://docs.dynatrace.com/docs/shortlink/semantic-dictionary

---

## 📋 Reusable Prompt Templates

Prompt files in `.github/prompts/` work as VS Code slash commands:

| Prompt | Command | Use Case |
|--------|---------|----------|
| `dt-daily-standup.prompt.md` | `/dt-daily-standup` | Daily standup report |
| `dt-health-check.prompt.md` | `/dt-health-check` | Production health check |
| `dt-incident-response.prompt.md` | `/dt-incident-response` | Active incident response |
| `dt-investigate-error.prompt.md` | `/dt-investigate-error` | Error investigation |
| `dt-performance-regression.prompt.md` | `/dt-performance-regression` | Deployment regression |
| `dt-troubleshoot-problem.prompt.md` | `/dt-troubleshoot-problem` | Problem troubleshooting |

---

## 📚 Reference Files Index

| File | Purpose |
|------|---------|
| `reference/DATA_REFERENCE_INDEX.md` | **START HERE** - Central index |
| `reference/Entities_Reference.md` | Cached entity IDs |
| `reference/BizEvents_Reference.md` | Event types |
| `reference/Spans_Reference.md` | Span/trace patterns |
| `reference/Logs_Reference.md` | Log and error patterns |
| `reference/Metrics_Reference.md` | Free metric queries |
| `reference/MCP_Query_Optimization_Guide.md` | Full cost guide |
| `reference/mcp_query_tracking_schema.md` | MCP telemetry event schema |
| `reference/scope_increase.md` | Token scope gaps & required permission fixes |
| `AI_Prompt.md` | Task templates |
| `skills/` | **Dynatrace AI Skills** (DQL essentials, observability, platform) |
| `.github/prompts/` | **Reusable prompt templates** (slash commands) |
| `example/MCP_Query_Usage_Dashboard.json` | MCP usage tracking dashboard |

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

---

## 🎯 Common Analysis Patterns

### Pattern 1: Service Performance Analysis
1. Read `reference/Entities_Reference.md` for service ID (or find_entity_by_name)
2. Use FREE metrics for request counts, response times, error rates
3. Only dive into spans if metrics show anomaly
4. Document findings in `reference/Spans_Reference.md`

### Pattern 2: Error Investigation  
1. Check `reference/Logs_Reference.md` for known error patterns
2. Query logs with loglevel filter (10-15 GB for 24h)
3. Identify top error services
4. Document new patterns in `reference/Logs_Reference.md`

### Pattern 3: Business Event Analysis
1. Check `reference/BizEvents_Reference.md` for known event types
2. Start with event.type summary query
3. Filter by specific event.type + dimensions
4. Document new event types in `reference/BizEvents_Reference.md`

### Pattern 4: New Dashboard Creation
1. Read ALL reference files for available data
2. Use cached entity IDs (no lookups needed)
3. Prefer FREE metrics over spans
4. Use BizEvents for business KPIs
5. Follow Gen 3 dashboard format (example/ directory)

### Pattern 5: GTM / Custom Tag Deployment Verification
1. **Check BizEvents first** (cheapest): `fetch bizevents | filter event.type == "expected.event.type"` — 0 GB if no data
2. **Check custom user actions**: `fetch user.events | filter characteristics.classifier == "user_action" and user_action.type == "custom"` (~8 GB for 7d)
3. **Check page has traffic** (to rule out no visitors): `fetch user.events | filter page.url.path == "/path/" | summarize count = count(), by:{characteristics.classifier}` (~2-10 GB)
4. **If all return 0:** tag not firing — advise customer to check GTM publish status, triggers, and DOM selectors

### Pattern 6: RUM Session & Event Analysis
1. **Start with user.sessions** (VERY CHEAP: <0.3 GB) for session counts, bounce rates, device mix
2. **Pre-filter user.events** by `characteristics.classifier` FIRST (saves 90%+ of scan cost)
3. **Use page.url.path** exact match, NEVER page.url.domain string filter (174 GB vs 4 GB)
4. **Correct entity filters:** Prefer `dt.rum.application.entity` (PRIMARY) on user.events, `in(dt.rum.application.entities,...)` (PRIMARY) on user.sessions; `frontend.name` acceptable as ALTERNATIVE for human-readable queries
5. **See reference/Entities_Reference.md** for full filter cheat sheet with verified correct/wrong patterns

---

## Environment
- **Dynatrace Tenant:** [TENANT_ID]
- **Customer:** [CLIENT_NAME]

---

## 🔀 Gen 2 API Access (only when `MCP_GRAIL_ONLY=no`)

> **If `MCP_GRAIL_ONLY=yes` (default):** Ignore this entire section. Use ONLY Gen 3 Grail DQL queries via MCP tools.

When `MCP_GRAIL_ONLY=no`, the following Gen 2 capabilities are available:

### 🔑 Gen 2 Token Reference
| Token | Env Variable | Scopes | Use For |
|-------|-------------|--------|---------|
| Gen 2 API Token | `DT_GEN2_API_TOKEN` | `ReadConfig`, `DTAQLAccess`, `settings.read` | USQL queries, session/action properties, Gen 2 config reads |

### Using the Gen 2 Token
For Gen 2 API calls (USQL, Settings 2.0), use `DT_GEN2_API_TOKEN` against the **classic URL** (`DT_CLASSIC_ENVIRONMENT`):
```bash
# USQL queries
curl -G -H "Authorization: Api-Token $DT_GEN2_API_TOKEN" --data-urlencode "query=SELECT ..." "$DT_CLASSIC_ENVIRONMENT/api/v1/userSessionQueryLanguage/table"
# Settings 2.0
curl -H "Authorization: Api-Token $DT_GEN2_API_TOKEN" "$DT_CLASSIC_ENVIRONMENT/api/v2/settings/objects?schemaIds=...&scopes={appId}"
```

### ⚠️ Reading Gen 2 User Session & Action Properties
**Use the USQL API endpoint — NOT the Config API v1 `userActionAndSessionProperties` endpoint** (it may return 404).

**Session properties:**
```sql
SELECT usersession.stringProperties, usersession.longProperties, usersession.doubleProperties
FROM usersession WHERE useraction.application="{App Display Name}" LIMIT 20
```

**Action properties:**
```sql
SELECT useraction.stringProperties, useraction.longProperties, useraction.doubleProperties
FROM useraction WHERE useraction.application="{App Display Name}" LIMIT 20
```

**Notes:**
- The `application` filter uses the Gen 2 **display name**, not the entity ID
- Gen 2 application IDs (e.g. `APPLICATION-XXXX`) may differ from Gen 3 entity IDs
- Use a Python script rather than raw curl to avoid shell escaping issues with USQL
- Requires `DTAQLAccess` scope on the token

---

## 🏷️ Feature Flag Quick Reference

| Flag | Default | Effect When `yes` | Effect When `no` |
|------|---------|-------------------|------------------|
| `MCP_GRAIL_ONLY` | `yes` | Only Gen 3 Grail DQL via MCP tools | Gen 2 USQL & classic APIs also available |
| `MCP_USE_USER_VARIABLE` | `yes` | Resolve `MCP_USER_ID`, include on events | Skip user identity, omit `user.id` |
| `MCP_SEND_TRACKING_EVENTS` | `yes` | Send CUSTOM_INFO event after every query | Skip all tracking events |

---

## � Dynatrace Semantic Dictionary
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

## �💡 Remember

**The goal is to build institutional knowledge that persists across sessions.**
**Every query is an opportunity to learn and document.**
**Future sessions should be faster and cheaper than current ones!**
