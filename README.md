# Dynatrace MCP Workspace

> **Version:** 3.0  
> **Created:** 30 January 2026  
> **Updated:** 18 June 2026  
> **Purpose:** Reusable, auto-updating Dynatrace MCP workspace with cost optimization, self-learning capabilities, and multi-tenant skill propagation
>
> **What's new in 3.0:**
> - **Auto-updating skills** — Skills sync from [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) weekly via GitHub Actions. Users receive updates via `git pull`.
> - **Custom skill support** — `skills-lock.json` v2 tracks both upstream and custom skills. Custom skills are never overwritten by the sync.
> - **Reference files are now local-only** — `reference/*.md` files are gitignored (tenant-specific data stays safe across pulls). Templates (`*.template.md`) are tracked.
> - **Auto-pull on workspace open** — VS Code task runs `git pull --ff-only` silently when the workspace opens.
> - **One-way sync** — Push is disabled after migration to prevent accidental upload of tenant data.
> - **First-run setup script** — `bash setup.sh` initializes reference files from templates and validates `.env`.

---

## 🚀 New Install

```bash
git clone https://github.com/mf-dynatrace/dt-mcp-workspace.git my-client-workspace
cd my-client-workspace
bash setup.sh
cp .env.example .env
```

Edit `.env` with your Dynatrace credentials:
```dotenv
DT_ENVIRONMENT=https://YOUR_TENANT_ID.apps.dynatrace.com
DT_PLATFORM_TOKEN=YOUR_PLATFORM_TOKEN_HERE
MCP_USER_ID=your.email@company.com
```

Then launch your AI client:
- **VS Code:** `code .` → Copilot Chat → *"What environment am I connected to?"*
- **Claude Code:** `claude` from the workspace root

> See [INSTALL.md](INSTALL.md) for detailed platform-specific instructions, token scopes, and Windows setup.

---

## ⬆️ Upgrade (From MCP-cleanDeploy)

If you have an existing workspace (git-cloned **or** folder-copied):

```bash
cd my-client-workspace
curl -fsSL https://raw.githubusercontent.com/mf-dynatrace/dt-mcp-workspace/main/migrate-to-v3.sh -o migrate-to-v3.sh
bash migrate-to-v3.sh
```

The migration script:
1. Backs up your `.env` and `reference/*.md` files
2. Connects to the new repo (initializes git if needed)
3. Pulls the latest structure (skills, prompts, instructions)
4. Restores your reference data (now gitignored — safe from future pulls)
5. Disables push (one-way sync — prevents accidental upload of tenant data)

---

## 🔄 Receiving Updates

### Automatic (VS Code)
A background task runs `git pull --ff-only` every time the workspace opens. Updated skills, prompts, and instructions arrive silently.

### Manual
```bash
git pull --ff-only
```

### What updates vs what stays local

| Updated automatically | Never overwritten |
|----------------------|-------------------|
| `skills/*.md` (synced weekly from [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai)) | `.env` — your credentials |
| `CLAUDE.md`, `.github/copilot-instructions.md` | `reference/*.md` — your cached tenant data |
| `.github/prompts/*` — slash commands | `report/` — your generated reports |
| `example/*` — dashboards & workflows | |

> **Push is disabled by design.** After migration, `git push` is blocked to prevent accidental upload of customer data.

### Adding Custom Skills
Add your own skills to `skills/` and register them in `skills-lock.json` with `"source": "custom"`. The upstream sync **only touches files sourced from `dynatrace/dynatrace-for-ai`** — custom skills are never overwritten.

---

## 🔌 Supported AI Clients

| Client | Config File | Loads `.env` Via |
|--------|-------------|-----------------|
| **VS Code + GitHub Copilot** | `.vscode/mcp.json` | VS Code `envFile` (native) |
| **Claude Code** (CLI / desktop / IDE) | `.mcp.json` | `bash -c "source .env && ..."` |

> Both configs are included. Configure `.env` once — works for both.
>
> ⚠️ **Claude Code reads `.mcp.json` at the workspace root — not `.claude/settings.json`.** `.claude/settings.json` is only for `enableAllProjectMcpServers: true` (auto-approval).

### Token Scopes

Create a Platform Token in Dynatrace with:

