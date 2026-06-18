# BizEvents Reference Guide

> **Generated:** 2026-03-06  
> **Environment:** [TENANT_ID]  
> **Data Period:** *(To be populated after first query)*  
> **Total Events Scanned:** *(To be populated after first query)*  
> **Total Event Types:** *(To be populated after first query)*  
> **Semantic Dictionary:** https://docs.dynatrace.com/docs/shortlink/semantic-dictionary — look up `bizevents` fields and conventions

---

## 📊 Volume Overview

### Ingestion Source Breakdown (Optional)
| Source | Events/Day | % of Total | Notes |
|--------|------------|------------|-------|
| OneAgent | | | Backend instrumentation |
| API Ingest | | | Custom event ingestion |
| RUM Agent | | | Browser/mobile events |

### High-Volume Event Types
| Event Type | Count/Day | Primary Use | Filters Required |
|------------|-----------|-------------|------------------|
| *(Add high-volume events as discovered)* | | | |

---

## ⚠️ RUM BizEvent JavaScript API (Updated 2026-03-13)

The Dynatrace RUM agent exposes **two separate global objects**:

| Global Object | Purpose | Key Methods |
|---------------|---------|-------------|
| `dtrum` | Classic RUM API | `enterAction()`, `leaveAction()`, `identifyUser()`, etc. |
| `dynatrace` | BizEvent API | `sendBizEvent(type, fields)` — **the ONLY way to send BizEvents from JS** |

**CRITICAL:** `dtrum.sendBizEvent()` does **NOT exist**. BizEvents must use `dynatrace.sendBizEvent()`.

```javascript
// ✅ CORRECT — use dynatrace global object
dynatrace.sendBizEvent("com.example.checkout.summary", { key: "value" });

// ❌ WRONG — sendBizEvent is NOT on dtrum
dtrum.sendBizEvent("com.example.checkout.summary", { key: "value" }); // undefined!
```

**Notes:**
- BizEvents sent via `dynatrace.sendBizEvent()` are **standalone events detached from user actions/sessions**
- You can still wrap calls in `dtrum.enterAction()`/`leaveAction()` for RUM action tracking alongside
- API docs: https://docs.dynatrace.com/javascriptapi/doc/types/dynatrace.html
- `dtrum` API docs: https://docs.dynatrace.com/javascriptapi/doc/types/dtrum.html

---

## 🛒 Sample BizEvent: [Example Event Type]

**Event Type:** `your.event.type`

### Key Fields Available
| Field | Example Value | Description |
|-------|---------------|-------------|
| `field1` | "value" | Description |
| `field2` | 123 | Description |
| `trace_id` | "abc123..." | Distributed trace correlation |
| `responseCode` | 200 | HTTP response code |

**Note:** [Any important field notes or nested data structures]

### Sample Query
```dql
fetch bizevents, from:now()-24h
| filter event.type == "your.event.type"
| fields timestamp, field1, field2
| limit 50
```

---

## Quick Reference: Event Types by Category

### 📊 Category 1: [CATEGORY_NAME]
| Event Type | Count (Period) | Description |
|------------|----------------|-------------|
| *(Add as discovered)* | | |

**Example Query:**
```dql
fetch bizevents, from:now()-24h
| filter event.type == "your.event.type"
| limit 50
```

---

### 📊 Category 2: [CATEGORY_NAME]
| Event Type | Count (Period) | Description |
|------------|----------------|-------------|
| *(Add as discovered)* | | |

---

## 🔍 Event Type Discovery Query

Run this to discover all event types:
```dql
fetch bizevents, from:now()-7d
| summarize count = count(), by:{event.type}
| sort count desc
| limit 50
```

---

## 📊 Event Fields Reference

### Common Fields (All Events)
| Field | Type | Description |
|-------|------|-------------|
| `event.type` | string | Event type identifier |
| `timestamp` | datetime | Event timestamp |
| `event.provider` | string | Source system |

### Custom Fields by Event Type

#### [event.type.1]
| Field | Type | Example | Description |
|-------|------|---------|-------------|
| *(Add as discovered)* | | | |

---

## 📈 Efficient Query Patterns

### Event Type Summary (Start Here)
```dql
fetch bizevents, from:now()-7d
| summarize count = count(), by:{event.type}
| sort count desc
```

### Hourly Volume Analysis
```dql
fetch bizevents, from:now()-24h
| filter event.type == "your.event.type"
| summarize count = count(), by:{bin(timestamp, 1h)}
| sort timestamp asc
```

### Specific Event Analysis
```dql
fetch bizevents, from:now()-24h
| filter event.type == "your.event.type"
| fields timestamp, field1, field2, field3
| limit 50
```

### Failure Analysis
```dql
fetch bizevents, from:now()-24h
| filter event.type == "your.event.type"
| filter result != "success" or responseCode != 200
| summarize count = count(), by:{result}
```

