# TripleDB — Phase 8 Plan v8.22

**Phase:** 8 — Flutter App Build (Second Pass)
**Iteration:** 22 (global), Discovery Redo (MCP Phase 1)
**Date:** March 2026
**Goal:** Rescrape all 4 reference sites with cookie workarounds. Produce complete UX analysis with comparison table and design decisions. Generate build log and report artifacts.

---

## Context

This is a REDO of the Discovery phase. The first pass (v8.17) had cookie consent walls blocking Firecrawl on several sites, resulting in incomplete design intelligence. The app exists and is live at tripledb.net — this iteration improves the design foundation, it doesn't rebuild the app.

---

## Autonomy Rules

```
1. AUTO-PROCEED between all steps. NEVER ask permission.
2. SELF-HEAL: diagnose → fix → re-run (max 3 attempts per error, then
   log and skip).
3. MCP RESTRICTION: Only Firecrawl and Playwright are allowed this phase.
   Do NOT use Context7 or Lighthouse. Do NOT modify any Flutter code.
4. COOKIE WORKAROUND: If Firecrawl returns a cookie wall or empty content:
   a. Use Playwright to navigate to the URL
   b. Look for and click any "Accept" / "Accept Cookies" / "I agree" button
   c. Wait 3 seconds for full render
   d. Take desktop (1440x900) and mobile (375x812) screenshots
   e. Use Playwright's accessibility snapshot to extract page text/structure
   f. Log what worked and what didn't in the build log
5. Do NOT skip any site. Get whatever you can — partial data is valuable.
6. NEVER run git, flutter, or firebase commands.
7. MANDATORY ARTIFACTS before session ends:
   a. docs/ddd-build-v8.22.md — FULL chronological transcript of every
      command, every MCP call, every response, every error, every fix.
      This is not a summary. It is a log.
   b. docs/ddd-report-v8.22.md — Structured findings with metrics.
8. Working directory is always app/ (relative paths resolve from here).
```

---

## Step 0: Pre-Flight

Verify MCP servers:

```
/mcp
```

Expected: Firecrawl ✅, Playwright ✅. If either is red, troubleshoot:
- Firecrawl TLS error → check `NODE_EXTRA_CA_CERTS` or disable VPN temporarily
- Playwright not found → `npx -y @playwright/mcp@latest` should auto-install

**Log the MCP status in the build log.**

---

## Step 1: Scrape Site 1 — DDD Locations

**URL:** `https://dinersdriveinsdiveslocations.com`
**Extract:** Search/filter UX, state browsing, restaurant card layout, mobile nav

### 1a. Firecrawl Attempt

```
Firecrawl: scrape https://dinersdriveinsdiveslocations.com
```

**Log the response** — did it return content or a cookie wall?

If content returned: save to `design-brief/scrapes/ddd-locations/scrape.md`

If cookie wall or empty: proceed to 1b.

### 1b. Playwright Fallback (if needed)

```
Playwright: navigate to https://dinersdriveinsdiveslocations.com
Playwright: look for cookie/consent button and click it
Playwright: wait 3 seconds
Playwright: screenshot at 1440x900 → design-brief/scrapes/ddd-locations/desktop.png
Playwright: screenshot at 375x812 → design-brief/scrapes/ddd-locations/mobile.png
Playwright: accessibility snapshot → save text to design-brief/scrapes/ddd-locations/playwright-extract.md
```

### 1c. Also Scrape a State Page

Try to scrape a state-specific page (California, Texas, or similar):

```
Firecrawl: scrape https://dinersdriveinsdiveslocations.com/california
```

If blocked, use Playwright on the same URL.

### 1d. Screenshots (if not already taken in 1b)

```
Playwright: screenshot https://dinersdriveinsdiveslocations.com at 1440x900 → desktop.png
Playwright: screenshot https://dinersdriveinsdiveslocations.com at 375x812 → mobile.png
```

### 1e. Document UX Patterns

