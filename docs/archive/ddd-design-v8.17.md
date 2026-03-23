# TripleDB — App Design v8.17

---

# Part 1: IAO × MCP v4 — Flutter Build Methodology

## How IAO and MCP v4 Merge

The MCP v4 pipeline (Discovery → Synthesis → Implementation → QA) provides the execution structure for building Flutter Web apps with agentic MCP servers. IAO provides the iteration framework, artifact spec, and review loop. Combined, each MCP phase becomes an IAO iteration with full plan-report artifact discipline.

### Phase Mapping

| IAO Iteration | MCP Phase | Focus | Duration | Laptop-Safe |
|---|---|---|---|---|
| v8.17 | 1 — Discovery | Scrape 4 reference restaurant finder sites for UX patterns | 30-45 min | ✅ |
| v8.18 | 2 — Synthesis | Design tokens, component patterns, data-to-UI mapping | 30-45 min | ✅ |
| v8.19 | 3a — Implementation (core) | Scaffold, routing, search, sample data provider | 60-90 min | ✅ |
| v8.20 | 3b — Implementation (map + geo) | Map view, geolocation, "diners near you", trivia | 60-90 min | ✅ |
| v8.21 | 4 — QA | Playwright visual review, Lighthouse, mobile testing | 30-45 min | ✅ |
| v8.22 | Firestore wiring | Swap sample JSON for Firestore, deploy to tripleDB.com | 30-45 min | After data ✅ |

Every iteration from v8.17 through v8.21 runs against `assets/data/sample_restaurants.jsonl` — 50 real restaurant records from the pipeline. No Firestore dependency until v8.22, which only happens after Group B production data is loaded.

### Artifact Spec (Same as Pipeline)

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `docs/ddd-design-v{P}.{I}.md` | Claude | App architecture, IAO+MCP methodology |
| Input | `docs/ddd-plan-v{P}.{I}.md` | Claude | Phase-specific execution steps |
| Output | `docs/ddd-build-v{P}.{I}.md` | Gemini | Session transcript |
| Output | `docs/ddd-report-v{P}.{I}.md` | Gemini | Metrics, findings, recommendation |

### GEMINI.md Location

The app has its own `app/GEMINI.md` (distinct from `pipeline/GEMINI.md`). Gemini launches from `app/` for Flutter iterations:

```bash
cd ~/Development/Projects/tripledb/app
gemini
```

### Agent Restrictions (Inherited from Pipeline)

```
1. NEVER run git, flutter deploy, or firebase deploy commands.
2. NEVER ask permission or "should I proceed?" — the plan IS the permission.
3. Self-heal errors: diagnose → fix → re-run (max 3 attempts, then log and skip).
4. MCP server usage is phase-restricted (see MCP Rules below).
5. All work is in app/ — do NOT modify pipeline/ code.
```

### MCP Rules

| Server | Phases Allowed | Purpose |
|--------|---------------|---------|
| Firecrawl | v8.17 (Discovery) ONLY | Scrape reference site branding and UX patterns |
| Playwright | v8.17 (Discovery) + v8.21 (QA) ONLY | Screenshots for analysis and visual QA |
| Context7 | Any phase | Flutter, Dart, Riverpod, GoRouter, Firestore API docs |
| Lighthouse | v8.21 (QA) ONLY | Performance, accessibility, SEO audits |

---

# Part 2: tripleDB.com — App Architecture

## What It Is

A restaurant finder powered by 805 DDD episodes. Google-style search across every dimension (dish, cuisine, city, chef, ingredient). Geolocation-aware ("top 3 diners near you"). Map view. Fun trivia. Deep links to the exact YouTube timestamp where Guy walks in.

**Domain:** tripleDB.com
**Stack:** Flutter Web + Dart → Firebase Hosting
**Data:** Cloud Firestore (restaurants + videos collections)
**Dev data:** `assets/data/sample_restaurants.jsonl` (50 records for local development)

## Core UX

### 1. Search-First Home Screen

A clean, centered Google-style search bar. No clutter. The search bar is the hero:

