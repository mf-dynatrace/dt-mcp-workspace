# Dynatrace MCP Workspace

> **Version:** 3.0  
> **Created:** 30 January 2026  
> **Updated:** 18 June 2026  
> **Purpose:** Reusable, auto-updating template for Dynatrace MCP connections with cost optimization, self-learning capabilities, and multi-tenant skill propagation
>
> **What's new in 3.0:**
> - **Auto-updating skills** — Skills sync from [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) weekly via GitHub Actions. Users receive updates via `git pull`.
> - **Custom skill support** — `skills-lock.json` v2 tracks both upstream and custom skills. Custom skills are never overwritten by the sync.
> - **Reference files are now local-only** — `reference/*.md` files are gitignored (tenant-specific data stays safe across pulls). Templates (`*.template.md`) are tracked.
> - **Auto-pull on workspace open** — VS Code task runs `git pull --ff-only` silently when the workspace opens.
> - **First-run setup script** — `bash setup.sh` initializes reference files from templates and validates `.env`.

---

## 🔌 MCP Server Setup

### Supported AI Clients

This workspace supports two AI clients — both use the same `.env` file:

| Client | Config File | Loads `.env` Via |
|--------|-------------|-----------------|
| **VS Code + GitHub Copilot** | `.vscode/mcp.json` | VS Code `envFile` (native) |
| **Claude Code** (CLI / desktop / IDE) | `.mcp.json` | `bash -c "source .env && ..."` |

> ⚠️ **Claude Code reads `.mcp.json` at the workspace root — not `.claude/settings.json`.** A `mcpServers` block in `.claude/settings.json` is silently ignored by Claude Code. `.claude/settings.json` is used only for `enableAllProjectMcpServers: true` (auto-approves the project server so users skip the trust prompt).

### Prerequisites
- **Node.js 18+** installed
- Choose your AI client:
  - **VS Code + GitHub Copilot** — Chat extension enabled
  - **Claude Code** — `npm install -g @anthropic-ai/claude-code`
- **Dynatrace Platform Token** with required scopes

### Step 1: Create Your .env File

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env` with your Dynatrace credentials:
```dotenv
# Your Dynatrace Platform URL (use apps.dynatrace.com format)
DT_ENVIRONMENT=https://abc12345.apps.dynatrace.com

# Platform Token with required scopes
DT_PLATFORM_TOKEN=YOUR_PLATFORM_TOKEN_HERE

