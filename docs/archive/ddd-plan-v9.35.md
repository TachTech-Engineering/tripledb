# TripleDB — Phase 9 Plan v9.35

**Phase:** 9 — App Optimization
**Iteration:** 35 (global)
**Executor:** Claude Code (first iteration with new executor)
**Date:** March 2026
**Goal:** Migrate Riverpod 2.x → 3.x, upgrade geolocator, build 60-80+ trivia facts with no-repeat logic, refactor proximity queries so 92692 (Mission Viejo, CA) sees 10-15+ nearby restaurants.

---

## Read Order

```
1. docs/ddd-design-v9.35.md — Architecture, Riverpod 3 migration spec, trivia design, proximity fix
2. docs/ddd-plan-v9.35.md — This file. Execution steps.
```

Read both fully before executing. Log confirmation in build log.

---

## Autonomy Rules

```
1. AUTO-PROCEED between ALL steps. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3, then skip).
3. SYSTEMIC FAILURE: 3 consecutive identical errors = STOP.
4. Git READ allowed. Git WRITE and firebase deploy FORBIDDEN.
5. flutter build web and flutter run ARE ALLOWED.
6. FULL PROJECT ACCESS: read/write ANYWHERE under ~/dev/projects/tripledb/.
7. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v9.35.md — FULL transcript
   b. docs/ddd-report-v9.35.md — metrics, recommendation
   c. README.md — COMPREHENSIVE update at PROJECT ROOT
8. CHECKPOINT after every numbered step → pipeline/data/checkpoints/v9.35_checkpoint.json
```

---

## Step 0: Pre-Flight + Checkpoint Setup

```bash
cd ~/dev/projects/tripledb

# Verify project structure
ls app/lib/providers/ app/lib/services/ app/lib/pages/ app/lib/widgets/
cat app/pubspec.yaml | grep -E "riverpod|geolocator|firebase"

# Current Riverpod version
grep "flutter_riverpod" app/pubspec.yaml

# Current geolocator version
grep "geolocator" app/pubspec.yaml

# Verify Flutter SDK
cd app && flutter --version

# Baseline: does the app build cleanly right now?
flutter analyze
flutter build web
```

Log all output. The baseline build MUST pass before any changes.

Initialize checkpoint:
```bash
mkdir -p ~/dev/projects/tripledb/pipeline/data/checkpoints
```

Check for existing checkpoint (crash recovery). If checkpoint exists with `last_completed_step >= N`, skip to Step N+1.

**Write checkpoint after Step 0.**

---

## Step 1: Riverpod 2.x → 3.x Migration

This is the highest-risk step. Approach systematically.

### 1a. Read current provider files

Before changing anything, read every provider file to understand the current patterns:

```
app/lib/providers/restaurant_providers.dart
app/lib/providers/location_providers.dart
app/lib/providers/trivia_providers.dart
app/lib/providers/cookie_provider.dart
app/lib/providers/router_provider.dart
```

Catalog which provider types are used:
- `StateProvider` → needs migration to `NotifierProvider`
- `StateNotifierProvider` → needs migration to `Notifier`
- `FutureProvider` → stays (but check for `valueOrNull`)
- `Provider` → stays
- `StreamProvider` → stays

### 1b. Update pubspec.yaml

```yaml
dependencies:
  flutter_riverpod: ^3.0.0
  # If hooks_riverpod is used:
  # hooks_riverpod: ^3.0.0
```

Do NOT change other deps yet. Run:
```bash
cd ~/dev/projects/tripledb/app
flutter pub get
```

If resolution fails, check which deps conflict and pin compatible versions.

### 1c. Immediate fixes (make it compile)

These are mechanical search-and-replace changes:

1. **`valueOrNull` → `value`:** Global find-and-replace across all `.dart` files.
2. **Legacy imports:** For any file using `StateProvider`, `StateNotifierProvider`, or `ChangeNotifierProvider`, add:
   ```dart
   import 'package:flutter_riverpod/legacy.dart';
   ```
3. **Ref subclass removal:** Replace `FutureProviderRef` → `Ref`, `AutoDisposeRef` → `Ref`, etc.

Run `flutter analyze` after each change to check progress.

### 1d. Migrate StateProvider to NotifierProvider

