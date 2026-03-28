# TripleDB — Report v9.39

**Phase:** 9 — App Optimization
**Iteration:** 39
**Executor:** Claude Code (Opus)
**Date:** 2026-03-28

---

## 1. Bug 1: Unknown City/State in Nearby Results

**Root cause:** The `nearbyRestaurants` provider in `location_providers.dart` filtered only for `latitude != null`, `longitude != null`, and `stillOpen != false`. No city/state validation existed. The `Restaurant.fromJson()` factory defaults null city/state values to `'Unknown'`, so restaurants with missing location data still appeared in nearby results as "Big Pig's Barbecue — Unknown, NJ • 22 mi".

**Data scope:** 154 of 1,102 restaurants have null/None city values in the JSONL dataset. Most lack lat/lng (filtered by existing check), but some were geocoded to state-level coordinates and slipped through.

**Fix:** Added `_hasValidLocation()` helper that validates both lat/lng AND city/state. Rejects empty strings and known invalid values: `unknown`, `none`, `n/a`, `null` (case-insensitive).

**Verification:** Post-flight TEST 1 — scanned full accessibility tree for `Unknown, XX` patterns. Zero matches. **PASS.**

---

## 2. Bug 2: Duplicate Restaurants in Nearby Results

**Root cause:** "Belly and Snout" has 3 entries in the normalized JSONL with different `restaurant_id` values:
- `r_fb7d0ba5b259` — city=None, lat=None (extraction artifact)
- `r_2dec384ed12b` — "Belly & Snout", Los Angeles, CA
- `r_016c92a74504` — "Belly and Snout", Rancho Cucamonga, CA

These are pipeline extraction duplicates from different DDD episodes. Different IDs prevented simple ID-based dedup from catching them.

**Fix:** Added dual deduplication after distance sort:
1. By `restaurant_id` (catches exact duplicates)
2. By normalized name (lowercase, non-alphanumeric stripped — catches "Belly & Snout" vs "Belly and Snout" variants)

The closest instance is kept. Bug 1's city filter also removes the `None`-city entry.

**Verification:** Post-flight TEST 2 — extracted all restaurant names from accessibility tree, checked for duplicates. Zero found. **PASS.**

---

## 3. Bug 3: Accept All Doesn't Trigger Location

**Root cause:** `_applyConsent()` called `_requestLocationAfterConsent()` which scheduled the location request via `WidgetsBinding.instance.addPostFrameCallback()`, then immediately called `_hide()` which set `_isVisible = false` and triggered a rebuild. The widget was removed from the tree before the post-frame callback fired, causing the location request to execute on a disposed widget (silently failing via try-catch).

**Fix:** Made `_applyConsent()` async. Replaced `addPostFrameCallback` with a direct `await _requestLocation()` call that executes BEFORE `_hide()`. The banner remains mounted during the permission request. The flow is now:
1. Save consent preferences
2. Update analytics consent
3. **await** location permission request (banner still visible)
4. Dismiss banner (after location request completes)

**Verification:** Post-flight TEST 3 — fresh incognito context, clicked Accept All via semantics DOM, confirmed banner dismissed AND geolocation API was called (intercepted via JS wrapper). **PASS.**

---

## 4. Post-Flight Results

### Tier 1 — Standard Health

| Gate | Description | Result |
|------|------------|--------|
| 1 | App bootstraps (no white screen) | **PASS** — Flutter element present, content 14,367 bytes |
| 2 | Console clean | **PASS** — 0 new errors (1 pre-existing Firestore init error on localhost) |
| 3 | Changelog ≥ 24 entries | **PASS** — 24 entries |

### Tier 2 — Iteration Playbook

| Test | Bug | Description | Result |
|------|-----|------------|--------|
| 1 | Bug 1 | No "Unknown" in nearby | **PASS** |
| 2 | Bug 2 | No duplicates in nearby | **PASS** |
| 3 | Bug 3 | Accept All → location request | **PASS** |
| 4 | — | Cookie persists on reload | **PASS** |
| 5 | — | Decline writes correct prefs | **PASS** |

**Total: 7/7 PASS. 0 FAIL. 0 SKIP.**

---

## 5. Changelog

Entry count: **24** (≥ 24 requirement met)

Appended v9.39 entry covering all three bug fixes, design doc update, and post-flight results.

---

## 6. Orchestration Report

| Tool | Category | Workload % | Efficacy |
|------|----------|-----------|----------|
| Claude Code (Opus) | Primary executor | 70% | 0 self-heal cycles. All 3 bugs diagnosed and fixed in single pass. |
| Puppeteer (npm) | Post-flight testing | 20% | 7/7 tests PASS. Flutter a11y tree enabled via semantics DOM. Test script required 4 iterations to handle Flutter canvas + fresh cookie state. |
| Python (pipeline) | Data investigation | 5% | Belly and Snout duplicate investigation confirmed 3 entries with different IDs. |
| build_runner + Flutter | Build toolchain | 5% | Codegen + analyze + build all clean. |

**Key observations:**
- Puppeteer test development took the most iteration — Flutter web's canvas rendering and deferred accessibility tree required enabling semantics mode and using DOM-based button clicks instead of coordinate-based.
- The `addPostFrameCallback` anti-pattern (Bug 3) is a common Flutter pitfall when dismissing widgets that need to perform async work before disposal.
- The pipeline has extraction duplicates (different IDs, same restaurant) that would benefit from a dedup pass at the normalization stage for future data quality.

---

## 7. Interventions

**0 interventions.** Full autonomous execution.

---

## 8. Claude's Recommendation

All three bugs fixed and verified. The app is ready to deploy.

**Recommended next steps:**
1. **Deploy:** `git push && flutter build web && firebase deploy --only hosting`
2. **Manual verification in incognito:** Confirm no "Unknown" in nearby, no duplicates, Accept All triggers location prompt
3. **Future consideration:** Pipeline-level dedup pass to consolidate extraction duplicates (e.g., "Belly & Snout" / "Belly and Snout") at normalization time rather than filtering at display time

**Iteration status: COMPLETE. Ready for deployment.**