In the scrape.md or playwright-extract.md, note:
- Search implementation (text input? dropdowns? faceted filters?)
- Restaurant card fields (name, city, cuisine, rating, image?)
- Navigation structure (state list? map? tabs?)
- Color palette (primary, secondary, accent colors — note hex codes if visible)
- Typography (serif? sans-serif? font sizes?)
- Mobile approach (responsive? separate mobile site? burger menu?)

---

## Step 2: Scrape Site 2 — Flavortown USA

**URL:** `https://flavortownusa.com`
**Extract:** Directory layout, "most visited" patterns, Guy Fieri brand energy

### 2a. Firecrawl Attempt

```
Firecrawl: scrape https://flavortownusa.com
```

Log response. If blocked → 2b.

### 2b. Playwright Fallback

```
Playwright: navigate to https://flavortownusa.com
Playwright: handle cookie consent if present
Playwright: screenshot at 1440x900 → design-brief/scrapes/flavortown-usa/desktop.png
Playwright: screenshot at 375x812 → design-brief/scrapes/flavortown-usa/mobile.png
Playwright: accessibility snapshot → design-brief/scrapes/flavortown-usa/playwright-extract.md
```

### 2c. Scroll and Capture

DDD fan sites often have long pages. Take additional screenshots at scroll positions:

```
Playwright: scroll down 800px, screenshot → design-brief/scrapes/flavortown-usa/desktop-scroll1.png
Playwright: scroll down 800px more, screenshot → design-brief/scrapes/flavortown-usa/desktop-scroll2.png
```

### 2d. Document UX Patterns

- "Most visited states" — how is it visualized? (map? ranked list? bar chart?)
- Restaurant listing format (cards? table? list?)
- Fun/trivia elements (does the site have any?)
- Dataset navigation (pagination? infinite scroll? state filter?)
- Brand energy (colors, imagery, tone — Guy Fieri vibes?)

---

## Step 3: Scrape Site 3 — Food Network DDD

**URL:** `https://www.foodnetwork.com/shows/diners-drive-ins-and-dives`
**Extract:** Official DDD branding, color palette, typography, episode card layout

### 3a. Firecrawl Attempt

```
Firecrawl: scrape https://www.foodnetwork.com/shows/diners-drive-ins-and-dives
```

Log response. Food Network is likely to have aggressive cookie/consent walls.

### 3b. Playwright Fallback

```
Playwright: navigate to https://www.foodnetwork.com/shows/diners-drive-ins-and-dives
Playwright: handle cookie consent
Playwright: screenshot at 1440x900 → design-brief/scrapes/food-network-ddd/desktop.png
Playwright: screenshot at 375x812 → design-brief/scrapes/food-network-ddd/mobile.png
Playwright: accessibility snapshot → design-brief/scrapes/food-network-ddd/playwright-extract.md
```

### 3c. Document UX Patterns

- **Official DDD color palette** — this is the authoritative brand reference
  (reds, yellows, oranges — note exact hex codes from CSS if extractable)
- Typography choices (heading font, body font, sizes)
- Episode/video card layout (thumbnail, title, description, duration)
- How restaurant info is presented within show context
- Header/nav treatment
- Guy Fieri imagery style (action shots? posed? candid?)

---

## Step 4: Scrape Site 4 — TV Food Maps

**URL:** `https://www.tvfoodmaps.com`
**Extract:** Map integration, filter by show/cuisine, restaurant pin clustering

### 4a. Firecrawl Attempt

```
Firecrawl: scrape https://www.tvfoodmaps.com
```

Log response. Also try a DDD-filtered page if URL structure allows:

```
Firecrawl: scrape https://www.tvfoodmaps.com/shows/diners-drive-ins-and-dives (or similar)
```

### 4b. Playwright Fallback

