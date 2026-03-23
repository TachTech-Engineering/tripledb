# UX Analysis & Synthesis (v8.22)

## 1. Pattern Comparison Table

| UX Pattern | DDD Locations | Flavortown USA | Food Network | TV Food Maps | TripleDB Decision |
|---|---|---|---|---|---|
| Search type | Region/State drilling | Text input + dropdown | Corporate sitewide search | Location input + "Near Me" | **Location input + "Near Me"** (modern standard) |
| Restaurant card fields | Address, Phone, Episode | Air date, City/State | High-level editorial | Description, TVF Score, Show Tag | **Image, Address, Episode info, Distance** |
| Map integration | Static/List based | Dedicated Map page | None (Lists) | "Road Trip Builder" | **Integrated interactive map as primary view** |
| Mobile navigation | Single column lists | Hamburger menu | Hamburger menu | Stacked layout | **Bottom App Bar with Map/List/Saved toggle** |
| Primary colors (hex) | `#DA7E12` (Orange) | `#222222` (Dark) | `#DD3333` (Red) | Clean Web White/Blue | **`#DD3333` (Brand Red) and `#DA7E12` (Orange)** |
| Secondary colors (hex)| `#337AB7` (Blue) | White/Gray | White | Dark Gray | **`#1E1E1E` (Dark Mode bias)** |
| Heading font | Standard Sans-Serif | Standard Sans-Serif | Clean corporate Sans | Modern Sans-Serif | **Outfit or Poppins (modern, clean sans-serif)** |
| Body font | Standard Sans-Serif | Standard Sans-Serif | Clean corporate Sans | Modern Sans-Serif | **Roboto or Inter** |
| Filter mechanism | By Food / By Cuisine | By Category Dropdown | None (Curated lists) | By Show / By Cuisine | **Faceted chips (City, Food, Episode)** |
| "Near me" feature | Not present | Not present | Not present | Prominent button | **Prominent Floating Action Button on Map** |
| Trivia/fun elements | "Road Trip" | Fan Q&A, Photos | Guy Fieri Imagery | "AI Concierge" | **Animated Trivia Widget (did you know?)** |
| YouTube/video | Not prominent | Video links | Embedded show clips | Not prominent | **Embedded YouTube clips starting at timestamps** |
| Restaurant detail depth| Address, Phone | Basic location, Air date| Recipe focus | Aggregated info, Score | **Deep dive: YouTube clip, Dishes, Trivia** |

## 2. Design Decisions for TripleDB

1. **Color palette:** Primary: `#DD3333` (DDD Red). Secondary: `#DA7E12` (DDD Orange). Background: `#121212` (Dark Theme) or `#F9F9F9` (Light Theme). Surface: `#1E1E1E` (Dark) or `#FFFFFF` (Light).
2. **Typography:** Heading font: `Outfit` (bold, geometric, energetic). Body font: `Inter` (highly legible).
3. **Search UX:** Prominent text input on a map overlay with "City, State, or Restaurant" placeholder, featuring instant debounce filtering and a "Near Me" location icon.
4. **Restaurant card:** List view: Thumbnail, Name, City, State, Distance (if Near Me active), and Episode Tag. Detail view: Full width image, embedded YouTube player, address, specific dishes Guy tried.
5. **Map style:** Mapbox or Google Maps with custom dark styling. Pins should be custom icons (perhaps a small Guy Fieri hair silhouette or simple orange drops). Clustering is required for zoomed-out states.
6. **Mobile navigation:** Standard Material Bottom Navigation Bar with three tabs: "Map", "List", "Saved/Route".
7. **Trivia widget:** A floating or inline card style widget with a subtle pulse animation that cycles through fun facts about the show or Guy Fieri every 10 seconds.
8. **YouTube integration:** The cornerstone feature. Detail pages must embed the YouTube video cueing exactly to the timestamp where the specific restaurant is featured in the episode.
9. **"Near me" UX:** A dedicated location FAB on the map screen. When tapped, prompts for permission natively, then animates camera to user's location and recalculates list distances.
10. **Overall aesthetic:** "Modern Flavortown". It should feel energetic and bold (high contrast, bright red/orange accents) but maintain a clean, modern, app-like structure rather than a cluttered web-1.0 directory.

## 3. Stolen Patterns

1. **Pattern:** "Road Trip Builder" / Route Planning
   - **From:** TV Food Maps & DDD Locations
   - **Mapping to TripleDB:** Allow users to "Save" locations to a specific "Trip" and see them connected on the map.
2. **Pattern:** Ranked "Most Visited" Data Visualizations
   - **From:** Flavortown USA
   - **Mapping to TripleDB:** An insights or stats page showing which states or cities have the most DDD locations.
3. **Pattern:** Episode Badges / Tags
   - **From:** Food Network
   - **Mapping to TripleDB:** Use clean pill-shaped tags on every restaurant card detailing Season and Episode (e.g., "S12 | E4").
4. **Pattern:** "Near Me" Centric Search
   - **From:** TV Food Maps
   - **Mapping to TripleDB:** Prioritize geolocation over manual text input as the default mobile entry point.
