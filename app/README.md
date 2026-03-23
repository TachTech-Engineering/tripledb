# TripleDB — DDD Restaurant Explorer

TripleDB is a high-performance Flutter Web application designed to visualize and explore the culinary landscape of Guy Fieri's *Diners, Drive-Ins and Dives*. It provides a modern, responsive interface for searching, mapping, and discovering 800+ restaurants featured on the show.

## 🚀 Features

- **Responsive Design:** "Modern Flavortown" aesthetic optimized for both Desktop and Mobile viewports.
- **Dynamic Search:** Real-time restaurant discovery with interactive search results.
- **Interactive Maps:** Full map integration using `flutter_map` and OpenStreetMap.
- **Trivia Engine:** Auto-cycling trivia card with real-time stats (e.g., total restaurants, city counts, and show history).
- **Restaurant Details:** Comprehensive views for each location, including address, city, and show-specific metadata.
- **Robust Data Handling:** Null-safe data models designed to handle raw DDD pipeline extractions reliably.

## 🛠️ Tech Stack

- **Framework:** [Flutter Web](https://flutter.dev/) (CanvasKit)
- **State Management:** [Riverpod](https://riverpod.dev/) (Generator-based)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
- **Theming:** Material 3 with custom Design Tokens
- **Maps:** [flutter_map](https://pub.dev/packages/flutter_map) + [latlong2](https://pub.dev/packages/latlong2)
- **Service Layer:** Local JSONL Data Service (prepared for Firestore migration)

## 📦 Getting Started

1.  **Install Flutter SDK:** Ensure you are on the `stable` channel (v3.11.1 or later).
2.  **Get Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run Build Runner:** (Required for Riverpod code generation)
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
4.  **Launch the App:**
    ```bash
    flutter run -d chrome
    ```

---

## 📝 Changelog

### [v8.25] — 2026-03-23
#### QA & Polish
- Conducted full quality assurance via Playwright screenshots and Lighthouse audits.
- Fixed missing `/explore` route in `GoRouter` resulting in 404s.
- Fixed `TriviaCard` text overlap bug on mobile viewports by removing `AnimatedSwitcher`.
- Enhanced SEO metadata in `web/index.html`.
- Verified 100% design token compliance and all 8 component patterns across Desktop, Tablet, and Mobile.

### [v8.24] — 2026-03-22
#### Implementation & Design Overhaul
- Applied complete design contract to the codebase (14 files modified).
- Full theme rewrite using `design-tokens.json` (Outfit + Inter fonts, DDD red/orange palette).
- Added cuisine emoji placeholders for restaurant thumbnail images.
- Implemented episode/video type badges replacing raw season/episode strings.
- Introduced 3-tab bottom navigation (`Map` / `List` / `Explore`).
- Built new `ExplorePage` with trivia, top states, most visited restaurants, and cuisine breakdown.
- Upgraded map to use CartoDB dark tiles with primary-colored pins.
- Added a functional Dark Mode toggle via Riverpod.

### [v8.23] — 2026-03-22
#### Design Synthesis
- Generated centralized `design-tokens.json`, `design-brief.md`, and `component-patterns.md`.
- Established strict widget patterns (SearchBar, RestaurantCard, DishCard, TriviaCard, NearbySection, MapWidget, RestaurantDetailPage, AppBar).

### [v8.22] — 2026-03-22
#### Discovery & Data Integrity
- Conducted full rescrape of DDD restaurant data using Playwright fallback for resilient extraction.
- Validated 804 restaurants against YouTube metadata for accurate timestamping.
- Established the base `sample_restaurants.jsonl` used for app development.

### [v8.21] — 2026-03-22
#### Added
- Initial Flutter Front End build completed.
- Implemented **Home Page** with Hero section, search bar, and nearby results.
- Built **Trivia Engine** with auto-cycling cards (8s timer) and show statistics.
- Implemented **Search Results** and **Restaurant Detail** pages.
- Integrated **Flutter Map** for restaurant location visualization.
- Configured **GoRouter** for URL-based navigation and deep linking.
- Defined **AppTheme** following the "Modern Flavortown" design brief.

#### Fixed
- Resolved critical runtime `TypeError` in `restaurant_models.dart` where null values in raw JSON fields caused crashes.
- Fixed `latlong2` import conflicts and standardizing `debugPrint` usage.
- Corrected responsive layout issues where trivia cards were overflowing on mobile viewports.

#### Technical
- Achieved **0 issues** in `flutter analyze`.
- Verified layout parity across Desktop (1440p) and Mobile (375x812) via Playwright snapshots.
- Prepared architecture for Phase 5 (Firestore wiring).