```
Playwright: navigate to https://www.tvfoodmaps.com
Playwright: handle cookie consent
Playwright: screenshot at 1440x900 → design-brief/scrapes/tv-food-maps/desktop.png
Playwright: screenshot at 375x812 → design-brief/scrapes/tv-food-maps/mobile.png
Playwright: accessibility snapshot → design-brief/scrapes/tv-food-maps/playwright-extract.md
```

### 4c. Map-Specific Capture

If the site has a map view, capture it specifically:

```
Playwright: navigate to map view (if separate URL)
Playwright: screenshot at 1440x900 → design-brief/scrapes/tv-food-maps/map-desktop.png
```

### 4d. Document UX Patterns

- Map provider (Google Maps? Mapbox? Leaflet? OpenStreetMap?)
- Pin/marker style (custom icons? clusters? color-coded?)
- Filter panel UX (sidebar? dropdown? inline chips?)
- Restaurant preview on marker tap (popup? bottom sheet? side panel?)
- "Road trip" builder — how does it work?
- How they handle multi-show content (filter by show? separate pages?)

---

## Step 5: Comparative UX Analysis

Read ALL scrapes, screenshots, and extracted text. Produce `design-brief/ux-analysis.md`.

### 5a. Pattern Comparison Table (REQUIRED)

| UX Pattern | DDD Locations | Flavortown USA | Food Network | TV Food Maps | TripleDB Decision |
|---|---|---|---|---|---|
| Search type | | | | | |
| Restaurant card fields | | | | | |
| Map integration | | | | | |
| Mobile navigation | | | | | |
| Primary colors (hex) | | | | | |
| Secondary colors (hex) | | | | | |
| Heading font | | | | | |
| Body font | | | | | |
| Filter mechanism | | | | | |
| "Near me" feature | | | | | |
| Trivia/fun elements | | | | | |
| YouTube/video integration | | | | | |
| Restaurant detail depth | | | | | |

Fill in EVERY cell. Use "N/A" or "Not present" if a site doesn't have the feature.
The "TripleDB Decision" column is the most important — it's what drives Synthesis.

### 5b. Design Decisions for TripleDB (REQUIRED — all 10)

Based on the analysis, make explicit decisions:

1. **Color palette:** Primary, secondary, accent, background — with hex codes
2. **Typography:** Heading font + body font pairing
3. **Search UX:** Text input style, placeholder text, debounce behavior
4. **Restaurant card:** Exactly which fields shown in list view vs detail view
5. **Map style:** Map provider, pin style, cluster behavior, preview card
6. **Mobile navigation:** Bottom nav, drawer, tab bar, or something else
7. **Trivia widget:** Visual style, placement, animation, cycle timing
8. **YouTube integration:** How timestamp links appear in dish cards and visit cards
9. **"Near me" UX:** Permission prompt style, distance display, card layout
10. **Overall aesthetic:** "Modern Flavortown" — define what this means in specific terms (warm vs cool, playful vs clean, bold vs subtle)

### 5c. Stolen Patterns

List 3-5 specific UX patterns to steal from the reference sites, with:
- Which site it comes from
- What the pattern is
- How it maps to tripleDB.net
- Which screenshot shows it

---

## Step 6: Scrape Quality Assessment

Before generating artifacts, self-assess:

```
For each site, count:
- Firecrawl: success / cookie-blocked / error
- Playwright screenshots: captured / failed
- Playwright text extraction: captured / failed
- UX patterns documented: complete / partial / missing

Total scrape coverage: X/4 sites with usable data
```

If fewer than 3 sites have usable data, log this as a critical finding. If all 4 have at least partial data, proceed.

---

## Step 7: Generate Artifacts

### docs/ddd-build-v8.22.md (MANDATORY)

**This must be a FULL chronological log**, including:
- Every MCP command issued (Firecrawl and Playwright calls)
- Every response received (success, error, cookie wall, timeout)
- Every file created or saved (with path)
- Every self-heal action taken
- Every decision made and why
- Timestamps or step numbers for ordering

**This is NOT a summary. It is a transcript.** If it's less than 100 lines, it's probably incomplete.

