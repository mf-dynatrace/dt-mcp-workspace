---
name: dtws-rum-JS-fixes
description: >-
  Identifies the top JavaScript runtime exceptions on a RUM web frontend, quantifies their
  impact (occurrences, affected sessions/users, browser/device split, trend), attempts to fetch
  the live public JS source (and sourcemap if reachable) to locate the failing code, and
  proposes a defensive code fix for each. Produces a markdown report saved to report/.
  If the frontend/application is not specified, prompt the user to choose before proceeding.
  Trigger: "JS errors", "javascript errors", "top JS errors", "fix JS error", "RUM exceptions",
  "why is this failing in the browser", "frontend error triage", "JS error report",
  "browser console errors", "client-side error analysis".
  Requires: dt-dql-essentials loaded before any DQL. dt-obs-frontends error-tracking reference.
  MCP query access to the tenant. Bash/curl network access to pull public JS source files.
  Does NOT cover mobile crash/ANR analysis (see dt-obs-frontends mobile-monitoring.md), CSP
  violations (see dt-obs-frontends csp-violations.md), or failed HTTP requests
  (characteristics.has_failed_request) — JS runtime exceptions only.
license: Apache-2.0
---

# RUM JavaScript Error Triage & Fix Suggestions

Analyse the top JavaScript exceptions on a specific RUM web frontend, quantify their impact,
pull the live public JS source to locate the failing code, and propose a defensive fix for each.

**Always load `dt-dql-essentials` before writing DQL from this skill.**

---

## Scope & Caveats (read before running anything)

- **Web only.** Mobile crashes/ANRs use different fields and are out of scope — point the user
  at `dt-obs-frontends/references/mobile-monitoring.md` if asked.
- **JS runtime exceptions only** (`error.type == "exception"`). HTTP/resource failures and CSP
  violations are intentionally excluded — if the user wants those, point them at
  `error-tracking.md` (`characteristics.has_failed_request`) or `csp-violations.md`.
- **Source fetch is best-effort, not guaranteed.** Production JS is usually minified/bundled and
  may not expose a public sourcemap. Use `curl` via Bash to fetch, not `WebFetch` — `WebFetch`
  converts HTML/JS to markdown and summarizes it through a model, which loses exact code
  formatting needed for extracting a real snippet. This skill, in order:
  1. `curl`s the file at `exception.file.full` as-is.
  2. Checks the fetched file for a `//# sourceMappingURL=...` comment and, if present, attempts
     to fetch that map (same path, or the path it points to).
  3. Also tries `<file-url>.map` directly in case the comment was stripped.
  4. If no map is reachable, analyses the raw minified code — clearly label this as
     **"minified, unmapped"** in the report. Never claim de-minified certainty you don't have.
- **Cross-origin / third-party files:** if the fetch is blocked (403/404/CORS) or
  `exception.file.provider` indicates third-party/CDN origin, say so plainly. A code "fix" is not
  actionable for code the customer doesn't own — report it as a vendor/dependency risk instead of
  proposing a patch to someone else's file. Also check whether the literal identifier from the
  error message still appears in the fetched file — if not, the vendor may have shipped a new
  version since the error occurred (see DQL Gotchas and `js-fix-patterns.md`).
- **Fix suggestions are advisory only.** This workspace has no access to the customer's source
  repository. Show the offending snippet and a proposed corrected version as a diff-style
  suggestion — the customer applies it in their own codebase and CI/CD pipeline.
- **Field availability is not guaranteed.** The reliably documented web exception fields are
  `exception.message`, `exception.type`, `exception.file.full`, `exception.file.provider`,
  `error.source`, `error.id`. Line/column/stack-trace fields are NOT confirmed for web RUM in
  every tenant (they are documented for mobile: `exception.stack_trace`). **Step 3 below runs a
  live field-discovery query before assuming anything beyond the confirmed set exists.**

---

## Workflow

### Step 1 — Identify the frontend
If the user already named an application, use it directly. If not specified, discover for free:
```dql
timeseries count = sum(dt.frontend.request.count, scalar: true), by:{frontend.name}
```
Ask which frontend to analyse if more than one is returned. Prefer web frontends (Liferay/
OutSystems/WebLogic-style entries) — mobile app names (Android/iOS) are out of scope for this
skill.