```
┌──────────────────────────────────────────────────┐
│                                                  │
│              🍔 TripleDB                         │
│     Every diner from Diners, Drive-Ins & Dives   │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │ 🔍 Search dishes, diners, cities...      │    │
│  └──────────────────────────────────────────┘    │
│                                                  │
│     🎲 Did you know? Guy has visited 47 states   │
│        and said "Flavortown" 312 times!          │
│                                                  │
│  ┌─ 📍 Top 3 Near You ──────────────────────┐   │
│  │  🍕 Joe's Pizza (2.1 mi) ★ 4.7           │   │
│  │  🌮 Taco Loco (3.4 mi) ★ 4.5             │   │
│  │  🍔 Burger Joint (5.2 mi) ★ 4.8          │   │
│  └───────────────────────────────────────────┘   │
│                                                  │
│  [🗺️ View Map]                                  │
│                                                  │
└──────────────────────────────────────────────────┘
```

### 2. Search Results

Instant-filter as you type (debounced 300ms). Results are restaurant cards showing name, city/state, cuisine, top dish, rating, and a "Watch Guy's Visit" button:

```
┌──────────────────────────────────────────────────┐
│  🔍 "brisket"                              ✕    │
├──────────────────────────────────────────────────┤
│  327 results across 218 restaurants              │
│                                                  │
│  ┌─────────────────────────────────────────────┐ │
│  │ Desert Oak Barbecue         El Paso, TX     │ │
│  │ Barbecue · Rich Funk & Suzanne              │ │
│  │ 🥩 Smoked Brisket, Loaded Potato            │ │
│  │ ⭐ 4.6  ·  5 DDD appearances                │ │
│  │ [▶ Watch Guy's Visit]  [📍 Directions]      │ │
│  └─────────────────────────────────────────────┘ │
│                                                  │
│  ┌─────────────────────────────────────────────┐ │
│  │ Fox Brothers Barbecue       Atlanta, GA     │ │
│  │ ...                                         │ │
└──────────────────────────────────────────────────┘
```

### 3. Restaurant Detail Page

Full detail with all visits, all dishes, YouTube deep links:

```
┌──────────────────────────────────────────────────┐
│  ← Back                                         │
│                                                  │
│  Desert Oak Barbecue                             │
│  El Paso, TX · Barbecue · ⭐ 4.6                │
│  Chef: Rich Funk & Suzanne                      │
│  🟢 Still Open                                  │
│                                                  │
│  ── Dishes ──────────────────────────────────    │
│  🥩 Smoked Brisket                              │
│     "Brined for 14 hours, oak-smoked..."        │
│     Guy: "That is OUT OF BOUNDS!"                │
│     [▶ 66:23] Watch this moment                  │
│                                                  │
│  🥔 Loaded Baked Potato                          │
│     "Topped with pulled pork and queso..."       │
│     Guy: "Winner winner chicken dinner!"         │
│     [▶ 71:45] Watch this moment                  │
│                                                  │
│  ── DDD Appearances (5) ────────────────────     │
│  📺 Top 10 BBQ Brisket Videos  [▶ 19:20]        │
│  📺 Top 30 BBQ Videos          [▶ 66:10]        │
│  📺 Top 10 Potato Videos       [▶ 24:34]        │
│  📺 Top 30 Videos of ALL TIME  [▶ 48:12]        │
│  📺 Best of El Paso            [▶ 12:00]        │
│                                                  │
│  [📍 Directions] [🌐 Website]                   │
│                                                  │
└──────────────────────────────────────────────────┘
```

### 4. Map View

All restaurants plotted. Cluster markers at zoom-out. Tap a marker to see the restaurant card. Filter by cuisine, state, or search query:

```
┌──────────────────────────────────────────────────┐
│  🔍 Filter map...                          🗺️   │
├──────────────────────────────────────────────────┤
│                                                  │
│     ·  ·        · ·                              │
│   ·    ·    ·       ·  ·                         │
│  (12)    ·    (8)     ·    ·                     │
│       ·    ·        ·                            │
│     ·        ·  ·       (5)                      │
│          ·        ·                              │
│                                                  │
│  ┌── 📍 Desert Oak Barbecue ──────────────┐     │
│  │ El Paso, TX · BBQ · ⭐ 4.6 · 5 visits  │     │
│  │ [Detail] [▶ Watch] [Directions]         │     │
│  └─────────────────────────────────────────┘     │
│                                                  │
└──────────────────────────────────────────────────┘
```

### 5. Rotating Trivia

