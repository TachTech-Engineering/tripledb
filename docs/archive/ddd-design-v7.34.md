# TripleDB — Design v7.34

---

# Part 1: IAO — Iterative Agentic Orchestration

## The Eight Pillars (Summary)

1. Plan-Report Loop — 2. Zero-Intervention Target — 3. Self-Healing Loops — 4. Versioned Artifacts — 5. Artifacts Travel Forward — 6. Methodology Co-Evolution — 7. Interactive vs Unattended — 8. Graduated Batches

## IAO Iteration History

| Iteration | Phase | Interventions | Key Learning |
|-----------|-------|---------------|--------------|
| v0.7–v4.13 | 0-4 | 0–20+ | Pipeline refinement → zero interventions by v3.12 |
| v5.14–v5.15 | 5 | **0** | 773 videos, 14-hour unattended run |
| v6.26–v6.29 | 6 | **0** | 1,102 loaded, 916 geocoded, app polished |
| v8.17–v8.25 | 8 | **0** | tripledb.net live |
| v7.30–v7.33 | 7 | **1** (API key) | Enrichment complete: 582 verified, AKA names, closed UX |

## Agent Restrictions

```
1. Git READ allowed. Git WRITE and firebase deploy FORBIDDEN.
2. flutter build web and flutter run ARE ALLOWED.
3. NEVER ask permission — auto-proceed on EVERY step.
4. Self-heal: diagnose → fix → re-run (max 3, then skip).
5. 3 consecutive identical errors = STOP.
6. MCP: Context7 ALLOWED. No other MCP servers.
7. FULL PROJECT ACCESS: read/write ANYWHERE under ~/dev/projects/tripledb/.
8. MUST produce ddd-build and ddd-report before ending.
9. CHECKPOINT after every numbered step.
10. $GOOGLE_PLACES_API_KEY — if not set, print error and HALT.
11. Build log is MANDATORY — full transcript.
```

## ADR Registry

| ADR | Project | Status | Iterations |
|-----|---------|--------|------------|
| ADR-001 | TripleDB | Active | v0.7 → v7.34 (current) |

---

# Part 2: ADR-001 — TripleDB

## Phase Status

| IAO Iteration | Phase | Focus | Status |
|---|---|---|---|
| v0.7–v5.15 | 0-5 | Pipeline build + production run | ✅ Complete |
| v6.26–v6.29 | 6 | Firestore, geocoding, polish | ✅ Complete |
| v8.17–v8.25 | 8 | Flutter app | ✅ Complete |
| v7.30–v7.33 | 7 | Enrichment + AKA + closed UX | ✅ Complete |
| v7.34 | 7 | Cookies, analytics, enrichment polish | 🔧 Current |

## v7.34 Scope — Three Deliverables

### Deliverable 1: Cookie Consent System