| Scope | Required For |
|-------|-------------|
| `app-engine:apps:run` | MCP server |
| `storage:logs:read` | Log queries |
| `storage:events:read` | Event queries |
| `storage:spans:read` | Trace/span queries |
| `storage:bizevents:read` | Business events |
| `storage:metrics:read` | Metric queries |
| `storage:entities:read` | Entity lookups |
| `storage:user.sessions:read` | RUM sessions (optional) |
| `storage:user.events:read` | RUM events (optional) |
| `storage:security.vulnerabilities:read` | Vulnerabilities (optional) |
| `storage:problems:read` | Davis problems (optional) |

### Feature Flags

| Flag | Default | What It Does |
|------|---------|-------------|
| `MCP_GRAIL_ONLY=yes` | `yes` | Gen 3 Grail DQL only. Set `no` for Gen 2 USQL. |
| `MCP_USE_USER_VARIABLE=yes` | `yes` | Include `user.id` on tracking events. |
| `MCP_SEND_TRACKING_EVENTS=yes` | `yes` | Send CUSTOM_INFO event after every query. |

### Placeholder Replacement

Replace these in `CLAUDE.md` and `copilot-instructions.md`:

| Placeholder | Replace With | Example |
|-------------|--------------|---------|
| `[CLIENT_NAME]` | Customer name | "Acme Corporation" |
| `[TENANT_ID]` | Dynatrace tenant ID | "abc12345" |
| `[INDUSTRY]` | Customer industry | "E-commerce" |
| `[WEBSITE_URL]` | Customer website | "www.acme.com" |

> **Tip:** Ask your AI: *"Replace all placeholders — prompt me for values before writing"*

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

When `MCP_SEND_TRACKING_EVENTS=yes` (default), AI assistants automatically send a CUSTOM_INFO event after every MCP query, providing:
- Complete visibility into MCP query usage
- Cost tracking and budget monitoring
- User-level consumption analytics *(when `MCP_USE_USER_VARIABLE=yes`)*

### Setup
1. Set `MCP_SEND_TRACKING_EVENTS=yes` in `.env` (default)
2. Set `MCP_USER_ID` to identify your queries
3. Import `example/MCP_Query_Usage_Dashboard.json` into Dynatrace

### Query tracking events
```dql
fetch events
| filter event.type == "CUSTOM_INFO" and event.name == "MCP Query Execution"
```

See `reference/mcp_query_tracking_schema.template.md` for full event schema.

---

## 🎯 Core Principles

### 1. Cost Optimization
- **Query Priority:** FREE tools first (`find_entity_by_name`, `list_problems`, `timeseries`), expensive queries last
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

## ✅ First Session Checklist

- [ ] `.env` configured with credentials
- [ ] Connection verified ("What environment am I connected to?")
- [ ] Placeholders replaced in `CLAUDE.md` and `copilot-instructions.md`
- [ ] Run `find_entity_by_name` to discover key services (FREE)
- [ ] Update `reference/Entities_Reference.md` with discovered IDs
- [ ] Run a BizEvents summary to discover event types
- [ ] Update `reference/BizEvents_Reference.md`

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

## 🆘 Troubleshooting

| Problem | Fix |
|---------|-----|
| MCP not connecting (VS Code) | Check `DT_ENVIRONMENT` URL format (`*.apps.dynatrace.com`); reload window |
| MCP not connecting (Claude Code) | Confirm `.mcp.json` at workspace root; run `claude` from that folder |
| MCP not connecting (Windows) | `bash` must be on PATH (Git for Windows); or pre-export `.env` vars |
| Auth errors | Verify token scopes match table above |
| "Not authorized for table" | Add missing `storage:*:read` scope to token |
| Copilot ignoring instructions | Ensure `.github/copilot-instructions.md` at workspace root |
| Claude ignoring instructions | Ensure `CLAUDE.md` at workspace root |
| High query costs | Read `reference/MCP_Query_Optimization_Guide.md` |
| `git push` fails | By design — workspace is pull-only after migration |
| Untracked files after upgrade | Gitignored files are safe; local-only data won't be pushed |

---

## 📚 Additional Resources

- [Dynatrace DQL Documentation](https://docs.dynatrace.com/docs/platform/grail/dynatrace-query-language)
- [Dynatrace Gen 3 Dashboards](https://docs.dynatrace.com/docs/observe-and-explore/dashboards-new)
- [Dynatrace BizEvents](https://docs.dynatrace.com/docs/platform/grail/data-model/business-events)
- [Dynatrace Semantic Dictionary](https://docs.dynatrace.com/docs/shortlink/semantic-dictionary)
- [dynatrace-for-ai Skills](https://github.com/Dynatrace/dynatrace-for-ai) — upstream skill source
