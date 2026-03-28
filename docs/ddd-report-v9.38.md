# TripleDB — Report v9.38

**Phase:** 9 — App Optimization
**Iteration:** 38 (global)
**Date:** 2026-03-27
**Status:** COMPLETE — All gates pass

---

## Root Cause

The cookie banner **does render correctly** for new visitors. Debug logging in a fresh
Puppeteer context confirmed: `hasConsented=false`, banner visible in screenshot.

The reported issue ("banner doesn't render on tripledb.net") was caused by a **stale cookie
from development** on Kyle's browser. Additionally, three defensive bugs were found:

1. **`Secure` flag on HTTP** — `_writeCookie()` always set `Secure`, which causes browsers
   to silently reject the cookie on non-HTTPS connections. This prevented cookie persistence
   during local testing and could mask issues.

2. **ISO 8601 `expires` format** — Browsers expect RFC 1123 (`Thu, 27 Mar 2027 00:00:00 GMT`),
   not ISO 8601 (`2027-03-27T00:00:00.000Z`). Most browsers are lenient but this is
   technically non-compliant and could cause cookies to be treated as session cookies.

3. **Fragile `_readCookie()` parsing** — Used `split('=')` with `parts.length == 2` check,
   which would fail if cookie values contained `=` characters.

## Fix

File changed: `lib/services/cookie_consent_service.dart`

- `_readCookie()`: Replaced `split('=')` with `indexOf('=')` for robust parsing. Added
  `essential` key validation to reject malformed/stale cookies.
- `_writeCookie()`: RFC 1123 date format via `_toRfc1123()` helper. Conditional `Secure`
  flag (only on HTTPS).
- Added static `_weekdays` and `_months` constants for RFC 1123 formatting.

No other files changed (debug logging added and removed in same iteration).

---

## Post-Flight Results

### Tier 1 — Standard Health

| Gate | Result |
|------|--------|
| App bootstraps (not white screen) | ✅ PASS |
| Console clean (0 critical errors) | ✅ PASS |
| Changelog ≥ 23 entries | ✅ PASS (23) |

### Tier 2 — Functional Playbook

| # | Test | Result |
|---|------|--------|
| 1 | Banner renders for new visitor (CRITICAL) | ✅ PASS |
| 2 | Accept All dismisses banner (CRITICAL) | ✅ PASS |
| 3 | Cookie persists across reload (CRITICAL) | ✅ PASS |
| 4 | Cookie structure valid | ✅ PASS |
| 5 | Fresh context gets banner again | ✅ PASS |
| 6 | Decline writes correct preferences | ✅ PASS |

**9/9 tests pass. 0 failures.**

---

## Changelog

- Count: 23 (gate: ≥ 23)
- v9.38 entry appended
- README iteration count, Pillar 9 description, iteration table, and footer updated

---

## Interventions: 0

---

## Recommendation

Deploy. The cookie consent system is now robust:
- Stale/malformed cookies are rejected (forces banner re-display)
- Cookie persistence is correct (RFC 1123 expires, conditional Secure)
- Parsing handles edge cases (indexOf instead of split)

After deployment, verify in incognito on tripledb.net:
1. Banner appears on first visit
2. Accept All → banner disappears → reload → banner stays gone
3. New incognito window → banner reappears
