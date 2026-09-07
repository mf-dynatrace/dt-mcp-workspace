# Infrastructure Analysis Queries

ISP distribution, browser homogeneity, and instance ID uniqueness analysis for a suspect session population.

---

## ISP Distribution

ISP diversity is a key differentiator between legitimate users and residential proxy networks.

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter geo.country.iso_code == "$SUSPECT_COUNTRY"
| summarize sessions = count(), by:{client.isp}
| sort sessions desc
| limit 15
```

**Note:** `client.isp` is a sensitive field, hidden by default. Requires the `builtin-sensitive-user-events-and-sessions` fieldset permission. If it returns null, request a scope grant before proceeding.

**Interpretation:**
- **1–3 ISPs dominate** (>80% of sessions): likely a VPN, datacenter proxy, or small residential proxy pool
- **Many ISPs, each with small counts** across an unexpected geography: residential proxy network — bots running on compromised consumer devices or residential proxy services (e.g. Bright Data, Oxylabs residential nodes)
- **Starlink present**: increasingly used by bot operators as a proxy exit point (no geographic registration, spread globally)

**Residential proxy indicator:** legitimate small-country traffic tends to use 2-3 major local ISPs. Bots using residential proxies will show 4-10+ ISPs with proportional distribution matching that country's consumer market — but at volumes far exceeding legitimate user base.

---

## Browser Homogeneity

Legitimate users show browser diversity. Bots typically use a single spoofed user agent.

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter geo.country.iso_code == "$SUSPECT_COUNTRY"
| summarize sessions = count(), by:{browser.name, browser.version}
| sort sessions desc
| limit 10
```

**Bot indicator:** >90% of sessions report the same `browser.name`. Legitimate populations show Safari mobile, Chrome Mobile, Samsung Browser, Edge, Firefox etc. in varying proportions.

**Note:** bots commonly spoof `Chrome` (desktop version) even when accessing a mobile-primary site. A population that is 100% Chrome Desktop from a country where 70-80% of legitimate users would be mobile is a strong secondary indicator.

---

## Instance ID Uniqueness (Cookie-Clearing Detection)

`dt.rum.instance.id` is a persistent pseudonymous ID stored in a cookie. If bots are clearing cookies or running in private/incognito mode between sessions, every session will have a unique instance ID (count-per-instance = 1).

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter geo.country.iso_code == "$SUSPECT_COUNTRY"
| summarize sessions_per_instance = count(), by:{dt.rum.instance.id}
| summarize
    unique_instances = count(),
    multi_session_instances = countIf(sessions_per_instance > 1),
    single_session_instances = countIf(sessions_per_instance == 1)
```

**Bot indicator:** `single_session_instances` equals or approaches `unique_instances` — every device/browser is used for exactly one session, then discarded.

**Legitimate user indicator:** a meaningful proportion of `multi_session_instances` — returning users with persistent cookies (browsing sessions, return visits).

---

## Session Duration Distribution

Bots have consistent, narrow session durations driven by their automation timeout. Humans show wide variation.

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter geo.country.iso_code == "$SUSPECT_COUNTRY"
| fieldsAdd duration_s = round(toDouble(duration) / 1000000000, decimals: 0)
| summarize sessions = count(), by:{duration_s}
| sort sessions desc
| limit 20
```

**Bot indicator:** heavy clustering around a specific duration (e.g. 55–60 seconds matches a typical 60-second session timeout). Legitimate sessions show a broad distribution from seconds to many minutes.

---

## Device Type Distribution

```dql
fetch user.sessions, from:now()-24h
| filter in(frontend.name, "$APP")
| filter geo.country.iso_code == "$SUSPECT_COUNTRY"
| summarize sessions = count(), by:{device.type}
```

**Bot indicator:** 100% "desktop" or 100% single device type from a mobile-dominant market. Most residential proxy bots run in headless Chrome on server infrastructure, which reports as desktop.
