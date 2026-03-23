# TripleDB — Phase 8 Plan v8.23

**Phase:** 8 — Flutter App Build (Second Pass)
**Iteration:** 23 (global), Synthesis (MCP Phase 2)
**Date:** March 2026
**Goal:** Produce the three-file design contract (design-tokens.json, design-brief.md, component-patterns.md) from the v8.22 Discovery scrapes. These three files become the single source of truth for all Implementation decisions in v8.24.

---

## Read Order (CRITICAL)

Gemini MUST read these documents in this exact order before executing:

```
1. docs/ddd-design-v8.22.md  — Architecture, methodology, app context
2. docs/ddd-plan-v8.23.md    — This file. Execution steps.
3. design-brief/ux-analysis.md — Discovery findings from v8.22
4. All 4 scrape files:
   - design-brief/scrapes/ddd-locations/scrape.md
   - design-brief/scrapes/flavortown-usa/scrape.md
   - design-brief/scrapes/food-network-ddd/scrape.md
   - design-brief/scrapes/tv-food-maps/scrape.md
```

Do NOT begin execution until all 6 files have been read. The design doc provides the app architecture and widget tree. The UX analysis provides the design decisions. The scrapes provide the raw evidence. Synthesis without reading all of these produces generic output.

---

## Context

Discovery (v8.22) scraped all 4 reference sites via Playwright and produced:
- 10 screenshots (desktop + mobile for each site, plus scroll captures)
- 4 scrape files with UX pattern analysis
- `ux-analysis.md` with comparison table and 10 design decisions
- Key brand colors: DDD Red `#DD3333`, Orange `#DA7E12`, Dark Surface `#1E1E1E`

This iteration transforms those findings into the three-file design contract that drives Implementation (v8.24).

---

## Autonomy Rules

```
1. AUTO-PROCEED between all steps. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts, then log and skip).
3. MCP RESTRICTION: NO MCP servers allowed this phase. Synthesis works
   from local files only. Do NOT call Firecrawl, Playwright, Context7,
   or Lighthouse.
4. READ the design doc (ddd-design-v8.22.md) FIRST. It contains the app
   architecture, widget tree, data model, and provider structure. Your
   design tokens and component patterns must align with that architecture.
5. NEVER run git write commands (add, commit, push), flutter deploy, or
   firebase deploy. Git read commands (pull, log, status, diff) are allowed.
6. NEVER ask "should I proceed?" — the plan IS the permission.
7. Build on the existing codebase. Do NOT delete or recreate files.
8. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v8.23.md — FULL chronological transcript
   b. docs/ddd-report-v8.23.md — Structured findings with metrics
9. Working directory is always app/ (relative paths resolve from here).
```

---

## Step 0: Pre-Flight

### 0a. Verify Environment

```bash
echo $NODE_EXTRA_CA_CERTS
# Expected: /etc/ssl/certs/Gateway_CA_-_Cloudflare_Managed_G1_3d028af29af87d79a8b3245461f04241.pem

test -f "$NODE_EXTRA_CA_CERTS" && echo "CERT EXISTS" || echo "CERT MISSING"
# Expected: CERT EXISTS
```

If cert is missing or env var is empty, this must be fixed before proceeding. Add to fish config:
```fish
set -x NODE_EXTRA_CA_CERTS "/etc/ssl/certs/Gateway_CA_-_Cloudflare_Managed_G1_3d028af29af87d79a8b3245461f04241.pem"
```

### 0b. Verify Discovery Artifacts Exist

```bash
test -f design-brief/ux-analysis.md && echo "UX analysis: OK" || echo "MISSING"
test -f design-brief/scrapes/ddd-locations/scrape.md && echo "DDD Locations: OK" || echo "MISSING"
test -f design-brief/scrapes/flavortown-usa/scrape.md && echo "Flavortown: OK" || echo "MISSING"
test -f design-brief/scrapes/food-network-ddd/scrape.md && echo "Food Network: OK" || echo "MISSING"
test -f design-brief/scrapes/tv-food-maps/scrape.md && echo "TV Food Maps: OK" || echo "MISSING"
ls design-brief/scrapes/*/desktop.png 2>/dev/null | wc -l
# Expected: 4 (one per site)
```

