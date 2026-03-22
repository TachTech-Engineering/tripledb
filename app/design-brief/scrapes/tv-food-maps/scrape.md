# Scrape Results: TV Food Maps
URL: https://www.tvfoodmaps.com/show/Diners-Drive-Ins-Dives

## Site Focus
Map-to-list interaction, city-based filtering, "on air now" markers.

## UX Patterns

### 1. Navigation & Search
- Search bar with "City, State" placeholder.
- "Nearby restaurants" quick link.
- Breadcrumbs for "Home > Explore > Shows > Diners Drive Ins Dives".
- Fast links for "All Shows", "Recent", "Plan Route".

### 2. Filtering & Sorting
- "Listing Controls" section with counts.
- Sorting options: "Top Rated", "Recently Added".
- Toggle for "Show Map" (Visualizing restaurants geographically).
- "Filter by State" sidebar with restaurant counts per state.

### 3. Restaurant Listings
- Article-based cards with:
  - Large thumbnail image.
  - "TVFScore" (Proprietary rating) overlay on image.
  - Restaurant Name (Link).
  - City, State (Link to city-specific page).
  - Short teaser description.
  - Tags for other shows the restaurant appeared on.
  - "Closed" status indicator where applicable.

### 4. Layout
- Two-column layout on desktop: Main results (Left), Filters/Next Steps (Right).
- Pagination at the bottom.
- Modern, clean aesthetic with plenty of whitespace.

### 5. Mobile Responsiveness
- Filters move to the bottom or become hidden behind a toggle.
- Single-column list of restaurant articles.
- Navigation becomes a compact header.

## Screenshots
- Desktop: `design-brief/scrapes/tv-food-maps/desktop.png`
- Mobile: `design-brief/scrapes/tv-food-maps/mobile.png`
