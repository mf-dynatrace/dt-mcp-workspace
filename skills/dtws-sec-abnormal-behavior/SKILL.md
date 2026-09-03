---
name: dtws-sec-abnormal-behavior
description: >-
  Security-focused RUM and trace analysis for detecting abnormal session behaviour in Dynatrace.
  Identifies bots, credential stuffing, account checking, content/price scraping, and residential
  proxy campaigns using Gen3 Grail data (user.sessions, user.events, spans). Outputs are
  formatted for security team consumption: IOC summaries, session fingerprints, geo-risk tables,
  and actionable WAF/CDN block recommendations.
  Trigger: "bot detection", "credential stuffing", "abnormal sessions", "suspicious traffic",
  "account takeover", "scraping", "fraud detection", "geo anomaly", "outlier sessions",
  "security analysis", "unauthorized access attempts", "suspicious login activity".
  Requires: dt-dql-essentials loaded before any DQL. MCP or dtctl access to the tenant.
  Does NOT replace a dedicated WAF or SIEM. Surfaces signals; the security team validates and acts.
license: Apache-2.0
---

# Abnormal Session Behaviour Detection

Detect and characterise automated, malicious, or anomalous traffic patterns using Dynatrace
Gen3 Grail RUM and trace data. Outputs structured findings suitable for a security team.

**Always load `dt-dql-essentials` before writing DQL from this skill.**

---

## Threat Taxonomy

| Threat Type | Primary Signal | Secondary Signal |
|---|---|---|
| **Credential stuffing** | High 4xx rate on auth endpoint + 0 page views | Single navigation per session, uniform browser UA |
| **Account checking** | Sequential auth attempts, unique instance IDs per session | No organic interaction (0 user actions) |
| **Content/price scraping** | Uniform event counts per SKU/URL | No page_summary events, direct API calls |
| **Residential proxy campaign** | Multiple ISPs in unexpected geography | Cookie clearing (unique instance IDs each session) |
| **Session hijacking** | Spike in sessions from new geo + auth success | Mismatch between geo and account's usual location |
| **Availability/inventory bot** | Systematic product page access, add-to-basket spikes | Short session duration, no search or browse |

---

## Workflow

### Step 1 — Baseline Legitimate Sessions

Before looking for anomalies, establish what normal looks like:

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| summarize
    sessions = count(),
    avg_pages = avg(page_summary_count),
    avg_navs = avg(navigation_count),
    avg_actions = avg(user_action_count),
    avg_duration_s = avg(toDouble(duration) / 1000000000),
    by:{geo.country.iso_code}
| sort sessions desc
| limit 20
```

Note the legitimate values for: pages per session, navigation count, user actions, session duration, browser diversity, ISP diversity. These become your baseline for anomaly scoring.

### Step 2 — Identify Geo Outliers by Error Rate

Load `references/geo-analysis.md` for the choropleth and error-rate queries.

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter isNotNull(geo.country.iso_code)
| summarize total = count(), errors = countIf(error.http_4xx_count > 0 or error.http_5xx_count > 0), by:{geo.country.iso_code}
| fieldsAdd error_rate = round(errors * 100.0 / total, decimals: 1)
| filter total >= 5
| sort error_rate desc
| limit 25
```

Countries with near-100% error rates AND volume (>10 sessions) are primary suspects.

### Step 3 — Session Fingerprint Analysis

For each suspect country, run the session fingerprint query:

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter geo.country.iso_code == "$SUSPECT_COUNTRY"
| summarize sessions = count(),
    by:{end_reason, page_summary_count, navigation_count, user_action_count, error.http_4xx_count}