If any are missing, the Discovery phase was incomplete. Do NOT proceed — log it and stop.

### 0c. Verify Existing App Code

```bash
test -f lib/main.dart && echo "App exists: OK" || echo "MISSING"
test -f lib/theme/app_theme.dart && echo "Theme exists: OK" || echo "MISSING"
test -f assets/data/sample_restaurants.jsonl && echo "Sample data: OK" || echo "MISSING"
```

### 0d. Read All Input Documents

Read these files in order. Log that you read them in the build log:

1. `docs/ddd-design-v8.22.md` — app architecture, widget tree, provider structure
2. `design-brief/ux-analysis.md` — comparison table, 10 design decisions, stolen patterns
3. `design-brief/scrapes/ddd-locations/scrape.md`
4. `design-brief/scrapes/flavortown-usa/scrape.md`
5. `design-brief/scrapes/food-network-ddd/scrape.md`
6. `design-brief/scrapes/tv-food-maps/scrape.md`

**Log in build doc:** "Read [filename] — [one-line summary of what was found]" for each file.

---

## Step 1: Generate design-tokens.json

Create `design-brief/design-tokens.json` — a Flutter ThemeData-compatible token file.

This file must contain ALL of the following sections. Use the v8.22 design decisions as the source.

### 1a. Color Palette

```json
{
  "colors": {
    "primary": "#DD3333",
    "primaryVariant": "#B22222",
    "secondary": "#DA7E12",
    "secondaryVariant": "#C06D0F",
    "background": "#FAFAFA",
    "surface": "#FFFFFF",
    "error": "#B00020",
    "onPrimary": "#FFFFFF",
    "onSecondary": "#FFFFFF",
    "onBackground": "#212121",
    "onSurface": "#212121",
    "onError": "#FFFFFF",
    "dark": {
      "background": "#121212",
      "surface": "#1E1E1E",
      "onBackground": "#E0E0E0",
      "onSurface": "#E0E0E0"
    }
  }
}
```

Adjust these based on what the scrapes actually revealed. The hex codes above are starting points from the v8.22 report — refine them using the actual extracted colors from Food Network and DDD Locations.

### 1b. Typography

```json
{
  "typography": {
    "headingFont": "<font from analysis>",
    "bodyFont": "<font from analysis>",
    "sizes": {
      "h1": 28,
      "h2": 22,
      "h3": 18,
      "body": 16,
      "caption": 12,
      "button": 14
    },
    "weights": {
      "heading": 700,
      "body": 400,
      "caption": 300
    }
  }
}
```

Choose fonts that match the "Modern Flavortown" aesthetic — warm and approachable, not sterile corporate. Reference the Food Network and Flavortown USA typography observations from the scrapes.

### 1c. Spacing and Layout

```json
{
  "spacing": {
    "xs": 4,
    "sm": 8,
    "md": 16,
    "lg": 24,
    "xl": 32,
    "xxl": 48
  },
  "borderRadius": {
    "sm": 4,
    "md": 8,
    "lg": 12,
    "xl": 16,
    "pill": 999
  },
  "breakpoints": {
    "mobile": 600,
    "tablet": 900,
    "desktop": 1200
  }
}
```

### 1d. Coverage / Status Colors (for restaurant cards)

```json
{
  "statusColors": {
    "open": "#4CAF50",
    "closed": "#F44336",
    "unknown": "#9E9E9E"
  }
}
```

### 1e. Map Tokens

```json
{
  "map": {
    "pinColor": "#DD3333",
    "clusterColor": "#DA7E12",
    "selectedPinColor": "#FF5722",
    "mapStyle": "standard"
  }
}
```

**Write the complete design-tokens.json with all sections.** Log the full file contents in the build log.

---

## Step 2: Generate design-brief.md

Create `design-brief/design-brief.md` — the creative direction document.

Must include ALL of the following sections:

### 2a. Project Summary
- What tripleDB.net is (one paragraph)
- Target audience (mobile-first food explorers, DDD fans, road trippers)
- Platform: Flutter Web → Google Play → App Store

