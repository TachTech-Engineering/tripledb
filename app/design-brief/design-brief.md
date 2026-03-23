# TripleDB App: Design Brief

## 1. Project Summary
TripleDB.net is a mobile-first Flutter Web application designed for food explorers, "Diners, Drive-Ins and Dives" (DDD) fans, and road trippers. It serves as an interactive map and directory of restaurants featured on the show. The app is built to be deployed initially as a PWA/Web App with a clear roadmap to native Google Play and App Store releases.

## 2. Aesthetic Direction: "Modern Flavortown"
- **Warm, not cool:** DDD red (`#DD3333`) and orange (`#DA7E12`) dominate the interface. Blue is strictly reserved for utilitarian accents (like system links or secondary actions) if needed at all.
- **Playful, not corporate:** We use rounded corners (`12px` to `16px`), tasteful emoji where appropriate, and engaging trivia cards to keep the vibe fun and distinctly Guy Fieri.
- **Bold, not subtle:** Guy Fieri energy is channeled into high-contrast color choices and vibrant accents, ensuring the app feels lively without relying on aggressive typography.
- **Clean, not cluttered:** Taking cues from Google-style search simplicity, we use generous whitespace, centered search bars, and distinct card layouts.
- **Mobile-first:** The UI is heavily optimized for one-hand thumb scrolling, featuring a bottom navigation bar, prominent floating action buttons (FABs), and chunky touch targets.

## 3. Color Application Rules
- **Primary Red (`#DD3333`):** Used for the main AppBar, primary calls-to-action (CTAs), active navigation states, and individual map pins.
- **Secondary Orange (`#DA7E12`):** Used for accents, episode/season badges, map clusters, and highlight elements within cards.
- **Dark Surface (`#1E1E1E`):** Used for restaurant cards in dark mode, detail page headers, and bottom sheets to create a sleek, modern container.
- **Light Theme (`#FFFFFF` surface, `#F9F9F9` background):** Provides a crisp, off-white background with subtle grey dividers for high legibility during daytime use.

## 4. Typography Rules
- **Heading Font (`Outfit`):** A bold, geometric, and energetic font used for page titles, restaurant names, section headers, and the prominent "Near Me" calls.
- **Body Font (`Inter`):** A highly legible, modern sans-serif used for detailed descriptions, ingredient lists, and Guy's response quotes.
- **Size Hierarchy:** Standardized sizes for headings (h1: 28px, h2: 22px, h3: 18px), body text (16px), and captions (12px), optimized for readability on mobile screens.

## 5. Imagery Direction
- **Guy Fieri Quotes:** Displayed prominently in the secondary body font (italicized), often with quote marks, and sometimes pulled out into a special tinted card for emphasis.
- **Restaurant Images:** A clean, edge-to-edge full-width placeholder image strategy will be used until the data enrichment pipeline provides real photos.
- **Emoji Usage:** Incorporated naturally to add visual flavor (e.g., 🍔 for branding/food items, 📍 for location features, 📺 for episode tags, and 💡 for trivia).

## 6. Tone of Voice
- **Casual, Fun, Enthusiastic:** The copywriting matches Guy Fieri's energetic persona. It feels like a buddy giving you a restaurant recommendation.
- **Trivia Card Style:** Exclamation marks are welcome, and food puns are encouraged (e.g., "Righteous!", "Out of bounds!").
- **Search Placeholder:** Conversational and inviting, e.g., "Search dishes, diners, cities..."
