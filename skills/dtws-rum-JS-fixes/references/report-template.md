# Report Template — RUM JS Error Triage

## File Naming Convention
```
report/RUM_JS_Fixes_[AppName]_[YYYY-MM-DD].md
report/RUM_JS_Fixes_[AppName]_[YYYY-MM-DD].pdf
```

## PDF Generation

Requires `pandoc` and headless Chrome. Check availability first:

```bash
which pandoc && "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --version 2>/dev/null | head -1
```

**No `reference/report_style.css` exists in this workspace as of 2026-09-03** despite other
skills' templates assuming one — write a scratch CSS file (basic typography, table borders,
`<pre>` wrapping for code blocks) to the session scratchpad directory rather than failing or
skipping styling. If a shared stylesheet is added to this workspace later, prefer that instead.

If pandoc/Chrome are both available, generate after saving the markdown:

```bash
REPORT_MD="report/RUM_JS_Fixes_[AppName]_[YYYY-MM-DD].md"
REPORT_PDF="${REPORT_MD%.md}.pdf"
CSS="/path/to/scratch/report_style.css"   # or reference/report_style.css if it now exists

pandoc "$REPORT_MD" -f markdown -t html5 -s \
  -c "$CSS" \
  --metadata title="RUM JavaScript Error Triage — [App Name]" \
  -o "report/.tmp_rum_js_fixes.html" && \
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$REPORT_PDF" \
  --print-to-pdf-no-header "report/.tmp_rum_js_fixes.html" && \
rm -f "report/.tmp_rum_js_fixes.html"
```

If `pandoc` or Chrome is unavailable, save the markdown only and inform the user. The
`CVDisplayLinkCreateWithCGDisplay failed` lines Chrome prints on macOS during headless PDF
generation are harmless and can be ignored.

## Markdown Report Template

```markdown
# RUM JavaScript Error Triage — [Frontend Name]

**Application:** [frontend.name] ([APPLICATION-entity-id if known])
**Generated:** [YYYY-MM-DD]
**Data Timeframe:** [timeframe used for queries]
**Tenant:** [environment URL]
**Total JS exceptions in window:** [n] across [n] sessions ([total_sessions] total sessions —
[%] session impact rate)

---

## Executive Summary

[2–3 sentences: which error dominates, how many users/sessions it touches, whether it's a
first-party bug, a third-party/vendor issue, or a compatibility issue, and the single highest-
priority fix.]

---

## Top 5 JavaScript Errors

| Rank | Error | Occurrences | % of all exceptions | Affected Sessions | Affected Users | First Seen | Last Seen |
|---|---|---|---|---|---|---|---|
| 1 | `[exception.type]: [exception.message]` | [n] | [%] | [n] | [n] | [date] | [date] |
| 2 | ... | | | | | | |
| 3 | ... | | | | | | |
| 4 | ... | | | | | | |
| 5 | ... | | | | | | |

---

## Error #1 — `[exception.type]: [exception.message]`

### Impact

| Metric | Value |
|---|---|
| Occurrences ([timeframe]) | [n] |
| % of all JS exceptions | [%] |
| Affected sessions | [n] ([%] of total sessions) |
| Affected users | [n] |
| Source file | `[exception.file.full]` |
| File origin | First-party / Third-party ([provider/domain]) |
| Error source | [console / exception / promise_rejection / fetch / xhr] |
| Trend | Flat / Growing / Single-day spike on [date] |
| Browser/device concentration | [e.g. "92% Safari 15 — likely compatibility bug" or "Evenly spread — general logic bug"] |
| Top affected page(s) | [page.name list] |

### What's Breaking

[Plain-language description of the failure: what the code was trying to do, why it's failing
given the error signature, and — if resolved — how confidently. State clearly whether this was
resolved via a fetched sourcemap, minified-only analysis, or metadata-only (file unreachable).]

**Source resolution:** [sourcemap-resolved / minified-only / unreachable]

### Existing Code

```js
[snippet — smallest relevant excerpt, not the whole file]
```

### Suggested Change

```js
[proposed corrected snippet]
```

[1–2 sentences on why this fixes it, and any residual caveat — e.g. "this prevents the crash but
the root cause (API contract change) should still be confirmed with the backend team."]

---

## Error #2 — `[exception.type]: [exception.message]`

[repeat the same structure as Error #1]

---

## Error #3 — `[exception.type]: [exception.message]`

[repeat]

---

## Error #4 — `[exception.type]: [exception.message]`

[repeat]

---

## Error #5 — `[exception.type]: [exception.message]`

[repeat]

---

## Third-Party / Vendor Issues (if any)

[List any of the top 5 that are third-party in origin, called out separately since no code
patch is proposed for them — vendor name, domain, recommended customer-side action.]

---

## Key Findings & Recommendations

1. **[Finding]** — [Recommendation, prioritised by impact]
2. **[Finding]** — [Recommendation]
3. **[Finding]** — [Recommendation]

---

## Data Sources & Methodology

- **DQL queries used:** see `skills/dtws-rum-JS-fixes/references/error-queries.md`
- **Source fetch method:** `curl` (Bash) against `exception.file.full`; sourcemap resolution
  attempted per `references/js-fix-patterns.md` Source Fetch Procedure
- **Fields discovered in this tenant (Step 3):** [list any fields beyond the documented set,
  e.g. line/column/stack — or "none beyond documented set"]

## Query Budget Summary

| Query | Approx. GB scanned |
|---|---|
| Field discovery (Step 3) | ~[n] GB |
| Denominators | ~[n] GB |
| Top 5 fingerprints | ~[n] GB |
| Per-error breakdown (x5) | ~[n] GB |
| **Total** | **~[n] GB** |
```
