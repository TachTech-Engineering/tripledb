# TripleDB — Design v6.29

---

## Phase Status

| IAO Iteration | Phase | Focus | Status |
|---|---|---|---|
| v0.7–v4.13 | 0-4 | Pipeline iterative refinement (Group A) | ✅ Complete |
| v5.14–v5.15 | 5 | Production run (Group B) | ✅ Complete |
| v6.26 | 6 | Firestore load + app wiring | ✅ Complete |
| v6.27 | 6 | Geolocation fix (broke Firestore, reverted in v6.28) | ✅ Fixed |
| v6.28 | 6 | Geocoding + Firestore restore | ✅ Complete |
| v6.29 | 6 | Polish — trivia fix, map clustering, README | 🔧 Current |
| v8.17–v8.25 | 8 | Flutter app build (two passes) | ✅ Complete |
| v7.30+ | 7 | Enrichment (ratings, open/closed, photos) | ⏳ Deferred |

## Current State

- **tripledb.net** is live with 1,102 restaurants, 2,286 dishes, 916 geocoded
- Map shows pins across the US, "Near Me" working, search functional
- Firestore serving full dataset

## Known Issues (v6.29 Scope)

1. **Trivia says "63 states"** — includes UNKNOWN (33 records). Should say "50 states" or "62 states and territories" excluding UNKNOWN.
2. **Map pins overlap** — CA and Northeast have dense clusters with no visual grouping. Need pin clustering via `flutter_map_marker_cluster` or equivalent.
3. **README.md is stale** — still shows v2.11 content. Needs full update with IAO Eight Pillars, current metrics, corrected architecture, full changelog.
4. **Trivia fact accuracy** — verify all facts compute from the live 1,102-restaurant dataset, not hardcoded or sample-based.

## Artifact Spec

| Direction | File | Author | Mandatory |
|-----------|------|--------|-----------|
| Input | `docs/ddd-design-v6.29.md` | Claude | ✅ |
| Input | `docs/ddd-plan-v6.29.md` | Claude | ✅ |
| Output | `docs/ddd-build-v6.29.md` | Gemini | ✅ HARD REQUIREMENT |
| Output | `docs/ddd-report-v6.29.md` | Gemini | ✅ HARD REQUIREMENT |

## Agent Restrictions

```
1. Git READ commands allowed (pull, log, status, diff, show).
   Git WRITE commands forbidden (add, commit, push, checkout, branch).
   firebase deploy forbidden — Kyle deploys manually.
2. flutter build web and flutter run ARE ALLOWED for testing.
3. NEVER ask permission — the plan IS the permission.
4. Self-heal errors: diagnose → fix → re-run (max 3 attempts, then skip).
5. MCP: Context7 ALLOWED for Flutter docs. No other MCP servers.
6. EVERY session ends with ddd-build and ddd-report artifacts. No exceptions.
7. Build on existing code. Do NOT recreate scaffolds.
```

## Tech Stack Reference

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | 2.x | State management (NOT 3.x — breaks providers) |
| `go_router` | 14.x | Deep-linking |
| `google_fonts` | 6.x | Outfit + Inter |
| `flutter_map` | 7.x | Map widget with CartoDB dark tiles |
| `geolocator` | 10.x | Browser geolocation (NOT 13.x — compat issue) |
| `cloud_firestore` | 5.x | Firestore data source |
| `firebase_core` | 3.x | Firebase initialization |

## GEMINI.md Template

```markdown
# TripleDB App — Agent Instructions

## Current Iteration: 6.29

IMPORTANT: Read documents in this EXACT order before executing:

1. docs/ddd-design-v6.29.md — Current state, known issues, tech stack
2. docs/ddd-plan-v6.29.md — Polish execution steps

Do NOT begin execution until both files have been read.

## Rules That Never Change
- Git READ commands allowed (pull, log, status, diff, show)
- Git WRITE commands forbidden (add, commit, push, checkout, branch)
- firebase deploy forbidden — Kyle deploys manually
- flutter build web and flutter run ARE ALLOWED for testing
- NEVER ask permission — auto-proceed on EVERY step
- Context7 MCP allowed. No other MCP servers.
- MUST produce ddd-build-v6.29.md AND ddd-report-v6.29.md before ending
- Build on existing code — do NOT recreate the app scaffold
```
