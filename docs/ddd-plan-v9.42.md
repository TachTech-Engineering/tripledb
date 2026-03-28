# TripleDB — Phase 9 Plan v9.42

**Phase:** 9 — App Optimization (Hardening Audit)
**Iteration:** 42 (global)
**Executor:** Claude Code (YOLO mode — `claude --dangerously-skip-permissions`)
**Date:** March 2026
**Goal:** Comprehensive hardening audit across 4 domains (Lighthouse, error boundaries, security, browser compat). Establish scored baseline. Introduce versioned changelog artifact. Audit results drive subsequent iterations — if all P0/P1 issues are fixable in this iteration, fix them inline. Otherwise, produce findings for v9.43+.

---

## Read Order

```
1. docs/ddd-design-v9.42.md — Full living ADR with Hardening Framework (Section 13), Tech Radar (Section 14)
2. docs/ddd-plan-v9.42.md — This file. Execution steps.
```

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO — code dangerously.
2. SELF-HEAL: max 3 attempts per error. Checkpoint for crash recovery.
3. Git READ only. NEVER git add/commit/push.
4. flutter build web and firebase deploy ARE ALLOWED.
5. FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
6. MANDATORY: ddd-build + ddd-report (with orchestration report) + ddd-changelog + README.
7. CHECKPOINT after every numbered step.
8. POST-FLIGHT: Tier 1 + Tier 3 (hardening audit). Tier 2 if Flutter code changes.
9. CHANGELOG: APPEND only, ≥ 27 entries after update. Copy to docs/ddd-changelog-v9.42.md.
10. Orchestration Report REQUIRED in ddd-report.
11. FIX INLINE: If a P0/P1 finding can be fixed in <15 minutes, fix it in this iteration.
    Log the fix in the build log. If it requires significant refactoring, defer to v9.43.
```

---

## Step 0: Pre-Flight

```bash
cd ~/dev/projects/tripledb

# Verify docs
ls docs/ddd-design-v9.42.md
ls docs/ddd-plan-v9.42.md

# Archive v9.41
mkdir -p docs/archive
mv docs/ddd-design-v9.41.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v9.41.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v9.41.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v9.41.md docs/archive/ 2>/dev/null
mv docs/ddd-changelog-v9.41.md docs/archive/ 2>/dev/null

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
# Expected: 26

# Initialize checkpoint
mkdir -p pipeline/data/checkpoints
```

**Write checkpoint after Step 0.**

---

## Step 1: Domain 1 — Lighthouse Performance Audit

### 1a. Run Lighthouse

Use Lighthouse CLI (preferred) or Lighthouse MCP if available. Run against locally served app AND production URL.

```bash
cd ~/dev/projects/tripledb/app

# Serve locally
python3 -m http.server 8080 -d build/web &
SERVER_PID=$!
sleep 3

# Run Lighthouse CLI (if available)
npx lighthouse http://localhost:8080 \
  --chrome-flags="--headless --no-sandbox --force-renderer-accessibility" \
  --output=json --output-path=../docs/lighthouse-local.json \
  --preset=desktop

# Also run against production
npx lighthouse https://tripledb.net \
  --chrome-flags="--headless --no-sandbox --force-renderer-accessibility" \
  --output=json --output-path=../docs/lighthouse-prod.json \
  --preset=desktop

kill $SERVER_PID 2>/dev/null
```

If `npx lighthouse` is not available, use Puppeteer to capture Chrome DevTools Performance metrics, or use the Lighthouse MCP server if connected.

### 1b. Record Scores

| Metric | Local | Prod | Target | Severity |
|--------|-------|------|--------|----------|
| Performance | | | ≥ 90 | |
| Accessibility | | | ≥ 90 | |
| Best Practices | | | ≥ 90 | |
| SEO | | | ≥ 90 | |
| FCP | | | < 1.8s | |
| LCP | | | < 2.5s | |
| TBT | | | < 200ms | |
| CLS | | | < 0.1 | |

### 1c. Bundle Size Analysis

```bash
ls -lh ~/dev/projects/tripledb/app/build/web/main.dart.js
# Note the file size — this is the Flutter app bundle

