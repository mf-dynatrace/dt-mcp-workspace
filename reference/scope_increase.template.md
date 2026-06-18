# Dynatrace Token Scope Increase Requests

> **Purpose:** Track permission/scope gaps encountered during MCP queries so they can be fixed by an admin.
> **Environment:** [TENANT_ID]
> **Last Updated:** *(Update when permission errors occur)*

---

## How to Fix
1. Go to **Dynatrace > Settings > Access Tokens**
2. Find the Platform Token used by MCP (`DT_PLATFORM_TOKEN` in `.env`)
3. Add the missing scopes listed below
4. Save and regenerate if needed

---

## ❌ Missing Permissions

*(Add entries as permission errors are encountered during sessions)*

---

## ✅ Resolved Permissions

*(Document resolved issues here as they are fixed)*

---

## ✅ Working Permissions

| Table / API | Status | Notes |
|-------------|--------|-------|
| `bizevents` | ✅ Works | Business events |
| `logs` | ✅ Works | Log ingestion and querying |
| `spans` | ✅ Works | Distributed traces |
| `events` | ✅ Works | Custom events (CUSTOM_INFO, etc.) |
| `metrics` (timeseries) | ✅ Works | Metric queries (FREE) |
| `dt.entity.service` | ✅ Works | Service entities |
| `dt.entity.host` | ✅ Works | Host entities |
| `user.events` | ⚠️ Test if needed | User actions, interactions, errors, JS exceptions (scope: `storage:user.events:read`) |
| `user.sessions` | ⚠️ Test if needed | User sessions Gen 3 (scope: `storage:user.sessions:read` — note: dot-notation, NOT hyphen!) |

---

## 📝 Template for New Issues

When a new permission error is encountered, add an entry using this template:

```markdown
### [DATE] — `<table_name>` — <Short Description>
- **Error:** `<exact error message>`
- **DQL That Failed:**
  ```dql
  <the query>
  ```
- **Impact:** <what analysis is blocked>
- **Required Scope:** `<scope name>`
- **Status:** 🔴 OPEN
```

Once resolved, move the entry from "Missing Permissions" to "Resolved Permissions" and update the status to ✅ RESOLVED.

---