For each `StateProvider`, create a `Notifier` class:

```dart
// BEFORE (Riverpod 2.x):
final showClosedProvider = StateProvider<bool>((ref) => true);
// Usage: ref.read(showClosedProvider.notifier).state = false;

// AFTER (Riverpod 3.x):
class ShowClosedNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}
final showClosedProvider = NotifierProvider<ShowClosedNotifier, bool>(
  ShowClosedNotifier.new,
);
// Usage: ref.read(showClosedProvider.notifier).toggle();
```

Apply this pattern to every `StateProvider` in the codebase. Common ones to look for:
- `showClosedProvider` (map filter)
- Search term state
- Dark mode toggle
- Any other simple state holders

### 1e. Migrate StateNotifierProvider to Notifier

For more complex state notifiers:

```dart
// BEFORE (Riverpod 2.x):
class SomeNotifier extends StateNotifier<SomeState> {
  SomeNotifier() : super(SomeState.initial());
  void doSomething() { state = state.copyWith(...); }
}
final someProvider = StateNotifierProvider<SomeNotifier, SomeState>((ref) => SomeNotifier());

// AFTER (Riverpod 3.x):
class SomeNotifier extends Notifier<SomeState> {
  @override
  SomeState build() => SomeState.initial();
  void doSomething() { state = state.copyWith(...); }
}
final someProvider = NotifierProvider<SomeNotifier, SomeState>(SomeNotifier.new);
```

### 1f. Disable auto-retry (optional but recommended)

In `main.dart`, wrap the app with:
```dart
ProviderScope(
  retry: (_, __) => null,  // Disable auto-retry for now
  child: MyApp(),
)
```

This prevents Riverpod 3's new auto-retry from unexpectedly retrying Firestore calls.

### 1g. Verify migration

```bash
cd ~/dev/projects/tripledb/app
flutter analyze    # Must be 0 errors
flutter build web  # Must succeed
```

If errors remain, fix them iteratively. Common issues:
- `.notifier.state = X` → use the notifier's method instead
- `ref.watch(provider.notifier)` patterns may need adjustment
- `AsyncValue` usage changes (`.value` instead of `.valueOrNull`)

### 1h. Upgrade geolocator

```bash
cd ~/dev/projects/tripledb/app
```

Check latest compatible version:
```bash
flutter pub outdated | grep geolocator
```

Update `pubspec.yaml` to the latest compatible version. If the latest (e.g., 13.x) conflicts, find the highest version that resolves cleanly.

```bash
flutter pub get
flutter analyze
```

If the API changed between 10.x and the new version, update `location_service.dart` accordingly. Common changes:
- Permission request API may differ
- `getCurrentPosition()` parameters may change
- `LocationSettings` class may be restructured

**Write checkpoint after Step 1.**

---

## Step 2: Trivia Expansion + No-Repeat System

### 2a. Read current trivia implementation

Read `app/lib/providers/trivia_providers.dart` to understand:
- How facts are generated
- How the timer works
- How facts rotate

### 2b. Build the trivia fact generator

Create or rewrite the trivia provider to generate 60-80+ facts dynamically from the restaurant dataset. The facts should be computed at load time, not hardcoded.

**Dynamic facts to generate (from Firestore data):**

