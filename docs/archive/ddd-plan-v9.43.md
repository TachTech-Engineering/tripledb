# TripleDB — Phase 9 Plan v9.43

**Phase:** 9 — App Optimization + Hardening
**Iteration:** 43 (global)
**Executor:** Claude Code (YOLO mode — `claude --dangerously-skip-permissions`)
**Date:** March 2026
**Goal:** Major package upgrades (flutter_map 8, go_router 17, google_fonts 8), trivia expansion to 150+ facts with dedup/randomization fix, preferences Save → force-enable location, Firefox ESR browser testing.

---

## Read Order

```
1. docs/ddd-design-v9.43.md — Full living ADR. Section 4 = environment setup. Section 7 = app architecture.
2. docs/ddd-plan-v9.43.md — This file. Execution steps.
```

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO — code dangerously.
2. SELF-HEAL: max 3 attempts per error. Checkpoint for crash recovery.
3. Git READ only. NEVER git add/commit/push.
4. flutter build web and firebase deploy ARE ALLOWED.
5. FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
6. MANDATORY: ddd-build + ddd-report + ddd-changelog + README.
7. CHECKPOINT after every numbered step.
8. POST-FLIGHT: Tier 1 + Tier 2 (Flutter code changes this iteration).
9. CHANGELOG: APPEND only, ≥ 28 entries after update. Copy to docs/ddd-changelog-v9.43.md.
10. Orchestration Report REQUIRED in ddd-report.
11. SUDO EXCEPTION: If a tool needs sudo, log the command and ask Kyle. This is NOT a plan failure.
12. PACKAGE UPGRADES: Evaluate breaking changes. Proceed if straightforward. Log before/after versions.
13. BROWSER TESTING: Chrome Stable + Firefox ESR ONLY. No Chromium, Edge, Brave, Safari.
```

---

## What This Iteration Changes

| Item | Change |
|------|--------|
| `pubspec.yaml` | flutter_map 7→8, go_router 14→17, google_fonts 6→8, flutter_map_marker_cluster update |
| Trivia service | Expand from ~55 to 150+ facts. Fix dedup. Improve randomization. |
| Cookie consent | Save Preferences with preferences enabled → force-enable geolocation |
| CLAUDE.md | Updated template with sudo exception, Puppeteer instructions, browser targets |
| README.md | Updated stats, changelog appended |
| Browser testing | Firefox ESR added to test matrix. Chromium/WebKit removed. |

---

## Step 0: Pre-Flight

```bash
cd ~/dev/projects/tripledb

# Verify docs
ls docs/ddd-design-v9.43.md
ls docs/ddd-plan-v9.43.md

# Archive v9.42
mkdir -p docs/archive
mv docs/ddd-design-v9.42.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v9.42.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v9.42.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v9.42.md docs/archive/ 2>/dev/null
mv docs/ddd-changelog-v9.42.md docs/archive/ 2>/dev/null

# Baseline build
cd app
flutter pub get
flutter analyze
# Expected: 0 issues

flutter build web
# Expected: success

cd ..

# Changelog count
grep -c '^\*\*v' README.md
# Expected: 27

# Check Firefox ESR availability
which firefox-esr 2>/dev/null || which firefox 2>/dev/null
# If neither: log for Kyle to install (pacman -S firefox-esr or yay -S firefox-esr-bin)

# Check Puppeteer
npx puppeteer --version 2>/dev/null || echo "Puppeteer not global — will use local install"

# Initialize checkpoint
mkdir -p pipeline/data/checkpoints
```

**Write checkpoint after Step 0.**

---

## Step 1: Package Upgrades

### 1a. Evaluate Breaking Changes

Before upgrading, check changelogs:

```bash
cd ~/dev/projects/tripledb/app

# Current versions
flutter pub deps | grep -E "flutter_map|go_router|google_fonts|flutter_map_marker_cluster"
```

**flutter_map 7 → 8:**
- Breaking: `FlutterMap` widget API changes. Check for renamed parameters.
- `TileLayer` options may have changed.
- `flutter_map_marker_cluster` must be compatible with flutter_map 8.

**go_router 14 → 17:**
- Breaking: Route configuration API changes between majors.
- Check `GoRoute`, `ShellRoute` constructors.
- `redirect` callback signature may differ.

**google_fonts 6 → 8:**
- Usually non-breaking. Font loading API stable.
- Check for deprecated `GoogleFonts.notoSans()` calls.

### 1b. Update pubspec.yaml

Update version constraints:

```yaml
dependencies:
  flutter_map: ^8.0.0
  flutter_map_marker_cluster: ^8.0.0  # or compatible version
  go_router: ^17.0.0
  google_fonts: ^8.0.0
