# TripleDB — Design v9.35

---

# Part 1: IAO — Iterative Agentic Orchestration

## Executor Change: Gemini CLI → Claude Code

Starting v9.35, the executing agent switches from Gemini CLI to Claude Code. The IAO methodology is unchanged — four artifacts per iteration, zero-intervention target, self-healing, checkpointing. The execution model adapts:

| Aspect | Gemini CLI (v0.7–v7.34) | Claude Code (v9.35+) |
|--------|------------------------|---------------------|
| Version lock | `GEMINI.md` | `CLAUDE.md` |
| Launch | `cd pipeline && gemini` | `cd ~/dev/projects/tripledb && claude` |
| Prompt | "Read GEMINI.md and execute" | "Read CLAUDE.md and execute" |
| File access | Shell commands only | Direct file read/write + shell |
| MCP support | Context7 only | Full MCP ecosystem |
| Working dir | `pipeline/` (restricted) | Full project root (unrestricted) |

### CLAUDE.md Spec

Located at project root (`~/dev/projects/tripledb/CLAUDE.md`). Same role as GEMINI.md — the version lock that points to current design + plan docs.

```markdown
# TripleDB — Agent Instructions

## Current Iteration: 9.35

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v9.35.md
2. docs/ddd-plan-v9.35.md

## Rules That Never Change
- NEVER run git add, git commit, git push, or firebase deploy
- NEVER ask permission — auto-proceed on EVERY step
- Self-heal: diagnose → fix → re-run (max 3, then skip)
- 3 consecutive identical errors = STOP
- MUST produce ddd-build and ddd-report before ending
- CHECKPOINT after every numbered step
- NEVER overwrite the restaurant `name` field
```

## The Eight Pillars (Summary)

1. Plan-Report Loop — 2. Zero-Intervention Target — 3. Self-Healing — 4. Versioned Artifacts — 5. Artifacts Travel Forward — 6. Methodology Co-Evolution — 7. Interactive vs Unattended — 8. Graduated Batches

## IAO Iteration History

| Iteration | Phase | Interventions | Executor | Key Learning |
|-----------|-------|---------------|----------|--------------|
| v0.7–v4.13 | 0-4 | 0–20+ | Gemini | Pipeline → zero interventions by v3.12 |
| v5.14–v5.15 | 5 | **0** | Gemini | 773 videos, 14-hour unattended run |
| v6.26–v6.29 | 6 | **0** | Gemini | 1,102 loaded, 916 geocoded, polished |
| v8.17–v8.25 | 8 | **0** | Gemini | tripledb.net live |
| v7.30–v7.34 | 7 | **1** | Gemini | Enrichment complete: 582 verified, cookies, analytics |
| v9.35 | 9 | target: **0** | **Claude Code** | First Claude Code iteration |

## Artifact Spec

| Direction | File | Author | Purpose |
|-----------|------|--------|---------|
| Input | `ddd-design-v{P}.{I}.md` | Claude (chat) | Living architecture |
| Input | `ddd-plan-v{P}.{I}.md` | Claude (chat) | Execution steps |
| Output | `ddd-build-v{P}.{I}.md` | Claude Code | Full session transcript |
| Output | `ddd-report-v{P}.{I}.md` | Claude Code | Metrics, recommendation |
| Output | `README.md` (updated) | Claude Code | All standard sections |

## Agent Restrictions

```
1. Git READ allowed. Git WRITE and firebase deploy FORBIDDEN.
2. flutter build web and flutter run ARE ALLOWED.
3. NEVER ask permission — auto-proceed on EVERY step.
4. Self-heal: diagnose → fix → re-run (max 3, then skip).
5. 3 consecutive identical errors = STOP.
6. FULL PROJECT ACCESS: read/write ANYWHERE under ~/dev/projects/tripledb/.
7. MUST produce ddd-build and ddd-report before ending.
8. CHECKPOINT after every numbered step → pipeline/data/checkpoints/.
9. Build log is MANDATORY — full transcript.
10. README at PROJECT ROOT: ~/dev/projects/tripledb/README.md.
```

