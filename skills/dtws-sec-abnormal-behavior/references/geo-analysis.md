# Geo Analysis Queries

All queries use `$APP` as the frontend.name placeholder.

---

## Baseline: All Countries by Session Volume and Error Rate

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter isNotNull(geo.country.iso_code)
| summarize
    total = count(),
    sessions_4xx = countIf(error.http_4xx_count > 0),
    sessions_5xx = countIf(error.http_5xx_count > 0),
    avg_pages = avg(page_summary_count),
    avg_navs = avg(navigation_count),
    by:{geo.country.iso_code}
| fieldsAdd error_rate = round((sessions_4xx + sessions_5xx) * 100.0 / total, decimals: 1)
| filter total >= 5
| sort error_rate desc
```

---

## High-Risk Country Table (non-domestic, ≥5 sessions)

Set `$PRIMARY_COUNTRY` to the ISO code of the application's legitimate primary market.

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter isNotNull(geo.country.iso_code) and geo.country.iso_code != "$PRIMARY_COUNTRY"
| summarize
    total = count(),
    errors = countIf(error.http_4xx_count > 0 or error.http_5xx_count > 0),
    avg_pages = avg(page_summary_count),
    avg_navs = avg(navigation_count),
    avg_actions = avg(user_action_count),
    by:{geo.country.iso_code}
| fieldsAdd error_rate = round(errors * 100.0 / total, decimals: 1)
| filter total >= 5
| sort error_rate desc
| limit 30
```

**Risk thresholds:**
- error_rate ≥ 90% + total ≥ 10: **Critical — very likely automated/bot**
- error_rate 50–90% + total ≥ 10: **High — investigate**
- error_rate 20–50% + total ≥ 20: **Medium — monitor**
- avg_pages = 0 across the country population: **Bot indicator regardless of error rate**

---

## Session Volume Trend by Suspect Country (timing analysis)

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter geo.country.iso_code == "$SUSPECT_COUNTRY"
| makeTimeseries sessions = count()
```

**Interpretation:**
- **Steady flat rate** (e.g. 3-15 sessions per 2-min bucket continuously) = paced automation to avoid rate limits
- **Sharp burst then silence** = one-off attack or test run
- **Organic wave pattern** (peaks in daytime, drops overnight) = likely legitimate traffic despite high error rate

---

## Choropleth Map Data (error rate by country)

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter isNotNull(geo.country.iso_code)
| summarize total = count(), errors = countIf(error.http_4xx_count > 0 or error.http_5xx_count > 0), by:{geo.country.iso_code}
| fieldsAdd error_rate = round(errors * 100.0 / total, decimals: 1)
| filter total >= 3
| fields geo.country.iso_code, error_rate
| sort error_rate desc
```

Use `choroplethMap` visualization with `countryCode: geo.country.iso_code`, `dimension: error_rate`, `colorPalette: red`.

---

## Session Fingerprint for Suspect Country

Critical query — reveals whether the country's session profile matches bot patterns:

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter geo.country.iso_code == "$SUSPECT_COUNTRY"
| summarize sessions = count(),
    by:{end_reason, page_summary_count, navigation_count, user_action_count, error.http_4xx_count}
| sort sessions desc
```

**Bot fingerprint:** dominant cluster will show `page_summary_count=0`, `navigation_count=1`, `error.http_4xx_count=1`, `end_reason=timeout`.

**Legitimate fingerprint:** spread across multiple rows with `page_summary_count ≥ 1`, `navigation_count ≥ 2`, `user_action_count ≥ 1`.

---

## Comparison: Suspect Country vs Legitimate Market

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter in(geo.country.iso_code, "$SUSPECT_COUNTRY", "$PRIMARY_COUNTRY")
| summarize
    sessions = count(),
    avg_pages = avg(page_summary_count),
    avg_navs = avg(navigation_count),
    avg_actions = avg(user_action_count),
    avg_duration_s = avg(toDouble(duration) / 1000000000),
    pct_zero_pages = round(countIf(page_summary_count == 0) * 100.0 / count(), decimals: 1),
    by:{geo.country.iso_code}
```

Stark differences in avg_pages, avg_actions, and pct_zero_pages between the two countries confirm automated vs human traffic.
