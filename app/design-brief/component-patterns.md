# Component Patterns

## 1. SearchBar Widget
- **Layout:** Google-style, prominently centered on the home page; persistent at the top on the search results page.
- **Debounce:** 300ms delay to prevent excessive queries while typing.
- **Placeholder Text:** "Search dishes, diners, cities..."
- **Styling:** Border radius of `999px` (pill shape), with a subtle elevation shadow (`elevation.sm`) for depth against the background. Includes a leading search icon and trailing clear button.

## 2. RestaurantCard Widget
- **Compact List View:** Features a thumbnail image (left), restaurant name (Outfit, bold), city/state, cuisine type, top dish, rating, and total DDD appearance count.
- **Placeholder Image:** Until enrichment provides real photos, display a colored container with a food emoji based on `cuisine_type`:
  - 🍕 Italian/Pizza
  - 🍔 American/Burgers
  - 🌮 Mexican/Tex-Mex
  - 🍖 BBQ/Barbecue
  - 🍣 Japanese/Sushi
  - 🍜 Asian/Noodles
  - 🥘 Soul Food/Southern
  - 🍽️ Default/Other
  The container background uses a muted tint of the primary color. The emoji renders at 32px centered. This ensures every card has visual weight even without photos.
- **Episode Badge:** A clean pill-shaped tag displaying the video type (e.g., "Compilation", "Full Episode", "Marathon") and total DDD appearance count (e.g., "5 visits"). If season/episode can be parsed from `video_title` (e.g., "Season 12, Episode 4" in the title string), display that as a bonus. The badge must work with `video_type` alone.
- **YouTube Button:** A clear CTA reading "▶ Watch Guy's Visit" that deep-links to the exact timestamp.
- **Styling:** Uses the `lg` (12px) border radius, `md` (16px) padding, and distinct elevation (`elevation.md`) from the design tokens.

## 3. DishCard Widget
- **Layout:** Contained within a clean card or list tile.
- **Content:** Dish name (Outfit, bold), description (Inter, regular), and ingredients presented as small chips or a comma-separated list.
- **Guy's Response:** Displayed in italics, wrapped in quotes, and styled in the secondary color for emphasis.
- **Action:** Includes a YouTube timestamp link specifically for that dish's appearance.
- **Styling:** Adheres to token spacing (`sm` and `md`).

## 4. TriviaCard Widget
- **Behavior:** Auto-cycling (8s interval) using a fade or slide animation between facts.
- **Styling:** Background uses a light tint of the primary color (`#DD3333` at 10% opacity) in light mode, or a dark surface with primary border in dark mode. Elevation shadow (`elevation.sm`).
- **Visuals:** Features a💡 emoji prefix for visual flavor. Border radius of `xl` (16px).

## 5. NearbySection Widget
- **Header:** "📍 Top 3 Near You" (Outfit, bold).
- **Behavior:** Displays a geolocation permission prompt style if location is unknown. Includes an "Enable location" button if permission is not granted.
- **Content:** Displays a compact variant of the `RestaurantCard` that prominently features the calculated distance from the user.

## 6. MapWidget
- **Pins/Markers:** Custom icons (e.g., Guy Fieri silhouette or simple drop) using the primary color (`#DD3333`).
- **Clusters:** Grouped markers using the secondary color (`#DA7E12`) with a bold count number in the center.
- **Interactions:** Tapping a pin reveals a preview card (bottom sheet) with a restaurant summary. Bottom sheet uses `elevation.lg`.
- **Integration:** The map reacts to the active search query, filtering visible pins instantly. Styled using the `dark` map style.

## 7. RestaurantDetailPage Layout
- **Header:** Full-width hero image, restaurant name, city/state, cuisine, rating, and open/closed status (using `statusColors` tokens).
- **Hero Placeholder:** Same emoji strategy but larger (64px emoji, full-width colored container with restaurant name overlaid in white Outfit bold).
- **Dish Section:** A scrollable vertical list of `DishCard` widgets.
- **Visit Section:** A list of visits/episodes with YouTube links.
- **Action Bar:** Sticky or prominent buttons for "Directions" and "Website".
- **Styling:** Generous `lg` (24px) spacing and section dividers based on the design tokens.

## 8. AppBar / Navigation
- **Mobile Layout:** Standard Material Bottom Navigation Bar with three tabs: "Map", "List", "Explore". The Explore tab shows trivia (larger format TriviaCard), top states (ranked list from data), most-visited restaurants (5+ DDD appearances), and cuisine breakdown (category counts). All computed from the loaded restaurant data — no additional API calls needed.
- **Top Bar:** A clean top AppBar containing the TripleDB logo (centered or leading) and a Dark Mode toggle action.
- **Logo Sizing:** Prominent but not overpowering, maintaining generous padding (`md` 16px).