## Checkpoint Protocol

Same as v7.33+:
```
pipeline/data/checkpoints/v9.35_checkpoint.json
```
Write after each step. Read on start for resume. Delete on completion.

---

# Part 2: ADR-001 — TripleDB

## Phase Status

| Phase | Name | Status | Iterations |
|-------|------|--------|------------|
| 0-4 | Pipeline Refinement | ✅ Complete | v0.7–v4.13 |
| 5 | Production Run | ✅ Complete | v5.14–v5.15 |
| 6 | Firestore + Geocoding + Polish | ✅ Complete | v6.26–v6.29 |
| 8 | Flutter App | ✅ Complete | v8.17–v8.25 |
| 7 | Enrichment + Analytics | ✅ Complete | v7.30–v7.34 |
| 9 | App Optimization | 🔧 Current | v9.35 |

## v9.35 Scope — Three Deliverables

### Deliverable 1: Riverpod 2.x → 3.x Migration

**Why:** Riverpod 2.x is now legacy. 3.x brings auto-retry, unified Ref API, better lifecycle management, and is required for long-term Flutter compatibility.

**Breaking changes to handle (from official migration guide):**

| Change | Migration |
|--------|-----------|
| `valueOrNull` removed | Replace with `.value` |
| `StateProvider` → legacy | Move to `flutter_riverpod/legacy.dart` import OR migrate to `NotifierProvider` |
| `StateNotifierProvider` → legacy | Same — legacy import or migrate to `Notifier` |
| `ChangeNotifierProvider` → legacy | Same |
| Ref subclasses removed | Use `Ref` directly instead of `FutureProviderRef` etc. |
| `==` for update filtering | All providers now use `==` not `identical` |
| Auto-retry on failing providers | Disable globally if unwanted: `ProviderScope(retry: (_, __) => null)` |
| Notifiers recreated on rebuild | May affect providers holding mutable state |

**Migration strategy:**

1. **Phase 1 — Update deps:** Bump `flutter_riverpod` to `^3.0.0` in `pubspec.yaml`.
2. **Phase 2 — Legacy imports:** Add `import 'package:flutter_riverpod/legacy.dart'` wherever `StateProvider` or `StateNotifierProvider` is used. This makes existing code compile immediately.
3. **Phase 3 — Migrate providers:** Convert `StateProvider` → `NotifierProvider` and `StateNotifierProvider` → `Notifier` pattern. This is the main work.
4. **Phase 4 — Clean up:** Remove legacy imports, fix `valueOrNull` → `value`, disable auto-retry if not wanted.

**Files to migrate (from v7.34 app structure):**
- `lib/providers/restaurant_providers.dart`
- `lib/providers/location_providers.dart`
- `lib/providers/trivia_providers.dart`
- `lib/providers/router_provider.dart`
- `lib/providers/cookie_provider.dart`
- Any widget using `ref.watch(someStateProvider.notifier)`

**Geolocator upgrade:** Bump `geolocator` from 10.x to latest compatible version (was downgraded in v6.27 for compat). Verify with `flutter pub get` that it resolves. If latest geolocator conflicts with other deps, find the highest compatible version.

### Deliverable 2: Trivia Expansion + No-Repeat System

**Current state:** ~12-15 trivia facts, cycling on an 8-second timer. Users see repeats quickly.

**Target:** 60-80+ trivia facts with no repeats until the full set is exhausted.

**Trivia categories:**

