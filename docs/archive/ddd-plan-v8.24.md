# TripleDB — Phase 8 Plan v8.24

**Phase:** 8 — Flutter App Build (Second Pass)
**Iteration:** 24 (global), Implementation (MCP Phase 3)
**Date:** March 2026
**Goal:** Fix 4 identified gaps in the design contract, then apply the complete design tokens and component patterns to the existing tripledb.net codebase. Every code change must trace back to a specific token or pattern.

---

## Read Order (CRITICAL)

Gemini MUST read these documents in this exact order before executing:

```
1. docs/ddd-design-v8.24.md  — Architecture, gap analysis, target widget tree
2. docs/ddd-plan-v8.24.md    — This file. Execution steps.
3. design-brief/design-tokens.json — Tokens to apply
4. design-brief/design-brief.md — Aesthetic rules
5. design-brief/component-patterns.md — Widget blueprints
```

Do NOT begin execution until all 5 files have been read. Log confirmation of each in the build log.

---

## Autonomy Rules

```
1. AUTO-PROCEED between all steps. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts, then log and skip).
3. MCP: Context7 ALLOWED for Flutter/Dart/Riverpod API docs.
   Firecrawl, Playwright, Lighthouse NOT allowed this phase.
4. Git READ commands allowed (pull, log, status, diff, show).
   Git WRITE commands forbidden (add, commit, push, checkout, branch).
   firebase deploy forbidden.
5. flutter build web and flutter run ARE ALLOWED for testing.
6. NEVER ask "should I proceed?" — the plan IS the permission.
7. EVERY code change must trace to a design token or component pattern.
   Log the mapping (e.g., "Set AppBar color to #DD3333 — tokens.colors.primary").
8. Build on existing code. Do NOT delete lib/ or recreate the scaffold.
9. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v8.24.md — FULL transcript, every file modified, every token applied
   b. docs/ddd-report-v8.24.md — Metrics, file change inventory, token coverage
10. Working directory is always app/ (relative paths resolve from here).
```

---

## Step 0: Pre-Flight

### 0a. Cert Validation

```bash
echo $NODE_EXTRA_CA_CERTS
test -f "$NODE_EXTRA_CA_CERTS" && echo "CERT OK" || echo "CERT MISSING — fix fish config"
```

### 0b. Design Contract Validation

```bash
test -f design-brief/design-tokens.json && echo "Tokens: OK" || echo "MISSING"
test -f design-brief/design-brief.md && echo "Brief: OK" || echo "MISSING"
test -f design-brief/component-patterns.md && echo "Patterns: OK" || echo "MISSING"
```

### 0c. Codebase Health

```bash
flutter pub get
flutter analyze
```

If `flutter analyze` shows errors, fix them before proceeding. Log all fixes in the build log.

### 0d. Read All Input Documents

Read the 5 files listed in Read Order above. For each file, log:
```
Read [filename] — [one-line summary of key content]
```

### 0e. Audit Current Codebase

Before changing anything, document the current state:

```bash
# List all Dart files
find lib/ -name "*.dart" | sort

# Check current theme
head -30 lib/theme/app_theme.dart

# Check current providers
ls lib/providers/

# Check current widgets
find lib/widgets/ -name "*.dart" | sort

# Check current pages
find lib/pages/ -name "*.dart" | sort
```

Log the output. This is the baseline for the change inventory in the report.

---

## Step 1: Gap Fix 1 — Add Elevation Tokens

Open `design-brief/design-tokens.json` and add the elevation section:

```json
"elevation": {
  "none": 0,
  "sm": 1,
  "md": 2,
  "lg": 4,
  "xl": 8
}
```

Update `design-brief/component-patterns.md` to reference specific elevation tokens:
- SearchBar: `elevation.sm` (subtle)
- RestaurantCard: `elevation.md` (distinct)
- TriviaCard: `elevation.sm`
- MapPreviewCard (bottom sheet): `elevation.lg`

**Log:** "Gap Fix 1 complete — elevation tokens added to design-tokens.json and referenced in component-patterns.md"

---

## Step 2: Gap Fix 2 — Episode Badges Use video_type

Open `design-brief/component-patterns.md` and update the RestaurantCard episode badge:

**Change from:**
> A clean pill-shaped tag displaying the Season and Episode (e.g., "S12 | E4")

**Change to:**
> A clean pill-shaped tag displaying the video type (e.g., "Compilation", "Full Episode", "Marathon") and total DDD appearance count (e.g., "5 visits"). If season/episode can be parsed from `video_title` (e.g., "Season 12, Episode 4" in the title string), display that as a bonus. The badge must work with `video_type` alone.

**Log:** "Gap Fix 2 complete — episode badges now use video_type from data model"

---

## Step 3: Gap Fix 3 — Replace "Saved" Tab with "Explore"

Open `design-brief/component-patterns.md` and update Section 8 (AppBar / Navigation):

**Change from:**
> Three tabs: "Map", "List", "Saved"