# Check for source maps (should NOT be deployed in production)
ls ~/dev/projects/tripledb/app/build/web/*.map 2>/dev/null
```

### 1d. Caching Headers Check

```bash
# Check firebase.json for headers configuration
cat ~/dev/projects/tripledb/app/firebase.json | grep -A 20 "headers"

# If no headers section exists, this is a P1 finding — static assets
# should have Cache-Control headers for performance
```

### 1e. Inline Fixes (if applicable)

- **Missing cache headers:** Add to `firebase.json`:
  ```json
  "headers": [
    {
      "source": "**/*.js",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }]
    },
    {
      "source": "**/*.css",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }]
    },
    {
      "source": "index.html",
      "headers": [{ "key": "Cache-Control", "value": "no-cache" }]
    }
  ]
  ```
- **Source maps in build:** Verify `flutter build web` does not include them by default (it shouldn't).

**Write checkpoint after Step 1.**

---

## Step 2: Domain 2 — Error Boundary Testing

Use Playwright MCP (preferred) or Puppeteer for all tests.

### 2a. Firestore Offline

```
CONTEXT: Block network access to firestore.googleapis.com
METHOD:  Playwright page.route('**firestore.googleapis.com**', route => route.abort())
CHECK:   Does the app show a loading/error state, or white screen crash?
PASS:    Graceful degradation (loading spinner, error message, or cached data)
FAIL:    White screen or uncaught error in console
```

### 2b. Location Denied

```
CONTEXT: Override geolocation permission to 'denied'
METHOD:  Playwright context.grantPermissions([], { origin: 'http://localhost:8080' })
         (empty permissions array = all denied)
ACTION:  Accept cookie consent, trigger nearby feature
CHECK:   App handles missing location gracefully
PASS:    Nearby shows restaurants without distance, or shows "Location unavailable" message
FAIL:    Crash, infinite spinner, or uncaught error
```

### 2c. Cookies Disabled

```
CONTEXT: Launch browser with cookies disabled
METHOD:  Playwright context with `javaScriptEnabled: true` but clear cookies after each set
         OR launch with a restrictive cookie policy
ACTION:  Navigate to app
CHECK:   Cookie consent banner behavior when cookies can't be stored
PASS:    Banner appears. If accept fails, app still loads (degraded but functional)
FAIL:    White screen or JS error
```

### 2d. Invalid URL (404 State)

```
CONTEXT: Fresh browser
ACTION:  Navigate to http://localhost:8080/#/restaurant/does-not-exist
CHECK:   GoRouter handles unknown route
PASS:    Redirects to home or shows "not found" message
FAIL:    White screen or error
```

### 2e. Empty Search Results

```
CONTEXT: App loaded
ACTION:  Search for "xyzzy123gibberish"
CHECK:   Zero results state
PASS:    "No results found" message or empty state UI
FAIL:    Crash, infinite spinner, or layout break
```

### 2f. Record Results

| Test | Status | Notes | Severity | Fix? |
|------|--------|-------|----------|------|
| Firestore offline | | | | |
| Location denied | | | | |
| Cookies disabled | | | | |
| Invalid URL | | | | |
| Empty search | | | | |

### 2g. Inline Fixes

Any error boundary issue that can be fixed with a simple try-catch, null check, or fallback widget — fix it now. Log the fix in the build log. Significant refactors (e.g., adding offline caching with Hive) → defer to v9.43.

**Write checkpoint after Step 2.**

---

## Step 3: Domain 3 — Security Audit

### 3a. Firebase Hosting Security Headers

Check current state:
```bash
# Inspect firebase.json for headers
cat ~/dev/projects/tripledb/app/firebase.json

# Check live headers
curl -I https://tripledb.net 2>/dev/null | grep -i -E "content-security|x-frame|x-content-type|referrer-policy|permissions-policy|strict-transport"
```

**Target headers to add (if missing) via `firebase.json`:**

```json
{
  "headers": [
    {
      "source": "**",
      "headers": [
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
        { "key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=(self)" },
        { "key": "Strict-Transport-Security", "value": "max-age=31536000; includeSubDomains" }
      ]
    }
  ]
}
```

**CSP header:** This is the most complex one. Flutter Web requires:
- `script-src 'self' 'unsafe-inline' 'unsafe-eval'` (Flutter's JS bootstrap needs these, unfortunately)
- `style-src 'self' 'unsafe-inline'`
- `connect-src 'self' https://firestore.googleapis.com https://*.google-analytics.com https://*.analytics.google.com https://tile.openstreetmap.org https://*.basemaps.cartocdn.com`
- `img-src 'self' https://*.basemaps.cartocdn.com https://tile.openstreetmap.org data:`
- `font-src 'self' https://fonts.gstatic.com`
- `frame-ancestors 'none'`

