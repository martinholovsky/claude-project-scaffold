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
│   ├── hooks/
│   │   └── lint-on-edit.sh
│   ├── memory/
│   │   ├── MEMORY.md
│   │   ├── patterns.md
│   │   ├── debugging.md
│   │   └── dependencies.md
│   └── commands/
│       ├── review.md
│       ├── test.md
│       ├── plan.md
│       ├── smoke.md
│       ├── lint.md
│       └── typecheck.md
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

# Memory topics: "filename|description" pairs
MEMORY_TOPICS="patterns.md|Recurring code patterns and conventions
debugging.md|Common errors and solutions
dependencies.md|Package-specific gotchas, version constraints, upgrade notes"

# Slash commands to scaffold
COMMANDS="review.md
test.md
plan.md
smoke.md
lint.md
typecheck.md"

# --- Substantive Rules Content ---

# shellcheck disable=SC2034
RULES_CONTENT_API_CONTRACTS='# API Contracts

> **When to use:** Adding or modifying API endpoints, debugging request/response issues.
>
> **Read first for:** New endpoints, type changes, error handling patterns.

## Base URL

- **Production:** `https://api.example.com/api/v1`
- **Local dev:** `http://localhost:3000/api/v1`

## Request/Response Patterns

### Creating a resource
```
POST /api/v1/resources
Body: { "name": "...", "description": "..." }
Response: 201 { "id": "...", "name": "...", ... }
```

### Listing resources (paginated)
```
GET /api/v1/resources?limit=50&offset=0&sort=createdAt&order=desc
Response: { "items": [...], "total": 123, "offset": 0, "limit": 50 }
```

### Error format
```json
{
  "detail": "Human-readable error message",
  "code": "NOT_FOUND",
  "status": 404
}
```

## Type Definitions

```typescript
// types/api.ts
interface PaginatedResponse<T> {
  items: T[]
  total: number
  offset: number
  limit: number
}

interface ApiError {
  detail: string
  code: string
  status: number
}
```

## Input Validation (Zod)

```typescript
import { z } from "zod"

const CreateResourceSchema = z.object({
  name: z.string().min(1).max(255),
  description: z.string().optional(),
})

type CreateResource = z.infer<typeof CreateResourceSchema>

// In route handler
const body = CreateResourceSchema.parse(req.body)
```

## Error Handling

```typescript
// middleware/error-handler.ts
export function errorHandler(err: Error, req: Request, res: Response, next: NextFunction) {
  if (err instanceof z.ZodError) {
    return res.status(422).json({
      detail: "Validation failed",
      code: "VALIDATION_ERROR",
      status: 422,
      errors: err.errors,
    })
  }

  console.error(err)
  res.status(500).json({
    detail: "Internal server error",
    code: "INTERNAL_ERROR",
    status: 500,
  })
}
```

## Health Endpoints

```
GET /health       # Liveness (no auth)
GET /ready        # Readiness with dependency checks (no auth)
```'

# shellcheck disable=SC2034
RULES_CONTENT_CROSS_SERVICE='# Cross-Service Patterns

> **When to use:** Ensuring consistency across modules, understanding shared conventions.
>
> **Read first for:** Type definitions, error handling, environment variables.

## TypeScript Conventions

- **Strict mode** enabled in `tsconfig.json`
- Prefer `interface` for object shapes, `type` for unions/intersections
- Use `unknown` over `any` — narrow types explicitly
- Never use `as` type assertions unless absolutely necessary (prefer type guards)

## Date/Time Format

All timestamps use **ISO 8601 UTC**: `2026-01-01T12:00:00Z`

```typescript
const now = new Date().toISOString() // "2026-01-01T12:00:00.000Z"
```

## Error Handling

```typescript
// Use Result pattern for expected failures
type Result<T, E = Error> = { ok: true; value: T } | { ok: false; error: E }

// Throw only for unexpected failures (bugs, invariant violations)
// Return Result for expected failures (not found, validation, auth)
```

## Environment Variables

```typescript
// config.ts — validate at startup, not at usage
import { z } from "zod"

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
})

export const config = envSchema.parse(process.env)
```

**Secrets are NEVER committed to git.** Use `.env` locally, secrets manager in production.

## Import Conventions

```typescript
// 1. Node.js built-ins
import { readFile } from "node:fs/promises"

// 2. External packages
import { z } from "zod"

// 3. Internal modules (use path aliases)
import { db } from "@/db"
import { UserService } from "@/services/user"
import type { User } from "@/types"
```

## Logging

```typescript
import pino from "pino"

const logger = pino({ level: process.env.LOG_LEVEL ?? "info" })

logger.info({ resourceId, userId }, "resource created")
logger.error({ err, query }, "database error")
```

**Never log:** passwords, tokens, PII, full request bodies with sensitive data.

## Testing Patterns

```typescript
import { describe, it, expect, beforeEach } from "vitest"

describe("UserService", () => {
  let service: UserService

  beforeEach(() => {
    service = new UserService(mockDb)
  })

  it("creates a user", async () => {
    const user = await service.create({ name: "Test" })
    expect(user.name).toBe("Test")
  })
})
```'

LINT_LANGUAGES="TypeScript/JS (eslint + prettier), JSON, YAML, Shell (shellcheck)"
