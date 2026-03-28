# TripleDB — Phase 9 Plan v9.38

**Phase:** 9 — App Optimization
**Iteration:** 38 (global)
**Executor:** Claude Code (YOLO mode — `--dangerously-skip-permissions`)
**Date:** March 2026
**Goal:** Debug and fix cookie banner, functionally verify with Playwright playbook, establish iteration-specific post-flight testing as permanent IAO pattern.

---

## Read Order

```
1. docs/ddd-design-v9.38.md — Debug strategy, functional post-flight spec
2. docs/ddd-plan-v9.38.md — This file.
```

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. (YOLO mode enforces this at CLI level)
2. SELF-HEAL: max 3 attempts per error.
3. Git READ only. No write, no deploy.
4. flutter build web and flutter run ARE ALLOWED.
5. FULL PROJECT ACCESS under ~/dev/projects/tripledb/.
6. MANDATORY: ddd-build + ddd-report + README update.
7. CHECKPOINT after every numbered step.
8. POST-FLIGHT: Tier 1 (health) + Tier 2 (functional playbook) must BOTH pass.
9. CHANGELOG: APPEND only, ≥ 23 entries after update.
10. If Playwright MCP unavailable: npm install puppeteer and use it instead.
    Functional testing is NOT optional.
```

---

## Step 0: Read the Full Rendering Chain

Before changing ANYTHING, read every file in the cookie banner rendering path.

```bash
cd ~/dev/projects/tripledb/app
```

Read IN ORDER:

```
1. cat lib/main.dart
   → Find: root widget, ProviderScope

2. cat lib/pages/main_page.dart
   → Find: Stack children, banner conditional, which provider is watched
   → Log the EXACT conditional line

3. cat lib/widgets/cookie_consent_banner.dart
   → Find: widget structure, Positioned, background color, button labels

4. cat lib/providers/cookie_provider.dart
   → Find: hasConsentedProvider definition

5. cat lib/services/cookie_consent_service.dart
   → Find: _readCookie(), hasConsented getter, _ensureInitialized()
```

Document the rendering chain in build log:

```
RENDERING CHAIN:
main.dart → ProviderScope → [root widget]
  → main_page.dart → Stack [
       Scaffold (main content),
       if (CONDITION) → CookieConsentBanner()
     ]
  → CONDITION = !ref.watch(hasConsentedProvider)
  → hasConsentedProvider → cookieServiceProvider.hasConsented
  → CookieConsentService.hasConsented → _readCookie() → document.cookie
```

Identify the failure point from code analysis.

**Write checkpoint after Step 0.**

---

## Step 1: Add Debug Logging + Diagnose

### 1a. Add temporary debug prints at every decision point

```dart
// main_page.dart build():
print('🍪 MAIN_PAGE: hasConsented=$hasConsented');

// cookie_provider.dart:
print('🍪 PROVIDER: service.hasConsented=$result');

// cookie_consent_service.dart hasConsented:
print('🍪 SERVICE: _initialized=$_initialized, _current=$_current');

