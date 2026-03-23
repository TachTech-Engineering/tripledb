# TripleDB — Phase 8 Plan v8.25

**Phase:** 8 — Flutter App Build (Second Pass)
**Iteration:** 25 (global), QA (MCP Phase 4)
**Date:** March 2026
**Goal:** Full quality assurance against the production build. Playwright visual screenshots at 3 viewport sizes. Lighthouse audit with actual scores. Functional testing of search, trivia, map, and navigation. Fix issues found. No skipping.

---

## Read Order (CRITICAL)

```
1. docs/ddd-design-v8.25.md  — QA specification, targets, known issues
2. docs/ddd-plan-v8.25.md    — This file. Execution steps.
3. design-brief/design-tokens.json — Token values to verify against
4. design-brief/component-patterns.md — Widget specs to verify against
```

Do NOT begin execution until all 4 files have been read. Log confirmation in build log.

---

## Autonomy Rules

```
1. AUTO-PROCEED between all steps. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts, then log and skip).
3. MCP ALLOWED: Playwright (screenshots + interaction), Lighthouse (audits),
   Context7 (Flutter docs if needed for fixes).
   MCP NOT ALLOWED: Firecrawl.
4. Git READ commands allowed. Git WRITE commands forbidden. firebase deploy forbidden.
5. flutter build web and flutter run ARE ALLOWED.
6. QA FIX RULE: If you find a visual or functional issue:
   a. Log the issue with a description and which screenshot/test revealed it
   b. Fix it in the code
   c. Rebuild (flutter build web)
   d. Re-take the screenshot or re-run the test to confirm the fix
   e. Log before/after in the build log
7. Do NOT modify design-tokens.json, design-brief.md, or component-patterns.md.
   If code doesn't match a pattern, fix the code, not the spec.
8. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v8.25.md — FULL transcript with every test, fix, and re-test
   b. docs/ddd-report-v8.25.md — Lighthouse scores, screenshot inventory,
      issue/fix log, final assessment
9. Working directory is always app/.
```

---

## Step 0: Pre-Flight

### 0a. Cert Validation

```bash
echo $NODE_EXTRA_CA_CERTS
test -f "$NODE_EXTRA_CA_CERTS" && echo "CERT OK" || echo "CERT MISSING"
```

### 0b. MCP Verification

```
/mcp
```

Expected: Playwright ✅, Lighthouse ✅, Context7 ✅. Firecrawl status doesn't matter (not used this phase).

### 0c. Production Build

QA MUST run against the production build, NOT the debug dev server. Lighthouse scores on debug are meaningless.

```bash
flutter build web
```

If build fails, fix errors first. Log all fixes.

### 0d. Serve Locally

```bash
cd build/web
python3 -m http.server 8080 &
cd ../..
```

Confirm the app loads at `http://localhost:8080` before proceeding.

### 0e. Read Input Documents

Read all 4 files listed in Read Order. Log confirmation:
```
Read [filename] — [one-line summary]
```

---

## Step 1: Visual Review — Desktop (1440×900)

Take Playwright screenshots of every page at desktop viewport:

### 1a. Home Page (List Tab)

```
Playwright: set viewport 1440x900
Playwright: navigate to http://localhost:8080
Playwright: wait for content to render (2-3 seconds for CanvasKit)
Playwright: screenshot → docs/qa/desktop-home.png
```