**Why:** tripledb.net needs GDPR/CCPA-compliant cookie handling before enabling any analytics. California users (including Kyle's own location) are covered by CCPA. European users by GDPR. Best practice: consent before tracking.

**Architecture:**

```
First Visit → Show consent banner (bottom of screen)
    ├─ "Accept All" → Set all cookies, enable analytics
    ├─ "Decline" → Essential only, analytics disabled
    └─ "Customize" → Category picker modal
         ├─ Essential (always on, not toggleable)
         ├─ Analytics (Firebase Analytics)
         └─ Preferences (dark mode, location, last search)

Consent stored in browser cookie: `tripledb_consent`
Cookie value: JSON → {"essential": true, "analytics": true, "preferences": true}
Cookie expiry: 365 days
```

**Cookie categories:**

| Category | Purpose | Default | Toggleable |
|----------|---------|---------|------------|
| Essential | App functionality (Firestore auth token, session) | ON | No (always on) |
| Analytics | Firebase Analytics — page views, feature usage, search queries | OFF | Yes |
| Preferences | Dark mode preference, last location, last search term | OFF | Yes |

**Key design decisions:**
- Default OFF for analytics and preferences (GDPR-compliant: opt-in, not opt-out)
- Banner appears on first visit only, not on every page load
- "Manage cookies" link in app footer for returning users to change preferences
- Consent state stored as a browser cookie (NOT localStorage — actual HTTP cookie so it persists correctly and is readable server-side if needed later)
- Banner styling: matches DDD design tokens (dark surface #1E1E1E, orange accent #DA7E12, Outfit font)

**Implementation approach — custom widget, no external package:**

For Flutter Web, cookies are managed via `dart:html` (`document.cookie`). Build a custom `CookieConsentBanner` widget and a `CookieConsentService` that:
1. Reads `tripledb_consent` cookie on app start
2. If cookie missing → show banner
3. If cookie present → parse JSON, apply preferences
4. Provides `hasConsent(category)` method for gating analytics/preferences

```dart
// CookieConsentService API
class CookieConsentService {
  bool get hasShownBanner;
  bool hasConsent(String category);  // 'analytics', 'preferences'
  void acceptAll();
  void declineAll();
  void setPreferences(Map<String, bool> prefs);
  Map<String, bool> get currentPreferences;
}
```

### Deliverable 2: Firebase Analytics with Consent Mode v2

**Why:** Track how users interact with tripledb.net — which features are used, what people search for, which restaurants are popular. This data informs future development priorities.

**Architecture:**

```
App Start
    ↓ Read cookie consent
    ↓ FirebaseAnalytics.instance.setConsent(
        analyticsStorage: consent ? ConsentStatus.granted : ConsentStatus.denied
      )
    ↓ If granted → track events
    ↓ If denied → no tracking (Firebase respects consent mode)
```

**Events to track:**

| Event | Parameters | When |
|-------|-----------|------|
| `page_view` | `page_name` | Tab navigation (Map, List, Explore) |
| `search` | `search_term`, `result_count` | User performs a search |
| `view_restaurant` | `restaurant_id`, `restaurant_name` | Restaurant detail page opened |
| `view_map` | `zoom_level`, `pin_count` | Map tab loaded |
| `filter_toggle` | `filter_name`, `enabled` | "Show closed" toggled |
| `external_link` | `link_type` (website, google_maps, youtube) | User taps external link |
| `consent_given` | `analytics`, `preferences` | Cookie consent response |
| `app_open` | `returning_user` | App loaded (cookie present = returning) |

**Consent mode integration:**
- Firebase Analytics SDK already supports consent mode v2
- Call `setConsent()` BEFORE any analytics events fire
- If user later changes consent via "Manage cookies", update `setConsent()` and log the change
- Default consent state on first load: `denied` (GDPR-safe)

**Dependencies to add:**
```yaml
dependencies:
  firebase_analytics: ^11.x  # Check latest compatible with firebase_core 3.x
```

Verify version compatibility with existing `firebase_core: 3.x` using Context7 before adding.

### Deliverable 3: Enrichment Polish

Three items to clean up:

**3a. Name-change threshold tightening:**
The v7.33 run flagged 365 name changes at 0.95 similarity threshold. Many are trivial formatting differences ("Crackling Jack's" → "Cracklin' Jack's"). Tighten to 0.90 so only genuine rebrands show the "Now known as" treatment.

Update the Firestore documents:
- Records with `name_similarity >= 0.90` → set `name_changed = false` (suppress display)
- Records with `name_similarity < 0.90` → keep `name_changed = true` (show AKA)
- This is a Firestore-only update using data already in `name_backfill.jsonl`

**3b. Resolve 26 UNCERTAIN records from v7.32:**
The LLM verification left 26 records classified as UNCERTAIN. For these, take a pragmatic approach:
- If `enrichment_match_score >= 0.80` → keep enrichment (likely correct)
- If `enrichment_match_score < 0.80` → remove enrichment (too risky)
- Log the resolution to `phase7-uncertain-resolved.jsonl`

**3c. Clean up enrichment log files:**
Consolidate the various phase7 log files into a single summary:
- `data/logs/phase7-enrichment-summary.json` with final counts and categories

## Current State (After v7.33)

### Pipeline Data
- **Unique restaurants:** 1,102
- **Enriched (verified):** 582 (52.8%)
- **Geocoded:** 1,006 (91.3%)
- **Permanently closed:** 30
- **Name changes (0.95 threshold):** 365 (283 in verified set)
- **UNCERTAIN records:** 26

### App (tripledb.net)
- Live with enrichment UI, grey pins, AKA names, closed filter
- No cookie consent banner
- No analytics tracking
- No returning visitor detection

### Firestore
- Project: tripledb-e0f77
- `restaurants`: 1,102 docs (582 enriched)
- `videos`: 773 docs
- No analytics collection yet

## Tech Stack (v7.34 additions)

| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_analytics` | 11.x | Event tracking with consent mode v2 |
| `dart:html` | (built-in) | Browser cookie read/write for Flutter Web |

**NOTE:** `dart:html` is web-only. The cookie service must be conditionally imported or guarded behind `kIsWeb` checks to avoid breaking non-web builds.

## Known Gotchas

1. **`dart:html` is web-only.** Use conditional imports if the app ever targets mobile.
2. **Firebase Analytics consent mode:** Call `setConsent()` BEFORE `logEvent()`. If analytics fires before consent is set, it defaults to the last known state.
3. **Cookie vs localStorage:** Use actual HTTP cookies (via `document.cookie`), not `window.localStorage`. Cookies persist correctly across sessions and are readable server-side.
4. **Cookie SameSite:** Set `SameSite=Lax` and `Secure` flag for tripledb.net.
5. **Banner z-index:** The consent banner must render ABOVE the map and bottom nav. Use a high z-index or an Overlay.
6. **GDPR default:** Analytics must default to DENIED until user explicitly accepts.
7. **Existing users:** On first deploy with cookies, ALL existing users will see the banner (cookie doesn't exist yet). This is correct behavior.
8. **Working directory:** Agent has FULL access to ~/dev/projects/tripledb/.
9. **Checkpoint after every step.**
10. **API key gate:** Halt if `$GOOGLE_PLACES_API_KEY` not set.

## GEMINI.md Template

```markdown
# TripleDB — Agent Instructions

## Current Iteration: 7.34

IMPORTANT: Read documents in this EXACT order before executing:

1. ../docs/ddd-design-v7.34.md — Cookies, analytics, enrichment polish specs
2. ../docs/ddd-plan-v7.34.md — Execution steps

## Rules That Never Change
- Git READ allowed. Git WRITE and firebase deploy FORBIDDEN.
- flutter build web and flutter run ARE ALLOWED.
- NEVER ask permission — auto-proceed on EVERY step.
- Context7 MCP allowed. No other MCP servers.
- FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
- MUST produce ddd-build-v7.34.md AND ddd-report-v7.34.md before ending.
- CHECKPOINT after every numbered step.
- README.md is at PROJECT ROOT.
- $GOOGLE_PLACES_API_KEY must be set. If not, print error and HALT.
- ddd-build must be FULL transcript.
```
