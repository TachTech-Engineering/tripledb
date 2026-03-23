# TripleDB — App Design v8.22

---

# Part 1: IAO × MCP v4 — Flutter Build (Second Pass)

## Why a Second Pass

The first pass (v8.17–v8.21) proved the architecture works — tripledb.net is live with search, trivia, geolocation, and map. But it ran as a single Gemini session that blew through all 4 MCP phases without producing build or report artifacts between them. Cookie issues blocked several reference site scrapes, meaning the Synthesis phase worked from incomplete design intelligence. Lighthouse never ran. The QA report was thin.

This second pass treats each MCP phase as a proper IAO iteration: plan in, build + report out, human review before the next phase. The existing codebase is the starting point — we're improving, not rebuilding.

## Phase Mapping (Second Pass)

| IAO Iteration | MCP Phase | Focus | Artifact Requirement |
|---|---|---|---|
| v8.22 | 1 — Discovery (redo) | Rescrape with cookie workarounds, capture what was missed | build + report |
| v8.23 | 2 — Synthesis (redo) | Produce proper design tokens from complete scrape data | build + report |
| v8.24 | 3 — Implementation (improve) | Apply design tokens to existing code, fix gaps | build + report |
| v8.25 | 4 — QA (full) | Lighthouse, Playwright, functional testing — no skipping | build + report |

After v8.25, the app is design-complete and validated. Firestore wiring (v8.26) happens once the production data is ready.

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
1. NEVER run git, flutter deploy, or firebase deploy commands.
   Flutter build and flutter run are ALLOWED for testing during
   Implementation and QA phases.
2. NEVER ask permission or "should I proceed?" — the plan IS the permission.
3. Self-heal errors: diagnose → fix → re-run (max 3 attempts, then log and skip).
4. MCP server usage is phase-restricted (see plan for allowed servers).
5. EVERY session ends with ddd-build and ddd-report artifacts. No exceptions.
6. Build on the existing codebase. Do NOT delete or recreate the app scaffold.
   Improve what exists.
```

## Cookie / Scrape Workarounds

The first pass had Firecrawl blocked by cookie consent walls on several sites. Strategies for v8.22:

1. **Try Firecrawl first** — some sites may have updated or the cookies may be session-based
2. **Playwright fallback** — if Firecrawl gets a cookie wall, use Playwright to:
   - Navigate to the page
   - Click "Accept cookies" button if present
   - Wait for full render
   - Take screenshots at multiple scroll positions
   - Extract page text via accessibility snapshot
3. **Manual screenshot supplement** — if both tools fail on a site, note it in the report. Kyle can provide manual screenshots from a browser session.
4. **Do NOT skip a site** — document what you got, even if partial. Partial data is better than no data.

---

# Part 2: tripleDB.net — App Architecture

## Domain

**tripledb.net** — Mobile-first Flutter Web, intended for eventual Google Play and App Store deployment via `flutter build apk` / `flutter build ios`.

## Current State (After v8.21)

The app is live at tripledb.net with:
- ✅ Google-style search bar
- ✅ Rotating trivia card (auto-cycling 8s, computed from sample data)
- ✅ "Top 3 Near You" with geolocation prompt
- ✅ "View All on Map" button
- ✅ Restaurant detail pages
- ✅ Sample data provider (50 restaurant records)
- ✅ Null-safe model parsing (fixed TypeError from v8.21 QA)

What needs improvement:
- ❌ Design tokens not properly applied (scrapes were incomplete)
- ❌ No Lighthouse audit scores
- ❌ Typography and color palette may be defaults rather than intentional
- ❌ Mobile responsiveness not formally tested via Playwright
- ❌ Search results page layout unvalidated
- ❌ Map view styling unvalidated
- ❌ YouTube deep link rendering unvalidated

## Reference Sites

| Site | URL | Focus |
|------|-----|-------|
| DDD Locations | `https://dinersdriveinsdiveslocations.com` | Search/filter UX, state browsing |
| Flavortown USA | `https://flavortownusa.com` | Directory layout, branding energy |
| Food Network DDD | `https://www.foodnetwork.com/shows/diners-drive-ins-and-dives` | Official branding, colors, typography |
| TV Food Maps | `https://www.tvfoodmaps.com` | Map integration, road trip UX |

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

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v{P}.{I}.md — App architecture, methodology
2. docs/ddd-plan-v{P}.{I}.md — Phase execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- NEVER run git or firebase deploy commands
- NEVER ask permission — auto-proceed on EVERY step
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- MCP servers are phase-restricted — only use what the plan allows
- MUST produce ddd-build-v{P}.{I}.md AND ddd-report-v{P}.{I}.md before ending
- Build on existing code — do NOT recreate the app scaffold
```