| sort sessions desc
```

**Bot fingerprint:** the majority of sessions will cluster on a single row with `page_summary_count=0`, `navigation_count=1`, and `error.http_4xx_count=1`.

### Step 4 — Infrastructure Analysis (ISP, Browser, Instance IDs)

Load `references/infrastructure-analysis.md` for ISP distribution, browser homogeneity, and instance ID uniqueness queries.

### Step 5 — Correlation with Auth / Span Data

Load `references/auth-correlation.md` to cross-reference RUM session anomalies with the backend auth service trace data (401 volume, timing, endpoint targeting).

### Step 6 — Output

Load `references/security-report-template.md` to produce the threat intelligence summary.

---

## Bot Session Scoring

Score each suspect session population on these criteria (1 point each):

| Criterion | Bot Signal | Legit Signal |
|---|---|---|
| Page views | = 0 (no content rendered) | ≥ 1 |
| Navigation count | = 1 (single endpoint hit) | ≥ 2 |
| Session duration | < 60s AND = timeout | Organic distribution |
| User actions | = 0 (no human interaction) | ≥ 1 |
| HTTP 4xx per session | = 1 (auth failure) | Near 0 |
| Browser diversity | Single UA dominates (>90%) | Mixed |
| Instance ID reuse | All unique (count=1 per ID) | Normal reuse |
| ISP distribution | Residential proxy spread | Organic ISP mix |
| Geographic legitimacy | No business presence in region | Expected market |
| Traffic pacing | Steady 2-20 sessions/2min | Organic peaks/troughs |

**Score 7+/10 = high confidence automated threat. Score 4-6 = investigate further. Score <4 = likely legitimate.**

---

## Key Fields Reference

| Field | Source | Security Use |
|---|---|---|
| `geo.country.iso_code` | `user.sessions` | Geographic anomaly detection |
| `client.isp` | `user.sessions` | ISP/proxy network identification |
| `browser.name`, `browser.version` | `user.sessions` | UA homogeneity detection |
| `dt.rum.instance.id` | `user.sessions` | Cookie-clearing / fresh-instance detection |
| `page_summary_count` | `user.sessions` | Content rendering vs bare HTTP |
| `navigation_count` | `user.sessions` | Endpoint count per session |
| `user_action_count` | `user.sessions` | Human vs automated interaction |
| `error.http_4xx_count`, `error.http_5xx_count` | `user.sessions` | Auth failure volume |
| `end_reason` | `user.sessions` | `timeout` = no human closed browser |
| `duration` | `user.sessions` | Session lifetime (automated = consistent) |
| `http.response.status_code` | `spans` | 401 Unauthorized on auth endpoint |
| `endpoint.name` | `spans` | Which endpoint is being targeted |
| `server.address` | `spans` | Upstream identity provider calls |

---

## DQL Gotchas (security queries)

1. **`client.isp` is a sensitive field** — hidden by default. Requires the `builtin-sensitive-user-events-and-sessions` fieldset permission. If it returns null for all records, a scope/permissions grant is needed.

2. **Duration type division — use `toDouble()` first:**
   ```dql
   | fieldsAdd duration_s = toDouble(duration) / 1000000000
   ```

3. **`geo.country.name` is often empty** — use `if(geo.country.iso_code == "GB", "United Kingdom", ...)` lookup instead.

4. **Session timing lag** — sessions take 30+ minutes of inactivity before being written to `user.sessions`. Use `from:now()-32h` if you need sessions that were active 24h ago.

5. **Unfiltered `fetch user.events` is extremely expensive** — always apply `frontend.name ==` AND `characteristics.has_X` filters. For security investigations, use `user.sessions` for the initial triage (very cheap, <0.3 GB for 24h) and only drill into `user.events` for confirmed suspect sessions.

---

## References

| File | Load When |
|---|---|
| [references/geo-analysis.md](references/geo-analysis.md) | Running geo-risk queries and choropleth data |
| [references/infrastructure-analysis.md](references/infrastructure-analysis.md) | ISP, browser homogeneity, instance ID uniqueness analysis |
| [references/auth-correlation.md](references/auth-correlation.md) | Cross-referencing RUM anomalies with auth service traces |
| [references/security-report-template.md](references/security-report-template.md) | Producing security team output (IOCs, recommendations) |