**IMPORTANT:** Test the CSP header locally before deploying. A restrictive CSP that breaks the app is worse than no CSP.

### 3b. Firestore Rules Pen Test

```
CONTEXT: Browser devtools on tripledb.net (or localhost)
ACTION:  Open console, attempt:

         const db = firebase.firestore();
         db.collection('restaurants').add({ test: true })
           .then(() => console.log('WRITE SUCCEEDED — FAIL'))
           .catch(e => console.log('WRITE BLOCKED — PASS', e.code));

CHECK:   Write attempt rejected with 'permission-denied'
PASS:    Error caught, permission-denied
FAIL:    Write succeeds
```

If the Firestore JS SDK isn't exposed globally, use Playwright to inject the test script.

### 3c. Cookie Security Verification

```bash
# Check cookie attributes on production
# Use Puppeteer/Playwright to read document.cookie after accepting consent
# Verify: Secure flag present (HTTPS), SameSite=Lax or Strict, path=/
```

### 3d. Dependency Audit

```bash
cd ~/dev/projects/tripledb/app
flutter pub outdated
# Note any packages with known security issues
# Check for deprecated packages (we already fixed dart:html in v9.40)
```

### 3e. Record Results

| Check | Status | Finding | Severity | Fix? |
|-------|--------|---------|----------|------|
| X-Frame-Options | | | | |
| X-Content-Type-Options | | | | |
| Referrer-Policy | | | | |
| Permissions-Policy | | | | |
| HSTS | | | | |
| CSP | | | | |
| Firestore write blocked | | | | |
| Cookie Secure flag | | | | |
| Cookie SameSite | | | | |
| Dependency audit | | | | |

### 3f. Inline Fixes

**Security headers in firebase.json are a quick win** — add them in this iteration. CSP header should be added carefully and tested before deploy.

**Write checkpoint after Step 3.**

---

## Step 4: Domain 4 — Browser & Device Compatibility

### 4a. Multi-Browser Testing

Use Playwright with multiple browser engines:

```
BROWSERS: chromium, firefox, webkit (Safari engine)
VIEWPORT: 1280x720 (desktop default)

For each browser:
  1. Navigate to http://localhost:8080
  2. Wait for app to load (not white screen)
  3. Cookie banner visible?
  4. Click Accept All
  5. Search for "BBQ" — results appear?
  6. Map renders with pins?
  7. Click a restaurant card — detail view loads?
  8. Console errors?
```

### 4b. Responsive Viewport Testing

Use Playwright viewport resizing:

```
VIEWPORTS:
  - 375x667   (iPhone SE — phone)
  - 768x1024  (iPad — tablet)
  - 1024x768  (small desktop)
  - 1920x1080 (full HD desktop)

For each viewport:
  1. App loads
  2. No horizontal scroll
  3. Search bar accessible
  4. Map visible (not cut off)
  5. Restaurant cards stack properly (column on mobile, grid on desktop)
  6. Cookie banner doesn't overflow
```

### 4c. Keyboard Navigation

```
CONTEXT: Desktop browser, no mouse
ACTION:  Tab through the page
CHECK:   Focus indicators visible on interactive elements
CHECK:   Search field reachable via Tab
CHECK:   Enter key triggers search
CHECK:   Escape key dismisses modals/overlays (if any)
```

### 4d. Record Results

| Browser/Viewport | Loads | Search | Map | Cards | Console | Notes |
|-----------------|-------|--------|-----|-------|---------|-------|
| Chrome 1280x720 | | | | | | |
| Firefox 1280x720 | | | | | | |
| WebKit 1280x720 | | | | | | |
| Chrome 375x667 | | | | | | |
| Chrome 768x1024 | | | | | | |
| Chrome 1920x1080 | | | | | | |

**Write checkpoint after Step 4.**

---

## Step 5: Aggregate Findings + Fix What's Quick

### 5a. Compile Master Findings Table

Merge all findings from Steps 1-4 into a single prioritized table:

