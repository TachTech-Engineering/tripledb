# TripleDB — Phase 6 Plan v6.29

**Phase:** 6 — Polish
**Iteration:** 29 (global)
**Date:** March 2026
**Goal:** Fix trivia state count, add map pin clustering, update README to current state, verify all data flows correctly from Firestore through UI.

---

## Read Order

```
1. docs/ddd-design-v6.29.md — Current state, known issues, tech stack
2. docs/ddd-plan-v6.29.md — This file. Execution steps.
```

Read both before executing. Log confirmation in build log.

---

## Autonomy Rules

```
1. AUTO-PROCEED between all steps. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts, then skip).
3. MCP: Context7 ALLOWED for Flutter/Dart docs. No other MCP servers.
4. Git READ commands allowed. Git WRITE commands and firebase deploy forbidden.
5. flutter build web and flutter run ARE ALLOWED for testing.
6. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v6.29.md — full transcript
   b. docs/ddd-report-v6.29.md — metrics and findings
7. Working directory: app/ (this is a frontend-only iteration).
```

---

## Step 0: Pre-Flight

```bash
cd ~/dev/projects/tripledb/app

# Verify app builds
flutter pub get
flutter analyze

# Verify Firestore is active (not bypassed)
grep -n "Firestore\|firestore\|BYPASS\|bypass\|TEMPORARY" lib/services/data_service.dart

# Verify current trivia provider
grep -n "state\|UNKNOWN\|63\|50" lib/providers/trivia_providers.dart
```

Log output. Confirm data_service.dart is using Firestore (not the v6.27 bypass).

---

## Step 1: Fix Trivia State Count

Open `lib/providers/trivia_providers.dart`. Find where the state count is computed.

### What's Wrong
The trivia currently counts ALL unique state values including "UNKNOWN" (33 records), showing "63 states" which is incorrect and confusing.

### Fix
When computing the state count, filter out "UNKNOWN" and null/empty states:

```dart
// BEFORE (broken):
final stateCount = restaurants.map((r) => r.state).toSet().length;

// AFTER (fixed):
final validStates = restaurants
    .map((r) => r.state)
    .where((s) => s != null && s.isNotEmpty && s != 'UNKNOWN')
    .toSet();
final stateCount = validStates.length;
```

The trivia fact should display something like:
- "Guy has visited restaurants in **50** states!" (if counting only US states)
- Or "Triple D has covered **62** states and territories" (if counting territories/DC)

Choose whichever is accurate based on the actual count after filtering.

### Also Verify Other Trivia Facts

Check that these compute from the full dataset:
- Total restaurants (~1,102)
- Total dishes (~2,286)
- Most-visited restaurant (Full Belly Deli, 16 visits)
- Most common cuisine type
- State with most diners (CA)

If any of these are hardcoded or reference sample data counts, fix them to compute dynamically.

---

## Step 2: Add Map Pin Clustering

The map currently renders 916 individual pins. At zoom-out, CA and the Northeast are a blob of overlapping red markers.

### Option A: flutter_map_marker_cluster (Preferred)

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_map_marker_cluster: ^1.4.0
```

Update `lib/pages/map_page.dart`:

```dart
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

// Replace MarkerLayer with MarkerClusterLayerWidget:
MarkerClusterLayerWidget(
  options: MarkerClusterLayerOptions(
    maxClusterRadius: 80,
    size: const Size(40, 40),
    markers: markers,
    builder: (context, clusterMarkers) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary, // Orange #DA7E12
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${clusterMarkers.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    },
  ),
),
```

This groups nearby pins into orange circles showing the count. Zooming in expands them into individual red pins.

**Check version compatibility** with flutter_map 7.x using Context7 before adding. If incompatible, try an older version or use Option B.

### Option B: Simple Zoom-Based Filtering (Fallback)

If the clustering package doesn't work with flutter_map 7.x, implement a simpler approach: only show pins when zoom level is above a threshold:

```dart
MapOptions(
  onPositionChanged: (position, hasGesture) {
    // Only show individual pins at zoom >= 8
    // Show state-level aggregate markers at lower zoom
  },
)
```

This is less elegant but avoids dependency issues.

---

## Step 3: Verify Full Data Flow

Run the app and verify these specific data points:

```bash
flutter run -d chrome
```

### 3a. Home Page (List Tab)
- [ ] Trivia shows correct state count (NOT "63 states")
- [ ] Trivia shows ~1,102 restaurants or ~2,286 dishes
- [ ] "Top 3 Near You" shows local restaurants with distances
- [ ] Search for "brisket" returns many results (not 5)
- [ ] Search for "Memphis" returns Memphis restaurants

### 3b. Map Tab
- [ ] Pins visible across the US (not blank)
- [ ] Pin clusters show at zoom-out (if clustering added)
- [ ] Zooming in shows individual pins
- [ ] Tapping a pin shows bottom sheet with restaurant name
- [ ] "Near Me" FAB moves map to user location

### 3c. Explore Tab
- [ ] Top States list shows CA at top
- [ ] Most Visited shows Full Belly Deli (16 visits)
- [ ] Cuisine breakdown shows real counts

### 3d. Restaurant Detail
- [ ] Dishes listed with descriptions and guy_response
- [ ] YouTube timestamp links formatted correctly
- [ ] Video type badges show (e.g., "compilation • 5 visits")

Log pass/fail for each item.

---

## Step 4: Update README.md

The root `README.md` is stale (still shows v2.11 content after git filter-repo rewrites dropped updates). Update ALL sections:

### 4a. Header
```markdown
# TripleDB