### Step 2 — Confirm timeframe
Default to **7d**. Ask if the user wants a different window (e.g. "since last deploy", "24h",
"last release window").

### Step 3 — Discover available exception fields (cheap, run once per session)
```dql
fetch user.events, from:now()-$TIMEFRAME
| filter frontend.name == "$APP" and error.type == "exception"
| limit 1
```
`| fields *` is **not valid DQL syntax** (`PARSE_ERROR`) — omit it; `fetch` already returns every
field on the raw record. Inspect the full JSON result for `exception.line_number`,
`exception.column_number`, and `exception.stack_trace` — these ARE present for web RUM on some
tenants despite being documented as mobile-only elsewhere. Use them in later steps if present;
otherwise fall back to message/type/file only. If
the query returns zero rows, stop and tell the user this frontend has no JS exceptions in the
chosen window — do not fabricate errors.

### Step 4 — Top 5 JS errors by fingerprint
```dql
fetch user.events, from:now()-$TIMEFRAME
| filter frontend.name == "$APP" and error.type == "exception"
| summarize
    occurrences = count(),
    affected_sessions = countDistinct(dt.rum.session.id),
    affected_users = countDistinct(dt.rum.instance.id, precision: 9),
    by: {error.id, exception.type, exception.message, exception.file.full,
         exception.file.provider, error.source}
| sort occurrences desc
| limit 5
```
`min(timestamp)`/`max(timestamp)` return null in `summarize` (Gotcha #3) — first/last-seen is a
separate follow-up query keyed on the resulting `error.id`s (with `toUid()`, per Gotcha #2). See
`references/error-queries.md` for that query, the fallback query when `error.id` is null (grouping
by `exception.message` + `exception.type` instead), and the total-exceptions/total-sessions
denominator queries needed to compute % impact.

### Step 5 — Per-error breakdown
For each of the 5 fingerprints from Step 4, run the browser/device split and daily trend queries
in `references/error-queries.md`. Compute:
- % of all JS exceptions this fingerprint represents
- % of all sessions on the frontend affected
- whether it's concentrated in one browser/device (compatibility bug) or spread evenly (general bug)
- whether occurrences are flat, growing, or a single spike tied to a specific day (deploy regression)

### Step 6 — Fetch and analyse the source file
For each error's `exception.file.full`, follow the fetch/sourcemap procedure in the Scope &
Caveats section above, then load `references/js-fix-patterns.md` to match the error signature
(`exception.type` + `exception.message` shape) to a known root-cause pattern and defensive-fix
template. Extract only the smallest relevant snippet — do not paste an entire bundle into the
report.

### Step 7 — Produce the report
Load `references/report-template.md` and populate it with the Step 4–6 results. Save to
`report/RUM_JS_Fixes_[AppName]_[YYYY-MM-DD].md`.

---

## Key Fields Reference

| Field | Confirmed for Web? | Description |
|---|---|---|
| `frontend.name` | ✅ | Application identifier — always filter this first |
| `error.type` | ✅ | `exception` = JS runtime error (also: `request`, `csp`, `crash`, `anr`) |
| `error.id` | ✅ | Fingerprint grouping similar errors — use for "top N" ranking |
| `error.source` | ✅ | `console`, `document_request`, `exception`, `fetch`, `promise_rejection`, `xhr` |
| `exception.type` | ✅ | JS error class (`TypeError`, `ReferenceError`, `SyntaxError`, ...) |
| `exception.message` | ✅ | Raw error message |
| `exception.file.full` | ✅ | JS file URL that threw — use this to fetch source |
| `exception.file.provider` | ✅ | `first_party`, `third_party`, or CDN origin |
| `exception.line_number` / `exception.column_number` | ⚠️ Verify with Step 3 | Confirmed present on web RUM in at least one tenant despite being documented mobile-only — don't assume either way |
| `exception.stack_trace` | ⚠️ Verify with Step 3 | Same caveat — confirmed present for web in testing, but treat as tenant-dependent |
| `dt.rum.session.id` | ✅ | Session ID — use for `countDistinct` affected-sessions |
| `dt.rum.instance.id` | ✅ | Pseudonymous device ID — use for `countDistinct` affected-users |
| `browser.name`, `device.type` | ✅ | Segmentation for compatibility-bug detection |
| `dt.frontend.error.count` (metric) | ✅ | Free, aggregate trend by `error.type` — no `error.id` dimension |

---

## DQL Gotchas

1. **`error.id` groups by fingerprint, not by literal message string** — two errors with slightly
   different messages (e.g. interpolated values) can share one `error.id`. Trust it over manual
   grouping by `exception.message`.

2. **`error.id` is a UID type, not a plain string — filtering with a bare string silently
   returns 0 rows.** Verified 2026-09-03: `filter error.id == "e052f06118c84ab5"` returns nothing;
   `filter error.id == toUid("e052f06118c84ab5")` returns the expected rows. Same rule as
   `trace.id` on spans. Always wrap: `filter in(error.id, toUid("id1"), toUid("id2"), ...)`.

3. **`min(timestamp)`/`max(timestamp)` return null in `summarize`** — use `start_time` instead:
   ```dql
   // ❌ null result
   | summarize first_seen = min(timestamp), last_seen = max(timestamp), by:{error.id}
   // ✅ correct
   | summarize first_seen = min(start_time), last_seen = max(start_time), by:{error.id}
   ```

4. **The same underlying bug can fragment across multiple `error.id` fingerprints by browser.**
   Different browsers word the same failure differently (Chrome: "Cannot read properties of null
   (reading 'X')" vs Safari: "null is not an object (evaluating 'Y.X')" vs Firefox: different
   wording again) — each gets its own `error.id`. Before ranking "top 5", spot-check whether two
   entries share a `exception.file.full` + line number and describe the same root cause; note
   this in the report rather than treating them as unrelated bugs with separate impact counts.

5. **Metrics have no `error.id` dimension.** `dt.frontend.error.count` is aggregate-only — use it
   for overall trend context (Step 5), not to isolate a single fingerprint's trend. For a single
   fingerprint's trend, bucket the `fetch user.events` query by day instead:
   ```dql
   fetch user.events, from:now()-7d
   | filter frontend.name == "$APP" and error.id == toUid("$ERROR_ID")
   | summarize count(), by:{bin(start_time, 1d)}
   ```

6. **Multi-value `in()` — don't use parenthesised list syntax:**
   ```dql
   // ❌   | filter x in ("a", "b")
   // ✅   | filter in(x, "a", "b")
   ```

7. **`countDistinctIf` does not exist:**
   ```dql
   // ❌   summarize x = countDistinctIf(session.id, error.count > 0)
   // ✅   | filter error.count > 0 | summarize x = countDistinct(session.id)
   ```

8. **Unfiltered `fetch user.events` can cost 500+ GB** — always apply `frontend.name ==` AND
   `error.type == "exception"` before any aggregation. A 7d top-5 query on a single mid-traffic
   frontend still scanned ~20 GB in testing — budget accordingly for larger windows.

9. **`exception.file.full` is null for cross-origin "Script error." and unhandled
   `promise_rejection` failures — it is NOT null for inline `<script>` block errors** (it's
   populated with the page URL itself in that case; use `exception.line_number` to locate the
   statement within the assembled page). Treat a null file as "cannot fetch source, describe
   from message/type only" — don't assume inline-script errors are unfetchable.

10. **A CMS-assembled page (e.g. Liferay fragments) may not reproduce the exact runtime line
    numbers on a plain `curl`/static fetch.** Content can vary between requests (personalization,
    caching, A/B tests, dynamically composed fragments) — a static fetch may legitimately not
    contain the reported line/column even when the file URL matches exactly. Report line-number
    matches you can textually confirm as confirmed; report ones you can't find as "page fetched,
    but reported line not found in this snapshot — content likely varies by request" rather than
    guessing or fabricating a matching line.

---

## References

| File | Load When |
|---|---|
| [references/error-queries.md](references/error-queries.md) | Running Step 4/5 queries in full |
| [references/js-fix-patterns.md](references/js-fix-patterns.md) | Step 6 — matching an error signature to a fix template |
| [references/report-template.md](references/report-template.md) | Step 7 — building the final report |