```

```bash
flutter pub get
```

### 1c. Fix Breaking Changes

After `flutter pub get`, run:

```bash
flutter analyze
```

Fix any issues reported. Common patterns:
- Renamed widget parameters → update call sites
- Changed constructor signatures → adapt
- Deprecated APIs → migrate to replacements

Use Context7 MCP to look up new API signatures if needed.

### 1d. Verify Build

```bash
flutter analyze
# MUST be 0 issues

flutter build web
# MUST succeed
```

**Log all version changes:**
```
flutter_map: 7.x.x → 8.x.x
flutter_map_marker_cluster: 1.x.x → 8.x.x
go_router: 14.x.x → 17.x.x
google_fonts: 6.x.x → 8.x.x
```

**Write checkpoint after Step 1.**

---

## Step 2: Trivia Expansion

### 2a. Audit Current Trivia

```bash
cd ~/dev/projects/tripledb/app

# Find the trivia data file/service
grep -rn "trivia\|did_you_know\|funFact" lib/ --include="*.dart" | head -20

# Count current facts
grep -c "fact\|trivia" lib/data/trivia_facts.dart 2>/dev/null || \
grep -c "fact\|trivia" lib/services/trivia_service.dart 2>/dev/null
```

### 2b. Identify Trivia Sources

Generate facts from the actual dataset. Categories:

**Geographic (state/city stats):**
- "California has more DDD restaurants than any other state — [X] locations!"
- "New York City alone has [X] restaurants featured on DDD"
- "[X] states have been featured on the show"
- "The southernmost DDD restaurant is in [city, state]"

**Show statistics:**
- "Guy has visited [1,102] unique restaurants across 805 episodes"
- "[773] episodes have been fully processed and catalogued"
- "[432] duplicate restaurant entries were merged during data processing"
- "The most revisited restaurant was featured in [X] different episodes"

**Food & cuisine:**
- "[2,286] unique dishes have been documented across all episodes"
- "BBQ is the most common cuisine type with [X] restaurants"
- "The most common ingredient mentioned is [X]"

**Name changes & closures:**
- "[279] restaurants have changed their name since appearing on the show"
- "[34] restaurants featured on DDD have permanently closed"
- "[11] restaurants are temporarily closed"
- "The average Google rating for DDD restaurants is 4.4 stars"

**Enrichment stats:**
- "[582] restaurants have been verified with current Google Places data"
- "[1,006] restaurants have been geocoded and mapped"
- "The enrichment pipeline matched restaurants with [X]% accuracy"

**Meta/fun:**
- "TripleDB was built at $0 total infrastructure cost"
- "The pipeline processed 805 YouTube videos using local CUDA transcription"
- "TripleDB's name combines 'Triple D' (the show's nickname) with 'DB' (database)"

### 2c. Implement Expanded Trivia

**Target: 150+ unique facts.** The trivia service should:

1. Store all facts in a single `List<String>` (or equivalent)
2. On app startup, shuffle the list with `List.shuffle()` using a fresh `Random()` instance
3. Display facts sequentially from the shuffled list (index 0, 1, 2, ...)
4. When all facts have been shown, reshuffle and restart
5. **NEVER show the same fact twice in a row** — if the last fact of the previous cycle equals the first fact of the new cycle, swap positions 0 and 1

```dart
class TriviaService {
  final List<String> _facts = [...]; // 150+ facts
  late List<String> _shuffled;
  int _index = 0;

  TriviaService() {
    _shuffled = List.of(_facts)..shuffle(Random());
  }