// cookie_consent_service.dart _readCookie():
print('🍪 READ_COOKIE: raw="${html.document.cookie}"');
```

### 1b. Build and capture console output

```bash
flutter build web
cd ~/dev/projects/tripledb/app
python3 -m http.server 8080 -d build/web &
sleep 3
```

Use Playwright MCP or Puppeteer to navigate and capture console:

```javascript
// Capture approach (Puppeteer if Playwright MCP unavailable):
const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch({headless: true, args: ['--no-sandbox']});
  const context = await browser.createBrowserContext(); // Clean — no cookies
  const page = await context.newPage();
  page.on('console', msg => console.log(`[${msg.type()}] ${msg.text()}`));
  await page.goto('http://localhost:8080', {waitUntil: 'networkidle0', timeout: 30000});
  await new Promise(r => setTimeout(r, 10000));
  const tree = await page.accessibility.snapshot();
  console.log('A11Y TREE:', JSON.stringify(tree, null, 2));
  const cookies = await page.cookies();
  console.log('COOKIES:', JSON.stringify(cookies));
  await browser.close();
})();
```

### 1c. Diagnosis table

| Debug output | Root cause | Fix |
|-------------|-----------|-----|
| `hasConsented=true` + `_current={...}` | Stale cookie | Add validation + reset malformed cookies |
| `hasConsented=false` + banner not in a11y tree | Widget not rendered or wrong z-order | Fix Stack, ensure banner is last child |
| No 🍪 prints | Provider not watched in build() | Wire ref.watch(hasConsentedProvider) |
| `raw=""` + `hasConsented=false` + banner in tree | **Working** — Kyle's browser had stale cookie | Code correct, document for user |

**Log FULL console output in build log.**

**Write checkpoint after Step 1.**

---

## Step 2: Apply the Fix

Based on Step 1 diagnosis, fix the root cause. Also apply these defensive improvements regardless:

### A. Cookie validation

```dart
Map<String, bool>? _readCookie() {
  try {
    final rawCookies = html.document.cookie ?? '';
    for (final cookie in rawCookies.split(';')) {
      final idx = cookie.indexOf('=');
      if (idx < 0) continue;
      final name = cookie.substring(0, idx).trim();
      if (name != _cookieName) continue;
      final value = Uri.decodeComponent(cookie.substring(idx + 1).trim());
      final parsed = Map<String, dynamic>.from(jsonDecode(value));
      if (!parsed.containsKey('essential')) return null; // Invalid structure
      return parsed.map((k, v) => MapEntry(k, v == true));
    }
    return null;
  } catch (e) {
    return null; // Any error → treat as no consent
  }
}
```

### B. Banner MUST be last Stack child with opaque background

```dart
// main_page.dart build():
return Stack(
  children: [
    Scaffold(body: ..., bottomNavigationBar: ...),

    // LAST child = highest z-order = visible on top
    if (!hasConsented)
      Positioned(
        left: 0, right: 0, bottom: 0,
        child: CookieConsentBanner(onAcceptAll: ..., onDecline: ..., onCustomize: ...),
      ),
  ],
);
```

### C. Banner container must be opaque

```dart
Container(
  width: double.infinity,
  color: const Color(0xFF1E1E1E), // OPAQUE dark background
  padding: const EdgeInsets.all(16),
  child: SafeArea(top: false, child: ...),
)
```

### After fix:

```bash
flutter analyze   # 0 errors
flutter build web
```

**Write checkpoint after Step 2.**

---

## Step 3: Remove Debug Logging

```bash
cd ~/dev/projects/tripledb/app
grep -rn "🍪" lib/
# Remove each occurrence
grep -rn "🍪" lib/
# Must return 0 matches
```

Rebuild:
```bash
flutter build web
```

**Write checkpoint after Step 3.**

---

## Step 4: Post-Flight — Tier 1 (Standard Health)

```bash
cd ~/dev/projects/tripledb/app
python3 -m http.server 8080 -d build/web &
SERVER_PID=$!
sleep 3
```

**GATE 1: App Bootstraps**
- Navigate to http://localhost:8080, wait 10s
- Accessibility snapshot has content nodes
- Console: 0 uncaught errors

**GATE 2: Console Clean**
- 0 error-level messages

**GATE 3: Changelog**
```bash
grep -c '^\*\*v' ~/dev/projects/tripledb/README.md
# ≥ 23
```

**Write checkpoint after Step 4.**

---

## Step 5: Post-Flight — Tier 2 (Functional Playbook)

This is the iteration-specific verification. Use Playwright MCP or Puppeteer.

### TEST 1: Cookie Banner Renders for New Visitor (CRITICAL)

```
CONTEXT: Fresh browser context (no cookies)
ACTION:  Navigate to http://localhost:8080
WAIT:    10 seconds
CHECK:   Accessibility snapshot OR page text content
EXPECT:  Contains "cookie" or "consent" or "Accept All" (case-insensitive)
PASS:    Banner text found
FAIL:    No banner text → fix not working
```

### TEST 2: Accept All Dismisses Banner (CRITICAL)

```
CONTEXT: Same session as Test 1
ACTION:  Click the "Accept All" button (by accessibility label or coordinates)
WAIT:    3 seconds
CHECK:   Re-take accessibility snapshot
EXPECT:  "Accept All" no longer in tree (banner dismissed)
PASS:    Banner gone
FAIL:    Banner still visible → dismiss logic broken
```

### TEST 3: Cookie Persists Across Reload (CRITICAL)

```
CONTEXT: Same session as Test 2
ACTION:  Reload page
WAIT:    10 seconds
CHECK:   Accessibility snapshot
EXPECT:  No banner text (cookie remembered consent)
PASS:    Banner stays dismissed
FAIL:    Banner reappeared → cookie not persisting
```

### TEST 4: Cookie Structure Valid

```
CONTEXT: Same session as Test 3
ACTION:  Execute JavaScript: document.cookie
EXPECT:  Contains "tripledb_consent=" with valid JSON
         JSON has essential:true, analytics:true, preferences:true
