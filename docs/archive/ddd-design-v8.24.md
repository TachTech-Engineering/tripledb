# TripleDB — App Design v8.24

---

# Part 1: IAO × MCP v4 — Flutter Build (Second Pass)

## Phase Mapping (Second Pass)

| IAO Iteration | MCP Phase | Focus | Status |
|---|---|---|---|
| v8.22 | 1 — Discovery (redo) | Rescrape with Playwright fallback | ✅ Complete |
| v8.23 | 2 — Synthesis | Design tokens, brief, component patterns | ✅ Complete |
| v8.24 | 3 — Implementation | Gap fixes + apply design contract to codebase | 🔧 Current |
| v8.25 | 4 — QA (full) | Lighthouse, Playwright, functional testing | ⏳ Next |

## Discovery Findings (v8.22)

- 4/4 sites scraped via Playwright (Firecrawl blocked by WARP TLS)
- Key brand colors: DDD Red `#DD3333`, Orange `#DA7E12`, Dark Surface `#1E1E1E`
- Key patterns: map-first nav, Near Me FAB, episode badges, YouTube deep links

## Synthesis Output (v8.23)

Three-file design contract produced:
- `design-brief/design-tokens.json` — colors, typography (Outfit + Inter), spacing, map tokens
- `design-brief/design-brief.md` — "Modern Flavortown" aesthetic, color/typography rules, tone
- `design-brief/component-patterns.md` — 8 widget patterns defined

## Gap Analysis (Pre-Implementation Fixes)

Review of the v8.23 design contract identified 4 gaps that must be fixed BEFORE applying tokens to the codebase:

### Gap 1: Missing Elevation Tokens
Component patterns reference "subtle elevation shadow" (SearchBar) and "distinct elevation" (RestaurantCard) but `design-tokens.json` has no elevation values. Without these, Gemini will improvise and produce inconsistent shadows.

**Fix:** Add elevation section to `design-tokens.json`:
```json
"elevation": {
  "none": 0,
  "sm": 1,
  "md": 2,
  "lg": 4,
  "xl": 8
}
```

### Gap 2: Episode Badges Reference Non-Existent Data
Component patterns specify "S12 | E4" season/episode badges, but the data model has no `season` or `episode` fields. The pipeline extracts `video_title`, `video_type`, and `video_id` only.

**Fix:** Change episode badges to display `video_type` (e.g., "Compilation", "Full Episode", "Marathon") and DDD appearance count (e.g., "5 visits"). If season/episode can be parsed from `video_title`, that's a bonus — but the badge must work without it.

### Gap 3: "Saved" Tab Has No Backend
The bottom nav specifies "Map / List / Saved" but there's no save/unsave logic, no `SavedProvider`, and no persistence layer. Building this in v8.24 would expand scope significantly.

**Fix:** Replace "Saved" with "Explore" — a tab that shows trivia, top states, most-visited restaurants, and fun stats. This uses data we already have and aligns with the Flavortown USA "ranked lists" stolen pattern. Save/Trip functionality deferred to post-launch.

### Gap 4: No Image Placeholder Strategy
Design brief says "edge-to-edge full-width placeholder image" but restaurants don't have images until Phase 6 enrichment.

**Fix:** Define a placeholder: restaurant initial letter in a colored circle (using `cuisine_type` to pick a color from a small palette), or a food emoji grid based on `cuisine_type` (🍕 Italian, 🍔 American, 🌮 Mexican, 🍖 BBQ, etc.). Component patterns must specify this explicitly so every card renders consistently.

## Artifact Spec (Enforced Per Iteration)

| Direction | File | Author | Mandatory |
|-----------|------|--------|-----------|
| Input | `docs/ddd-design-v8.24.md` | Claude | ✅ |
| Input | `docs/ddd-plan-v8.24.md` | Claude | ✅ |
| Output | `docs/ddd-build-v8.24.md` | Gemini | ✅ HARD REQUIREMENT |
| Output | `docs/ddd-report-v8.24.md` | Gemini | ✅ HARD REQUIREMENT |

## Agent Restrictions

```
1. Git READ commands allowed: git pull, git log, git status, git diff, git show.
   Git WRITE commands forbidden: git add, git commit, git push, git checkout, git branch.
   firebase deploy forbidden.
   flutter build and flutter run ARE ALLOWED this phase for testing.
2. NEVER ask permission or "should I proceed?" — the plan IS the permission.
3. Self-heal errors: diagnose → fix → re-run (max 3 attempts, then log and skip).
4. MCP: Context7 ALLOWED for Flutter/Dart API docs. Firecrawl, Playwright, Lighthouse NOT allowed.
5. EVERY session ends with ddd-build and ddd-report artifacts. No exceptions.
6. Build on the existing codebase. Do NOT delete or recreate the app scaffold.
7. EVERY code change must trace back to a design token or component pattern.
   If a widget doesn't have a corresponding pattern, do NOT implement it.
```