  String getNextFact() {
    if (_index >= _shuffled.length) {
      final lastShown = _shuffled.last;
      _shuffled = List.of(_facts)..shuffle(Random());
      // Avoid repeat at boundary
      if (_shuffled.first == lastShown && _shuffled.length > 1) {
        final temp = _shuffled[0];
        _shuffled[0] = _shuffled[1];
        _shuffled[1] = temp;
      }
      _index = 0;
    }
    return _shuffled[_index++];
  }
}
```

### 2d. Verify

```bash
flutter analyze
flutter build web
```

Serve locally and verify:
- Multiple page loads show different trivia
- No duplicate facts within a session
- Facts reference real data (not placeholder values)

**Write checkpoint after Step 2.**

---

## Step 3: Preferences Save → Force Location

### 3a. Understand Current Behavior

The cookie consent banner has three options:
1. **Accept All** → enables analytics + requests geolocation ✅ (working)
2. **Reject Non-Essential** → disables analytics, skips geolocation ✅ (working)
3. **Save Preferences** (with preferences radio) → saves selection but **does NOT request geolocation** ❌ (bug)

### 3b. Fix: Save Preferences → Enable Location

When the user clicks "Save Preferences" and the preferences radio button is in the enabled state, the handler should:

1. Write the cookie with the selected preferences
2. **If geolocation preference is enabled (or if any non-essential preference is enabled), request geolocation** — same behavior as "Accept All"
3. Dismiss the banner

Find the consent banner widget:
```bash
grep -rn "Save Preferences\|savePreferences\|save_preferences" lib/ --include="*.dart"
```

The fix should be in the button's `onPressed` callback. After writing the cookie, check if geolocation is enabled in the selected preferences and call the location request if so.

**Key constraint from v9.39:** Location must be requested BEFORE the banner widget is dismissed (widget must be mounted for the permission dialog to show). Use the same pattern as "Accept All" — request location, then dismiss.

### 3c. Verify

Test via Puppeteer:

```
TEST: Save Preferences enables location
CONTEXT: Fresh browser, no cookies
ACTION:  Navigate to app
WAIT:    Banner appears
ACTION:  Select preferences radio (if applicable)
ACTION:  Click "Save Preferences"
CHECK:   Cookie written with preferences
CHECK:   Geolocation request fired (browser permission dialog or mock)
PASS:    Location requested after save
FAIL:    No geolocation request
```

**Write checkpoint after Step 3.**

---

## Step 4: Firefox ESR Testing

### 4a. Verify Firefox ESR Installation

```bash
# Check if Firefox ESR is available
which firefox-esr 2>/dev/null
# If not installed:
# Log: "SUDO REQUIRED: sudo pacman -S firefox-esr (or yay -S firefox-esr-bin)"
# Ask Kyle to install
# If Kyle is unavailable, use regular Firefox as fallback and note the gap
```

### 4b. Firefox Test Suite

Run the same tests as Chromium but against Firefox:

```
BROWSER: Firefox ESR (or Firefox stable as fallback)

Test 1: App loads
Test 2: Search works ("BBQ")
Test 3: Map renders with pins
Test 4: Cookie banner appears
Test 5: Accept All writes cookie
Test 6: Trivia shows (not repeated)
Test 7: Save Preferences triggers location
```

**Known issue:** Flutter Web has an upstream bug in Firefox — `Invalid language tag: "undefined"`. If this blocks app loading, document it as a known issue and note whether it's a render-blocking error or a console warning.

### 4c. Chrome Stable Test Suite

Run the same 7 tests against Chrome Stable (the system `chromium` package).

### 4d. Record Results

| Browser | Test 1 | Test 2 | Test 3 | Test 4 | Test 5 | Test 6 | Test 7 | Overall |
|---------|--------|--------|--------|--------|--------|--------|--------|---------|
| Chrome Stable | | | | | | | | |
| Firefox ESR | | | | | | | | |

**Write checkpoint after Step 4.**

---

## Step 5: Update CLAUDE.md

Replace contents with the v9.43 template from the design doc (Section: CLAUDE.md Template).

Key changes from v9.42:
- Sudo exception documented
- Puppeteer instructions (local fallback pattern)
- Browser targets: Chrome Stable + Firefox ESR only
- Package upgrade policy
- Section 4 reference for missing tools

**Write checkpoint after Step 5.**

---

## Step 6: Build + Deploy

```bash
cd ~/dev/projects/tripledb/app
flutter analyze
# Expected: 0 issues

flutter build web
# Expected: success

firebase deploy --only hosting
```

**Write checkpoint after Step 6.**

---

## Step 7: Post-Flight

### Tier 1 — Standard Health

| Gate | Check | Expected |
|------|-------|----------|
| 1 | `flutter analyze` | 0 issues |
| 2 | `flutter build web` | Success |
| 3 | Changelog count | ≥ 28 |
| 4 | First entry preserved | v0.7 present |
| 5 | Last entry present | v9.43 present |
| 6 | `docs/ddd-changelog-v9.43.md` exists | Yes |

### Tier 2 — Iteration Playbook

| # | Test | Expected | Browser |
|---|------|----------|---------|
| 1 | App loads (not white screen) | PASS | Chrome + Firefox |
| 2 | Trivia displays (visible in a11y tree) | PASS | Chrome |
| 3 | Multiple reloads show different trivia | PASS | Chrome |
| 4 | No repeated trivia in 10 consecutive views | PASS | Chrome |
| 5 | Save Preferences triggers geolocation | PASS | Chrome |
| 6 | Map renders (flutter_map 8 upgrade) | PASS | Chrome |
| 7 | Search works ("BBQ" returns results) | PASS | Chrome |
| 8 | GoRouter handles invalid URL (go_router 17) | PASS | Chrome |
| 9 | Cookie banner works on Firefox ESR | PASS or KNOWN_ISSUE | Firefox |

**Write checkpoint after Step 7.**

---

## Step 8: Update README + Generate Artifacts

### 8a. APPEND Changelog Entry

```markdown
**v9.43 (Phase 9 — Package Upgrades + Trivia + Preferences Fix)**
- **Package upgrades:** flutter_map 7→8, go_router 14→17, google_fonts 6→8. Breaking changes
  resolved. flutter analyze: 0 issues.