```dart
List<String> generateDynamicFacts(List<Restaurant> restaurants) {
  final facts = <String>[];
  final open = restaurants.where((r) => r.stillOpen != false).toList();
  final closed = restaurants.where((r) => r.stillOpen == false).toList();
  final enriched = restaurants.where((r) => r.googleRating != null).toList();
  final renamed = restaurants.where((r) => r.nameChanged).toList();

  // --- Dataset scope ---
  facts.add('Guy Fieri has visited ${restaurants.length} restaurants across America on Triple D!');
  final totalDishes = restaurants.fold(0, (sum, r) => sum + r.dishes.length);
  facts.add('The Triple D database has $totalDishes dishes — and counting!');
  final totalVisits = restaurants.fold(0, (sum, r) => sum + r.visits.length);
  facts.add('There have been $totalVisits restaurant segments across all DDD episodes');

  // --- State facts ---
  final byState = <String, List<Restaurant>>{};
  for (final r in restaurants) {
    if (r.state != null && r.state != 'UNKNOWN') {
      byState.putIfAbsent(r.state!, () => []).add(r);
    }
  }
  final sortedStates = byState.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));

  facts.add('${sortedStates[0].key} leads the pack with ${sortedStates[0].value.length} DDD restaurants!');
  facts.add('${sortedStates[1].key} comes in second with ${sortedStates[1].value.length} DDD spots');
  facts.add('${sortedStates[2].key} takes third place with ${sortedStates[2].value.length} restaurants');
  // Bottom states
  final smallestState = sortedStates.last;
  facts.add('${smallestState.key} has just ${smallestState.value.length} DDD restaurant — but it\'s a good one!');
  // Random mid-tier states
  for (int i = 5; i < sortedStates.length && i < 12; i++) {
    facts.add('${sortedStates[i].key} has ${sortedStates[i].value.length} restaurants featured on Triple D');
  }

  // --- Restaurant superlatives ---
  final byVisits = [...restaurants]..sort((a, b) => b.visits.length.compareTo(a.visits.length));
  facts.add('${byVisits[0].name} holds the record with ${byVisits[0].visits.length} DDD appearances!');
  facts.add('${byVisits[1].name} has been featured ${byVisits[1].visits.length} times on the show');
  facts.add('${byVisits[2].name} is a Triple D favorite with ${byVisits[2].visits.length} visits');

  // --- Rating facts (from enrichment) ---
  if (enriched.isNotEmpty) {
    final avgRating = enriched.fold(0.0, (sum, r) => sum + r.googleRating!) / enriched.length;
    facts.add('The average Google rating for a DDD restaurant is ${avgRating.toStringAsFixed(1)} stars ⭐');

    final topRated = [...enriched]..sort((a, b) => b.googleRating!.compareTo(a.googleRating!));
    facts.add('${topRated[0].name} has a stellar ${topRated[0].googleRating} rating on Google!');
    facts.add('${topRated[1].name} is rated ${topRated[1].googleRating} stars — Guy knows quality!');

    final mostReviewed = [...enriched]..sort((a, b) => (b.googleRatingCount ?? 0).compareTo(a.googleRatingCount ?? 0));
    facts.add('${mostReviewed[0].name} has ${mostReviewed[0].googleRatingCount} Google reviews!');
  }

  // --- Closed/renamed ---
  if (closed.isNotEmpty) {
    facts.add('${closed.length} DDD restaurants have permanently closed since filming');
    facts.add('${open.length} out of ${restaurants.length} DDD restaurants are still open today!');
  }
  if (renamed.isNotEmpty) {
    facts.add('${renamed.length} DDD restaurants have been renamed since their episode aired');
    // Pick a specific interesting rename
    final exampleRename = renamed.firstWhere(
      (r) => r.googleCurrentName != null && r.name != r.googleCurrentName,
      orElse: () => renamed.first,
    );
    facts.add('"${exampleRename.name}" is now known as "${exampleRename.googleCurrentName}"');
  }

  // --- Cuisine facts ---
  final cuisineCounts = <String, int>{};
  for (final r in restaurants) {
    if (r.cuisineType != null && r.cuisineType!.isNotEmpty) {
      for (final c in r.cuisineType!.split(',').map((s) => s.trim())) {
        cuisineCounts[c] = (cuisineCounts[c] ?? 0) + 1;
      }
    }
  }
  final topCuisines = cuisineCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  if (topCuisines.isNotEmpty) {
    facts.add('${topCuisines[0].key} is the most common cuisine on Triple D (${topCuisines[0].value} restaurants)');
    if (topCuisines.length > 1) {
      facts.add('${topCuisines[1].key} comes in at #2 with ${topCuisines[1].value} DDD spots');
    }
    if (topCuisines.length > 2) {
      facts.add('${topCuisines[2].key} rounds out the top 3 cuisines on the show');
    }
  }

  return facts;
}
```

**Curated fun facts (hardcoded):**