### 2b. Aesthetic Direction: "Modern Flavortown"
Define this in specific, actionable terms:
- **Warm, not cool** — DDD red and orange dominate, blue is accent only
- **Playful, not corporate** — rounded corners, emoji where appropriate, fun trivia
- **Bold, not subtle** — Guy Fieri energy in the color choices, not in the typography
- **Clean, not cluttered** — Google-style search simplicity, generous whitespace
- **Mobile-first** — designed for one-hand thumb scrolling, not desktop mouse hovering

### 2c. Color Application Rules
- Where does primary red appear? (AppBar, CTAs, active states)
- Where does secondary orange appear? (accents, badges, highlights)
- Where does dark surface appear? (cards in dark mode, restaurant detail headers)
- What about the light theme? (white/off-white background, subtle grey dividers)

### 2d. Typography Rules
- Heading font and where it's used (page titles, restaurant names, section headers)
- Body font and where it's used (descriptions, ingredients, guy_response quotes)
- Size hierarchy for mobile vs desktop

### 2e. Imagery Direction
- Guy Fieri quotes displayed how? (italic? quote marks? special card?)
- Restaurant images (placeholder strategy until enrichment provides real photos)
- Emoji usage (burger 🍔 for branding, pin 📍 for location, TV 📺 for episodes)

### 2f. Tone of Voice
- Casual, fun, enthusiastic — matches Guy's energy
- Trivia card language style (exclamation marks OK, puns welcome)
- Search placeholder text ("Search dishes, diners, cities...")

---

## Step 3: Generate component-patterns.md

Create `design-brief/component-patterns.md` — widget composition blueprints.

This file maps the design tokens to specific Flutter widgets. Must include ALL of the following:

### 3a. SearchBar Widget
- Google-style centered on home page
- Persistent at top on search results page
- Debounce: 300ms
- Placeholder text: from design brief
- Border radius: from tokens
- Shadow: subtle elevation for depth

### 3b. RestaurantCard Widget
- **Compact (list view):** name, city/state, cuisine, top dish, rating, DDD appearance count
- **Fields shown:** based on ux-analysis.md comparison table decisions
- **Episode badge:** pill shape with season/episode (from Food Network pattern)
- **YouTube button:** "▶ Watch Guy's Visit" with timestamp
- Border radius, padding, elevation from tokens

### 3c. DishCard Widget
- Dish name (bold)
- Description (body text)
- Ingredients (chips or comma-separated)
- Guy's response (italic, quoted, in secondary color)
- YouTube timestamp link
- Padding, spacing from tokens

### 3d. TriviaCard Widget
- Auto-cycling (8s interval)
- Background: light tint of primary color (10% opacity)
- Emoji prefix for visual flavor
- Fade or slide animation between facts
- Border radius from tokens

### 3e. NearbySection Widget
- Header: "📍 Top 3 Near You"
- Geolocation permission prompt style
- Compact RestaurantCard variant with distance display
- "Enable location" button if permission not granted

### 3f. MapWidget
- Pin/marker style: custom icon using primary color
- Cluster style: using secondary color with count
- Preview card on tap: bottom sheet with restaurant summary
- Filter integration: search query filters visible pins

### 3g. RestaurantDetailPage Layout
- Header: name, city/state, cuisine, rating, open/closed status
- Dish section: scrollable list of DishCards
- Visit section: list of VisitCards with YouTube links
- Action bar: Directions button, Website button
- Spacing, section dividers from tokens

### 3h. AppBar / Navigation
- Mobile: bottom navigation bar or persistent top bar?
- Dark mode toggle placement
- Logo placement and size
- Based on ux-analysis.md mobile navigation decision

---

## Step 4: Cross-Reference Validation

Before finalizing, validate that the three files are consistent:

```
For each widget in component-patterns.md:
  - Does it reference specific color tokens from design-tokens.json?
  - Does it reference specific spacing/radius tokens?
  - Does it align with the aesthetic described in design-brief.md?

For each design decision in ux-analysis.md:
  - Is it reflected in at least one of the three output files?
  - If a decision was made to "steal" a pattern, is the pattern documented in component-patterns.md?
```

Log any inconsistencies found and fix them.

---

## Step 5: Generate Artifacts

### docs/ddd-build-v8.23.md (MANDATORY)

Full chronological transcript including:
- Which files were read and a one-line summary of each
- Every design token chosen and why (reference the scrape that informed it)
- Every component pattern defined and which reference site inspired it
- Cross-reference validation results
- File creation confirmations