## Pre-Flight Requirements

```
1. NODE_EXTRA_CA_CERTS is set and cert file exists
2. Design contract files exist:
   - design-brief/design-tokens.json
   - design-brief/design-brief.md
   - design-brief/component-patterns.md
3. Existing app code is intact (lib/main.dart, lib/theme/app_theme.dart)
4. Sample data present (assets/data/sample_restaurants.jsonl)
5. flutter pub get succeeds
6. flutter analyze returns 0 errors
```

---

# Part 2: tripleDB.net — App Architecture

## Domain

**tripledb.net** — Mobile-first Flutter Web → Google Play → App Store.

## Current State (After v8.23 Synthesis)

- ✅ Live at tripledb.net with working search, trivia, geolocation, map
- ✅ Complete design contract (tokens, brief, component patterns)
- ✅ 4/4 reference site scrapes with UX analysis
- ❌ Design tokens not applied to codebase (defaults still in use)
- ❌ Component patterns not reflected in widget implementations
- ❌ Gap fixes needed before applying tokens

## Tech Stack

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Deep-linking and navigation |
| `google_fonts` | Typography (Outfit + Inter) |
| `flutter_map` or `google_maps_flutter` | Map widget |
| `geolocator` | Browser geolocation |
| `url_launcher` | YouTube deep links, directions |

## Widget Tree (Target After v8.24)

```
MaterialApp.router (ThemeData from design-tokens.json)
└── GoRouter
    ├── Scaffold with BottomNavigationBar (Map / List / Explore)
    │
    ├── HomePage (List tab)
    │   ├── AppBar (TripleDB logo, dark mode toggle)
    │   ├── SearchBar (pill shape, Outfit placeholder, 300ms debounce)
    │   ├── TriviaCard (primary tint bg, xl radius, 8s cycle)
    │   ├── NearbySection (📍 header, compact cards with distance)
    │   └── RestaurantCardList (full results when searching)
    │
    ├── MapPage (Map tab)
    │   ├── MapWidget (dark style, red pins, orange clusters)
    │   ├── NearMe FAB (primary color, location icon)
    │   └── RestaurantPreviewCard (bottom sheet on pin tap)
    │
    ├── ExplorePage (Explore tab — replaces "Saved")
    │   ├── TriviaCard (larger format)
    │   ├── TopStatesSection (ranked list)
    │   ├── MostVisitedSection (restaurants with 5+ appearances)
    │   └── CuisineBreakdownSection (category counts)
    │
    └── RestaurantDetailPage (push route)
        ├── HeroHeader (placeholder image, name, city, cuisine, status)
        ├── DishList → DishCard (guy_response in italic secondary)
        ├── VisitList → VisitCard (video_type badge, YouTube link)
        └── ActionBar (Directions, Website)
```

## Data Model Reminder

The sample data has these fields per restaurant:
```json
{
  "restaurant_id": "r_uuid",
  "name": "Desert Oak Barbecue",
  "city": "El Paso",
  "state": "TX",
  "cuisine_type": "Barbecue",
  "owner_chef": "Rich Funk and Suzanne",
  "visits": [{ "video_id", "youtube_url", "video_title", "video_type", "guy_intro", "timestamp_start" }],
  "dishes": [{ "dish_name", "description", "ingredients", "dish_category", "guy_response", "video_id", "timestamp_start" }]
}
```

Fields NOT available yet (Phase 6 enrichment): `address`, `latitude`, `longitude`, `google_rating`, `yelp_rating`, `website_url`, `still_open`. Design accordingly — show what we have, gracefully hide what we don't.

## GEMINI.md Template

```markdown
# TripleDB App — Agent Instructions

## Current Iteration: 8.24

IMPORTANT: Read documents in this EXACT order before executing:

1. docs/ddd-design-v8.24.md — Architecture, gap analysis, widget tree
2. docs/ddd-plan-v8.24.md — Implementation execution steps
3. design-brief/design-tokens.json — Color, typography, spacing tokens
4. design-brief/design-brief.md — Creative direction and aesthetic rules
5. design-brief/component-patterns.md — Widget composition blueprints

Do NOT begin execution until all 5 files have been read.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden
- flutter build and flutter run ARE ALLOWED for testing
- NEVER ask permission — auto-proceed on EVERY step
- Context7 MCP allowed for Flutter/Dart docs. No other MCP servers.
- MUST produce ddd-build-v8.24.md AND ddd-report-v8.24.md before ending
- Every code change must trace to a design token or component pattern
- Build on existing code — do NOT recreate the app scaffold
```
