# dt-mcp-workspace — Install & Upgrade Guide

> Get a Dynatrace MCP workspace running in 5 minutes.  
> **Version 3.0** — Auto-updating skills, one-way sync, multi-tenant safe.

---

## New Install (Fresh Deployment)

### Prerequisites

- **Node.js 18+** — [nodejs.org](https://nodejs.org)
- **VS Code** with GitHub Copilot (Chat enabled) — *for Copilot users*
- **Claude Code** installed — *for Claude users* (`npm install -g @anthropic-ai/claude-code`)
- **Dynatrace Platform Token** with required scopes

> Works on **macOS**, **Windows**, and **Linux**. Platform-specific commands noted below.

### Step 1: Clone & Initialize

**macOS / Linux:**
```bash
git clone https://github.com/mf-dynatrace/dt-mcp-workspace.git my-client-workspace
cd my-client-workspace
bash setup.sh
```

**Windows (Git Bash or PowerShell):**
```powershell
git clone https://github.com/mf-dynatrace/dt-mcp-workspace.git my-client-workspace
cd my-client-workspace
bash setup.sh
```

> `setup.sh` creates `reference/*.md` files from templates, validates your environment, and creates the `report/` directory. On Windows, use Git Bash to run it.

### Step 2: Create Your `.env`

```bash
cp .env.example .env
```

Edit `.env` with your Dynatrace credentials:

```dotenv
DT_ENVIRONMENT=https://YOUR_TENANT_ID.apps.dynatrace.com
DT_PLATFORM_TOKEN=YOUR_PLATFORM_TOKEN_HERE
MCP_USER_ID=your.email@company.com
```

### Step 3: Token Scopes

Create a **Platform Token** in Dynatrace with:

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

### Step 4: Launch Your AI Client

**VS Code + GitHub Copilot:**
```bash
code .
```
The MCP server auto-starts via `.vscode/mcp.json`. Verify in Copilot Chat:  
> "What Dynatrace environment am I connected to?"

**Claude Code (macOS / Linux):**
```bash
claude
```
Run from the workspace root. Claude Code loads `.mcp.json` automatically.

**Claude Code (Windows):**
```powershell
Get-Content .env | Where-Object { $_ -notmatch '^#' -and $_ -ne '' } | ForEach-Object {
    $k, $v = $_ -split '=', 2; [System.Environment]::SetEnvironmentVariable($k, $v)
}
claude
```

**VS Code extension (Claude):** After cloning, run **Developer: Reload Window** (`Cmd/Ctrl+Shift+P`) so the extension picks up `.mcp.json`, then check `/mcp`.

### Step 5: Replace Placeholders

Search and replace across all files:

| Placeholder | Replace With |
|-------------|-------------|
| `[CLIENT_NAME]` | Customer name |
| `[TENANT_ID]` | Dynatrace tenant ID |
| `[INDUSTRY]` | Customer industry |
| `[WEBSITE_URL]` | Customer website URL |

> **Tip:** Ask your AI to do this: *"Replace all placeholders — prompt me for values before writing"*

---

## Upgrade (Existing MCP-cleanDeploy Workspace)

### If the workspace was git-cloned:

```bash
cd my-client-workspace
curl -fsSL https://raw.githubusercontent.com/mf-dynatrace/dt-mcp-workspace/main/migrate-to-v3.sh -o migrate-to-v3.sh
bash migrate-to-v3.sh
```

### If the workspace was folder-copied (no `.git` directory):

Same command — the migration script detects this and initializes git automatically:

```bash
cd my-client-workspace
curl -fsSL https://raw.githubusercontent.com/mf-dynatrace/dt-mcp-workspace/main/migrate-to-v3.sh -o migrate-to-v3.sh
bash migrate-to-v3.sh
```

### What the migration does:
1. **Backs up** your `.env` and `reference/*.md` files
2. **Connects** the workspace to `mf-dynatrace/dt-mcp-workspace` (initializes git if needed)
3. **Pulls** the latest structure (skills, prompts, instructions, examples)
4. **Restores** your reference files (now gitignored — safe from future pulls)
5. **Disables push** (one-way sync only — prevents accidental upload of tenant data)

### After migration:
- Your `.env` and reference data are **unchanged**
- Skills are now at the **latest version** (17 skills including new Azure, GCP, alerting, JS runtime, predictive analytics)
- VS Code will **auto-pull updates** every time you open the workspace
- No further manual steps needed

---

## Receiving Updates (After Install or Upgrade)

### Automatic (VS Code)
A background task runs `git pull --ff-only` every time the workspace opens. You get updated skills, prompts, and instructions silently.

### Manual (Claude Code or terminal)
```bash
cd my-client-workspace
git pull --ff-only
```

### What updates include
- Skills (synced weekly from [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai))
- Instruction files (`CLAUDE.md`, `copilot-instructions.md`)
- Prompt templates (`.github/prompts/`)
- Example dashboards and workflows

### What is NEVER overwritten by updates
- `.env` — your credentials (gitignored)
- `reference/*.md` — your tenant-specific cached data (gitignored)
- `report/` — your generated reports (gitignored)

### Push is disabled by design
After migration, `git push` is blocked. This workspace is **pull-only** to prevent accidental upload of customer data to the shared repo.

---

## Supported AI Clients

| Client | Config File | How It Connects |
|--------|-------------|-----------------|
| **VS Code + GitHub Copilot** | `.vscode/mcp.json` | VS Code native `envFile` support |
| **Claude Code** (CLI / desktop / IDE) | `.mcp.json` | Bash wrapper sources `.env` |

> **Both configs are included.** Configure `.env` once — works for both.
>
> ⚠️ **Claude Code reads `.mcp.json` (workspace root), NOT `.claude/settings.json`.** The `mcpServers` key only works in `.mcp.json`. `.claude/settings.json` is only for `enableAllProjectMcpServers` (auto-approval).

---

## Feature Flags (Optional)

All default to `yes`. Set to `no` in `.env` to disable:

| Flag | Effect when `no` |
|------|-----------------|
| `MCP_GRAIL_ONLY` | Enables Gen 2 USQL/classic APIs |
| `MCP_USE_USER_VARIABLE` | Skips user identity on events |
| `MCP_SEND_TRACKING_EVENTS` | Disables query tracking |

---

## File Structure

```
.env                            ← Your credentials (gitignored)
.mcp.json                       ← MCP server config for Claude Code
.vscode/mcp.json                ← MCP server config for VS Code + Copilot
.vscode/tasks.json              ← Auto-pull updates on workspace open
.claude/settings.json           ← Claude Code: enableAllProjectMcpServers
.github/copilot-instructions.md ← GitHub Copilot behaviour rules
CLAUDE.md                       ← Claude Code behaviour rules
setup.sh                        ← First-run initialization
migrate-to-v3.sh                ← One-time upgrade from MCP-cleanDeploy
skills-lock.json                ← Skill registry (upstream + custom)
skills/                         ← DQL domain knowledge (auto-synced + custom)
reference/*.template.md         ← Clean templates (git-tracked)
reference/*.md                  ← Tenant-specific data (gitignored)
example/                        ← Sample dashboards & workflows
report/                         ← Generated reports (gitignored)
```

---

## First Session Checklist

- [ ] `.env` configured with credentials
- [ ] Connection verified ("What environment am I connected to?")
- [ ] Placeholders replaced in `CLAUDE.md` and `copilot-instructions.md`
- [ ] Run `find_entity_by_name` to discover key services (FREE)
- [ ] Update `reference/Entities_Reference.md` with discovered IDs
- [ ] Run a BizEvents summary to discover event types
- [ ] Update `reference/BizEvents_Reference.md`

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| MCP not connecting (VS Code) | Check `DT_ENVIRONMENT` URL format (`*.apps.dynatrace.com`); reload window |
| MCP not connecting (Claude Code) | Confirm `.mcp.json` exists at workspace root; run `claude` from that folder; reload window in VS Code extension |
| MCP not connecting (Windows) | `bash` must be on PATH (Git for Windows) — or pre-export `.env` vars before `claude` |
| Auth errors | Verify token scopes match table above |
| "Not authorized for table" | Add missing `storage:*:read` scope to token |
| Copilot ignoring instructions | Ensure `.github/copilot-instructions.md` at workspace root |
| Claude ignoring instructions | Ensure `CLAUDE.md` at workspace root |
| High query costs | Read `reference/MCP_Query_Optimization_Guide.md` |
| `git push` fails | By design — workspace is pull-only after migration |
| Untracked files after upgrade | Run `git status` — gitignored files are safe; any "U" files are local-only |
