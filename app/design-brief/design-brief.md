# TripleDB App: Creative Direction Brief
**Phase:** 2 — Synthesis (v8.18)

## 1. The Vision
TripleDB is the definitive interactive guide to every restaurant featured on *Diners, Drive-Ins and Dives*. It bridges the gap between the TV show's high-energy entertainment and a highly functional, location-aware restaurant directory. The app must feel like a premium, modern web application—fast, responsive, and visually engaging.

## 2. Core Aesthetic: "Modern Flavortown"
We are moving away from cluttered fan-site aesthetics toward a clean, app-like experience inspired by modern directory tools (like Google Maps or Yelp) but injected with DDD's signature energy.
- **High Contrast:** Bright whites and light grays for backgrounds to make food imagery and map pins pop.
- **Bold Branding:** The signature "Flavortown Red" (#E12026) serves as the primary action color, anchored by a deep "Chrome Blue" (#1A2B4C) for structural elements.
- **Typography-Driven:** We use clean, highly legible sans-serif fonts for data (addresses, ingredients) and bold, character-rich sans-serifs for headings.

## 3. Key UX Paradigms
1. **The Almighty Search Bar:** A large, centered search bar that handles multi-dimensional queries (dishes, cities, states, cuisines). This is the primary interaction point.
2. **Instant Gratification:** No full-page reloads. Search results, map updates, and filtering happen instantly using Flutter's reactive state management (Riverpod).
3. **Map-List Duality:** Users can seamlessly toggle between a geographic view (Map) and a detailed list view, or see them side-by-side on desktop.
4. **The "Guy Factor":** Every restaurant detail page elevates Guy Fieri's specific reaction to the food (the `guy_response` field) and provides a frictionless deep-link to the exact timestamp of that moment on YouTube.

## 4. Interaction Guidelines
- **Hover States:** Desktop users should experience subtle elevations and color shifts on cards and map pins.
- **Touch Targets:** Mobile users require large, forgiving touch targets (minimum 48x48 logical pixels) for all interactive elements, especially video play buttons and map pins.
- **Transitions:** Use Flutter's native Hero animations for transitioning between a Restaurant Card in the list and its full Detail Page.
- **Empty States:** When a search yields no results, display a fun, themed empty state (e.g., "Guy hasn't rolled out here yet!").
