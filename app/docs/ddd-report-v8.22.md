# Discovery Report v8.22

## 1. Scrape Success Table

| Site | Firecrawl | Playwright Screenshots | Text Extraction | UX Patterns |
|------|-----------|----------------------|-----------------|-------------|
| DDD Locations | ❌ | ✅ | ✅ | Complete |
| Flavortown USA | ❌ | ✅ | ✅ | Complete |
| Food Network | ❌ | ✅ | ✅ | Complete |
| TV Food Maps | ❌ | ✅ | ✅ | Complete |

## 2. Screenshot Inventory
- `design-brief/scrapes/ddd-locations/desktop.png`
- `design-brief/scrapes/ddd-locations/mobile.png`
- `design-brief/scrapes/flavortown-usa/desktop.png`
- `design-brief/scrapes/flavortown-usa/mobile.png`
- `design-brief/scrapes/flavortown-usa/desktop-scroll1.png`
- `design-brief/scrapes/flavortown-usa/desktop-scroll2.png`
- `design-brief/scrapes/food-network-ddd/desktop.png`
- `design-brief/scrapes/food-network-ddd/mobile.png`
- `design-brief/scrapes/tv-food-maps/desktop.png`
- `design-brief/scrapes/tv-food-maps/mobile.png`

## 3. Key Finding Per Site
- **DDD Locations:** Functions mostly as a static, region-based directory. Emphasizes finding restaurants via deep nested links rather than an active search bar.
- **Flavortown USA:** Highly community-driven approach (fan recommendations, photos, questions). Information layout is clean, focusing on metrics like "Most Visited States".
- **Food Network DDD:** Uses a heavily curated, editorial approach (galleries, top 10 lists). The official color palette (Red `#DD3333` and Orange) and Guy Fieri action imagery are central to the brand.
- **TV Food Maps:** Centers the user experience around geolocation ("Near Me") and multi-show cross-pollination. Offers a "Road Trip Builder" which is a highly actionable feature.

## 4. Top 5 Design Decisions
1. **Interactive Map as Primary View:** Moving away from static lists, TripleDB will use an integrated interactive map (with clustering) as the core navigation tool.
2. **Prominent "Near Me" FAB:** Adopting TV Food Maps' focus on geolocation, we will feature a Floating Action Button that centers the map and recalibrates lists to the user's location.
3. **Official DDD Brand Colors:** The primary theme will use Food Network's official red (`#DD3333`) and orange (`#DA7E12`), set against a modern dark theme (`#1E1E1E` surface) to make the colors pop.
4. **Episode Badges / Tags:** Instead of just text, every restaurant card will clearly display a pill tag containing the Season and Episode (e.g., "S12 \| E4") as seen on Food Network.
5. **Integrated YouTube/Trivia Deep Dive:** While competitors just list addresses or basic info, our detail view will feature embedded YouTube video starting exactly at the relevant timestamp, paired with an animated Trivia widget.

## 5. Scrape Coverage
**4/4 sites with usable data.** All sites were successfully scraped via Playwright fallback.

## 6. Issues Encountered
- **Firecrawl Certificate Errors:** Firecrawl failed on all 4 sites due to a "self-signed certificate in certificate chain" error. `skipTlsVerification` did not resolve it.
- **Bot Protection:** TV Food Maps triggered a Vercel Security Checkpoint 429 error on the first Playwright navigation, but a short wait and page reload successfully bypassed it.

## 7. Comparison to First Pass (v8.17)
The Playwright fallback workflow implemented in v8.22 worked flawlessly to bypass cookie walls and cert errors that blocked Firecrawl in v8.17. We now have a full, 4-site comparative view of the UX landscape, complete with 10 screenshots and full accessibility snapshots, leading to much clearer design decisions.

## 8. Gemini's Recommendation
**Ready for Synthesis (v8.23).** The competitive analysis is complete, design decisions are locked in, and we have clear UX patterns to build from.

## 9. Human Interventions
0
