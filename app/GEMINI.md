# TripleDB — Agent Instructions

## Current Iteration: 6.28

Read docs/ddd-plan-v6.28.md then execute.

This iteration spans pipeline/ (geocoding + Firestore reload) and app/ (restore Firestore connection).

## Rules
- Git READ allowed. Git WRITE and firebase deploy forbidden.
- flutter build web IS ALLOWED for testing.
- Context7 MCP allowed for Flutter/Firebase docs.
- NEVER ask permission — diagnose, fix, test, report.
- MUST produce ddd-build-v6.28.md AND ddd-report-v6.28.md before ending.
- Start in pipeline/ for Steps 0-3, switch to app/ for Steps 4-6.