```dart
const curatedFacts = [
  'Guy Fieri\'s birth name is Guy Ramsay Ferry — he changed it to his grandfather\'s Italian surname',
  'Diners, Drive-Ins and Dives premiered on April 23, 2006',
  'The show is often nicknamed "Triple D" by fans',
  'Guy\'s iconic yellow Camaro is a 1968 Chevrolet Camaro SS convertible',
  'Guy Fieri has hosted over 400 episodes of Triple D',
  'The show films about 3 restaurants per episode',
  'Guy\'s catchphrase "Winner, winner, chicken dinner!" became a pop culture staple',
  'DDD restaurants span from Alaska to Puerto Rico',
  'The show has filmed in all 50 US states',
  'Guy Fieri raised over \$25 million for restaurant workers during the pandemic',
  'Before TV, Guy owned two restaurants in California: Johnny Garlic\'s and Tex Wasabi\'s',
  'Guy won Season 2 of "The Next Food Network Star" in 2006',
  'Triple D inspired thousands of food road trips across America',
  'Guy\'s signature look — frosted tips, backwards sunglasses, and flame shirts — is instantly recognizable',
  'Many DDD restaurants report a 300%+ sales increase after their episode airs',
];
```

### 2c. No-repeat rotation system

Replace the current trivia cycling with a shuffle-based system:

```dart
class TriviaNotifier extends Notifier<TriviaState> {
  Timer? _timer;

  @override
  TriviaState build() {
    final restaurants = ref.watch(allRestaurantsProvider).value ?? [];
    final dynamicFacts = generateDynamicFacts(restaurants);
    final allFacts = [...dynamicFacts, ...curatedFacts]..shuffle();

    // Start auto-advance timer
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(Duration(seconds: 8), (_) => advance());

    return TriviaState(facts: allFacts, currentIndex: 0);
  }

  void advance() {
    final next = (state.currentIndex + 1) % state.facts.length;
    if (next == 0) {
      // Exhausted all facts — reshuffle for next cycle
      state = TriviaState(
        facts: [...state.facts]..shuffle(),
        currentIndex: 0,
      );
    } else {
      state = state.copyWith(currentIndex: next);
    }
  }
}

class TriviaState {
  final List<String> facts;
  final int currentIndex;

  TriviaState({required this.facts, this.currentIndex = 0});

  String get currentFact => facts.isEmpty ? '' : facts[currentIndex];
  int get totalFacts => facts.length;
  int get factNumber => currentIndex + 1;

  TriviaState copyWith({List<String>? facts, int? currentIndex}) {
    return TriviaState(
      facts: facts ?? this.facts,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}
```

### 2d. Update trivia card widget

In `lib/widgets/trivia/trivia_card.dart`, optionally add a subtle counter:
```
"Fact 23 of 74"
```
This shows users there's a big pool and they're seeing unique content.

**Write checkpoint after Step 2.**

---

## Step 3: Proximity Query Refactor

### 3a. Read current nearby logic

Read these files to understand the current implementation:
```
app/lib/providers/location_providers.dart
app/lib/providers/restaurant_providers.dart
app/lib/pages/home_page.dart
app/lib/services/location_service.dart
```

Identify:
- How user location is obtained
- How distance is calculated
- How many results are returned
- Whether there's a radius cutoff
- How "Near You" section is rendered

### 3b. Fix the "Top 3 Near You" limitation

Expand from 3 to a configurable number. In the provider:

```dart
// BEFORE:
final nearbyProvider = Provider<List<Restaurant>>((ref) {
  // ... get user location
  // ... sort by distance
  return sorted.take(3).toList();  // ← THE PROBLEM
});

// AFTER:
final nearbyProvider = Provider<List<NearbyRestaurant>>((ref) {
  final userPos = ref.watch(userLocationProvider).value;
  if (userPos == null) return [];

  final restaurants = ref.watch(allRestaurantsProvider).value ?? [];
  final open = restaurants.where((r) => r.stillOpen != false && r.latitude != null).toList();

  final nearby = open.map((r) {
    final distance = haversineDistance(
      userPos.latitude, userPos.longitude,
      r.latitude!, r.longitude!,
    );
    return NearbyRestaurant(restaurant: r, distanceMiles: distance);
  }).toList()
    ..sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));

  return nearby.take(15).toList();  // Show 15 nearby
});
```

### 3c. Create NearbyRestaurant wrapper