### Multi-Dimensional Analysis
```dql
fetch bizevents, from:now()-7d
| filter event.type == "your.event.type"
| summarize count = count(), by:{dimension1, dimension2}
| sort count desc
```

### Trace Correlation
```dql
fetch bizevents, from:now()-24h
| filter event.type == "your.event.type"
| filter trace_id == "YOUR_TRACE_ID"
| fields timestamp, responseCode, field1
```

---

## ⚠️ High-Volume Event Types

| Event Type | Volume | Recommendation |
|------------|--------|----------------|
| *(Add high-volume events)* | | ⚠️ Add filters |

---

## 📝 Update Log

### 2026-03-10 - Ecommerce Funnel Discovery
- **Source:** user.events page_summary + request queries for APPLICATION-XXXXXXXXXXXX
- **Finding:** Mapped full booking funnel. `/your/bookings/` is a React SPA — all hotel booking wizard steps happen within one URL. SPA steps identified via API call patterns.
- **Page-Level Funnel (7d):** Homepage (26K sessions) → Places to Stay (13K) → Bookings SPA (6.2K) → Confirmation (539)
- **SPA Steps (7d):** api/packages/definitions (11.5K) → api/seasons/getAll (11.1K) → api/hotel/list (10.4K) → api/hotel/details (6.7K) → api/masterdata/getAttractionsAvailabilityInfo (9.7K)
- **Key Domains:** www.[CLIENT_WEBSITE] (60K pages/24h), tickets.[CLIENT_WEBSITE] ([TICKET_PROVIDER] tickets), bookings.example.com
- **Dashboard:** example/Ecommerce_Journey_Funnel_Dashboard.json

### 2026-03-10 - [TICKET_PROVIDER] Iframe Ticket Checkout Journey Discovery
- **Source:** user.events request classifier for APPLICATION-XXXXXXXXXXXX, domain `tickets.[CLIENT_WEBSITE]`
- **Finding:** Mapped complete [TICKET_PROVIDER] iframe checkout SPA funnel. Iframe embeds on tickets page, SPA navigation tracked via `view.url.path` changes on XHR requests within the iframe.
- **[TICKET_PROVIDER] SPA Funnel (7d):** Select Date (~5K) → Select Ticket (~930) → Add Extras (~950) → Basket (~720) → Checkout (~680) → Purchase (~420)
- **SPA View Paths:**
  - `/snap-calendar-wizard/SnapWizardPromo1D/SnapWizardPromoAdmission1D` — Date selection (1-Day admission)
  - `/snap-calendar-wizard/SnapWizardPromo2D/SnapWizardPromoAdmission2D` — Date selection (2-Day admission)
  - `/snap-calendar-wizard/*/package/SnapWizardPromoAdmission1D/*` — Ticket type selection
  - `/extras/SnapWizardPromo1D/WizardSpecials` — Add extras/upgrades
  - `/cartView` — Shopping basket review
  - `/[ticket_provider]-pay` — Payment/checkout page
- **Key API Endpoints (on [TICKET_PROVIDER] domain):**
  - `/api/request/getkeywordcalendar` — Calendar/date picker (2,944 sessions)
  - `/api/request/getmerchantpackageeventdates` — Available dates (2,245 sessions)
  - `/api/request/getdynamicpricingadjustment` — Dynamic pricing (2,160 sessions, 230K requests)
  - `/api/request/addcartitem` — Add to cart (1,485 sessions)
  - `/api/request/getcartsummary` — Cart summary (3,510 sessions)
  - `/api/request/getpackageswaps` — Extras/swaps (3,457 sessions)
  - `/api/request/updatecartcheckoutinfo` — Checkout info (1,518 sessions)
  - `/api/request/purchase` — Purchase completion (423 sessions)
  - `/api/request/guestvieworder` — Order confirmation (456 sessions)
  - `/api/request/getnewcartid` — New cart creation (3,046 sessions)
- **Other Wizard Types:** FastTrack (`/fastlanewizard/`, 918 sessions), Recommended (`/recommenderWizard/`, 519 sessions), Calendar Pricing (`/calendarPricingWithImage/`)
- **Parent Site Entry Pages:** Homepage `/your-location/` (36.7K req sessions) → Tickets Page `/your-location/tickets-passes/tickets/` (34.1K req sessions)
- **BizEvents Status:** [TICKET_PROVIDER] GTM tracking tag NOT yet deployed — no `com.[ticket_provider].*` BizEvents available yet

### [DATE] - Initial Setup
- **Source:** Workspace initialization
- **Finding:** Reference file created
- **Data:** Template ready for population

<!--
Example update entry:

### [DATE] - Event Discovery
- **Source:** BizEvents summary query
- **Finding:** Discovered 25 event types
- **Data:** Top events: event.type.1 (500K), event.type.2 (250K)
-->

---

## 🔄 How to Update This File

When you discover new event types:
1. Add to appropriate category section
2. Include: Event Type, Count, Description
3. Document important fields
4. Add to Update Log with source query
5. Flag high-volume events with warnings
