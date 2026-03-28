# TripleDB — Phase 9 Plan v9.40

**Phase:** 9 — App Optimization (FINAL DEV ITERATION)
**Iteration:** 40 (global)
**Executor:** Claude Code (YOLO mode — `claude --dangerously-skip-permissions`)
**Date:** March 2026
**Goal:** Migrate `dart:html` → `package:web` for WASM compatibility, deploy Firestore security rules (read-only public), final dev polish before Phase 10 UAT handoff.

---

## Read Order

```
1. docs/ddd-design-v9.40.md — Full living ADR with Eight Pillars, environment setup, Dev/UAT model
2. docs/ddd-plan-v9.40.md — This file. Execution steps.
```

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO — code dangerously.
2. SELF-HEAL: max 3 attempts per error. Checkpoint for crash recovery.
3. Git READ only. No write, no deploy.
4. flutter build web and flutter run ARE ALLOWED.
5. FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
6. MANDATORY: ddd-build + ddd-report (with orchestration report) + README.
7. CHECKPOINT after every numbered step.
8. POST-FLIGHT: Tier 1 + Tier 2 playbook must BOTH pass.
9. CHANGELOG: APPEND only, ≥ 25 entries after update.
10. Orchestration Report REQUIRED in ddd-report.
```

---

## Step 0: Pre-Flight

```bash
cd ~/dev/projects/tripledb

# Verify project
ls app/lib/services/cookie_consent_service.dart
grep "dart:html" app/lib/services/cookie_consent_service.dart
# Expected: 1 match (the import to migrate)

# Check current Firestore rules
cat app/firestore.rules 2>/dev/null || echo "No rules file yet"

# Baseline build
cd app
flutter pub get
flutter analyze
flutter build web

# Initialize checkpoint
mkdir -p ~/dev/projects/tripledb/pipeline/data/checkpoints
```

**Write checkpoint after Step 0.**

---

## Step 1: Migrate `dart:html` → `package:web` + `dart:js_interop`

### 1a. Add `package:web` dependency

```bash
cd ~/dev/projects/tripledb/app
```

Add to `pubspec.yaml`:
```yaml
dependencies:
  web: ^1.0.0  # or latest compatible version
```

```bash
flutter pub get
```

### 1b. Rewrite `cookie_consent_service.dart`

The ONLY file using `dart:html` is `lib/services/cookie_consent_service.dart`. Replace:

**BEFORE:**
```dart
import 'dart:html' as html;
// ...
html.document.cookie  // read
html.document.cookie = '...'  // write
html.window.location.protocol  // check HTTPS
```

**AFTER:**
```dart
import 'package:web/web.dart' as web;
import 'dart:js_interop';
// ...
web.document.cookie  // read
web.document.cookie = '...'  // write (may need .toJS conversion)
web.window.location.protocol  // check HTTPS
```

**Key migration points from official docs:**

1. `html.document.cookie` → `web.document.cookie`
   - In `package:web`, `document.cookie` is a `String` property that maps directly
   - Reading: `final cookies = web.document.cookie;`
   - Writing: `web.document.cookie = 'name=value; ...'`

2. `html.window.location.protocol` → `web.window.location.protocol`
   - Returns `'https:'` or `'http:'`

3. The `kIsWeb` guard remains unchanged — it's from `package:flutter/foundation.dart`

4. If any type conversions are needed (Dart String ↔ JS String), use `.toDart` / `.toJS` from `dart:js_interop`

### 1c. Use conditional import for web-only code

To ensure the app could theoretically compile for non-web platforms:

```dart
// lib/services/cookie_consent_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import pattern
import 'cookie_consent_stub.dart'
    if (dart.library.js_interop) 'cookie_consent_web.dart';
```

**However**, since TripleDB is currently web-only and we're not shipping to mobile, the simpler approach is acceptable: just use `package:web` directly with `kIsWeb` guard. Use Context7 to verify the exact API if needed.

### 1d. Verify migration

```bash
cd ~/dev/projects/tripledb/app

# dart:html should be GONE
grep -rn "dart:html" lib/
# Expected: 0 matches

# package:web should be present
grep -rn "package:web" lib/
# Expected: 1+ matches (cookie_consent_service.dart)

flutter analyze
# Expected: 0 errors, 0 infos (the dart:html deprecation warning should be GONE)

