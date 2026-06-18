# Clean Deploy — Quick Install Guide

> Get a Dynatrace MCP workspace running in 5 minutes.

---

## Supported AI Clients

This workspace works with **two AI clients** — both read credentials from the same `.env` file:

| Client | Config File | How It Connects |
|--------|-------------|-----------------|
| **VS Code + GitHub Copilot** | `.vscode/mcp.json` | Uses VS Code's native `envFile` support |
| **Claude Code** (CLI / desktop / IDE) | `.mcp.json` | Uses a bash wrapper to source `.env` |

> **Both configs are included.** Configure `.env` once — it works for both clients.
>
> ⚠️ **Claude Code reads `.mcp.json` (workspace root), NOT `.claude/settings.json`.** The `mcpServers` key only works in `.mcp.json` for Claude Code. `.claude/settings.json` is used only for `enableAllProjectMcpServers` (auto-approval). If you've seen "MCP not connecting" in Claude Code before, a missing `.mcp.json` is the usual cause.

---

## Prerequisites

- **Node.js 18+** — [nodejs.org](https://nodejs.org)
- **VS Code** with GitHub Copilot (Chat enabled) — *for Copilot users*
- **Claude Code** installed — *for Claude users* (`npm install -g @anthropic-ai/claude-code`)
- **Dynatrace Platform Token** with required scopes

> Works on **macOS**, **Windows**, and **Linux**. Platform-specific commands are noted below.

---

## 1. Download the Template

Download a clean copy of the working folder, using web download or commands, from:  
**https://github.com/mf-dynatrace/dt-mcp-workspace**

**macOS / Linux (Terminal):**
```bash
git clone https://github.com/mf-dynatrace/dt-mcp-workspace.git my-client-workspace
cd my-client-workspace
bash setup.sh
```

**Windows (PowerShell or CMD):**
```powershell
git clone https://github.com/mf-dynatrace/dt-mcp-workspace.git my-client-workspace
cd my-client-workspace
bash setup.sh
```

> `setup.sh` creates `reference/*.md` files from templates and validates your environment. On Windows, use Git Bash to run it.

## 2. Create Your `.env`

**macOS / Linux:**
```bash
cp .env.example .env
```

**Windows (PowerShell):**
```powershell
Copy-Item .env.example .env
```

**Windows (CMD):**
```cmd
copy .env.example .env
```

Open `.env` in any text editor and fill in these three values:

```dotenv
DT_ENVIRONMENT=https://YOUR_TENANT_ID.apps.dynatrace.com
DT_PLATFORM_TOKEN=YOUR_PLATFORM_TOKEN_HERE
MCP_USER_ID=your.email@company.com
```

## 3. Token Scopes

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

## 4a. Open in VS Code (GitHub Copilot)

**macOS / Linux / Windows:**
```bash
code .
```

> If `code` is not recognised on macOS, open VS Code → `Cmd+Shift+P` → "Shell Command: Install 'code' command in PATH".  
> On Windows, the VS Code installer adds `code` to PATH automatically.

The MCP server auto-starts via `.vscode/mcp.json` — no install step needed.  
It runs: `npx -y @dynatrace-oss/dynatrace-mcp-server@latest`

**Verify in Copilot Chat:**
> "What Dynatrace environment am I connected to?"

---

## 4b. Open with Claude Code

Claude Code uses **`.mcp.json`** (at the workspace root) to connect to the same MCP server. It reads credentials directly from `.env` via a bash wrapper. `.claude/settings.json` ships with `enableAllProjectMcpServers: true` so the server is trusted automatically (no approval prompt).

> **Why `.mcp.json` and not `.claude/settings.json`?** Claude Code (CLI, desktop, and the VS Code extension) reads MCP server definitions **only** from `.mcp.json` or `~/.claude.json`. A `mcpServers` block placed in `.claude/settings.json` is silently ignored — this is the #1 cause of "MCP not connecting" in Claude Code.

**macOS / Linux — open with Claude Code:**
```bash
claude
```

> Run this from the workspace root (the folder containing `.env` and `.mcp.json`).  
> Claude Code loads the MCP server automatically at startup.

**VS Code extension:** After cloning, run **Developer: Reload Window** (`Cmd/Ctrl+Shift+P`) so the extension picks up `.mcp.json` — it is only read at session start. Then check `/mcp` to confirm `dynatrace-mcp-server` is connected.

**Windows — export variables first, then run:**
```powershell
# PowerShell: export env vars from .env before starting Claude Code
Get-Content .env | Where-Object { $_ -notmatch '^#' -and $_ -ne '' } | ForEach-Object {
    $k, $v = $_ -split '=', 2; [System.Environment]::SetEnvironmentVariable($k, $v)
}
claude
```

> **Why the difference?** VS Code supports `envFile` natively in `mcp.json`. Claude Code on macOS/Linux uses `bash -c "source .env && ..."` to achieve the same result. On Windows, pre-export the variables to your session before running `claude`.

**Verify in Claude:**
> "What Dynatrace environment am I connected to?"

---

## 6. Replace Placeholders

Search and replace across all files:

| Placeholder | Replace With |
|-------------|-------------|
| `[CLIENT_NAME]` | Customer name |
| `[TENANT_ID]` | Dynatrace tenant ID |
| `[INDUSTRY]` | Customer industry |
| `[WEBSITE_URL]` | Customer website URL |

> **Tip:** You can ask your LLM to mass-change these by prompting:  
> *"Replace all placeholders with the correct information, prompt with discovered values before writing to files"*

---

## Feature Flags (Optional)

All default to `yes`. Set to `no` in `.env` to disable:

| Flag | Effect when `no` |
|------|-----------------|
| `MCP_GRAIL_ONLY` | Enables Gen 2 USQL/classic APIs |
| `MCP_USE_USER_VARIABLE` | Skips user identity on events |
| `MCP_SEND_TRACKING_EVENTS` | Disables query tracking |

---

## File Structure (Key Files)

```
.env                            ← Your credentials (git-ignored)
.mcp.json                       ← MCP server config for Claude Code
.vscode/mcp.json                ← MCP server config for VS Code + Copilot
.vscode/tasks.json              ← Auto-pull updates on workspace open
.claude/settings.json           ← Claude Code: enableAllProjectMcpServers
.github/copilot-instructions.md ← GitHub Copilot behaviour rules
CLAUDE.md                       ← Claude Code behaviour rules
setup.sh                        ← First-run initialization
skills-lock.json                ← Skill registry (upstream + custom)
skills/                         ← DQL domain knowledge (auto-synced + custom)
reference/*.template.md         ← Clean templates (git-tracked)
reference/*.md                  ← Tenant-specific data (gitignored)
example/                        ← Sample dashboards & workflows
report/                         ← Generated reports (gitignored)
```

---

## First Session Checklist

- [ ] `.env` configured
- [ ] Connection verified (`claude` or VS Code — "What environment am I connected to?")
- [ ] Placeholders replaced in `CLAUDE.md` and `copilot-instructions.md`
- [ ] Run `find_entity_by_name` to discover key services (FREE)
- [ ] Update `reference/Entities_Reference.md` with discovered IDs
- [ ] Run a BizEvents summary to discover event types
- [ ] Update `reference/BizEvents_Reference.md`

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| MCP not connecting (VS Code Copilot) | Check `DT_ENVIRONMENT` URL format (must be `*.apps.dynatrace.com`); reload the window |
| MCP not connecting (Claude Code) | Confirm **`.mcp.json` exists at the workspace root** — Claude Code ignores `mcpServers` in `.claude/settings.json`. Run `claude` from the folder containing `.env` and `.mcp.json`, or **Developer: Reload Window** in the VS Code extension. Verify with `/mcp`. |
| MCP not connecting (Claude Code, Windows) | `bash` must be on PATH (install Git for Windows) — or pre-export `.env` vars (see step 4b) before running `claude` |
| Auth errors | Verify token scopes match table above |
| "Not authorized for table" | Add missing `storage:*:read` scope to token |
| Copilot ignoring instructions | Ensure `.github/copilot-instructions.md` exists at workspace root |
| Claude ignoring instructions | Ensure `CLAUDE.md` exists at workspace root |
| High query costs | Read `reference/MCP_Query_Optimization_Guide.md` |
