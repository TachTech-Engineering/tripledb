# TripleDB — App Design v8.23

---

# Part 1: IAO × MCP v4 — Flutter Build (Second Pass)

## Why a Second Pass

The first pass (v8.17–v8.21) proved the architecture works — tripledb.net is live with search, trivia, geolocation, and map. But it ran as a single Gemini session that blew through all 4 MCP phases without producing build or report artifacts between them. Cookie issues and TLS certificate errors blocked Firecrawl scrapes, meaning the Synthesis phase worked from incomplete design intelligence. Lighthouse never ran. The QA report was thin.

This second pass treats each MCP phase as a proper IAO iteration: plan in, build + report out, human review before the next phase. The existing codebase is the starting point — we're improving, not rebuilding.

## Phase Mapping (Second Pass)

| IAO Iteration | MCP Phase | Focus | Status |
|---|---|---|---|
| v8.22 | 1 — Discovery (redo) | Rescrape with Playwright fallback | ✅ Complete — 4/4 sites scraped |
| v8.23 | 2 — Synthesis | Design tokens, brief, component patterns from scrape data | 🔧 Current |
| v8.24 | 3 — Implementation (improve) | Apply design tokens to existing code, fix gaps | ⏳ Next |
| v8.25 | 4 — QA (full) | Lighthouse, Playwright, functional testing — no skipping | ⏳ Pending |

After v8.25, the app is design-complete and validated. Firestore wiring (v8.26) happens once the production data is ready.

## Discovery Findings (v8.22)

Carried forward for Synthesis reference:

- **Firecrawl:** Blocked on all 4 sites by Cloudflare WARP TLS inspection ("self-signed certificate in certificate chain"). `NODE_EXTRA_CA_CERTS` now set to Cloudflare Gateway CA for future phases.
- **Playwright:** Successfully scraped all 4 sites. 10 screenshots captured. Full accessibility snapshots extracted.
- **Key brand colors from scrapes:**
  - DDD Red: `#DD3333` (Food Network official)
  - DDD Orange: `#DA7E12` (DDD Locations primary)
  - Dark Surface: `#1E1E1E` (for dark mode)
- **Key design decisions from v8.22 report:**
  1. Interactive map as primary navigation tool
  2. Prominent "Near Me" FAB for geolocation
  3. Official DDD brand colors (red + orange)
  4. Episode badges / pill tags on restaurant cards
  5. Embedded YouTube deep links with timestamps

## Document Read Order (ENFORCED)

Every iteration, Gemini MUST read documents in a specified order before executing. The plan defines the exact order. The build log must confirm each file was read with a one-line summary. If the build log does not show confirmation of reading the design doc, the iteration is incomplete.

## Artifact Spec (Enforced Per Iteration)

Every iteration MUST produce ALL FOUR artifacts:

| Direction | File | Author | Mandatory |
|-----------|------|--------|-----------|
| Input | `docs/ddd-design-v{P}.{I}.md` | Claude | ✅ |
| Input | `docs/ddd-plan-v{P}.{I}.md` | Claude | ✅ |
| Output | `docs/ddd-build-v{P}.{I}.md` | Gemini | ✅ HARD REQUIREMENT |
| Output | `docs/ddd-report-v{P}.{I}.md` | Gemini | ✅ HARD REQUIREMENT |

**The build log is not optional.** It must contain every command run, every error encountered, every decision made, and every file created or modified. If Gemini ends a session without a build log, the iteration is incomplete.

**The report is not a summary.** It must contain metrics, success/failure counts, findings, and a recommendation for the next iteration. "Visual confirmation" is not a test result.

## Agent Restrictions

```
1. Git READ commands allowed: git pull, git log, git status, git diff, git show.
   Git WRITE commands forbidden: git add, git commit, git push, git checkout, git branch.
   firebase deploy forbidden.
   flutter build and flutter run ALLOWED during Implementation and QA phases.
2. NEVER ask permission or "should I proceed?" — the plan IS the permission.
3. Self-heal errors: diagnose → fix → re-run (max 3 attempts, then log and skip).
4. MCP server usage is phase-restricted (see plan for allowed servers).
5. EVERY session ends with ddd-build and ddd-report artifacts. No exceptions.
6. Build on the existing codebase. Do NOT delete or recreate the app scaffold.
   Improve what exists.
```

## Pre-Flight Requirements (Every Iteration)

Every plan's pre-flight MUST verify:

```
1. NODE_EXTRA_CA_CERTS is set and the cert file exists:
   echo $NODE_EXTRA_CA_CERTS
   test -f "$NODE_EXTRA_CA_CERTS" && echo "OK" || echo "MISSING"

2. Required input artifacts from previous iteration exist

3. Existing app code is intact (lib/main.dart, lib/theme/app_theme.dart)

4. Sample data present (assets/data/sample_restaurants.jsonl)
```

---

# Part 2: tripleDB.net — App Architecture

## Domain

**tripledb.net** — Mobile-first Flutter Web, intended for eventual Google Play and App Store deployment via `flutter build apk` / `flutter build ios`.

## Current State (After v8.22 Discovery)

The app is live at tripledb.net with:
- ✅ Google-style search bar
- ✅ Rotating trivia card (auto-cycling 8s, computed from sample data)
- ✅ "Top 3 Near You" with geolocation prompt
- ✅ "View All on Map" button
- ✅ Restaurant detail pages
- ✅ Sample data provider (50 restaurant records)
- ✅ Null-safe model parsing (fixed TypeError from v8.21 QA)
- ✅ Complete Discovery scrapes from 4 reference sites (v8.22)
- ✅ UX analysis with comparison table and 10 design decisions (v8.22)

What needs improvement:
- ❌ Design tokens not properly applied — Synthesis (v8.23) fixes this
- ❌ No Lighthouse audit scores — QA (v8.25) fixes this
- ❌ Typography and color palette may be defaults rather than intentional
- ❌ Mobile responsiveness not formally tested via Playwright
- ❌ Search results page layout unvalidated
- ❌ Map view styling unvalidated
- ❌ YouTube deep link rendering unvalidated

## Reference Sites (Scraped in v8.22)

| Site | URL | Scrape Status |
|------|-----|---------------|
| DDD Locations | `https://dinersdriveinsdiveslocations.com` | ✅ Playwright (Firecrawl blocked) |
| Flavortown USA | `https://flavortownusa.com` | ✅ Playwright (Firecrawl blocked) |
| Food Network DDD | `https://www.foodnetwork.com/shows/diners-drive-ins-and-dives` | ✅ Playwright (Firecrawl blocked) |
| TV Food Maps | `https://www.tvfoodmaps.com` | ✅ Playwright (Firecrawl blocked) |

## Design Contract (Three-File System)

The Synthesis phase (v8.23) produces three files that become the single source of truth for Implementation:

| File | Purpose | Consumed By |
|------|---------|-------------|
| `design-brief/design-tokens.json` | Colors, typography, spacing, map tokens → maps to Flutter ThemeData | `lib/theme/app_theme.dart` |
| `design-brief/design-brief.md` | Creative direction, aesthetic rules, tone of voice | All widget implementation |
| `design-brief/component-patterns.md` | Widget composition blueprints — what each widget looks like and how it behaves | Every file in `lib/widgets/` and `lib/pages/` |

These three files are the handoff contract between Synthesis and Implementation. Implementation (v8.24) must reference them explicitly. Any widget that doesn't trace back to a component pattern is unspecified work.

## Tech Stack (Unchanged)

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Deep-linking and navigation |
| `google_fonts` | Typography |
| `flutter_map` or `google_maps_flutter` | Map widget |
| `geolocator` | Browser geolocation |
| `url_launcher` | YouTube deep links, directions |

## Widget Tree (Current)

```
MaterialApp.router
└── GoRouter
    ├── HomePage
    │   ├── AppBar (TripleDB branding)
    │   ├── SearchBar (Google-style, centered)
    │   ├── TriviaCard (rotating fun facts)
    │   ├── NearbySection (geolocation-aware)
    │   └── MapButton
    ├── SearchResultsPage
    │   ├── SearchBar (persistent)
    │   └── RestaurantCardList
    ├── RestaurantDetailPage
    │   ├── RestaurantHeader
    │   ├── DishList → DishCard (with YouTube timestamps)
    │   └── VisitList → VisitCard
    └── MapPage
        ├── MapWidget (markers)
        └── RestaurantPreviewCard
```

## GEMINI.md Template (Update Per Iteration)

```markdown
# TripleDB App — Agent Instructions

## Current Iteration: {P}.{I}

IMPORTANT: Read documents in the EXACT order specified in the plan's
"Read Order" section before executing any steps.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden
- NEVER ask permission — auto-proceed on EVERY step
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- MCP servers are phase-restricted — only use what the plan allows
- MUST produce ddd-build AND ddd-report before ending — NO EXCEPTIONS
- Build on existing code — do NOT recreate the app scaffold
```