# Feature flags (yes/no) - see Feature Flags section below
MCP_GRAIL_ONLY=yes
MCP_USE_USER_VARIABLE=yes
MCP_SEND_TRACKING_EVENTS=yes
```

### Step 2: Required Token Scopes

Create a Platform Token in Dynatrace with these scopes:

**Core Data Access:**
- `app-engine:apps:run`
- `storage:logs:read`
- `storage:events:read`
- `storage:spans:read`
- `storage:bizevents:read`
- `storage:metrics:read`
- `storage:entities:read`

**RUM/Session Analytics (if using Real User Monitoring):**
- `storage:user.sessions:read` - Gen3 session analytics (cheaper than user.events!)
- `storage:user.events:read` - RUM events (JS errors, navigations, interactions)

**Security/Problems (if needed):**
- `storage:security.vulnerabilities:read` - Vulnerability data
- `storage:problems:read` - Davis problem data

**Note:** Use `user.sessions` (dot-notation) for session-level aggregates. It's much cheaper than `user.events` for device/geo/engagement analysis.

### Step 3: Verify MCP Connection

**VS Code + GitHub Copilot:**
1. Open VS Code in this workspace (`code .`)
2. The MCP server starts automatically via `.vscode/mcp.json`
3. Ask in Copilot Chat: *"What Dynatrace environment am I connected to?"*

**Claude Code (macOS/Linux):**
1. Run `claude` from the workspace root (the folder containing `.env` and `.mcp.json`)
2. The MCP server starts automatically via `.mcp.json`
3. Ask: *"What Dynatrace environment am I connected to?"*

> **Using the VS Code extension?** After cloning/opening, run **Developer: Reload Window** (`Cmd/Ctrl+Shift+P`) so the extension reads `.mcp.json` (only loaded at session start), then check `/mcp` to confirm `dynatrace-mcp-server` is connected.

**Claude Code (Windows):**
```powershell
# Export .env variables to your session first
Get-Content .env | Where-Object { $_ -notmatch '^#' -and $_ -ne '' } | ForEach-Object {
    $k, $v = $_ -split '=', 2; [System.Environment]::SetEnvironmentVariable($k, $v)
}
claude
```

---

## �🚀 Quick Start

### Step 1: Configure for Your Client

Replace these placeholders throughout all files:

| Placeholder | Replace With | Example |
|-------------|--------------|---------|
| `[CLIENT_NAME]` | Customer name | "Acme Corporation" |
| `[TENANT_ID]` | Dynatrace tenant ID | "abc12345" |
| `[DATE]` | Current date | "30 January 2026" |
| `[INDUSTRY]` | Customer industry | "E-commerce" |
| `[WEBSITE_URL]` | Customer website | "www.acme.com" |

Or ask AI to Prompt for all and replace the placeholders where required

### Feature Flags

Three `.env` flags control AI assistant behaviour:

| Flag | Default | What It Does |
|------|---------|-------------|
| `MCP_GRAIL_ONLY=yes` | `yes` | **Gen 3 only** — AI uses only Grail DQL via MCP tools. Set to `no` to also enable Gen 2 USQL and classic API calls (requires `DT_GEN2_API_TOKEN`). |
| `MCP_USE_USER_VARIABLE=yes` | `yes` | **User tracking** — AI resolves `MCP_USER_ID` at session start and includes `user.id` on all tracking events. Set to `no` to skip user identity entirely. |
| `MCP_SEND_TRACKING_EVENTS=yes` | `yes` | **Query telemetry** — AI sends a CUSTOM_INFO event to Dynatrace after every MCP query. Set to `no` to disable all tracking events. |

### Step 2: Copy to New Location

```bash
git clone https://github.com/mf-dynatrace/dt-mcp-workspace.git my-client-workspace
cd my-client-workspace
bash setup.sh
```

### Step 3: Initial Data Discovery

Start your first session by running these FREE queries:
1. `find_entity_by_name` - Discover entities
2. `list_problems` - Check active problems
3. BizEvents summary query - Discover event types
4. Metrics discovery query - Find available metrics

### Step 4: Populate Reference Files

As you discover data, update the reference files:
- Add entities to `reference/Entities_Reference.md`
- Add event types to `reference/BizEvents_Reference.md`
- Add span patterns to `reference/Spans_Reference.md`
- Add error patterns to `reference/Logs_Reference.md`
- Add metrics to `reference/Metrics_Reference.md`

---

## 📁 File Structure

```
dt-mcp-workspace/
├── .env.example                   # Environment template (copy to .env)
├── .gitignore                     # Excludes .env, reference/*.md, report/
├── .github/
│   ├── copilot-instructions.md    # GitHub Copilot instructions (auto-loaded)
│   └── workflows/
│       └── sync-skills.yml        # Weekly upstream skill sync (GitHub Action)
├── .mcp.json                      # MCP server config — Claude Code
├── .vscode/
│   ├── mcp.json                   # MCP server config — VS Code + Copilot
│   ├── settings.json              # VS Code settings
│   └── tasks.json                 # Auto-pull on workspace open
├── .claude/
│   └── settings.json              # Claude Code: enableAllProjectMcpServers
├── CLAUDE.md                      # Claude Code AI instructions (auto-loaded)
├── setup.sh                       # First-run initialization
├── migrate-to-v3.sh               # Migration from MCP-cleanDeploy (one-time)
├── skills-lock.json               # Skill registry (upstream + custom)
├── skills/                        # DQL domain knowledge (auto-synced + custom)
├── reference/
│   ├── *.template.md              # Clean starting templates (git-tracked)
│   └── *.md                       # Tenant-specific data (gitignored, local-only)
├── example/                       # Sample dashboards & workflows
└── report/                        # Generated reports (gitignored)
```

---

## 📊 MCP Query Tracking

### Overview
When `MCP_SEND_TRACKING_EVENTS=yes` (default), all MCP queries are automatically tracked via `send_event` (CUSTOM_INFO events). This provides:
- Complete visibility into MCP query usage
- Cost tracking and budget monitoring
- User-level consumption analytics *(when `MCP_USE_USER_VARIABLE=yes`)*
- Query optimization insights

**When `MCP_SEND_TRACKING_EVENTS=no`:** Tracking is completely disabled. No events are sent.

### Setup
1. Set `MCP_SEND_TRACKING_EVENTS=yes` in your `.env` file (default)
2. Set `MCP_USER_ID` in your `.env` file to identify your queries *(if `MCP_USE_USER_VARIABLE=yes`)*
3. Import `example/MCP_Query_Usage_Dashboard.json` into Dynatrace
4. AI assistants will automatically send tracking events after each query

### How It Works
After every MCP query (execute_dql, list_problems, find_entity_by_name, etc.), the AI sends a tracking event:
```
event.name: "MCP Query Execution"
event.type: CUSTOM_INFO
properties:
  query.bytes_scanned: "0.84"
  query.cost_usd: "0.042"
  user.id: "your.email@company.com"
  ...