- **Trivia expansion:** Increased from ~55 to 150+ unique facts. Fixed duplicate display issue.
  Implemented shuffle-based rotation with no-repeat guarantee.
- **Save Preferences → location:** Clicking Save Preferences with geolocation enabled now
  correctly triggers the browser location prompt, matching Accept All behavior.
- **Firefox ESR testing:** Added Firefox ESR to browser test matrix. Chrome Stable + Firefox ESR
  are the two supported test targets. [Note Firefox status].
- **Sudo exception:** Formalized in Pillar 2/3. YOLO agents cannot run sudo — they ask Kyle.
  Sudo interventions tracked separately from plan quality.
- **Puppeteer standardized:** Puppeteer (npm) is the primary browser testing tool. Playwright MCP
  is fallback only.
```

### 8b. Update README Stats

Update any stats that changed (trivia count, package versions).

### 8c. Verify Changelog

```bash
grep -c '^\*\*v' README.md          # ≥ 28
grep '^\*\*v0\.7' README.md | head -1
grep '^\*\*v9\.43' README.md | head -1
```

### 8d. Generate Versioned Changelog

Copy changelog section from README to `docs/ddd-changelog-v9.43.md`.

### 8e. Generate Build + Report

Standard artifacts per Pillar 1.

Delete checkpoint.

---

## Success Criteria

```
[ ] Pre-flight passes
[ ] v9.42 artifacts archived
[ ] PACKAGE UPGRADES:
    [ ] flutter_map 7 → 8 (map renders, pins cluster)
    [ ] go_router 14 → 17 (routing works, 404 handled)
    [ ] google_fonts 6 → 8 (fonts render)
    [ ] flutter analyze: 0 issues after upgrades
    [ ] flutter build web: success after upgrades
[ ] TRIVIA EXPANSION:
    [ ] 150+ unique facts
    [ ] No duplicates in 10 consecutive views
    [ ] Different facts on each page load
    [ ] Facts reference real data
[ ] PREFERENCES → LOCATION:
    [ ] Save Preferences with prefs enabled triggers geolocation
    [ ] Cookie written correctly
    [ ] Banner dismisses after save
[ ] BROWSER TESTING:
    [ ] Chrome Stable: all tests pass
    [ ] Firefox ESR: tested (document known issues)
[ ] CLAUDE.md updated with v9.43 template
[ ] README changelog ≥ 28 entries
[ ] docs/ddd-changelog-v9.43.md generated
[ ] firebase deploy --only hosting: success
[ ] Tier 1: all gates pass
[ ] Tier 2: playbook results recorded
[ ] Orchestration report in ddd-report
[ ] Interventions: 0 (sudo interventions tracked separately)
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb

# Archive v9.42
mv docs/ddd-design-v9.42.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v9.42.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v9.42.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v9.42.md docs/archive/ 2>/dev/null
mv docs/ddd-changelog-v9.42.md docs/archive/ 2>/dev/null

# Place new docs
cp /path/to/ddd-design-v9.43.md docs/
cp /path/to/ddd-plan-v9.43.md docs/

# Update CLAUDE.md (use editor — fish has no heredocs)
# Content: see design doc CLAUDE.md Template (v9.43)

# Ensure Firefox ESR is installed
which firefox-esr 2>/dev/null || echo "Install: sudo pacman -S firefox-esr or yay -S firefox-esr-bin"

# Ensure Puppeteer global is available
npx puppeteer --version 2>/dev/null || echo "Install: sudo npm install -g puppeteer"

# Commit
git add .
git commit -m "KT starting 9.43 — package upgrades, trivia expansion, preferences fix"

# Launch YOLO
claude --dangerously-skip-permissions
```

Then: `Read CLAUDE.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 9.43 — flutter_map 8, 150+ trivia, preferences→location"
git push
```

---

## Reminder: Changelog Rules

The README changelog currently has 27 entries. After this iteration it must have ≥ 28.

1. PRESERVE every existing entry verbatim
2. APPEND v9.43 entry
3. Copy to `docs/ddd-changelog-v9.43.md`
4. Verify count: `grep -c '^\*\*v' README.md` → ≥ 28
