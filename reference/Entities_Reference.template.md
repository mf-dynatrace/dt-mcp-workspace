# Entities Reference

> **Purpose:** Cached entity IDs and topology to avoid repeated `find_entity_by_name` lookups
> **Last Updated:** *(Update after first session)*
> **Update Rule:** Add new entities whenever discovered via MCP queries
> **Semantic Dictionary:** https://docs.dynatrace.com/docs/shortlink/semantic-dictionary — look up entity types and field names

---

## 🏢 Service Entities

### Web Services (Frontend Applications)
| Service Name | Entity ID | Description | Type | Last Verified |
|--------------|-----------|-------------|------|---------------|
| *(Add as discovered)* | | | | |

### Backend Services / APIs
| Service | Entity ID | Description | Last Verified |
|---------|-----------|-------------|---------------|
| *(Add as discovered)* | | | |

### Azure Functions / Serverless
| Service | Entity ID | Description | Last Verified |
|---------|-----------|-------------|---------------|
| *(Add as discovered)* | | | |

**Note:** When discovering services, document error volumes and key characteristics alongside entity IDs.

---

## 🖥️ Host Entities

| Host Name | Entity ID | Description | Last Verified |
|-----------|-----------|-------------|---------------|
| *(Add as discovered)* | | | |

---

## 🖥️ Process Entities

| Process Name | Entity ID | Type | Last Verified |
|--------------|-----------|------|---------------|
| *(Add as discovered)* | | | |

---

## 📦 Container Entities

| Container Name | Entity ID | Pod/Host | Last Verified |
|----------------|-----------|----------|---------------|
| *(Add as discovered)* | | | |

---

## 📱 RUM Application Entities

| Application Name | Entity ID | Frontend ID | Description | Last Verified |
|-----------------|-----------|-------------|-------------|---------------|
| *(Add as discovered)* | | | | |

**Note:** RUM applications track real user monitoring data (sessions, page views, errors, performance)

### ⛔ Gen3 RUM Data Object Reference

**Valid data objects for RUM queries:**
| Data Object | Purpose | Example |
|-------------|---------|--------|
| `user.sessions` | Session-level aggregates | `fetch user.sessions, from:now()-7d` |
| `user.events` | Event-level detail (requests, errors, actions) | `fetch user.events, from:now()-24h` |
| `bizevents` | Business events sent via `dynatrace.sendBizEvent()` | `fetch bizevents, from:now()-7d` |

**❌ INVALID data objects — will return DQL-SYNTAX-ERROR:**
- `user_action` — DOES NOT EXIST
- `user.actions` — DOES NOT EXIST
- `events` — NOT for RUM data (platform events only)
- `user_session` — DOES NOT EXIST

### ⛔ Application Entity Filter Cheat Sheet

| Table | ✅ PRIMARY (canonical, entity ID-based) | ✅ ALTERNATIVE (human-readable name) | ❌ WRONG (returns 0) |
|-------|----------------------------------------|-------------------------------------|---------------------|
| `user.sessions` | `in(dt.rum.application.entities, "APPLICATION-XXXXXXXXXXXX")` | `frontend.name == "[APP_NAME]"` ⚠️ frontend.name is an ARRAY — `==` may return 0; prefer `in()` filter | `dt.entity.application == "APPLICATION-XXXXXXXXXXXX"` |
| `user.events` | `dt.rum.application.entity == "APPLICATION-XXXXXXXXXXXX"` | `frontend.name == "[APP_NAME]"` | `dt.entity.application == "APPLICATION-XXXXXXXXXXXX"` |

**Filtering best practices:**
- **PRIMARY (recommended):** Use `dt.rum.application.entity` (user.events) or `dt.rum.application.entities` (user.sessions) for entity ID-based filtering — most precise, unambiguous, survives app renames
- **ALTERNATIVE:** Use `frontend.name == "[APP_NAME]"` when you want human-readable queries or need to filter by display name in dashboards
- **WRONG:** `dt.entity.application` is ALWAYS NULL on both `user.sessions` and `user.events` — DO NOT USE

**When to use which:**
- **Use entity ID filter** (`dt.rum.application.entity`) when: writing automation scripts, building reusable queries, working with multiple environments where app names may differ
- **Use name filter** (`frontend.name`) when: building ad-hoc exploration queries, creating dashboard variables where users select by name, debugging when you don't have the entity ID yet

### Key RUM Queries (Gen3 Grail)

**⚠️ Gen3 user.events does NOT have `error.message`, `error.type == "javascript"`, or `action.name`.**

```dql
// ---- SESSION QUERIES (CHEAP: ~0.41 GB per 7d) ----

// ⚠️ KEY FIELD NAMES:
//   characteristics.is_bounce (boolean) — NOT isBounce
//   dt.rum.user_type — values: "real_user", "robot", "synthetic" (lowercase!)
//   frontend.name — is an ARRAY, use in() filter or dt.rum.application.entities instead

// Session count and duration
fetch user.sessions, from:now()-7d
| filter in(dt.rum.application.entities, "APPLICATION-XXXXXXXXXXXX")
| summarize sessions = count(), avg_duration = avg(duration)

// Session breakdown by device type
fetch user.sessions, from:now()-7d
| filter in(dt.rum.application.entities, "APPLICATION-XXXXXXXXXXXX")
| summarize sessions = count(), by:{device.type}
| sort sessions desc

// ---- USER EVENT QUERIES (ALWAYS PRE-FILTER BY CLASSIFIER) ----

// Error analysis (cheap: ~0.9-2.2 GB for 24h)
fetch user.events, from:now()-24h
| filter dt.rum.application.entity == "APPLICATION-XXXXXXXXXXXX"
| filter characteristics.classifier == "error"
| summarize count = count(), by:{error.name, error.type, error.source}
| sort count desc

// Page performance
fetch user.events, from:now()-24h
| filter dt.rum.application.entity == "APPLICATION-XXXXXXXXXXXX"
| filter characteristics.classifier == "view_summary"
| summarize views = count(), avg_duration = avg(duration), by:{view.detected_name}
| sort views desc
```

---

## 🔗 Entity Relationships

### Service Dependencies
| Source Entity | Target Entity | Relationship | Notes |
|---------------|---------------|--------------|-------|
| *(Add as discovered)* | | | |

---

## 📝 Discovery Log

Track when entities were discovered to avoid re-querying:

| Date | Entity | How Discovered | Notes |
|------|--------|----------------|-------|
| *(Add as discovered)* | | | |
