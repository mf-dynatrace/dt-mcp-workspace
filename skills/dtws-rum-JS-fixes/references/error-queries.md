# JS Error Queries

All queries scoped to `error.type == "exception"` on `user.events` unless noted. Replace
`$APP`, `$TIMEFRAME`, and `$ERROR_ID` with actual values.

## Contents
- [Denominators (for % impact)](#denominators-for--impact)
- [Top 5 Fingerprints](#top-5-fingerprints)
- [Fallback Grouping (error.id is null)](#fallback-grouping-erroridis-null)
- [Per-Error Browser/Device Split](#per-error-browserdevice-split)
- [Per-Error Daily Trend](#per-error-daily-trend)
- [Per-Error Affected Pages](#per-error-affected-pages)
- [Overall Trend Context (free metric)](#overall-trend-context-free-metric)

## Denominators (for % impact)

Total exceptions and total sessions on the frontend — needed to express each top-5 error as a
percentage rather than a raw count.

```dql
fetch user.events, from:now()-$TIMEFRAME
| filter frontend.name == "$APP" and error.type == "exception"
| summarize total_exceptions = count()
```

```dql
fetch user.sessions, from:now()-$TIMEFRAME
| filter in(dt.rum.application.entities, "$APP_ENTITY_ID")
| summarize total_sessions = count()
```
Use `frontend.name == "$APP"` as the alternative filter on `user.sessions` if the entity ID
isn't known yet (see `dt-obs-frontends` application filter cheat sheet — `frontend.name` is an
array field, so prefer `in()` semantics are not needed here since `==` against a session-level
array works for equality checks in this context; if it returns 0, switch to the entity ID form).

## Top 5 Fingerprints

`min(timestamp)`/`max(timestamp)` return null in `summarize` — use `start_time` instead (see
SKILL.md DQL Gotchas #3). This query intentionally omits first/last seen for that reason; run
the dedicated query below for that once you have the top 5 `error.id` values.

```dql
fetch user.events, from:now()-$TIMEFRAME
| filter frontend.name == "$APP" and error.type == "exception"
| summarize
    occurrences = count(),
    affected_sessions = countDistinct(dt.rum.session.id),
    affected_users = countDistinct(dt.rum.instance.id, precision: 9),
    by: {error.id, exception.type, exception.message, exception.file.full,
         exception.file.provider, error.source, exception.line_number, exception.column_number}
| sort occurrences desc
| limit 5
```

## First/Last Seen for Top 5

`error.id` is a UID type — a bare string filter silently returns 0 rows (see SKILL.md DQL
Gotchas #2). Always wrap each ID in `toUid()`:

```dql
fetch user.events, from:now()-$TIMEFRAME
| filter frontend.name == "$APP" and error.type == "exception"
| filter in(error.id, toUid("$ID1"), toUid("$ID2"), toUid("$ID3"), toUid("$ID4"), toUid("$ID5"))
| summarize first_seen = min(start_time), last_seen = max(start_time), by:{error.id}
```

## Fallback Grouping (error.id is null)

Some older agent versions or synthetic-injected errors may not populate `error.id`. If Step 4's
result set has null `error.id` values, re-run grouped by message shape instead:

```dql
fetch user.events, from:now()-$TIMEFRAME
| filter frontend.name == "$APP" and error.type == "exception"
| filter isNull(error.id)
| summarize
    occurrences = count(),
    affected_sessions = countDistinct(dt.rum.session.id),
    by: {exception.type, exception.message, exception.file.full}
| sort occurrences desc
| limit 5
```

## Per-Error Browser/Device Split

```dql
fetch user.events, from:now()-$TIMEFRAME
| filter frontend.name == "$APP" and error.id == toUid("$ERROR_ID")
| summarize occurrences = count(), by:{browser.name, device.type}
| sort occurrences desc
```

**Interpretation:** if >80% of occurrences concentrate on one `browser.name`, first rule out that
this is simply that browser's wording for a cross-browser bug (see SKILL.md DQL Gotchas #4 —
Chrome/Edge/Safari/Firefox each word the same JS failure differently, so the same underlying bug
naturally shows up as Chromium-heavy or Safari-heavy purely because of message-text fragmentation,
not because of an actual compatibility difference). Only call it a genuine compatibility bug if
the concentration can't be explained by message wording alone (e.g. it's a CSS/API feature only
one engine lacks).

## Per-Error Daily Trend

Metrics have no `error.id` dimension, so bucket the raw events by day for a single fingerprint:

```dql
fetch user.events, from:now()-$TIMEFRAME
| filter frontend.name == "$APP" and error.id == toUid("$ERROR_ID")
| summarize occurrences = count(), by:{bin(start_time, 1d)}
| sort `bin(start_time, 1d)` asc
```

**Interpretation:**
- Flat/steady → longstanding bug, not tied to a specific deploy
- Single-day spike then drop → likely fixed already, or a transient environment issue
- Step increase that persists → correlates with a deploy; ask the user for the deploy date/time
  to confirm the correlation

## Per-Error Affected Pages

Useful context for prioritisation — which page(s) the error actually breaks for the user:

```dql
fetch user.events, from:now()-$TIMEFRAME
| filter frontend.name == "$APP" and error.id == toUid("$ERROR_ID")
| summarize occurrences = count(), by:{page.name}
| sort occurrences desc
| limit 10
```

## Overall Trend Context (free metric)

For a cheap sanity check that the top-5 fingerprints roughly track the frontend's overall error
volume (not a substitute for Per-Error Daily Trend above):

```dql
timeseries error_count = sum(dt.frontend.error.count),
  by:{frontend.name, error.type}, from:now()-$TIMEFRAME, interval:1d
| filter frontend.name == "$APP"
```