**Change to:**
> Three tabs: "Map", "List", "Explore". The Explore tab shows trivia (larger format TriviaCard), top states (ranked list from data), most-visited restaurants (5+ DDD appearances), and cuisine breakdown (category counts). All computed from the loaded restaurant data — no additional API calls needed.

**Log:** "Gap Fix 3 complete — Saved tab replaced with Explore tab"

---

## Step 4: Gap Fix 4 — Image Placeholder Strategy

Open `design-brief/component-patterns.md` and add to the RestaurantCard section:

> **Placeholder Image:** Until enrichment provides real photos, display a colored container with a food emoji based on `cuisine_type`:
> - 🍕 Italian/Pizza
> - 🍔 American/Burgers
> - 🌮 Mexican/Tex-Mex
> - 🍖 BBQ/Barbecue
> - 🍣 Japanese/Sushi
> - 🍜 Asian/Noodles
> - 🥘 Soul Food/Southern
> - 🍽️ Default/Other
>
> The container background uses a muted tint of the primary color. The emoji renders at 32px centered. This ensures every card has visual weight even without photos.

Also update the RestaurantDetailPage hero header:
> **Hero Placeholder:** Same emoji strategy but larger (64px emoji, full-width colored container with restaurant name overlaid in white Outfit bold).

**Log:** "Gap Fix 4 complete — placeholder image strategy defined using cuisine-based emoji"

---

## Step 5: Apply Theme (app_theme.dart)

Now apply the design tokens to the Flutter ThemeData. Open `lib/theme/app_theme.dart` and rewrite using the token values.

### What to apply:

