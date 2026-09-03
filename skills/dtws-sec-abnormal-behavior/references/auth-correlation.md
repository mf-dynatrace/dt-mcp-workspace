# Auth Service Correlation Queries

Cross-reference RUM session anomalies with backend auth service trace data.

Requires knowledge of the auth service entity ID — find it first:
```
find_entity_by_name(["authorization", "auth", "login"])
```

All queries use `$AUTH_SERVICE_ID` as the auth service `SERVICE-*` entity ID placeholder.

---

## Auth Failure Volume Over Time

```dql
timeseries failures = sum(dt.service.request.failure_count),
          requests = sum(dt.service.request.count),
          filter:{dt.entity.service == "$AUTH_SERVICE_ID"}
| fieldsAdd failure_rate = failures[] * 100.0 / requests[]
```

Free metric query — 0 GB cost. Correlate any spike in failure rate with the timing of suspect geo session activity.

---

## HTTP 401 Volume by Time Bucket

```dql
fetch spans, from:now()-24h
| filter dt.entity.service == "$AUTH_SERVICE_ID" and request.is_root_span == true
| filter http.response.status_code == 401
| summarize count(), by:{bin(timestamp, 15m)}
| sort `bin(timestamp, 15m)` asc
```

**Interpretation:**
- **Sustained low-level rate** (e.g. 50-100 per 15min, consistent over hours): credential stuffing campaign actively running, paced to avoid detection
- **Burst then silence**: targeted attack, likely a list-based run (exhausting a credential list)
- **Spike aligned with suspect geo timing**: confirms geo anomaly and auth backend are the same campaign

---

## Auth Endpoint Targeting

```dql
fetch spans, from:now()-24h
| filter dt.entity.service == "$AUTH_SERVICE_ID" and request.is_root_span == true
| summarize total = count(), failures_401 = countIf(http.response.status_code == 401), by:{endpoint.name}
| fieldsAdd failure_pct = round(failures_401 * 100.0 / total, decimals: 1)
| sort total desc
```

Confirms which specific endpoint is being targeted. Credential stuffing typically targets a single POST endpoint repeatedly.

---

## Auth Failure Reason Breakdown

```dql
fetch spans, from:now()-24h
| filter dt.entity.service == "$AUTH_SERVICE_ID" and request.is_root_span == true and request.is_failed == true
| filter iAny(span.events[][span_event.name] == "exception")
| expand span.events
| fieldsFlatten span.events, fields: {exception.type, exception.message}
| summarize count(), by:{endpoint.name, exception.type}
| sort `count()` desc
```

**Note:** exception.message may be empty due to PCI-DSS intentional redaction. The exception.type alone (generic `Error`) is still a useful confirmation that all failures are of the same type, consistent with a single automated attack vector.

---

## Absence of HTTP 429 (Rate Limiting Gap)

```dql
fetch spans, from:now()-24h
| filter dt.entity.service == "$AUTH_SERVICE_ID" and request.is_root_span == true
| summarize count(), by:{http.response.status_code}
| sort `count()` desc
```

**Critical signal:** if HTTP 429 (Too Many Requests) does NOT appear in the results, no rate limiting is active on the auth endpoint. A credential stuffing campaign running at moderate velocity will proceed entirely unchecked.

**Action:** configure rate limiting on the auth endpoint (e.g. 10 auth requests per IP per 60 seconds). This is a WAF/API gateway configuration, not a Dynatrace configuration.

---

## Downstream Identity Provider (SSO) Impact

If the auth service calls an upstream SSO or identity provider, check whether the volume of 401s is stressing the upstream:

```dql
fetch spans, from:now()-24h
| filter dt.entity.service == "$AUTH_SERVICE_ID" and span.kind == "client"
| summarize calls = count(), failures = countIf(request.is_failed == true), avg_ms = round(toDouble(avg(duration))/1000000, decimals:1), by:{server.address}
| sort calls desc
```

High call volume to the SSO provider combined with elevated failure rates may trigger upstream account lockouts or security responses from the identity provider.