**Minimum 80 lines.** If shorter, it's incomplete.

### docs/ddd-report-v8.23.md (MANDATORY)

Must include:

1. **Input files read:** list all 6 input files with confirmation
2. **Design tokens summary:**
   | Token Category | Key Values | Source |
   |---|---|---|
   | Primary color | #DD3333 | Food Network DDD |
   | Secondary color | #DA7E12 | DDD Locations |
   | ... | ... | ... |
3. **Typography choices:** font pairing with reasoning
4. **Component count:** how many widget patterns defined
5. **Cross-reference results:** any inconsistencies found and fixed
6. **Design contract completeness:**
   - [ ] design-tokens.json: all sections present (colors, typography, spacing, status, map)
   - [ ] design-brief.md: all sections present (summary, aesthetic, color rules, typography, imagery, tone)
   - [ ] component-patterns.md: all widgets defined (8 minimum)
7. **Comparison to first pass:** what's better this time
8. **Gemini's Recommendation:** Ready for Implementation (v8.24)?
9. **Human interventions:** count (target: 0)

---

## Phase 8.23 Success Criteria

```
[ ] Pre-flight passes:
    [ ] NODE_EXTRA_CA_CERTS set and cert file exists
    [ ] All 4 scrape files present
    [ ] ux-analysis.md present
    [ ] Existing app code present
[ ] All 6 input documents read (confirmed in build log)
[ ] design-brief/design-tokens.json created with ALL sections:
    [ ] Colors (light + dark)
    [ ] Typography (fonts, sizes, weights)
    [ ] Spacing and border radius
    [ ] Status colors
    [ ] Map tokens
[ ] design-brief/design-brief.md created with ALL sections:
    [ ] Project summary
    [ ] Aesthetic direction ("Modern Flavortown" defined)
    [ ] Color application rules
    [ ] Typography rules
    [ ] Imagery direction
    [ ] Tone of voice
[ ] design-brief/component-patterns.md created with ALL widgets:
    [ ] SearchBar
    [ ] RestaurantCard
    [ ] DishCard
    [ ] TriviaCard
    [ ] NearbySection
    [ ] MapWidget
    [ ] RestaurantDetailPage
    [ ] AppBar / Navigation
[ ] Cross-reference validation completed
[ ] ddd-build-v8.23.md generated (80+ lines)
[ ] ddd-report-v8.23.md generated (with design token table)
[ ] No MCP servers used this phase
[ ] Human interventions: 0
```

---

## GEMINI.md Update

Before launching, update `app/GEMINI.md`:

```markdown
# TripleDB App — Agent Instructions

## Current Iteration: 8.23

IMPORTANT: Read documents in this EXACT order before executing:

1. docs/ddd-design-v8.22.md — App architecture, methodology, widget tree
2. docs/ddd-plan-v8.23.md — Synthesis phase execution steps
3. design-brief/ux-analysis.md — Discovery findings and design decisions
4. design-brief/scrapes/ddd-locations/scrape.md
5. design-brief/scrapes/flavortown-usa/scrape.md
6. design-brief/scrapes/food-network-ddd/scrape.md
7. design-brief/scrapes/tv-food-maps/scrape.md

Do NOT begin execution until all 7 files have been read.

## Rules That Never Change
- NEVER run git write commands (add, commit, push) or firebase deploy
- Git read commands (pull, log, status, diff) are allowed
- NEVER ask permission — auto-proceed on EVERY step
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- NO MCP servers allowed this phase — local files only
- MUST produce ddd-build-v8.23.md AND ddd-report-v8.23.md before ending
- Build on existing code — do NOT recreate the app scaffold
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb/app

# Archive v8.22 docs
mv docs/ddd-plan-v8.22.md docs/archive/ 2>/dev/null
mv docs/ddd-build-v8.22.md docs/archive/ 2>/dev/null
mv docs/ddd-report-v8.22.md docs/archive/ 2>/dev/null

# Place new plan (design doc carries forward from v8.22)
# (copy ddd-plan-v8.23.md into docs/)

# Update GEMINI.md
nano GEMINI.md

# Launch
gemini
```

Then type:

```
Read GEMINI.md and execute.
```