**Verify against component patterns:**
- [ ] AppBar shows DDD red (#DD3333) with TripleDB branding
- [ ] Search bar is pill-shaped, centered, with Outfit placeholder
- [ ] Trivia card has primary color tint background, xl radius
- [ ] Nearby section shows "📍 Top 3 Near You" header
- [ ] Bottom nav visible with 3 tabs (Map / List / Explore)

### 1b. Map Tab

```
Playwright: click Map tab (or navigate to /map)
Playwright: wait 3 seconds for map tiles to load
Playwright: screenshot → docs/qa/desktop-map.png
```

**Verify:**
- [ ] Map renders with dark CartoDB tiles
- [ ] Restaurant pins visible in DDD red
- [ ] Near Me FAB visible

### 1c. Explore Tab

```
Playwright: click Explore tab (or navigate to /explore)
Playwright: screenshot → docs/qa/desktop-explore.png
```

**Verify:**
- [ ] Trivia card present (larger format)
- [ ] Top States ranked list rendered
- [ ] Most Visited restaurants section populated
- [ ] Cuisine breakdown visible

### 1d. Search Results

```
Playwright: click search bar
Playwright: type "brisket"
Playwright: wait 500ms (debounce + render)
Playwright: screenshot → docs/qa/desktop-search.png
```

**Verify:**
- [ ] Results appear with restaurant cards
- [ ] Cards have cuisine emoji placeholders
- [ ] Video type badges visible

### 1e. Restaurant Detail

```
Playwright: click on a restaurant card from results
Playwright: wait for page load
Playwright: screenshot → docs/qa/desktop-detail.png
Playwright: scroll down to see dishes/visits
Playwright: screenshot → docs/qa/desktop-detail-scroll.png
```

**Verify:**
- [ ] Hero placeholder with cuisine emoji (64px)
- [ ] Restaurant name in Outfit bold
- [ ] Dish cards with guy_response in italic secondary color
- [ ] Visit cards with video_type badge
- [ ] YouTube timestamp links present

### 1f. Dark Mode

```
Playwright: navigate back to home
Playwright: click dark mode toggle
Playwright: wait 1 second
Playwright: screenshot → docs/qa/desktop-dark.png
```

**Verify:**
- [ ] Background switches to dark surface (#1E1E1E or #121212)
- [ ] Text becomes light (#E0E0E0)
- [ ] Cards render on dark surface
- [ ] Primary red and secondary orange still pop

---

## Step 2: Visual Review — Mobile (375×812)

Repeat key pages at mobile viewport:

### 2a. Home Page

```
Playwright: set viewport 375x812
Playwright: navigate to http://localhost:8080
Playwright: screenshot → docs/qa/mobile-home.png
```

**Verify:**
- [ ] Search bar fills width with appropriate padding
- [ ] Trivia card doesn't overflow
- [ ] Restaurant cards stack vertically
- [ ] Bottom nav is thumb-friendly
- [ ] No horizontal scroll

### 2b. Map Tab

```
Playwright: navigate to map tab
Playwright: screenshot → docs/qa/mobile-map.png
```

**Verify:**
- [ ] Map fills viewport
- [ ] Pins don't overlap excessively
- [ ] FAB doesn't obstruct content

### 2c. Restaurant Detail

```
Playwright: navigate to a restaurant detail
Playwright: screenshot → docs/qa/mobile-detail.png
Playwright: scroll down
Playwright: screenshot → docs/qa/mobile-detail-scroll.png
```

**Verify:**
- [ ] No text overflow (restaurant names, dish names, guy_response)
- [ ] Touch targets are ≥48px
- [ ] YouTube links are tappable
- [ ] Content fits within viewport width

---

## Step 3: Visual Review — Tablet (768×1024)

Spot-check the home page and detail page at tablet size:

```
Playwright: set viewport 768x1024
Playwright: navigate to http://localhost:8080
Playwright: screenshot → docs/qa/tablet-home.png
Playwright: navigate to restaurant detail
Playwright: screenshot → docs/qa/tablet-detail.png
```

**Verify:**
- [ ] Layout adapts (not just stretched mobile or cramped desktop)
- [ ] Cards may show in 2-column grid if breakpoint supports it
- [ ] No awkward whitespace

---

## Step 4: Functional Testing

Flutter CanvasKit limits what Playwright can interact with directly. Use coordinate-based clicks and URL navigation for testing.

### 4a. Search Functionality

```
Playwright: navigate to http://localhost:8080
Playwright: type in search area "barbecue"
Playwright: wait 500ms
Playwright: screenshot → docs/qa/func-search-barbecue.png
```

Does the results list update? Are results relevant (BBQ restaurants)?

### 4b. Trivia Cycling

```
Playwright: navigate to home page
Playwright: screenshot → docs/qa/func-trivia-1.png
Playwright: wait 9 seconds
Playwright: screenshot → docs/qa/func-trivia-2.png
```

Compare the two screenshots. The trivia text should have changed.

### 4c. Dark Mode Toggle

```
Playwright: navigate to home
Playwright: screenshot → docs/qa/func-light.png
Playwright: click dark mode toggle
Playwright: screenshot → docs/qa/func-dark.png
```

Compare: background, text color, card surfaces should all change.

### 4d. Navigation Tabs

```
Playwright: click Map tab → screenshot → docs/qa/func-tab-map.png
Playwright: click List tab → screenshot → docs/qa/func-tab-list.png
Playwright: click Explore tab → screenshot → docs/qa/func-tab-explore.png
```

All 3 tabs should render distinct content.

### 4e. Deep Link

```
Playwright: navigate to http://localhost:8080/#/restaurant/r_[any valid id from sample data]
Playwright: screenshot → docs/qa/func-deeplink.png
```

Should load the restaurant detail page directly.

---

## Step 5: Lighthouse Audit

**CRITICAL: Run against production build (localhost:8080), NOT debug server.**

```
Lighthouse: audit http://localhost:8080
```

Record ALL four scores:
- Performance: target ≥80
- Accessibility: target ≥90
- Best Practices: target ≥90
- SEO: target ≥90

Also record:
- First Contentful Paint (FCP)
- Largest Contentful Paint (LCP)
- Total Blocking Time (TBT)
- Cumulative Layout Shift (CLS)

If any score is below the "acceptable" threshold (Performance ≥60, others ≥80):
1. Log the specific failures Lighthouse reports
2. Fix the top 3 most impactful issues
3. Rebuild and re-run Lighthouse
4. Log before/after scores

### Common Flutter Web Lighthouse Issues and Fixes

- **Performance low:** CanvasKit init is heavy. Ensure `flutter build web --release` was used. Add `<meta>` viewport tag in `web/index.html`.
- **Accessibility low:** Flutter CanvasKit gates semantic tree behind opt-in. This is a platform limitation. Score ≥80 is realistic; 100 is not achievable with CanvasKit.
- **SEO low:** Update `web/index.html` with proper `<title>`, `<meta name="description">`, and `<meta property="og:...">` tags.
- **Best Practices low:** Check for console errors, mixed content, or missing HTTPS (localhost is fine for testing).

---

## Step 6: Fix Issues Found

For EVERY issue found in Steps 1-5:

1. **Log the issue:** which step, which screenshot, what's wrong
2. **Categorize:** visual (wrong color/spacing), functional (broken interaction), performance (Lighthouse flag), accessibility (contrast/semantic)
3. **Fix it:** make the code change
4. **Rebuild:** `flutter build web`
5. **Re-verify:** retake the screenshot or re-run the test
6. **Log before/after:** in the build log

Prioritize fixes by impact:
1. Functional breaks (search doesn't work, pages don't load)
2. Mobile overflow/text truncation
3. Lighthouse accessibility failures
4. Visual inconsistencies with design tokens
5. Minor polish

---

## Step 7: Final Build Verification

After all fixes are applied:

```bash
flutter analyze
flutter build web
```

Both must pass cleanly. Log the output.

---

## Step 8: Stop Local Server

```bash
# Kill the python http server
pkill -f "python3 -m http.server 8080"
```

---

## Step 9: Generate Artifacts

### docs/ddd-build-v8.25.md (MANDATORY)

Full chronological transcript including:
- All 4 input files read with summaries
- Production build command and output
- Every Playwright command with viewport size and target URL
- Every screenshot taken with file path
- Every verification checklist with pass/fail per item
- Lighthouse full output (all 4 scores + core web vitals)
- Every issue found with description
- Every fix applied with before/after
- Re-verification results after fixes
- Final build verification output
- **Minimum 150 lines.** This is the most screenshot/test-heavy iteration.

### docs/ddd-report-v8.25.md (MANDATORY)

Must include:

1. **Screenshot inventory:**
   | Screenshot | Viewport | Page | Path |
   |---|---|---|---|
   | Desktop Home | 1440×900 | Home | docs/qa/desktop-home.png |
   | ... | ... | ... | ... |

2. **Visual verification results:**
   | Check | Desktop | Mobile | Tablet |
   |---|---|---|---|
   | AppBar DDD red | ✅/❌ | ✅/❌ | ✅/❌ |
   | Search bar pill shape | ✅/❌ | ✅/❌ | — |
   | Trivia card styling | ✅/❌ | ✅/❌ | — |
   | ... | ... | ... | ... |

3. **Functional test results:**
   | Test | Result | Notes |
   |---|---|---|
   | Search returns results | ✅/❌ | |
   | Trivia cycles (8s) | ✅/❌ | |
   | Dark mode toggle | ✅/❌ | |
   | Tab navigation | ✅/❌ | |
   | Deep link loads | ✅/❌ | |

4. **Lighthouse scores:**
   | Category | Score | Target | Status |
   |---|---|---|---|
   | Performance | XX | ≥80 | ✅/❌ |
   | Accessibility | XX | ≥90 | ✅/❌ |
   | Best Practices | XX | ≥90 | ✅/❌ |
   | SEO | XX | ≥90 | ✅/❌ |

   Core Web Vitals: FCP, LCP, TBT, CLS

5. **Issues found and fixed:**
   | # | Issue | Category | Fix | Re-verified |
   |---|---|---|---|---|
   | 1 | ... | visual/functional/perf/a11y | ... | ✅/❌ |

6. **Issues deferred (not fixed this iteration):**
   - Directions/Website buttons no-op (awaiting enrichment data)
   - YouTube links untestable without real video IDs in sample data
   - Geolocation untestable in automated Playwright (requires user permission)

7. **Design token compliance:** X/Y tokens verified in visual output
8. **Component pattern compliance:** X/8 patterns visually confirmed
9. **Comparison to first pass QA (v8.21):** what's better, what's the same
10. **Gemini's Recommendation:** App ready for Firestore wiring (v8.26)?
11. **Human interventions:** count (target: 0)

---

## Phase 8.25 Success Criteria

```
[ ] Pre-flight passes:
    [ ] NODE_EXTRA_CA_CERTS set and cert exists
    [ ] Playwright, Lighthouse, Context7 MCP green
    [ ] flutter build web succeeds
    [ ] localhost:8080 serves the app
[ ] All 4 input documents read (confirmed in build log)
[ ] Desktop screenshots (1440×900):
    [ ] Home, Map, Explore, Search, Detail, Detail-scroll, Dark mode
[ ] Mobile screenshots (375×812):
    [ ] Home, Map, Detail, Detail-scroll
[ ] Tablet screenshots (768×1024):
    [ ] Home, Detail
[ ] Functional tests:
    [ ] Search returns results
    [ ] Trivia cycles (screenshot comparison)
    [ ] Dark mode toggle works
    [ ] All 3 nav tabs render distinct content
    [ ] Deep link loads correct restaurant
[ ] Lighthouse audit completed (not skipped):
    [ ] Performance score recorded
    [ ] Accessibility score recorded
    [ ] Best Practices score recorded
    [ ] SEO score recorded
    [ ] Core Web Vitals recorded
[ ] Issues found are logged with category
[ ] Fixes applied, rebuilt, and re-verified
[ ] Final flutter analyze: 0 errors
[ ] Final flutter build web: success
[ ] Screenshot count: ≥15
[ ] ddd-build-v8.25.md generated (150+ lines)
[ ] ddd-report-v8.25.md generated (with all tables filled)
[ ] Human interventions: 0
```

---

## GEMINI.md Content

```markdown
# TripleDB App — Agent Instructions

## Current Iteration: 8.25

IMPORTANT: Read documents in this EXACT order before executing:

1. docs/ddd-design-v8.25.md — QA specification, targets, known issues
2. docs/ddd-plan-v8.25.md — QA execution steps
3. design-brief/design-tokens.json — Token values to verify against
4. design-brief/component-patterns.md — Widget specs to verify against

Do NOT begin execution until all 4 files have been read.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden
- flutter build and flutter run ARE ALLOWED
- NEVER ask permission — auto-proceed on EVERY step
- MCP allowed: Playwright, Lighthouse, Context7. NOT Firecrawl.
- MUST produce ddd-build-v8.25.md AND ddd-report-v8.25.md before ending
- QA fixes allowed — fix code issues, log before/after
- Do NOT modify design tokens or component patterns
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb/app

# Archive v8.24 docs
mv docs/ddd-plan-v8.24.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v8.24.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v8.24.md docs/archive/ 2>/dev/null

# Place new docs
# (copy ddd-design-v8.25.md and ddd-plan-v8.25.md into docs/)

# Update GEMINI.md
nano GEMINI.md

# Launch
gemini
```

Then type:

```
Read GEMINI.md and execute.
```