flutter build web
# Must succeed
```

**The `info • 'dart:html' is deprecated` warning that has been present since v7.34 should now be ELIMINATED.** This is the primary success metric for Step 1.

**Write checkpoint after Step 1.**

---

## Step 2: Deploy Firestore Security Rules

### 2a. Understand TripleDB's access pattern

- **Public reads:** Anyone can browse restaurants, search, view details. No authentication required.
- **No client-side writes:** The Flutter app NEVER writes to Firestore. All writes are done by pipeline scripts using Firebase Admin SDK (which bypasses security rules entirely).
- **Admin writes:** Pipeline scripts (`phase6_load_firestore.py`, `phase7_load_enriched.py`, `phase7_load_names.py`, `clean_false_positives.py`) use Firebase Admin SDK with Application Default Credentials.

Therefore, the rules are simple: allow all reads, deny all client writes.

### 2b. Create `firestore.rules`

```bash
cd ~/dev/projects/tripledb/app
```

Create or update `firestore.rules`:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Restaurants collection — public read, no client write
    match /restaurants/{restaurantId} {
      allow read: if true;
      allow write: if false;
    }

    // Videos collection — public read, no client write
    match /videos/{videoId} {
      allow read: if true;
      allow write: if false;
    }

    // Default deny for any other collection
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 2c. Verify `firebase.json` references the rules file

```bash
cat ~/dev/projects/tripledb/app/firebase.json
```

Ensure it includes:
```json
{
  "firestore": {
    "rules": "firestore.rules"
  },
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]
  }
}
```

If the `firestore` section is missing, add it.

### 2d. Test rules with Firebase emulator (optional but recommended)

If the Firebase emulator is installed:
```bash
firebase emulators:start --only firestore
# Test reads and writes against the emulator
```

If not installed, skip — the rules are simple enough that manual review is sufficient.

### 2e. Note for Kyle's deploy

The rules deploy command (which Kyle runs manually, NOT the agent):
```bash
firebase deploy --only firestore:rules
```

This is separate from `firebase deploy --only hosting`. After this iteration, Kyle should run BOTH:
```bash
firebase deploy --only firestore:rules,hosting
```

**Write checkpoint after Step 2.**

---

## Step 3: Build + Post-Flight

### 3a. Final build

```bash
cd ~/dev/projects/tripledb/app
flutter analyze
# Expected: 0 errors, 0 warnings, 0 infos (dart:html warning GONE)

flutter build web
```

### 3b. Serve locally

```bash
python3 -m http.server 8080 -d build/web &
SERVER_PID=$!
sleep 3
```

### 3c. Tier 1 — Standard Health

**GATE 1: App Bootstraps**
- Navigate to http://localhost:8080, wait 10s
- NOT white screen, content renders

**GATE 2: Console Clean**
- 0 uncaught errors
- **BONUS: The dart:html deprecation warning should be GONE from analyzer output**

**GATE 3: Changelog**
```bash
grep -c '^\*\*v' ~/dev/projects/tripledb/README.md
# ≥ 25
```

### 3d. Tier 2 — Iteration Playbook

### TEST 1: Cookie System Still Works (regression after dart:html removal)

```
CONTEXT: Fresh browser context (no cookies)
ACTION:  Navigate to http://localhost:8080
WAIT:    10s
CHECK:   Cookie banner visible in accessibility tree
PASS:    Banner renders (package:web cookie read returning empty = new visitor)
FAIL:    Banner missing → package:web migration broke cookie reading
```

### TEST 2: Accept All Still Works (regression)

```
CONTEXT: Same as Test 1
ACTION:  Click "Accept All"
CHECK:   Banner dismisses
CHECK:   document.cookie contains tripledb_consent
PASS:    Cookie written via package:web
FAIL:    Cookie not written → package:web cookie write broken
```

### TEST 3: Cookie Persists on Reload (regression)

```
CONTEXT: Same session
ACTION:  Reload page
CHECK:   Banner does NOT reappear
PASS:    Cookie persisted
FAIL:    Banner reappeared → cookie write format wrong
```

### TEST 4: No "Unknown" in Nearby (regression from v9.39)

```
CONTEXT: App loaded
CHECK:   Nearby results contain zero "Unknown" city/state values
PASS:    Filter working
FAIL:    Regression
```

### TEST 5: Firestore Rules File Exists and Is Valid

```bash
cat ~/dev/projects/tripledb/app/firestore.rules
# Verify: contains "allow read: if true" and "allow write: if false"
# Verify: firebase.json references the rules file
```

### Playbook Results Table

| Test | What | Result | Notes |
|------|------|--------|-------|
| 1 | Cookie banner renders (post-migration) | | |
| 2 | Accept All writes cookie | | |
| 3 | Cookie persists on reload | | |
| 4 | No "Unknown" in nearby (regression) | | |
| 5 | Firestore rules file valid | | |

```bash
kill $SERVER_PID 2>/dev/null
```

**Write checkpoint after Step 3.**

---

## Step 4: Update README

```bash
cd ~/dev/projects/tripledb
```

### APPEND changelog entry:

```markdown
**v9.40 (Phase 9 — dart:html Migration + Firestore Security Rules)**
- **dart:html → package:web:** Migrated cookie_consent_service.dart from deprecated dart:html
  to package:web + dart:js_interop. Eliminates the persistent analyzer deprecation warning and
  enables future WASM compilation. All cookie read/write/HTTPS-detection functions verified.
