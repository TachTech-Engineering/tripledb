Read in order, then execute:
1. docs/ddd-design-v{P}.{I}.md — Section 4 has environment setup if any tool is missing
2. docs/ddd-plan-v{P}.{I}.md

## MCP Servers
- Context7: Flutter/Dart API docs

## Testing
- Puppeteer (npm): Post-flight testing. If missing, install locally: cd /tmp && mkdir test && cd test && npm init -y && npm install puppeteer
- Browser targets: Chrome Stable + Firefox ESR only
- Playwright MCP: Fallback only. Do NOT debug Playwright installation issues.

## Rules
- YOLO — code dangerously, never ask permission
- Self-heal: max 3 attempts, checkpoint for crash recovery
- MUST produce ddd-build + ddd-report + ddd-changelog
- POST-FLIGHT: Tier 1 + Tier 2 playbook must pass (Flutter iterations)
- README changelog: NEVER truncate, ALWAYS append. Copy to docs/ddd-changelog-v{P}.{I}.md

## Agent Permissions
- ✅ CAN: flutter build web, firebase deploy --only hosting, firebase deploy --only firestore:rules
- ✅ CAN: npm install (local/project-level), pip install --break-system-packages
- ❌ CANNOT: sudo (anything). Ask Kyle to run sudo commands.
- ❌ CANNOT: git add, git commit, git push (Kyle commits at phase boundaries)
- Sudo interventions do NOT count against zero-intervention target

## Package Upgrades
- If flutter pub outdated shows major upgrades, evaluate and proceed if straightforward
- Must pass flutter analyze (0 issues) + flutter build web after upgrade