PASS:    Valid structure
FAIL:    Missing or malformed
```

### TEST 5: Fresh Context Gets Banner Again

```
CONTEXT: NEW browser context (completely fresh)
ACTION:  Navigate to http://localhost:8080
WAIT:    10 seconds
CHECK:   Accessibility snapshot
EXPECT:  Banner text IS present
PASS:    New visitors see banner
FAIL:    Banner missing for new visitors too → fundamental rendering bug
```

### TEST 6: Decline Writes Correct Preferences

```
CONTEXT: NEW browser context
ACTION:  Navigate, wait for banner
ACTION:  Click "Decline"
WAIT:    3 seconds
CHECK:   document.cookie
EXPECT:  tripledb_consent has analytics:false, preferences:false
PASS:    Decline correctly restricts
FAIL:    Wrong cookie values
```

### Playbook Results Table

Log in this format:

| Test | Description | Result | Notes |
|------|------------|--------|-------|
| 1 | Banner renders (new visitor) | PASS/FAIL | |
| 2 | Accept All dismisses | PASS/FAIL | |
| 3 | Cookie persists on reload | PASS/FAIL | |
| 4 | Cookie structure valid | PASS/FAIL | |
| 5 | Fresh context gets banner | PASS/FAIL | |
| 6 | Decline writes correct prefs | PASS/FAIL | |

**Tests 1-3 are CRITICAL. If any fail, fix and re-run the entire playbook (max 3 attempts).**

```bash
kill $SERVER_PID 2>/dev/null
```

**Write checkpoint after Step 5.**

---

## Step 6: Update README

```bash
cd ~/dev/projects/tripledb
```

APPEND this entry (do NOT remove existing):

```markdown
**v9.38 (Phase 9 — Cookie Banner Fix + Functional Post-Flight)**
- **Root cause:** [FILL — exact reason from debug logging]
- **Fix:** [FILL — what code changed]
- **Post-Flight v2:** Two-tier system. Tier 1: health gates. Tier 2: iteration-specific
  Playwright functional playbook with click-verify-confirm actions. Canvas screenshots
  replaced with accessibility tree verification and interactive button clicking.
- Cookie banner verified via 6-test playbook: renders, dismisses, persists, validates cookie
  structure, fresh context, decline path.
```

Verify:
```bash
grep -c '^\*\*v' README.md   # ≥ 23
grep 'v0.7' README.md | head -1
grep 'v9.38' README.md | head -1
```

Update: iteration history, phase 9 status, Pillar 9 description, footer.

**Write checkpoint after Step 6.**

---

## Step 7: Generate Artifacts + Cleanup

### docs/ddd-build-v9.38.md

Full rendering chain, debug output, root cause, code changes, debug removal, Tier 1 results, Tier 2 playbook test-by-test.

### docs/ddd-report-v9.38.md

Root cause + evidence, fix, Tier 1 gates, Tier 2 playbook table, changelog count, interventions, recommendation.

Delete checkpoint.

---

## Success Criteria

```
[ ] Rendering chain documented
[ ] Root cause identified with debug evidence
[ ] Fix applied, debug removed
[ ] flutter analyze: 0 errors
[ ] flutter build web: success
[ ] TIER 1: App loads, console clean, changelog ≥ 23
[ ] TIER 2 PLAYBOOK:
    [ ] Test 1: Banner renders (CRITICAL)
    [ ] Test 2: Accept dismisses (CRITICAL)
    [ ] Test 3: Cookie persists (CRITICAL)
    [ ] Test 4: Cookie valid
    [ ] Test 5: Fresh context gets banner
    [ ] Test 6: Decline correct
[ ] README updated
[ ] Artifacts generated
[ ] Interventions: 0
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb

# Archive
mv docs/ddd-design-v9.37.md docs/archive/ 2>/dev/null
mv docs/ddd-plan-v9.37.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v9.37.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v9.37.md docs/archive/ 2>/dev/null

# Place new docs
cp /path/to/ddd-design-v9.38.md docs/
cp /path/to/ddd-plan-v9.38.md docs/

# Update CLAUDE.md
cat > CLAUDE.md << 'EOF'
# TripleDB — Agent Instructions

## Current Iteration: 9.38

BUG FIX: Cookie banner does not render. Debug, fix, FUNCTIONALLY verify.

1. docs/ddd-design-v9.38.md
2. docs/ddd-plan-v9.38.md

## MCP Servers
- Playwright MCP: REQUIRED for Tier 2 functional testing
- Context7: Flutter docs

## Rules
- NEVER git add/commit/push or firebase deploy
- NEVER ask permission — YOLO mode active
- POST-FLIGHT: Tier 1 + Tier 2 playbook must BOTH pass
- CHANGELOG ≥ 23 entries
- If Playwright MCP unavailable, npm install puppeteer
EOF

# Commit
git add .
git commit -m "KT starting 9.38 — cookie banner fix + functional post-flight"

# Launch Claude Code — YOLO MODE (no permission prompts)
claude --dangerously-skip-permissions
```

Then: `Read CLAUDE.md and execute.`

After completion:
```bash
cd ~/dev/projects/tripledb
git add .
git commit -m "KT completed 9.38 — cookie banner fixed, playbook verified"
git push

cd app && flutter build web && firebase deploy --only hosting
# VERIFY: incognito → tripledb.net → banner → Accept → location prompt
```