- **Firestore security rules:** Deployed read-only public rules. restaurants and videos collections
  allow public reads, deny all client writes. Admin SDK writes (pipeline scripts) bypass rules.
  Default deny on all other collections.
- **Final dev iteration:** Phase 9 complete. All P0/P1 items resolved. App is production-ready
  for Phase 10 UAT handoff.
```

### Verify:
```bash
grep -c '^\*\*v' README.md   # ≥ 25
grep 'v0.7' README.md | head -1
grep 'v9.40' README.md | head -1
```

### Also update:
- Phase 9 status: ✅ Complete | v9.35–v9.40
- Iteration history: v9.40 row
- Footer: `*Last updated: Phase 9.40 — Final Dev Polish*`
- Note Phase 10 as next: "Phase 10: UAT handoff — Gemini CLI executes all phases autonomously"

**Write checkpoint after Step 4.**

---

## Step 5: Generate Artifacts + Cleanup

### docs/ddd-build-v9.40.md (MANDATORY — FULL TRANSCRIPT)

Must include:
- Pre-flight output
- dart:html → package:web migration details (exact code changes, import changes)
- `flutter analyze` output BEFORE and AFTER migration (showing deprecation warning removal)
- Firestore rules file content
- firebase.json update
- Build output
- Tier 1 + Tier 2 playbook results
- README changes

### docs/ddd-report-v9.40.md (MANDATORY)

Must include:
1. **dart:html migration:** What changed, what the analyzer says now (should be 0 issues total)
2. **Firestore rules:** Rules content, access pattern rationale
3. **Post-flight:** Tier 1 gates + Tier 2 playbook table
4. **Changelog:** Entry count
5. **Orchestration Report:** Tools used, workload %, efficacy
6. **Interventions:** Target 0
7. **Claude's Recommendation:** Phase 9 complete, ready for Phase 10 UAT?
8. **Phase 10 readiness assessment:** What needs to happen for Gemini CLI to execute all phases in UAT

Delete checkpoint.

---

## Success Criteria

```
[ ] Pre-flight passes
[ ] dart:html → package:web migration:
    [ ] package:web added to pubspec.yaml
    [ ] cookie_consent_service.dart uses package:web (not dart:html)
    [ ] grep -rn "dart:html" lib/ returns 0 matches
    [ ] flutter analyze: 0 errors AND 0 infos (deprecation warning GONE)
[ ] Firestore security rules:
    [ ] firestore.rules file created
    [ ] restaurants: read=true, write=false
    [ ] videos: read=true, write=false
    [ ] default: read=false, write=false
    [ ] firebase.json references firestore.rules
[ ] flutter build web: success
[ ] TIER 1: App loads, console clean, changelog ≥ 25
[ ] TIER 2 PLAYBOOK:
    [ ] Test 1: Cookie banner renders (post-migration)
    [ ] Test 2: Accept All writes cookie
    [ ] Test 3: Cookie persists
    [ ] Test 4: No "Unknown" in nearby (regression)
    [ ] Test 5: Firestore rules file valid
[ ] README changelog ≥ 25 entries
[ ] Orchestration report in ddd-report
[ ] Artifacts generated
[ ] Interventions: 0
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb

# Archive
mv docs/ddd-design-v9.39.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v9.39.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v9.39.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v9.39.md docs/archive/ 2>/dev/null

# Place new docs
cp /path/to/ddd-design-v9.40.md docs/
cp /path/to/ddd-plan-v9.40.md docs/

# Update CLAUDE.md
cat > CLAUDE.md << 'EOF'
# TripleDB — Agent Instructions

## Current Iteration: 9.40 (FINAL DEV ITERATION)

Last polish before Phase 10 UAT handoff. dart:html migration + Firestore security rules.

1. docs/ddd-design-v9.40.md — Full living ADR
2. docs/ddd-plan-v9.40.md — Execution steps + playbook

## MCP Servers
- Playwright MCP: Post-flight testing
- Context7: Flutter/Dart/package:web docs

## Rules
- YOLO mode — code dangerously, never ask permission
- POST-FLIGHT: Tier 1 + Tier 2 must pass
- CHANGELOG ≥ 25 entries
- Include Orchestration Report in ddd-report
- dart:html deprecation warning must be ELIMINATED after migration
EOF

# Commit
git add .
git commit -m "KT starting 9.40 — final dev polish, dart:html migration + Firestore rules"

# Launch YOLO
claude --dangerously-skip-permissions
```

Then: `Read CLAUDE.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 9.40 — Phase 9 complete, ready for Phase 10 UAT"
git push

cd app
flutter build web
firebase deploy --only firestore:rules,hosting
# NOTE: This deploy includes BOTH hosting AND Firestore security rules

# VERIFY in incognito:
# 1. Cookie banner appears and works
# 2. App loads all restaurant data (rules allow reads)
# 3. No analyzer warnings in build output
```