```markdown
| # | Domain | Finding | Severity | Status | Notes |
|---|--------|---------|----------|--------|-------|
| 1 | Security | Missing X-Frame-Options header | P1 | FIXED | Added to firebase.json |
| 2 | Performance | No cache headers on static assets | P1 | FIXED | Added to firebase.json |
| 3 | Error | White screen on Firestore offline | P0 | DEFER v9.43 | Needs offline caching |
| ... | ... | ... | ... | ... | ... |
```

### 5b. Apply All Quick Fixes

Batch all `firebase.json` changes (security headers + cache headers) into a single update. Rebuild and deploy:

```bash
cd ~/dev/projects/tripledb/app
flutter build web
firebase deploy --only hosting
```

### 5c. Re-run Affected Tests

After fixes, re-test the specific findings that were addressed. Update the findings table with post-fix status.

**Write checkpoint after Step 5.**

---

## Step 6: Update README + Generate Changelog Artifact

### 6a. APPEND Changelog Entry

```markdown
**v9.42 (Phase 9 — Hardening Audit)**
- **Lighthouse baseline:** Performance, accessibility, SEO, and best practices scores established
  for both local and production builds.
- **Error boundary testing:** Firestore offline, location denied, cookies disabled, invalid URL,
  and empty search edge cases audited. [X fixed inline / Y deferred].
- **Security hardening:** Firebase Hosting security headers (X-Frame-Options, HSTS, CSP, etc.)
  audited and deployed. Firestore rules pen-tested. Dependency audit completed.
- **Browser compatibility:** Chrome, Firefox, WebKit tested across 4 viewport sizes. Responsive
  breakpoints and keyboard navigation verified.
- **Versioned changelog:** Introduced ddd-changelog-v{P}.{I}.md as 5th artifact for resilience.
```

**Adjust the bracketed items** based on actual findings.

### 6b. Verify

```bash
grep -c '^\*\*v' README.md          # ≥ 27
grep '^\*\*v0\.7\|^\*\*v1\.10' README.md | head -1   # First entry preserved
grep '^\*\*v9\.42' README.md | head -1  # Last entry present
```

### 6c. Generate Versioned Changelog

```bash
cd ~/dev/projects/tripledb

# Extract changelog section from README and save as versioned artifact
# The agent should copy everything from the ## Changelog header through the last entry
# into docs/ddd-changelog-v9.42.md
```

The changelog file format:

```markdown
# TripleDB — Changelog v9.42

**Snapshot Date:** 2026-03-28
**Total Entries:** 27
**Source:** README.md changelog section

---

[Full changelog content from README, verbatim]
```

**Write checkpoint after Step 6.**

---

## Step 7: Generate Artifacts + Cleanup

### docs/ddd-build-v9.42.md (MANDATORY — FULL TRANSCRIPT)

Must include:
- Pre-flight output
- Lighthouse scores (all 4 categories + Core Web Vitals)
- Bundle size
- Error boundary test results (all 5 tests)
- Security header audit results
- Firestore rules pen test result
- Browser compatibility matrix
- All inline fixes applied (code changes, firebase.json changes)
- Post-fix re-test results
- README changelog verification
- Versioned changelog generated

### docs/ddd-report-v9.42.md (MANDATORY)

Must include:
1. **Hardening baseline:** Master findings table with all domains
2. **Lighthouse scores:** Before and after (if fixes applied)
3. **Error boundary results:** 5 tests with pass/fail/deferred
4. **Security audit:** Headers, Firestore rules, cookies, dependencies
5. **Browser compat:** Matrix of browser × viewport results
6. **Fixes applied this iteration:** What was fixed inline
7. **Deferred findings:** What needs v9.43+
8. **Changelog:** Entry count + versioned copy confirmed
9. **Orchestration Report:** Tools used, workload %, efficacy
10. **Interventions:** Target 0
11. **Claude's Recommendation:** More hardening iterations needed? Or proceed to Phase 10?

### docs/ddd-changelog-v9.42.md (NEW — MANDATORY)

Versioned snapshot of README changelog section.

Delete checkpoint.

---

## Success Criteria

