# Security Report Template

Output formatted for security team consumption. Populate from query results.

## File Naming
```
report/Security_AbnormalBehavior_[AppName]_[YYYY-MM-DD].md
report/Security_AbnormalBehavior_[AppName]_[YYYY-MM-DD].pdf
```

---

## Report Template

```markdown
# Security Threat Intelligence — Abnormal Session Behaviour

**Application:** [frontend.name]
**Tenant:** [environment URL]
**Analysis Period:** [timeframe]
**Generated:** [YYYY-MM-DD HH:MM UTC]
**Classification:** INTERNAL — SECURITY TEAM
**Severity:** [CRITICAL / HIGH / MEDIUM / LOW]

---

## Executive Summary

[2–3 sentences for a CISO audience. State: what is happening, at what volume, what is at risk,
and the top recommended action.]

Example:
*A sustained credential stuffing campaign originating from [country] is making approximately
[N] automated authentication attempts per hour against [app]. 100% of attempts are failing
(HTTP 401), indicating the attacker is testing credentials from a compromised list. No rate
limiting is currently in place; immediate WAF configuration is recommended.*

---

## Threat Classification

| Attribute | Value |
|---|---|
| Threat type | [Credential stuffing / Account checking / Scraping / Residential proxy] |
| Confidence | [High / Medium / Low] — based on bot score [X/10] |
| Ongoing | [Yes — continuous / Yes — burst / Unknown] |
| Rate limiting in place | [Yes / **No — action required**] |
| Known attacker infrastructure | [Residential proxy network / Datacenter / VPN] |
| Primary target | [Endpoint or page] |
| Secondary behavior | [e.g. Product catalog scraping / None observed] |

---

## Indicators of Compromise (IOCs)

### Geographic IOCs

| Country / Territory | Sessions ([period]) | Error Rate | Risk Level |
|---|---|---|---|
| [ISO] — [Country Name] | [N] | [%] | 🔴 Critical / 🟡 High / 🟠 Medium |

### Infrastructure IOCs

| ISP | Sessions | Notes |
|---|---|---|
| [ISP Name] | [N] | [e.g. Residential ISP — typical residential proxy exit] |

### Session Behavioural Fingerprint

```
page_summary_count:  [value]  (0 = no content rendered — automated)
navigation_count:    [value]  (1 = single endpoint hit — automated)
user_action_count:   [value]  (0 = no human interaction)
error.http_4xx_count:[value]  (1 = auth failure)
end_reason:          timeout  (no natural session close — automated)
session_duration_s:  ~[N]s    (consistent = automated timeout cycle)
browser:             [name]   (100% single UA — spoofed)
instance_id_reuse:   None     (all unique — cookie clearing between attempts)
```

### Bot Confidence Score: [X] / 10

| Criterion | Score | Evidence |
|---|---|---|
| 0 page views | ✅ 1 | page_summary_count = 0 in [N]% of sessions |
| Single navigation | ✅ 1 | navigation_count = 1 in [N]% of sessions |
| Consistent session duration | ✅ 1 | ~[N]s avg, narrow distribution |
| Zero user actions | ✅ 1 | [N]% of sessions had 0 user_action_count |
| Near-100% auth failures | ✅ 1 | [N]% of sessions have 4xx errors |
| Single browser UA | ✅ 1 | [N]% Chrome (expected: diverse) |
| Cookie clearing (unique IDs) | ✅ 1 | All [N] sessions have unique instance IDs |
| Residential proxy ISPs | ✅ 1 | [ISP list] — distributed across [N] carriers |
| No legitimate market presence | ✅ 1 | [Country] has no [Company] stores or operations |
| Paced automation | ✅ 1 | Steady [N]-[N] sessions per 2-min interval |

---

## Volume & Timing

| Metric | Value |
|---|---|
| Total suspect sessions ([period]) | [N] |
| Sessions per hour (avg) | [N] |
| Auth failures per hour | [N] |
| Peak interval | [timestamp / time-of-day pattern] |
| Traffic pattern | [Continuous paced / Burst / Unknown] |

---

## Attack Narrative

[1–3 paragraphs describing what the attacker is doing, how their infrastructure works,
and what they are likely trying to achieve.]

Example:

*The attacker is operating a credential stuffing campaign using a residential proxy network
distributed across [country] ISPs including [ISP1], [ISP2], and [ISP3]. Residential proxy
networks route bot traffic through real consumer IP addresses, making IP-based blocking less
effective as blocked IPs belong to legitimate ISPs rather than known datacenter ranges.*

*Each bot instance clears its browser cookies and storage between requests (confirmed by every
session having a unique `dt.rum.instance.id`). This defeats cookie-based bot detection mechanisms.
The Chrome user agent is spoofed on every request; no browser diversity is observed, which is
characteristic of headless Chromium automation.*

*Running in parallel with the credential stuffing activity, the same geo source is making
systematic product catalog requests against [N] product URLs with highly uniform event counts
(~[N] events per product), consistent with automated price or inventory scraping.*

---

## Impact Assessment

| Risk Area | Current Status | Potential Impact |
|---|---|---|
| Account takeover (ATO) | Active risk — [N] auth attempts/hr ongoing | Customer account compromise, fraudulent orders |
| Rate limiting | ❌ Not in place | Attack continues unchecked |
| Inventory scraping | [Suspected / Confirmed / Not observed] | Competitive intelligence, stockpiling |
| Auth service load | [N] extra calls/hr to SSO provider | [Minimal / Risk of upstream lockout at scale] |
| Customer trust | No visible customer impact yet | Potential if ATO succeeds at scale |

---

## Recommendations

### Immediate (within 24 hours)

1. **Configure rate limiting on the auth endpoint** — limit to 10 auth requests per IP per 60-second window. Return HTTP 429. Apply at WAF or API gateway level, not application level.
2. **Review auth service SSO upstream call volume** — confirm [SSO provider] is not approaching per-tenant limits.
3. **Alert on sustained 401 rate** — configure a Davis Custom Event to alert if the 30-minute rolling 401 count exceeds [N×2 current baseline].

### Short-term (within 1 week)

4. **Evaluate CAPTCHA** on auth endpoint after [N] failed attempts per session.
5. **Consider geo-blocking or geo-challenge** for [countries with near-100% error rate and no business presence] — CAPTCHA challenge or block at CDN level.
6. **Instrument auth failure sub-reasons** — currently all failures surface as generic HTTP 401 with no sub-type. Structured error codes (wrong_password, account_locked, invalid_token) would enable more granular detection and SIEM ingestion.
7. **Investigate product scraping vector** — determine whether the same IP addresses appear in web server logs accessing the product catalog systematically.

### Medium-term (within 1 month)

8. **Deploy device fingerprinting** — supplement cookie-based instance ID with a client-side fingerprint that persists across cookie clears.
9. **Add `data-dt-name` to auth form elements** — currently auth form interactions are named "masked" or unnamed; structured element names would enable detection of form-field interaction patterns distinguishing bots from humans.

---

## Appendix: DQL Queries Used

| Query | Purpose | GB Scanned |
|---|---|---|
| Geo baseline (user.sessions, 24h) | Country error rate overview | ~0.3 GB |
| Session fingerprint | Bot behavioral confirmation | ~0.15 GB |
| ISP distribution | Residential proxy identification | ~0.15 GB |
| Browser homogeneity | UA spoofing confirmation | ~0.15 GB |
| Instance ID uniqueness | Cookie-clearing confirmation | ~0.15 GB |
| Auth failure volume (spans, 24h) | Backend confirmation | ~8-30 GB |
| 401 timing distribution (spans) | Attack pattern timing | ~8-30 GB |
| Rate limiting gap check | 429 absence | ~8-30 GB |
| **Total** | | **~20-65 GB** |
```
