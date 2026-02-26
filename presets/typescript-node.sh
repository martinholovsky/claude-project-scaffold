#!/usr/bin/env bash
# Preset: TypeScript/Node.js

preset_name="typescript-node"
preset_description="TypeScript/Node.js project with eslint, vitest, and API patterns"

# Rules files: newline-delimited "filename|description" pairs
RULES_FILES="api-contracts.md|API endpoint contracts, request/response types, error handling
cross-service.md|Shared patterns, conventions, type definitions"

# Technology stack entries
TECH_STACK="| Runtime | Node.js 20+ |
| Language | TypeScript 5+ |
| Framework | *Express / Fastify / Hono / other* |
| Testing | Vitest |
| Linting | ESLint + Prettier |
| Package Manager | *npm / pnpm / bun* |"

# Context loading table entries
CONTEXT_LOADING_TABLE="| **New API endpoint** | \`.claude/rules/api-contracts.md\`, \`src/routes/\` |
| **Type changes** | \`src/types/\`, \`.claude/rules/cross-service.md\` |
| **Debugging** | \`.claude/rules/troubleshooting.md\` |
| **Architecture decisions** | \`docs/decisions/index.md\` |"

# Context groups
CONTEXT_GROUPS='### `api`
Read: `.claude/rules/api-contracts.md`, `src/routes/`, `src/types/`

### `config`
Read: `tsconfig.json`, `package.json`, `.env.example`

### `debug`
Read: `.claude/rules/troubleshooting.md`'

# Development workflow
WORKFLOW='```bash
# Setup
npm install  # or: pnpm install / bun install

# Run dev server
npm run dev

# Run tests
npm test

# Lint & format
npm run lint
npm run format

# Type check
npx tsc --noEmit

# Build
npm run build
```'

# Project overview
PROJECT_OVERVIEW="TypeScript/Node.js service."

# Workspace structure
WORKSPACE_STRUCTURE='{{PROJECT_NAME}}/
├── CLAUDE.md
├── .claude/
│   ├── rules/
│   │   ├── api-contracts.md
│   │   ├── cross-service.md
│   │   └── troubleshooting.md
│   └── hooks/
│       └── lint-on-edit.sh
├── src/
│   ├── index.ts
│   ├── routes/
│   ├── types/
│   ├── services/
│   └── utils/
├── tests/
├── docs/
│   ├── plans/
│   │   └── .plan-template.md
│   └── decisions/
│       ├── index.md
│       └── adr-template.md
├── scripts/
│   └── smoke-app.sh
├── package.json
└── tsconfig.json'

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
TROUBLESHOOTING_SECTIONS='## 1. TypeScript / Build

### Symptom: `Cannot find module` or path alias not resolving

**Diagnosis:** TypeScript path aliases in `tsconfig.json` are not being resolved at runtime.
`tsc` resolves them at compile time but Node.js does not natively support them.

**Fix:** Use `tsconfig-paths` or configure your bundler to resolve aliases:
```bash
npm install -D tsconfig-paths
# In dev: node -r tsconfig-paths/register dist/index.js
```

---

### Symptom: `ERR_UNKNOWN_FILE_EXTENSION .ts` when running directly

**Diagnosis:** Node.js cannot execute `.ts` files without a loader.

**Fix:**
```bash
# Use tsx for development
npx tsx src/index.ts

# Or use ts-node with ESM
node --loader ts-node/esm src/index.ts
```

---

## 2. Dependencies

### Symptom: Peer dependency conflicts during install

**Diagnosis:** Conflicting version requirements between packages.

**Fix:**
```bash
# Check the conflict
npm ls <package-name>

# Force install (use cautiously)
npm install --legacy-peer-deps
```

---

## 3. Testing

### Symptom: Vitest hangs or does not exit

**Diagnosis:** Open handles (database connections, timers, servers) preventing clean exit.

**Fix:** Ensure all resources are cleaned up in `afterAll` / `afterEach` hooks.
Run with `--reporter=verbose` to see which test is hanging.

---

*Add entries as you encounter and solve issues. Use the Symptom -> Diagnosis -> Fix format.*'

LINT_LANGUAGES="TypeScript/JS (eslint + prettier), JSON, YAML, Shell (shellcheck)"
