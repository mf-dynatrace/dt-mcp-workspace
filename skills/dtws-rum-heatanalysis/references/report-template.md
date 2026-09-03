# Report Template (Markdown & PDF)

## File Naming Convention
```
report/RUM_Interaction_[PageName]_[YYYY-MM-DD].md
report/RUM_Interaction_[PageName]_[YYYY-MM-DD].pdf
```

## PDF Generation

Requires `pandoc` and headless Chrome. Check availability first:

```bash
which pandoc && "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --version 2>/dev/null | head -1
```

If both are available, generate after saving the markdown:

```bash
REPORT_MD="report/RUM_Interaction_[PageName]_[YYYY-MM-DD].md"
REPORT_PDF="${REPORT_MD%.md}.pdf"
CSS="reference/report_style.css"   # adjust path if CSS is elsewhere in the workspace

pandoc "$REPORT_MD" -f markdown -t html5 -s \
  -c "../$CSS" \
  --metadata title="RUM Interaction Analysis — [Page Name]" \
  -o "report/.tmp_rum_interaction.html" && \
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$REPORT_PDF" \
  --print-to-pdf-no-header "report/.tmp_rum_interaction.html" && \
rm -f "report/.tmp_rum_interaction.html"
```

If `pandoc` or Chrome is unavailable, save the markdown only and inform the user.

---

## Markdown Report Template

```markdown
# RUM Interaction Analysis — [Page Name]

**Application:** [frontend.name]
**Page:** [page.name]
**Generated:** [YYYY-MM-DD]
**Data Timeframe:** [timeframe used for queries]
**Tenant:** [environment URL]

---

## Executive Summary

[2–3 sentences summarising the most important findings. Lead with the biggest retail/UX impact.]

---

## Page Health

| Metric | Value | Assessment |
|---|---|---|
| Page views ([timeframe]) | [n] | |
| Total clicks | [n] | |
| Action timeouts | [n] | 🔴/🟡/✅ |
| LCP P75 | [n]ms | Good / Needs Improvement / Poor |
| FCP P75 | [n]ms | Good / Needs Improvement / Poor |
| INP P75 | [n]ms | Good / Needs Improvement / Poor |
| CLS P75 | [n] | Good / Needs Improvement / Poor |

---

## Click Behaviour

### Clicks by Element Type

| Element | Clicks | Interpretation |
|---|---|---|
| div | [n] | Generic containers — see Named Element Breakdown below |
| a | [n] | Link clicks |
| input | [n] | Form / search box interactions |
| img | [n] | Image clicks |
| h3 | [n] | Heading / product title clicks |
| button | [n] | Explicit button interactions |
| [others] | | |

### Named Element Breakdown

*Only elements where OneAgent captured a readable name.*

| Element Name | Clicks | Retail Interpretation |
|---|---|---|
| [name] | [n] | [e.g. "Sort action", "Add to basket from this page", "Search box"] |

### Element Name Data Quality

| Category | Count | % |
|---|---|---|
| Named (readable intent) | [n] | [%] |
| Masked (privacy/PCI) | [n] | [%] |
| Unnamed (structural container) | [n] | [%] |

*To improve unnamed coverage: add `data-dt-name="[semantic-name]"` HTML attributes to product card wrappers and interactive containers.*

### What Clicks Triggered

| Destination (url.path) | Clicks | Type |
|---|---|---|
| [path] | [n] | [API call / page navigation / analytics tag] |

---

## User Journey

### Where Users Came From

| Referrer Page | Navigations |
|---|---|
| [page] | [n] |

### Action Type Split

| Action Type | Count | Meaning |
|---|---|---|
| same_view | [n] | Stayed on page (filter, search, basket action) |
| hard_navigation | [n] | Left to another page |
| api | [n] | Background XHR/fetch (no visible navigation) |

---

## Friction & Failures

### Action Completion Failures

| Reason | Count | Retail Impact |
|---|---|---|
| timeout | [n] | Dead/broken element — nothing responded |
| interrupted_by_automatic | [n] | Rapid navigation (refining quickly) |
| page_hide | [n] | User left page mid-action |

### Error Types

| Error Type | Count |
|---|---|
| request (failed HTTP calls) | [n] |
| exception (JS errors) | [n] |
| csp (blocked scripts) | [n] |

### Long Tasks (JS Main Thread Blocking)

| Severity | Count |
|---|---|
| Severe (>250ms) | [n] |
| Critical (>100ms) | [n] |
| Problematic (>50ms) | [n] |

---

## Geo & Audience

### Device Split

| Device | Sessions | % |
|---|---|---|
| Mobile | [n] | [%] |
| Desktop | [n] | [%] |

*If mobile is dominant, all interaction friction is mobile friction first.*

### Error Session Rate by Country (non-domestic)

| Country | Sessions | Error Rate | Assessment |
|---|---|---|---|
| [ISO] — [Name] | [n] | [%] | [Normal / Elevated / Suspicious] |

*Near-100% error rates from countries with no local store/business presence may indicate automated credential-stuffing or bot activity.*

---

## Key Findings & Recommendations

1. **[Finding]** — [Recommendation]
2. **[Finding]** — [Recommendation]
3. **[Finding]** — [Recommendation]

---

## Enhancement Opportunities

*(Items not available from current instrumentation — no Dynatrace gap)*

- **Element name coverage** — [X]% of clicks are on unnamed structural containers. Adding `data-dt-name` attributes to product card wrappers would make ~[n] clicks per hour readable.
- **[Other gaps specific to this page]**

---

## Query Budget Summary

| Query | Approx. GB scanned |
|---|---|
| Page health overview | ~[n] GB |
| CWV | ~[n] GB |
| Click analysis | ~[n] GB |
| Error / long task | ~[n] GB |
| Geo / session queries | ~[n] GB (user.sessions — very cheap) |
| **Total** | **~[n] GB** |
```
