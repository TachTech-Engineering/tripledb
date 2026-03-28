# TripleDB — Agent Instructions

## Current Iteration: 9.38

BUG FIX: Cookie banner does not render. Debug, fix, and FUNCTIONALLY verify.

1. docs/ddd-design-v9.38.md — Debug strategy, functional post-flight spec
2. docs/ddd-plan-v9.38.md — Steps with Playwright playbook

## MCP Servers
- Playwright MCP: REQUIRED for functional testing
- Context7: Flutter docs

## Rules
- NEVER git add/commit/push or firebase deploy
- POST-FLIGHT Tier 1 + Tier 2 must BOTH pass
- Tier 2 = actually click buttons, verify state changes, confirm cookie persistence
- If Playwright MCP unavailable, npm install puppeteer and use that
- CHANGELOG ≥ 23 entries