A fun-fact widget that cycles through pre-computed stats. Computable from the normalized JSONL:

- "Guy has visited **608** restaurants across **47** states"
- "The most-featured restaurant is **Pizzeria Lola** with 7 appearances"
- "**California** leads with 88 diners — that's 14% of all DDD locations"
- "There are **1,015** unique dishes in the database"
- "**Barbecue** is the most common cuisine type"
- "Guy said 'Out of Bounds' in **23** different restaurants"

These are computed once during Firestore load and stored as a `trivia` collection, or computed client-side from the restaurant data.

## Data Architecture

### Development Mode (v8.17–v8.21)

```
assets/data/sample_restaurants.jsonl  →  RestaurantProvider (JSON)
                                             ↓
                                         Flutter UI
```

Load 50 real restaurant records from a local JSONL asset. No network dependency. Works offline, on planes, anywhere.

### Production Mode (v8.22+)

```
Cloud Firestore (restaurants collection)  →  RestaurantProvider (Firestore)
                                                  ↓
                                              Flutter UI
```

Swap the data provider from local JSON to Firestore. The UI doesn't change — only the provider implementation.

### Provider Architecture (Riverpod 3.0)

```
restaurantProvider        → AsyncNotifier, loads all restaurants
searchQueryProvider       → Notifier<String>, debounced 300ms
searchResultsProvider     → computed, filters restaurants by query
nearbyProvider            → computed, sorts by distance from user location
selectedRestaurantProvider → Notifier, drives detail page
triviaProvider            → Notifier, rotating fun facts
locationProvider          → AsyncNotifier, browser geolocation API
mapMarkersProvider        → computed, transforms restaurants to map pins
```

### Search Fields

The search bar queries across ALL of these fields simultaneously:

| Field | Example Match |
|-------|--------------|
| `name` | "Desert Oak" → Desert Oak Barbecue |
| `city` | "Memphis" → all Memphis restaurants |
| `state` | "TX" or "Texas" → all Texas restaurants |
| `cuisine_type` | "barbecue" or "BBQ" → all BBQ joints |
| `owner_chef` | "Guy" → (probably not useful) / "Rich Funk" |
| `dishes[].dish_name` | "brisket" → any restaurant with a brisket dish |
| `dishes[].ingredients[]` | "buttermilk" → dishes using buttermilk |
| `dishes[].guy_response` | "out of bounds" → restaurants where Guy said it |

### Routing (GoRouter)

| Route | Page |
|-------|------|
| `/` | Home (search + nearby + trivia) |
| `/search?q=brisket` | Search results |
| `/restaurant/:id` | Restaurant detail |
| `/map` | Map view |
| `/map?cuisine=barbecue` | Filtered map |

## Tech Stack

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management (Notifier/AsyncNotifier) |
| `go_router` | Deep-linking and navigation |
| `google_fonts` | Typography (clean, readable food UI) |
| `google_maps_flutter` or `flutter_map` | Map widget |
| `geolocator` | Browser geolocation API |
| `geoflutterfire_plus` | Firestore proximity queries (v8.22) |
| `url_launcher` | YouTube deep links, Google Maps directions |
| `cached_network_image` | Restaurant photos (Phase 6 enrichment) |

## Reference Sites for Phase 1 Discovery

| Site | URL | What to Extract |
|------|-----|-----------------|
| DDD Locations | `https://dinersdriveinsdiveslocations.com` | Search/filter UX, state browsing, restaurant cards |
| Flavortown USA | `https://flavortownusa.com` | Directory layout, "most visited" patterns, mobile nav |
| Food Network DDD | `https://www.foodnetwork.com/shows/diners-drive-ins-and-dives` | Official branding, color palette, typography, episode cards |
| TV Food Maps | `https://www.tvfoodmaps.com` | Map integration, road trip builder, filter by show/cuisine |

## Widget Tree

