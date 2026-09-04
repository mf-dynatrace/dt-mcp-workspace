# JS Error Signature → Fix Pattern Matching

Match `exception.type` + the shape of `exception.message` to one of these known patterns before
writing a custom fix. These are starting templates — always verify against the actual fetched
source before proposing a patch; never paste a template fix without confirming it fits the real
code.

## Contents
- [Source Fetch Procedure](#source-fetch-procedure)
- [Pattern: Undefined/Null Property Access](#pattern-undefinednull-property-access)
- [Pattern: Not a Function](#pattern-not-a-function)
- [Pattern: Reference Not Defined](#pattern-reference-not-defined)
- [Pattern: JSON Parse Failure](#pattern-json-parse-failure)
- [Pattern: Null DOM Query Result](#pattern-null-dom-query-result)
- [Pattern: Unhandled Promise Rejection](#pattern-unhandled-promise-rejection)
- [Pattern: Third-Party Script Error](#pattern-third-party-script-error)
- [When No Sourcemap Is Reachable](#when-no-sourcemap-is-reachable)

## Source Fetch Procedure

1. `curl` the URL in `exception.file.full` (not `WebFetch` — it converts content to markdown via
   a model and loses exact code formatting/byte-for-byte text needed for matching).
2. Scan the last ~200 bytes of the response for `//# sourceMappingURL=`. If found, resolve it
   (relative to the file's own URL) and `curl` the map.
3. If no comment is found, try `curl` on `<exception.file.full>.map` directly — some builds
   omit the comment but still publish the map at the conventional path.
4. If a sourcemap is retrieved, use it to identify the original source file/line for the
   function name or line context implicated by the error message. Full AST-level de-minification
   is out of scope — locate the relevant *statement*, not necessarily the exact original
   formatting.
5. If nothing is reachable (404, CORS-blocked, or no map), fall back to
   [When No Sourcemap Is Reachable](#when-no-sourcemap-is-reachable).
6. When `exception.file.full` equals the page URL itself (inline `<script>` error), fetch the
   page HTML directly (`curl`, not `WebFetch` — `WebFetch` converts to markdown and loses exact
   code formatting) and search for text matching the identifiers in `exception.message` near
   the reported `exception.line_number`. **On CMS-assembled pages (e.g. Liferay fragments), a
   static fetch may not reproduce the exact runtime line count** — content can vary between
   requests (personalization, caching, A/B tests, dynamically composed fragments). Confirm a
   match by finding the literal failing expression (e.g. `closeButton.addEventListener`) in the
   fetched HTML; if the reported line number doesn't contain a plausible match, say so explicitly
   rather than citing an unrelated line as the cause.
7. For third-party files, check whether the literal identifier from the error message (e.g. an
   undefined function name in a `ReferenceError`) actually appears in the currently-fetched file.
   If it doesn't, the vendor has likely shipped a new version since the error occurred — note this
   explicitly ("current live file no longer contains this reference — may already be fixed, or
   affected users are on a cached/older copy") instead of claiming a stale analysis is current.

Record which of these outcomes occurred in the report — "source: sourcemap-resolved",
"source: minified-only", "source: inline-script, line confirmed", "source: inline-script, line
not found in current snapshot", or "source: unreachable (report metadata only)".

## Pattern: Undefined/Null Property Access

**Signature:** `TypeError: Cannot read propert(y|ies) of undefined/null (reading 'X')`

**Root cause:** code accesses `.X` on a value that is sometimes `undefined`/`null` — typically
an API response field that's missing/renamed, a race condition (accessed before async data
loads), or an object built conditionally.

**Existing code shape (example):**
```js
const total = response.data.summary.total;
```

**Suggested fix:**
```js
const total = response?.data?.summary?.total ?? 0;
```
If the surrounding logic needs to *know* the value was missing (not just default it), guard
explicitly instead of silently defaulting:
```js
if (!response?.data?.summary) {
  console.warn('summary missing from response', response);
  return;
}
const total = response.data.summary.total;
```

## Pattern: Not a Function

**Signature:** `TypeError: X is not a function`

**Root cause:** either (a) a library/global hasn't loaded yet when the call runs (script load
order / async race), or (b) an API surface changed (method renamed/removed in a dependency
upgrade), or (c) a typo.

**Suggested fix — load-order guard:**
```js
if (typeof window.SomeLib?.init === 'function') {
  window.SomeLib.init();
} else {
  document.addEventListener('DOMContentLoaded', () => window.SomeLib?.init?.());
}
```
If it's a dependency version mismatch, the fix is a version pin/upgrade, not a code patch — say
so explicitly rather than proposing a workaround that masks a real regression.

## Pattern: Reference Not Defined

**Signature:** `ReferenceError: X is not defined`

**Root cause:** a missing script tag, a build/bundling misconfiguration (tree-shaken export that
was still referenced), or a global expected from a third-party tag manager that didn't fire.

**Suggested fix:**
```js
// Guard against the global not being present yet
if (typeof X !== 'undefined') {
  X.doThing();
}
```
Flag to the customer that the durable fix is ensuring the defining script loads before this one
runs (script order, `defer`/`async` attributes, or bundler config) — the guard above only
prevents the crash, it doesn't restore the missing functionality.

## Pattern: JSON Parse Failure

**Signature:** `SyntaxError: Unexpected token ... in JSON` / `Unexpected end of JSON input`

**Root cause:** an API returned non-JSON (HTML error page, empty body) but the caller parsed it
unconditionally.

**Existing code shape (example):**
```js
const data = JSON.parse(responseText);
```

**Suggested fix:**
```js
let data;
try {
  data = JSON.parse(responseText);
} catch (e) {
  console.error('Failed to parse response as JSON', { responseText, error: e });
  data = null; // handle downstream — do not let this crash the page
}
```

## Pattern: Null DOM Query Result

**Signature:** `TypeError: Cannot read properties of null (reading 'addEventListener' | 'value' | 'style' | ...)`

**Root cause:** `document.querySelector`/`getElementById` ran before the target element existed
(script ran too early) or the element was conditionally rendered/removed.

**Existing code shape (example):**
```js
document.getElementById('submit-btn').addEventListener('click', handleSubmit);
```

**Suggested fix:**
```js
const submitBtn = document.getElementById('submit-btn');
if (submitBtn) {
  submitBtn.addEventListener('click', handleSubmit);
}
```
If the element is expected to always exist on this page, the real issue may be script placement
(running before the DOM node renders) — recommend moving the script below the element or wrapping
in `DOMContentLoaded`.

## Pattern: Unhandled Promise Rejection

**Signature:** `error.source == "promise_rejection"`, `exception.message` often just the
rejection reason with no stack context.

**Root cause:** an async call (`fetch`, `.then()` chain) has no `.catch()`/`try-catch`.

**Suggested fix:**
```js
fetch('/api/endpoint')
  .then(res => res.json())
  .catch(err => {
    console.error('endpoint call failed', err);
    // surface a user-facing fallback instead of an unhandled rejection
  });
```

## Pattern: Third-Party Script Error

**Signature:** `exception.file.provider != "first_party"` (CDN/third-party origin).

**Do not propose a code patch** — the customer doesn't own this file. Instead, the report should:
- Name the vendor/domain clearly.
- Recommend: check for a newer vendor SDK version, wrap the *integration point* (the first-party
  code that calls into the vendor script) defensively, or contact the vendor if the error rate
  is high enough to indicate a vendor-side regression.
- If `WebFetch` was blocked by CORS, note that this is expected for third-party scripts and is
  not itself a bug.

## When No Sourcemap Is Reachable

Still produce a best-effort analysis:
1. Search the minified file text for identifier fragments named in `exception.message` (e.g. for
   `reading 'total'`, search for `.total` or `["total"]` occurrences).
2. If a `first_seen`/`last_seen` window in Step 4/5 is narrow and recent, note that a corresponding
   line number is unreliable to state without a map — describe the *behaviour* (what the code is
   trying to do based on message + surrounding minified context) rather than inventing exact
   line/column citations.
3. Label the report section clearly: **"Source: minified, no sourcemap available — analysis based
   on error signature and surrounding minified context, not exact source line."**