| Category | Source | Examples | Est. count |
|----------|--------|---------|------------|
| Dataset stats | Computed from Firestore | "1,102 restaurants in 62 states" | 10-12 |
| State records | Computed | "California has the most DDD restaurants (X)" | 10-15 |
| Restaurant superlatives | Computed | "Full Belly Deli has 16 visits — the most of any restaurant" | 8-10 |
| Dish facts | Computed | "The most common dish ingredient is cheese" | 8-10 |
| Enrichment facts | Computed | "X restaurants have been renamed since filming" | 5-8 |
| Guy Fieri fun facts | Hardcoded (curated) | "Guy's real first name is Guy Ramsay Fieri" | 10-15 |
| Show facts | Hardcoded (curated) | "DDD has been on the air since 2006" | 5-8 |

**No-repeat mechanism:**

```dart
class TriviaState {
  final List<String> allFacts;     // Full pool (shuffled on first load)
  final int currentIndex;           // Pointer into shuffled list
  final Set<int> seenIndices;       // Track what's been shown this session

  String get currentFact => allFacts[currentIndex];

  TriviaState advance() {
    int next = (currentIndex + 1) % allFacts.length;
    // If we've cycled through all, reshuffle
    if (next == 0) {
      return TriviaState(
        allFacts: allFacts..shuffle(),
        currentIndex: 0,
        seenIndices: {},
      );
    }
    return copyWith(currentIndex: next, seenIndices: {...seenIndices, next});
  }
}
```

The shuffle happens once on app load. The timer advances the pointer. When the pointer wraps around to 0, the list reshuffles so the next cycle is in a different order. Users see every fact exactly once before any repeats.

**Dynamic fact generation:** Most facts should be computed from the actual Firestore data at load time, not hardcoded. This means the trivia provider fetches restaurants and derives facts programmatically:

```dart
List<String> generateFacts(List<Restaurant> restaurants) {
  final facts = <String>[];

  // Total count
  facts.add('Triple D has featured ${restaurants.length} restaurants!');

  // State counts
  final stateCounts = groupBy(restaurants, (r) => r.state);
  final topState = stateCounts.entries.maxBy((e) => e.value.length);
  facts.add('${topState.key} leads with ${topState.value.length} DDD restaurants');

  // Most visited
  final mostVisited = restaurants.maxBy((r) => r.visits.length);
  facts.add('${mostVisited.name} has been visited ${mostVisited.visits.length} times — the most of any restaurant!');

  // Cuisine breakdown
  // Dish stats
  // Closed restaurants
  // Name changes
  // Rating stats
  // ... etc

  // Add curated fun facts
  facts.addAll(curatedGuyFacts);
  facts.addAll(curatedShowFacts);

  facts.shuffle();
  return facts;
}
```

### Deliverable 3: Proximity Query Refactor

**Problem:** Kyle's zip 92692 (Mission Viejo, CA) should return many nearby DDD restaurants — Southern California is DDD-dense. But "Top 3 Near You" only shows 3, and the broader results may not be sorted by proximity.

**Root causes to investigate and fix:**

1. **"Top 3" is literally 3.** Expand to "Nearby Restaurants" showing 10-15, with a "Show more" option.

2. **Distance calculation may be wrong or filtering too aggressively.** The current `nearbyRestaurants` provider likely:
   - Gets user location via geolocator
   - Computes haversine distance to each restaurant
   - Sorts by distance
   - Takes top N
   
   If the location service returns inaccurate coords (WARP VPN, browser geolocation denial), or if there's a radius cutoff, results will be sparse.

3. **Firestore query isn't proximity-aware.** Firestore loads ALL 1,102 restaurants then filters client-side. This is fine for 1,102 docs but the sorting/filtering needs to be correct.

4. **Closed restaurants excluded from "Near You."** Correct (from v7.33), but verify the count after exclusion.

**Fixes:**

**3a. Expand "Top 3 Near You" to "Nearby Restaurants":**
- Show 10-15 by default (not 3)
- Add "Show all nearby" that expands to 25+
- Show distance on each card (e.g., "2.3 mi away")
- Sort strictly by distance ascending