```
MaterialApp.router
└── GoRouter
    ├── HomePage
    │   ├── AppBar (TripleDB logo + theme toggle)
    │   ├── SearchBar (Google-style, centered, hero element)
    │   ├── TriviaCard (rotating fun facts, auto-cycle 8s)
    │   ├── NearbySection
    │   │   ├── NearbyHeader ("Top 3 Near You" + location status)
    │   │   └── RestaurantCardList (3 nearest, compact)
    │   └── MapButton ("View All on Map")
    │
    ├── SearchResultsPage
    │   ├── SearchBar (persistent, pre-filled with query)
    │   ├── ResultCount ("327 results across 218 restaurants")
    │   └── RestaurantCardList (full results, scrollable)
    │
    ├── RestaurantDetailPage
    │   ├── RestaurantHeader (name, city, state, cuisine, rating, status)
    │   ├── DishList
    │   │   └── DishCard (name, description, ingredients, guy_response, YouTube link)
    │   ├── VisitList
    │   │   └── VisitCard (video title, timestamp link)
    │   └── ActionBar (Directions, Website)
    │
    └── MapPage
        ├── SearchBar (filter pins by query)
        ├── MapWidget (clustered markers)
        └── RestaurantPreviewCard (tap marker → bottom sheet)
```

## File Structure

```
app/
├── docs/
│   ├── ddd-design-v8.17.md          ← This file
│   └── ddd-plan-v8.17.md            ← Discovery phase plan
├── design-brief/
│   ├── scrapes/                     ← Phase 1: Firecrawl + Playwright captures
│   │   ├── ddd-locations/
│   │   ├── flavortown-usa/
│   │   ├── food-network-ddd/
│   │   └── tv-food-maps/
│   ├── ux-analysis.md               ← Phase 1: UX pattern comparison
│   ├── design-brief.md              ← Phase 2: Creative direction
│   ├── design-tokens.json           ← Phase 2: Flutter ThemeData tokens
│   └── component-patterns.md        ← Phase 2: Widget composition blueprints
├── assets/
│   ├── data/
│   │   └── sample_restaurants.jsonl  ← 50 real records for dev
│   ├── logos/
│   └── images/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── restaurant_models.dart    ← Restaurant, Dish, Visit data classes
│   ├── providers/
│   │   ├── restaurant_providers.dart ← Core data + search + filter
│   │   ├── location_providers.dart   ← Geolocation + nearby
│   │   ├── trivia_providers.dart     ← Rotating fun facts
│   │   └── router_provider.dart      ← GoRouter config
│   ├── services/
│   │   ├── data_service.dart         ← JSON loader (dev) / Firestore (prod)
│   │   └── location_service.dart     ← Browser geolocation wrapper
│   ├── theme/
│   │   └── app_theme.dart            ← Light + dark themes from design tokens
│   ├── utils/
│   │   ├── breakpoints.dart          ← Responsive column counts
│   │   └── search_utils.dart         ← Multi-field fuzzy search logic
│   ├── pages/
│   │   ├── home_page.dart
│   │   ├── search_results_page.dart
│   │   ├── restaurant_detail_page.dart
│   │   └── map_page.dart
│   └── widgets/
│       ├── search/
│       │   └── search_bar.dart       ← Google-style search widget
│       ├── restaurant/
│       │   ├── restaurant_card.dart  ← Compact card for lists
│       │   ├── dish_card.dart        ← Dish with YouTube timestamp link
│       │   └── visit_card.dart       ← Video appearance with play button
│       ├── map/
│       │   ├── restaurant_map.dart   ← Map widget with clustered markers
│       │   └── map_preview_card.dart ← Bottom sheet on marker tap
│       └── trivia/
│           └── trivia_card.dart      ← Rotating fun fact widget
├── GEMINI.md
├── pubspec.yaml
└── firebase.json
```

## YouTube Deep Link Format

Each dish and visit has a `timestamp_start` in seconds. Convert to a YouTube URL with timestamp:

```
https://youtube.com/watch?v={video_id}&t={floor(timestamp_start)}
```

Example: `https://youtube.com/watch?v=Q2fk6b-hEbc&t=215` opens at 3:35.

Use `url_launcher` to open in the user's browser/YouTube app.

## Trivia Data Source

Trivia facts are pre-computed from the normalized dataset. Either:
- Computed at build time and embedded as a JSON asset
- Computed client-side on first load from the restaurant data
- Stored as a small `trivia` Firestore collection

Examples that are computable from the current data:
- Total restaurants, dishes, states, videos
- Most-featured restaurant (by visit count)
- State with most diners
- Most common cuisine type
- Most common ingredient
- Average dishes per restaurant
- Restaurants with 5+ DDD appearances