### docs/ddd-report-v8.22.md (MANDATORY)

Must include:

1. **Scrape success table:**
   | Site | Firecrawl | Playwright Screenshots | Text Extraction | UX Patterns |
   |------|-----------|----------------------|-----------------|-------------|
   | DDD Locations | ✅/❌ | ✅/❌ | ✅/❌ | Complete/Partial |
   | Flavortown USA | ✅/❌ | ✅/❌ | ✅/❌ | Complete/Partial |
   | Food Network | ✅/❌ | ✅/❌ | ✅/❌ | Complete/Partial |
   | TV Food Maps | ✅/❌ | ✅/❌ | ✅/❌ | Complete/Partial |

2. **Screenshot inventory:** list every file saved with path
3. **Key finding per site** (2-3 sentences each)
4. **Top 5 design decisions** with reasoning
5. **Scrape coverage:** X/4 sites with usable data
6. **Issues encountered:** cookie walls, timeouts, blocked content
7. **Comparison to first pass (v8.17):** what improved, what's still missing
8. **Gemini's Recommendation:** Ready for Synthesis (v8.23) or rescrape specific sites?
9. **Human interventions:** count (target: 0)

---

## Phase 8.22 Success Criteria

```
[ ] MCP servers verified (Firecrawl + Playwright green)
[ ] Site 1 (DDD Locations): attempted Firecrawl + Playwright fallback
    [ ] At least desktop + mobile screenshots captured
    [ ] UX patterns documented
[ ] Site 2 (Flavortown USA): attempted Firecrawl + Playwright fallback
    [ ] At least desktop + mobile screenshots captured
    [ ] UX patterns documented
[ ] Site 3 (Food Network DDD): attempted Firecrawl + Playwright fallback
    [ ] At least desktop + mobile screenshots captured
    [ ] UX patterns documented
[ ] Site 4 (TV Food Maps): attempted Firecrawl + Playwright fallback
    [ ] At least desktop + mobile screenshots captured
    [ ] UX patterns documented
[ ] design-brief/ux-analysis.md written with:
    [ ] Pattern comparison table (all cells filled)
    [ ] 10 design decisions documented
    [ ] 3-5 stolen patterns listed
[ ] Scrape quality self-assessment completed
[ ] ddd-build-v8.22.md generated (FULL transcript, 100+ lines)
[ ] ddd-report-v8.22.md generated (structured with metrics table)
[ ] Human interventions: 0
```

---

## GEMINI.md Update

Before launching, update `app/GEMINI.md`:

```markdown
# TripleDB App — Agent Instructions

## Current Iteration: 8.22

Read these two documents in order, then execute the plan:

1. docs/ddd-design-v8.22.md — App architecture, methodology
2. docs/ddd-plan-v8.22.md — Discovery redo execution steps

Follow the autonomy rules defined in the plan. Begin with Step 0.

## Rules That Never Change
- NEVER run git or firebase deploy commands
- NEVER ask permission — auto-proceed on EVERY step
- If you find yourself typing a question mark, STOP. Re-read the plan. Execute.
- Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip)
- MCP servers are phase-restricted — only Firecrawl + Playwright this phase
- MUST produce ddd-build-v8.22.md AND ddd-report-v8.22.md before ending
- Build on existing code — do NOT recreate the app scaffold
- Do NOT modify any Flutter code this phase — Discovery only
```

---

## Launch Sequence

```bash
cd ~/dev/projects/tripledb/app

# Archive previous phase docs if desired
mkdir -p docs/archive
mv docs/ddd-report-v8.*.md docs/archive/ 2>/dev/null

# Place new docs
# (copy ddd-design-v8.22.md and ddd-plan-v8.22.md into docs/)

# Update GEMINI.md
nano GEMINI.md

# Launch
gemini
```

Then type:

```
Read GEMINI.md and execute.
```

After Gemini completes, review the report. If satisfied, send it to Claude for the v8.23 Synthesis plan.