```dart
class NearbyRestaurant {
  final Restaurant restaurant;
  final double distanceMiles;

  NearbyRestaurant({required this.restaurant, required this.distanceMiles});

  String get formattedDistance {
    if (distanceMiles < 1) return '${(distanceMiles * 5280).round()} ft';
    if (distanceMiles < 10) return '${distanceMiles.toStringAsFixed(1)} mi';
    if (distanceMiles < 100) return '${distanceMiles.round()} mi';
    return '${distanceMiles.round()}+ mi';
  }
}
```

### 3d. Haversine distance function (in miles)

Verify or create:

```dart
import 'dart:math';

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusMiles = 3958.8;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusMiles * c;
}

double _toRadians(double degrees) => degrees * pi / 180;
```

### 3e. Update Home Page UI

In `lib/pages/home_page.dart`:

```dart
// Section header: "Nearby Restaurants" (not "Top 3 Near You")
// Show distance on each card
// "Show more" button at bottom that navigates to full nearby list or expands

// Example card subtitle:
// "Mama's Soul Food — 2.3 mi away"
// "Joe's BBQ — 0.8 mi away"
```

### 3f. Search results — proximity tiebreaker

In the search provider, when results are returned, add distance as a secondary sort:

```dart
// After relevance filtering:
if (userLocation != null) {
  results.sort((a, b) {
    // Primary: relevance score (if you have one)
    // Secondary: distance from user
    final distA = haversineDistance(userLocation.lat, userLocation.lng, a.lat, a.lng);
    final distB = haversineDistance(userLocation.lat, userLocation.lng, b.lat, b.lng);
    return distA.compareTo(distB);
  });
}
```

### 3g. Verify with 92692 coordinates

After implementation, verify that a simulated location of 33.60°N, 117.65°W (Mission Viejo, CA) returns 10+ nearby restaurants. Southern California is extremely DDD-dense.

```dart
// Debug: log what the location service returns
print('User location: ${position.latitude}, ${position.longitude}');
print('Nearby count: ${nearby.length}');
print('Closest: ${nearby.first.restaurant.name} at ${nearby.first.formattedDistance}');
print('Furthest (of 15): ${nearby.last.restaurant.name} at ${nearby.last.formattedDistance}');
```

**Write checkpoint after Step 3.**

---

## Step 4: Build, Test, Verify

```bash
cd ~/dev/projects/tripledb/app

flutter pub get
flutter analyze    # Must be 0 errors
flutter build web  # Must succeed
```

Optionally `flutter run -d chrome` and verify:
- [ ] App loads without Riverpod errors
- [ ] Trivia shows diverse facts (not the same 10 repeating)
- [ ] Trivia counter shows "Fact X of 70+" (or similar)
- [ ] No trivia fact repeats within a full cycle
- [ ] "Nearby Restaurants" shows 10-15 results (not 3)
- [ ] Distance displayed on each nearby card
- [ ] Nearby restaurants sorted by distance
- [ ] Closed restaurants excluded from nearby
- [ ] Search results sorted with nearby results first
- [ ] Map still works (pins, clustering, filter toggle)
- [ ] Restaurant detail still works (ratings, badges, links)
- [ ] Cookie consent still works
- [ ] Analytics events still fire (if consented)

Log pass/fail.

**Write checkpoint after Step 4.**

---

## Step 5: Update README.md

```bash
cd ~/dev/projects/tripledb
```

### 5a. Phase Status

Add Phase 9 row:
```
| 9 | App Optimization | ✅ Complete | v9.35 |
```

### 5b. Tech Stack

Update Riverpod and geolocator versions:
```
| State Management | flutter_riverpod 3.x | Migrated from 2.x in v9.35 |
| Geolocation | geolocator [version] | Upgraded from 10.x |
```

### 5c. Current Metrics

Add:
```
- **75+** rotating trivia facts with no-repeat system
- **15** nearby restaurants shown (proximity-sorted)
```

### 5d. IAO Iteration History

```
| v9.35 | App Optimization | ✅ | Riverpod 2→3, 75+ trivia facts, proximity refactor. First Claude Code iteration. |
```

### 5e. Changelog