**Every restaurant from Diners, Drive-Ins and Dives — structured, searchable, and mapped.**

🌐 **[tripledb.net](https://tripledb.net)** · 📂 **28 iterations** · 🔧 **Status: Live**
```

### 4b. Project Status Table
Update all phases through v6.29. Show Phase 8 (Flutter app) as complete.

### 4c. Architecture Diagram
Must show Gemini 2.5 Flash API (NOT Ollama) for both extraction and normalization. Include geocoding step.

### 4d. Current Metrics
```markdown
### Live Dataset (tripledb.net)
- **1,102** unique restaurants across **62** states and territories
- **2,286** dishes with ingredients and Guy's reactions
- **2,336** video appearances from **773** processed YouTube videos
- **916** restaurants with map coordinates
- **432** cross-video dedup merges
```

### 4e. IAO Methodology Section
Add the Eight Pillars and iteration history table.

### 4f. Changelog
Add entries for v3.12 through v6.29 (all missing).

### 4g. Footer
```markdown
*Last updated: Phase 6.29 — Polish*
```

### 4h. Fix Stale References
- "804 videos" → "805 videos"
- "tripleDB.com" → "tripledb.net"
- "Qwen 3.5-9B (Ollama)" → "Gemini 2.5 Flash API"
- "Phase 1.10" → current phase
- Any references to local Ollama for extraction or normalization

---

## Step 5: Build and Final Verify

```bash
flutter analyze
flutter build web
```

Both must pass. Log output.

---

## Step 6: Generate Artifacts

### docs/ddd-build-v6.29.md (MANDATORY)

Full transcript:
- Pre-flight output
- Trivia provider changes (before/after)
- Map clustering implementation (or fallback approach)
- Data flow verification checklist (pass/fail per item)
- README changes summary
- flutter analyze + build output

### docs/ddd-report-v6.29.md (MANDATORY)

Must include:
1. **Trivia fix:** what was changed, new state count value
2. **Map clustering:** implemented (which approach) or deferred (why)
3. **Data flow verification:** pass/fail table for all checklist items
4. **README status:** sections updated
5. **Build status:** flutter analyze + build results
6. **Known remaining issues:** (if any)
7. **Gemini's Recommendation:** ready for deploy? ready for Phase 7 enrichment?
8. **Human interventions:** count (target: 0)

---

## Success Criteria

```
[ ] Pre-flight passes
[ ] Trivia state count fixed (excludes UNKNOWN)
[ ] All trivia facts compute from full dataset
[ ] Map pin clustering implemented (or reasonable fallback)
[ ] Data flow verification: all items pass
[ ] README.md fully updated:
    [ ] tripledb.net domain
    [ ] Current metrics
    [ ] Corrected architecture (Gemini Flash)
    [ ] IAO Eight Pillars section
    [ ] Changelog through v6.29
    [ ] Footer: v6.29
[ ] flutter analyze: 0 errors
[ ] flutter build web: success
[ ] ddd-build-v6.29.md generated
[ ] ddd-report-v6.29.md generated
[ ] Human interventions: 0
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb/app

# Place docs
# (copy ddd-design-v6.29.md and ddd-plan-v6.29.md into docs/)

# Update GEMINI.md
nano GEMINI.md

# Launch
gemini
```

Then: `Read GEMINI.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb/app
flutter build web
firebase deploy --only hosting

cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 6.29 — trivia fix, map clustering, README update"
git push
```