| Token | Flutter Property |
|-------|-----------------|
| `colors.primary` (#DD3333) | `ColorScheme.primary` |
| `colors.primaryVariant` (#B22222) | `ColorScheme.primaryContainer` |
| `colors.secondary` (#DA7E12) | `ColorScheme.secondary` |
| `colors.background` (#F9F9F9) | `ColorScheme.surface` (Flutter 3.x) |
| `colors.surface` (#FFFFFF) | `ColorScheme.surfaceContainerLowest` |
| `colors.error` (#B00020) | `ColorScheme.error` |
| `colors.onPrimary` (#FFFFFF) | `ColorScheme.onPrimary` |
| `colors.onBackground` (#212121) | `ColorScheme.onSurface` |
| Dark theme equivalents | Separate `ThemeData.dark()` |
| `typography.headingFont` (Outfit) | `textTheme` headings via `google_fonts` |
| `typography.bodyFont` (Inter) | `textTheme` body via `google_fonts` |
| All font sizes | `textTheme` style definitions |

**Use `google_fonts` package:**
```dart
import 'package:google_fonts/google_fonts.dart';

final headingStyle = GoogleFonts.outfit(fontWeight: FontWeight.w700);
final bodyStyle = GoogleFonts.inter(fontWeight: FontWeight.w400);
```

Create BOTH light and dark ThemeData. Log every token→property mapping in the build log.

After applying, verify:
```bash
flutter analyze
```

---

## Step 6: Apply Component Patterns to Widgets

For EACH widget in `component-patterns.md`, update the corresponding Dart file. Work through them in order:

### 6a. SearchBar
- File: `lib/widgets/search/search_bar.dart` (or equivalent)
- Apply: pill border radius (999px), elevation.sm, Outfit placeholder text, 300ms debounce
- Log token mappings

### 6b. RestaurantCard
- File: `lib/widgets/restaurant/restaurant_card.dart` (or equivalent)
- Apply: lg border radius (12px), md padding (16px), elevation.md, cuisine emoji placeholder, video_type badge in secondary color
- Log token mappings

### 6c. DishCard
- File: `lib/widgets/restaurant/dish_card.dart` (or equivalent)
- Apply: guy_response in italic Inter + secondary color, ingredient chips, YouTube timestamp link
- Log token mappings

### 6d. TriviaCard
- File: `lib/widgets/trivia/trivia_card.dart` (or equivalent)
- Apply: primary color 10% tint background, xl border radius (16px), 💡 emoji prefix, 8s cycle
- Log token mappings

### 6e. NearbySection
- File: `lib/widgets/restaurant/nearby_section.dart` (or equivalent)
- Apply: Outfit bold header, compact card variant with distance, location permission prompt
- Log token mappings

### 6f. MapWidget
- File: `lib/widgets/map/restaurant_map.dart` (or equivalent)
- Apply: dark map style, red pins (#DD3333), orange clusters (#DA7E12), bottom sheet preview on tap
- Log token mappings

### 6g. RestaurantDetailPage
- File: `lib/pages/restaurant_detail_page.dart` (or equivalent)
- Apply: hero placeholder (64px emoji), lg spacing (24px), dish section, visit section with video_type badges, YouTube deep links, action bar
- Log token mappings

### 6h. Navigation (Bottom Bar + AppBar)
- File: `lib/main.dart` or page scaffold
- Apply: 3-tab bottom nav (Map / List / Explore), AppBar with logo + dark mode toggle
- Create ExplorePage if it doesn't exist
- Log token mappings

---

## Step 7: Create ExplorePage

If `lib/pages/explore_page.dart` doesn't exist, create it:

```
ExplorePage
├── TriviaCard (larger format, same 8s cycle)
├── TopStatesSection
│   └── Ranked list of states by restaurant count (computed from data)
├── MostVisitedSection
│   └── Restaurants with 3+ DDD appearances (sorted by visit count)
└── CuisineBreakdownSection
    └── Category counts with cuisine emoji (computed from data)
```

Use existing providers or create simple computed providers that derive from the restaurant data.

---

## Step 8: Verify Build

```bash
flutter analyze
flutter build web
```

If `flutter analyze` passes with 0 issues and `flutter build web` succeeds:

```bash
cd build/web
python3 -m http.server 8080
```

Open in browser, visually confirm:
- [ ] AppBar shows DDD red (#DD3333)
- [ ] Search bar is pill-shaped with Outfit placeholder text
- [ ] Trivia card has primary tint background
- [ ] Restaurant cards have cuisine emoji placeholders
- [ ] Bottom nav shows Map / List / Explore tabs
- [ ] Dark mode toggle works
- [ ] Video type badges appear on restaurant cards

Log what you see. Take note of any visual issues for QA (v8.25).

Stop the server after verification.

---

## Step 9: Generate Artifacts

### docs/ddd-build-v8.24.md (MANDATORY)

Full chronological transcript including:
- All 5 input files read with summaries
- Gap fix changes (4 fixes with exact edits)
- Codebase audit (baseline file listing)
- Every token→Flutter property mapping applied
- Every file modified with what changed
- flutter analyze output
- flutter build web output
- Visual verification results
- **Minimum 120 lines.** This is a code-heavy iteration.

### docs/ddd-report-v8.24.md (MANDATORY)

Must include:

1. **Gap fixes applied:** 4/4 with description
2. **Files modified:** complete inventory
   | File | Changes | Token/Pattern Source |
   |------|---------|---------------------|
   | lib/theme/app_theme.dart | Full rewrite from tokens | design-tokens.json |
   | lib/widgets/search/... | Pill shape, elevation | component-patterns §1 |
   | ... | ... | ... |
3. **Token coverage:** how many tokens from design-tokens.json are applied in code
4. **Component coverage:** how many of 8 component patterns are implemented
5. **New files created:** list any new files (e.g., explore_page.dart)
6. **Build status:** flutter analyze result + flutter build web result
7. **Visual verification:** checklist with pass/fail for each item
8. **Known issues:** anything that needs QA attention in v8.25
9. **Gemini's Recommendation:** Ready for QA (v8.25)?
10. **Human interventions:** count (target: 0)

---

## Phase 8.24 Success Criteria

```
[ ] Pre-flight passes:
    [ ] NODE_EXTRA_CA_CERTS set and cert exists
    [ ] All 3 design contract files present
    [ ] flutter pub get succeeds
    [ ] flutter analyze returns 0 errors
[ ] All 5 input documents read (confirmed in build log)
[ ] Gap fixes applied:
    [ ] Elevation tokens added to design-tokens.json
    [ ] Episode badges use video_type (not season/episode)
    [ ] "Saved" tab replaced with "Explore"
    [ ] Image placeholder strategy defined (cuisine emoji)
[ ] Theme applied:
    [ ] Light ThemeData created from tokens
    [ ] Dark ThemeData created from tokens
    [ ] Outfit headings via google_fonts
    [ ] Inter body via google_fonts
[ ] Components updated (8 total):
    [ ] SearchBar — pill shape, debounce, elevation
    [ ] RestaurantCard — emoji placeholder, video_type badge, elevation
    [ ] DishCard — guy_response italic, YouTube link
    [ ] TriviaCard — primary tint, xl radius, 8s cycle
    [ ] NearbySection — distance display, location prompt
    [ ] MapWidget — dark style, red pins, orange clusters
    [ ] RestaurantDetailPage — hero placeholder, dish/visit sections
    [ ] Navigation — 3-tab bottom bar (Map/List/Explore)
[ ] ExplorePage created with trivia, top states, most visited, cuisine breakdown
[ ] flutter analyze: 0 errors
[ ] flutter build web: success
[ ] Visual verification: all items pass
[ ] ddd-build-v8.24.md generated (120+ lines)
[ ] ddd-report-v8.24.md generated (with file inventory and token coverage)
[ ] Human interventions: 0
```

---

## GEMINI.md Content

```markdown
# TripleDB App — Agent Instructions

## Current Iteration: 8.24

IMPORTANT: Read documents in this EXACT order before executing:

1. docs/ddd-design-v8.24.md — Architecture, gap analysis, target widget tree
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

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb/app

# Archive v8.23 plan (keep design-brief files in place — they're the contract)
mv docs/ddd-plan-v8.23.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v8.23.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v8.23.md docs/archive/ 2>/dev/null

# Place new docs
# (copy ddd-design-v8.24.md and ddd-plan-v8.24.md into docs/)

# Update GEMINI.md
nano GEMINI.md

# Launch
gemini
```

Then type:

```
Read GEMINI.md and execute.
```