```

### Dashboard Queries
Query tracking events with:
```dql
fetch events
| filter event.type == "CUSTOM_INFO" and event.name == "MCP Query Execution"
```

See [reference/mcp_query_tracking_schema.md](reference/mcp_query_tracking_schema.md) for full event schema.

---

## 🎯 Core Principles

### 1. Cost Optimization
- **Query Priority:** FREE tools first, expensive queries last
- **Timeframes:** Start with 24h, extend only if needed
- **Filters:** Always filter by event.type/entity before other filters
- **Aggregation:** Use summarize, not raw data

### 2. Self-Learning
- **Update Reference Files:** After EVERY discovery, update the relevant file
- **Cache Entity IDs:** Never look up the same entity twice
- **Document Patterns:** Record what works for future sessions

### 3. Session Continuity
- **Read First:** Always read reference files before querying
- **Check Existing Data:** Data may already be documented
- **Incremental Updates:** Add new learnings to existing docs

---

## 🔄 Receiving Updates

### Automatic (VS Code)
When you open the workspace in VS Code, a background task runs `git pull --ff-only` to fetch the latest skills, prompts, and instruction updates. Your local data (`.env`, `reference/*.md`, `report/`) is gitignored and will **not** be affected.

### Manual
```bash
cd my-client-workspace
git pull --ff-only
```

### What updates include
- **Skills** — synced weekly from [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) via GitHub Actions
- **Prompts** — reusable slash commands in `.github/prompts/`
- **Instructions** — `CLAUDE.md`, `.github/copilot-instructions.md`
- **Examples** — dashboard and workflow templates

### What is never overwritten
- `.env` — your credentials
- `reference/*.md` — your tenant-specific cached data
- `report/` — your generated reports

### Adding Custom Skills
Custom skills live alongside upstream skills in `skills/` and are tracked in `skills-lock.json` with `"source": "custom"`. The upstream sync action **only touches files sourced from `dynatrace/dynatrace-for-ai`** — your custom skills are never overwritten.

### Migrating from MCP-cleanDeploy
If you have an existing clone of `MCP-cleanDeploy`, run the one-time migration script:
```bash
bash migrate-to-v3.sh
```
This backs up your reference data, pulls the new structure, and restores your files (now safely gitignored).

---

## 📊 Query Cost Reference

| Query Type | Typical Cost | When to Use |
|------------|-------------|-------------|
| `find_entity_by_name` | 0 GB (FREE) | Always - first step |
| `list_problems` | 0 GB (FREE) | Problem investigation |
| `timeseries` metrics | 0 GB (FREE) | Performance trends |
| BizEvents (filtered, 7d) | 0.5-5 GB | Business analysis |
| Logs (loglevel filter, 24h) | 10-15 GB | Error investigation |
| Spans (entity filter, 24h) | 15-20 GB | Trace analysis |
| Spans (entity filter, 7d) | 100-130 GB | **AVOID** |
| Logs/Spans (unfiltered) | 300+ GB | **NEVER** |

---

## ✅ Checklist for New Deployments

- [ ] Copy `.env.example` to `.env`
- [ ] Configure `DT_ENVIRONMENT` with your tenant URL
- [ ] Configure `DT_PLATFORM_TOKEN` with required scopes
- [ ] Set feature flags (`MCP_GRAIL_ONLY`, `MCP_USE_USER_VARIABLE`, `MCP_SEND_TRACKING_EVENTS`)
- [ ] Verify MCP connection (VS Code Copilot **or** Claude Code — "What environment am I connected to?")
- [ ] Replace all `[PLACEHOLDER]` values in reference files
- [ ] Keep `.github/copilot-instructions.md` (for Copilot)
- [ ] Keep `.mcp.json` + `.claude/settings.json` (for Claude Code)
- [ ] Run initial entity discovery
- [ ] Run BizEvents summary query
- [ ] Populate `reference/Entities_Reference.md` with discovered entities
- [ ] Populate `reference/BizEvents_Reference.md` with event types
- [ ] Test a sample dashboard query
- [ ] (Optional) Copy example dashboards to `example/` folder

---

## 🔧 Customization

### Adding New Reference Categories

If your client has unique data types (e.g., custom metrics, specific integrations):

1. Create a new reference file: `CustomData_Reference.md`
2. Add to `DATA_REFERENCE_INDEX.md`
3. Add to `.github/copilot-instructions.md` file references
4. Follow the same self-updating protocol

### Industry-Specific Templates

Modify `AI_Prompt.md` to include:
- Industry-specific KPIs
- Common use case templates
- Client-specific terminology

---

## 📝 Maintenance

### Regular Updates
- Review and clean up reference files monthly
- Archive outdated patterns
- Update cost baselines as data volumes change

### Version Control
- Commit reference file updates frequently
- Tag stable versions before major changes
- Keep changelog of significant discoveries

---

## 🆘 Troubleshooting

### High Query Costs
1. Check if entity ID is cached in `Entities_Reference.md`
2. Verify using metrics instead of spans where possible
3. Reduce timeframe to 24h for exploration
4. Add more filters before executing

### Missing Data
1. Run discovery queries (event types, metrics)
2. Check semantic dictionary for available fields
3. Verify entity exists with `find_entity_by_name`

### Copilot Not Following Instructions
1. Ensure `.github/copilot-instructions.md` is in workspace root
2. Check file is properly formatted (Markdown)
3. Restart Copilot session

---

## 📚 Additional Resources

- [Dynatrace DQL Documentation](https://docs.dynatrace.com/docs/platform/grail/dynatrace-query-language)
- [Dynatrace Gen 3 Dashboards](https://docs.dynatrace.com/docs/observe-and-explore/dashboards-new)
- [Dynatrace BizEvents](https://docs.dynatrace.com/docs/platform/grail/data-model/business-events)
