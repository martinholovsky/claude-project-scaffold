#!/usr/bin/env bash
# Preset: TypeScript/Node.js

preset_name="typescript-node"
preset_description="TypeScript/Node.js project with eslint, vitest, and API patterns"

# Rules files: newline-delimited "filename|description" pairs
RULES_FILES="api-contracts.md|API endpoint contracts, request/response types"

# Technology stack entries
TECH_STACK="| Runtime | Node.js 20+ |
| Language | TypeScript 5+ |
| Framework | *Express / Fastify / Hono / other* |
| Testing | Vitest |
| Linting | ESLint + Prettier |
| Package Manager | *npm / pnpm / bun* |"

# Development workflow
WORKFLOW='```bash
# Setup
npm install  # or: pnpm install / bun install

# Run dev server
npm run dev

# Run tests
npm test

# Lint & format
npm run lint && npm run format

# Type check
npx tsc --noEmit
```'

# Project conventions
PROJECT_CONVENTIONS='- Run `npm test` to verify changes.
- Run `npx tsc --noEmit` for type checking.
- Run `npm run lint && npm run format` before committing.'

# Smoke test scripts
SMOKE_SCRIPTS="smoke-app.sh|Application Health Checks|SMOKE_APP_CHECKS"

# shellcheck disable=SC2034
SMOKE_APP_CHECKS='section "Application"

if [[ -f "src/index.ts" ]]; then
  pass "src/index.ts exists"
else
  fail "src/index.ts not found"
fi

if [[ -f "package.json" ]]; then
  pass "package.json exists"
else
  fail "package.json not found"
fi

section "Dependencies"

if [[ -d "node_modules" ]]; then
  pass "node_modules exists"
else
  fail "node_modules missing — run npm install"
fi

section "Type Checking"

if npx tsc --noEmit 2>/dev/null; then
  pass "TypeScript compiles without errors"
else
  warn "TypeScript compilation errors found"
fi

section "Linting"

if npx eslint --quiet src/ 2>/dev/null; then
  pass "ESLint passes"
else
  warn "ESLint has findings"
fi

section "Tests"

if npx vitest --run --reporter=silent 2>/dev/null; then
  pass "Tests pass"
else
  warn "Tests failing or not found"
fi'

# Troubleshooting sections
TROUBLESHOOTING_SECTIONS='### Symptom: `Cannot find module` or path alias not resolving

**Diagnosis:** TypeScript path aliases in `tsconfig.json` are not resolved at runtime by Node.js.

**Fix:** Use `tsconfig-paths` or configure your bundler to resolve aliases.

---

### Symptom: `ERR_UNKNOWN_FILE_EXTENSION .ts` when running directly

**Diagnosis:** Node.js cannot execute `.ts` files without a loader.

**Fix:**
```bash
npx tsx src/index.ts       # Use tsx for development
```'

# Memory topics: "filename|description" pairs
MEMORY_TOPICS="patterns.md|Recurring code patterns and conventions
debugging.md|Common errors and solutions
dependencies.md|Package-specific gotchas, version constraints, upgrade notes"

# Slash commands to scaffold
COMMANDS="review.md
test.md
smoke.md
lint.md
typecheck.md"

# --- Substantive Rules Content ---

# shellcheck disable=SC2034
RULES_CONTENT_API_CONTRACTS='# API Contracts

> Document your actual API endpoints here.

## Base URL

- **Local dev:** `http://localhost:3000/api/v1`
- **Production:** `https://api.example.com/api/v1`

## Endpoints

*Add your real endpoints below as you build them:*

```
GET  /api/v1/resources          # List (paginated)
POST /api/v1/resources          # Create
GET  /api/v1/resources/{id}     # Get one
PATCH /api/v1/resources/{id}    # Update
```'

LINT_LANGUAGES="TypeScript/JS (eslint + prettier), JSON, YAML, Shell (shellcheck)"