```
[ ] Pre-flight passes (flutter analyze 0 issues, build success)
[ ] v9.41 artifacts archived to docs/archive/
[ ] CLAUDE.md updated to v9.42
[ ] DOMAIN 1 — LIGHTHOUSE:
    [ ] Lighthouse scores recorded (local + prod)
    [ ] Bundle size documented
    [ ] Cache headers assessed (fix if missing)
[ ] DOMAIN 2 — ERROR BOUNDARIES:
    [ ] Firestore offline tested
    [ ] Location denied tested
    [ ] Cookies disabled tested
    [ ] Invalid URL tested
    [ ] Empty search tested
[ ] DOMAIN 3 — SECURITY:
    [ ] Security headers audited (add if missing)
    [ ] Firestore rules pen-tested (writes blocked)
    [ ] Cookie security verified
    [ ] Dependency audit run
[ ] DOMAIN 4 — BROWSER COMPAT:
    [ ] Chrome, Firefox, WebKit tested
    [ ] 4 viewport sizes tested
    [ ] Keyboard navigation tested
[ ] Master findings table produced
[ ] Quick fixes applied + redeployed
[ ] README changelog ≥ 27 entries
[ ] docs/ddd-changelog-v9.42.md generated
[ ] flutter build web: success (post-fix)
[ ] firebase deploy --only hosting: success (post-fix)
[ ] Orchestration report in ddd-report
[ ] Artifacts generated (build + report + changelog)
[ ] Interventions: 0
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb

# Archive v9.41
mv docs/ddd-design-v9.41.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v9.41.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v9.41.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v9.41.md docs/archive/ 2>/dev/null
mv docs/ddd-changelog-v9.41.md docs/archive/ 2>/dev/null

# Place new docs
cp /path/to/ddd-design-v9.42.md docs/
cp /path/to/ddd-plan-v9.42.md docs/

# Update CLAUDE.md (fish shell — use printf or editor, no heredocs)
# Content:
# ---
# # TripleDB — Agent Instructions
#
# ## Current Iteration: 9.42
#
# Hardening audit. Lighthouse + error boundaries + security + browser compat.
#
# Read in order, then execute:
# 1. docs/ddd-design-v9.42.md
# 2. docs/ddd-plan-v9.42.md
#
# ## MCP Servers
# - Playwright MCP: Post-flight + browser compat testing
# - Context7: Flutter/Dart API docs
#
# ## Rules
# - YOLO — code dangerously, never ask permission
# - Self-heal: max 3 attempts, checkpoint for crash recovery
# - MUST produce ddd-build + ddd-report + ddd-changelog
# - POST-FLIGHT: Tier 1 + Tier 3 (hardening audit)
# - README changelog: NEVER truncate, ALWAYS append, ≥ 27 after update
# - Copy changelog to docs/ddd-changelog-v9.42.md
# - FIX INLINE if <15 min. Otherwise defer to v9.43.
#
# ## Agent Permissions
# - ✅ CAN: flutter build web, firebase deploy --only hosting, firebase deploy --only firestore:rules
# - ❌ CANNOT: git add, git commit, git push (Kyle commits at phase boundaries)
# ---

# Commit (Kyle does this manually)
git add .
git commit -m "KT starting 9.42 — hardening audit"

# Launch YOLO
claude --dangerously-skip-permissions
```

Then: `Read CLAUDE.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb

# Review findings table in docs/ddd-report-v9.42.md
# Decide: more hardening (v9.43) or proceed to Phase 10

git add .
git commit -m "KT completed 9.42 — hardening audit baseline established"
git push
```

---

## Decision Gate: After v9.42

Read the report. Check the master findings table.

| Condition | Action |
|-----------|--------|
| All findings P2/P3 (nice-to-have) | Proceed to Phase 10 |
| P0/P1 findings remain (deferred) | Produce v9.43 plan targeting those fixes |
| P0/P1 findings are extensive (>5 items) | Produce v9.43 + v9.44 plans (fix → verify cycle) |

The audit drives the iteration count. No predetermined limit.

---

## Reminder: Changelog Rules

**CRITICAL — READ THIS BEFORE TOUCHING README.md:**

The README changelog currently has 26 entries. After this iteration it must have ≥ 27. The executing agent must:

1. Read the ENTIRE existing changelog section
2. PRESERVE every existing entry verbatim
3. APPEND the v9.42 entry at the bottom
4. Verify the count: `grep -c '^\*\*v' README.md` → ≥ 27
5. **NEW:** Copy the full changelog section to `docs/ddd-changelog-v9.42.md`
6. Post-flight verifies BOTH the README count AND the docs copy exist