**3b. Distance display:**
- Show in miles (not km) for US users
- Format: "0.5 mi" / "2.3 mi" / "15 mi" / "120+ mi"
- If user hasn't granted location, show "Enable location to see nearby restaurants" instead of empty section

**3c. Location accuracy:**
- Log the actual coords returned by geolocator for debugging
- 92692 (Mission Viejo) should resolve to approximately 33.60°N, 117.65°W
- If coords are wildly off, the geolocator upgrade (Deliverable 1) may fix it

**3d. Search results sorting:**
- When user searches, results should be sorted by relevance first, then by distance as tiebreaker
- If user searches "BBQ" from Mission Viejo, CA BBQ spots should appear before Tennessee BBQ spots

## Current App Architecture (files to modify)

```
app/lib/
├── main.dart                           ← ProviderScope, Firebase init
├── models/restaurant_models.dart       ← Restaurant model
├── providers/
│   ├── restaurant_providers.dart       ← Main data + search + nearby
│   ├── location_providers.dart         ← Geolocation
│   ├── trivia_providers.dart           ← Trivia facts + timer
│   ├── cookie_provider.dart            ← Cookie consent
│   └── router_provider.dart            ← GoRouter
├── services/
│   ├── data_service.dart               ← Firestore queries
│   ├── location_service.dart           ← Geolocator wrapper
│   ├── analytics_service.dart          ← Firebase Analytics
│   └── cookie_consent_service.dart     ← Cookie read/write
├── theme/app_theme.dart
├── pages/
│   ├── home_page.dart                  ← List tab + "Near You" + search
│   ├── map_page.dart                   ← Map + pins + clustering + filter
│   ├── explore_page.dart               ← Stats + enrichment info
│   ├── search_results_page.dart
│   └── restaurant_detail_page.dart
└── widgets/
    ├── search/search_bar_widget.dart
    ├── restaurant/restaurant_card.dart
    ├── restaurant/dish_card.dart
    ├── restaurant/visit_card.dart
    ├── trivia/trivia_card.dart
    └── cookie_consent_banner.dart
```

## Tech Stack Changes (v9.35)

| Package | Before | After | Notes |
|---------|--------|-------|-------|
| `flutter_riverpod` | 2.x | 3.x | Major migration |
| `geolocator` | 10.x | Latest compat | Was downgraded in v6.27 |
| `collection` | (may need) | ^1.18+ | For `groupBy` in trivia generation |

## Known Gotchas

1. **Riverpod 3 auto-retry:** Disable globally with `ProviderScope(retry: (_, __) => null)` unless you specifically want retry on Firestore providers.
2. **`valueOrNull` → `value`:** Global search-and-replace.
3. **StateProvider migration:** Can use legacy import as intermediate step. Full migration to `Notifier` is cleaner.
4. **Geolocator permissions:** Flutter Web uses browser Geolocation API. User must grant permission. If denied, handle gracefully.
5. **Trivia shuffle:** Use `List.shuffle()` with no seed for true randomness per session.
6. **Distance calc:** Haversine formula. Earth radius = 3,958.8 miles (for US display).
7. **dart:html:** Cookie service uses this — web-only. Conditional import if needed.
8. **Build log MANDATORY.** Full transcript.
9. **README at PROJECT ROOT.**
10. **Checkpoint after every step.**

## CLAUDE.md Template

```markdown
# TripleDB — Agent Instructions

## Current Iteration: 9.35

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v9.35.md — Architecture, Riverpod migration, trivia spec, proximity fix
2. docs/ddd-plan-v9.35.md — Execution steps

## Rules That Never Change
- NEVER run git add, git commit, git push, or firebase deploy
- NEVER ask permission — auto-proceed on EVERY step
- Self-heal: diagnose → fix → re-run (max 3, then skip)
- 3 consecutive identical errors = STOP
- MUST produce ddd-build-v9.35.md AND ddd-report-v9.35.md before ending
- ddd-build must be FULL transcript
- CHECKPOINT after every numbered step
- README.md is at project root
```