```markdown
**v7.34 → v9.35 (Phase 9 App Optimization)**
- **Riverpod 3.x:** Full migration from 2.x. StateProvider → NotifierProvider, StateNotifier → Notifier.
  Geolocator upgraded from 10.x to [version].
- **Trivia:** Expanded from ~15 facts to 75+. Dynamic generation from dataset. No-repeat shuffle system —
  every fact shown once before any repeats. Shows "Fact X of Y" counter.
- **Proximity:** "Top 3 Near You" → "Nearby Restaurants" showing 15 results with distance display.
  Search results sorted by proximity. Closed restaurants excluded from nearby.
- **Executor:** First iteration using Claude Code instead of Gemini CLI.
```

### 5f. Footer

```markdown
*Last updated: Phase 9.35 — App Optimization (Riverpod 3, Trivia, Proximity)*
```

### 5g. Verify

```bash
grep "9.35" README.md | head -3
grep "Riverpod 3" README.md
grep "Last updated" README.md
```

**Write checkpoint after Step 5.**

---

## Step 6: Generate Artifacts + Cleanup

### docs/ddd-build-v9.35.md (MANDATORY — FULL TRANSCRIPT)

Must include:
- Pre-flight output (current dep versions, baseline build)
- Riverpod migration: files changed, patterns migrated, errors fixed
- Geolocator upgrade: old version → new version, API changes
- Trivia: total facts generated, categories, sample facts
- Proximity: old behavior vs new behavior, nearby count from 92692 test
- flutter analyze + build output
- Verification results
- README changes
- Errors and fixes

### docs/ddd-report-v9.35.md (MANDATORY)

Must include:
1. **Riverpod migration:** providers migrated, patterns changed, build status
2. **Geolocator:** version change, any API differences
3. **Trivia:** total fact count, category breakdown, no-repeat verification
4. **Proximity:** nearby count for 92692, distance range, excluded closed count
5. **Build status:** analyze + build
6. **Executor comparison:** Claude Code vs Gemini CLI observations
7. **Human interventions:** count (target: 0)
8. **Gemini's Recommendation** → rename to **Claude's Recommendation:** What's next?
9. **README Update Confirmation**

### Cleanup

Delete checkpoint file after all artifacts are written.

---

## Success Criteria

```
[ ] Pre-flight passes with baseline build
[ ] Riverpod 3.x migration:
    [ ] flutter_riverpod bumped to ^3.0.0
    [ ] All StateProvider → NotifierProvider
    [ ] All StateNotifierProvider → Notifier
    [ ] valueOrNull → value
    [ ] No legacy imports remaining
    [ ] Auto-retry disabled or configured
    [ ] flutter analyze: 0 errors
[ ] Geolocator upgraded from 10.x
[ ] Trivia expansion:
    [ ] 60+ facts generated dynamically
    [ ] 15+ curated fun facts
    [ ] No-repeat shuffle system working
    [ ] Facts don't repeat until full cycle
    [ ] Fact counter displayed
[ ] Proximity refactor:
    [ ] "Nearby" shows 10-15 results (not 3)
    [ ] Distance displayed on each card (in miles)
    [ ] Sorted by distance ascending
    [ ] Closed restaurants excluded
    [ ] Search results use proximity as tiebreaker
    [ ] 92692 location returns 10+ results
[ ] flutter build web: success
[ ] README at project root fully updated
[ ] ddd-build-v9.35.md generated (FULL transcript)
[ ] ddd-report-v9.35.md generated
[ ] Checkpoint cleared
[ ] Human interventions: 0
```

---

## Launch Sequence

```bash
# 1. Archive previous iteration
cd ~/dev/projects/tripledb
mv docs/ddd-design-v7.34.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v7.34.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v7.34.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v7.34.md docs/archive/ 2>/dev/null

# 2. Place new docs
cp /path/to/ddd-design-v9.35.md docs/
cp /path/to/ddd-plan-v9.35.md docs/

# 3. Create CLAUDE.md (replaces GEMINI.md as version lock)
cat > CLAUDE.md << 'EOF'
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
- MUST produce ddd-build-v9.35.md AND ddd-report-v9.35.md before ending
- ddd-build must be FULL transcript
- CHECKPOINT after every numbered step
- README.md is at project root
EOF

# 4. Commit
git add .
git commit -m "KT starting 9.35 — first Claude Code iteration"

# 5. Launch Claude Code
cd ~/dev/projects/tripledb
claude
```

Then: `Read CLAUDE.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 9.35 and README updated"
git push

cd app
flutter build web
firebase deploy --only hosting
```
