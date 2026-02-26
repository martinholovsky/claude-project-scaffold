#!/usr/bin/env bash
# Preset: Full-stack (backend + frontend)

preset_name="fullstack"
preset_description="Full-stack project with backend API, frontend, cross-service contracts, and API integration patterns"

# Rules files: newline-delimited "filename|description" pairs
RULES_FILES="api-contracts.md|Inter-service API contracts — the source of truth for request/response shapes
architecture.md|System architecture, service boundaries, data flow
cross-service.md|Shared conventions: date formats, IDs, pagination, error handling, env vars"

# Technology stack entries
TECH_STACK="| Frontend | *React / Vue / Svelte / Next.js / Nuxt* |
| Backend API | *FastAPI / Express / Hono / other* |
| Database | *PostgreSQL / MongoDB / other* |
| Auth | *JWT / OAuth2 / session-based* |
| Testing | *pytest + Vitest / Jest* |"

# Context loading table entries
CONTEXT_LOADING_TABLE="| **Backend API work** | \`backend/CLAUDE.md\` (if exists), \`.claude/rules/api-contracts.md\` |
| **Frontend UI work** | \`frontend/CLAUDE.md\` (if exists), \`.claude/rules/api-contracts.md\` |
| **Cross-service feature** | \`.claude/rules/architecture.md\`, \`.claude/rules/api-contracts.md\`, then both service dirs |
| **Auth changes** | \`.claude/rules/architecture.md\` (Auth section), \`.claude/rules/api-contracts.md\` |
| **Database changes** | \`backend/\` models/schemas |
| **Debugging** | \`.claude/rules/troubleshooting.md\` |
| **Architecture decisions** | \`docs/decisions/index.md\` |"

# Context groups
CONTEXT_GROUPS='### `api`
Read: `.claude/rules/api-contracts.md`, backend routes/routers, frontend API client

### `auth`
Read: `.claude/rules/architecture.md` (Auth section), `.claude/rules/api-contracts.md` (Auth endpoints),
backend auth module, frontend auth store/composable

### `cross-service`
Read: `.claude/rules/cross-service.md`, `.claude/rules/api-contracts.md`

### `debug`
Read: `.claude/rules/troubleshooting.md`

### `architecture`
Read: `.claude/rules/architecture.md`, `docs/decisions/index.md`'

# Development workflow
WORKFLOW='### Cross-Service Tasks

When a task spans backend + frontend:
1. Read `.claude/rules/api-contracts.md` for the contract
2. Implement backend first (API contract producer)
3. Implement frontend second (API contract consumer)
4. Test the integration

```bash
# Backend
cd backend && # install deps && start dev server

# Frontend (separate terminal)
cd frontend && # install deps && start dev server
```'

# Project overview
PROJECT_OVERVIEW="Full-stack application with separate backend and frontend."

# Workspace structure
WORKSPACE_STRUCTURE='{{PROJECT_NAME}}/
├── CLAUDE.md                    # Root orchestrator
├── .claude/
│   ├── rules/
│   │   ├── architecture.md      # System architecture & data flow
│   │   ├── api-contracts.md     # Inter-service API contracts
│   │   ├── cross-service.md     # Shared conventions
│   │   └── troubleshooting.md   # Error playbook
│   ├── hooks/
│   │   └── lint-on-edit.sh
│   ├── memory/
│   │   ├── MEMORY.md
│   │   ├── api-patterns.md
│   │   ├── frontend-patterns.md
│   │   ├── debugging.md
│   │   └── cross-service.md
│   └── commands/
│       ├── review.md
│       ├── test.md
│       ├── plan.md
│       ├── smoke.md
│       └── lint.md
├── backend/
│   ├── CLAUDE.md                # Backend-specific instructions (optional)
│   └── ...
├── frontend/
│   ├── CLAUDE.md                # Frontend-specific instructions (optional)
│   └── ...
├── docs/
│   ├── plans/
│   │   └── .plan-template.md
│   └── decisions/
│       ├── index.md
│       └── adr-template.md
└── scripts/
    ├── smoke-backend.sh
    └── smoke-frontend.sh'

# Smoke test scripts: "filename|title|checks_variable_name"
SMOKE_SCRIPTS="smoke-backend.sh|Backend Health Checks|SMOKE_BACKEND_CHECKS
smoke-frontend.sh|Frontend Health Checks|SMOKE_FRONTEND_CHECKS"

# shellcheck disable=SC2034
SMOKE_BACKEND_CHECKS='section "Backend"

if [[ -d "backend" ]]; then
  pass "backend/ directory exists"
else
  fail "backend/ directory not found"
fi

section "Backend Dependencies"

if [[ -f "backend/requirements.txt" ]] || [[ -f "backend/package.json" ]] || [[ -f "backend/pyproject.toml" ]]; then
  pass "Backend dependency file exists"
else
  warn "No dependency file found in backend/"
fi

section "API Contracts"

if [[ -f ".claude/rules/api-contracts.md" ]]; then
  pass "API contracts file exists"
else
  warn "No API contracts defined yet"
fi'

# shellcheck disable=SC2034
SMOKE_FRONTEND_CHECKS='section "Frontend"

if [[ -d "frontend" ]]; then
  pass "frontend/ directory exists"
else
  fail "frontend/ directory not found"
fi

section "Frontend Dependencies"

if [[ -f "frontend/package.json" ]]; then
  pass "frontend/package.json exists"
else
  fail "frontend/package.json not found"
fi

if [[ -d "frontend/node_modules" ]]; then
  pass "frontend/node_modules exists"
else
  fail "frontend dependencies not installed — cd frontend && npm install"
fi

section "Build"

if (cd frontend && npm run build 2>/dev/null); then
  pass "Frontend builds successfully"
else
  warn "Frontend build failed or no build script"
fi'

# Troubleshooting sections
TROUBLESHOOTING_SECTIONS='## 1. Cross-Service / API Integration

### Symptom: Frontend gets CORS errors when calling backend

**Diagnosis:** Backend is not configured to allow requests from the frontend origin.

**Fix:** Configure CORS on the backend to allow the frontend dev server origin:
- FastAPI: `CORSMiddleware(allow_origins=["http://localhost:3000"])`
- Express: `cors({ origin: "http://localhost:3000" })`

---

### Symptom: Frontend receives 401 but user is logged in

**Diagnosis:** JWT token is not being sent in the Authorization header, or the token
has expired.

**Fix:** Check the frontend API client is including `Authorization: Bearer <token>`.
Verify the token expiry in jwt.io. Implement token refresh logic.

---

## 2. Backend

### Symptom: {describe backend issue}

**Diagnosis:** {root cause}

**Fix:**
```bash
# commands to resolve
```

---

## 3. Frontend

### Symptom: {describe frontend issue}

**Diagnosis:** {root cause}

**Fix:**
```bash
# commands to resolve
```

---

## 4. Database

*Add entries as you encounter database issues.*

---

*Add entries as you encounter and solve issues. Use the Symptom -> Diagnosis -> Fix format.*'

# Memory topics: "filename|description" pairs
MEMORY_TOPICS="api-patterns.md|API endpoint patterns and contract decisions
frontend-patterns.md|UI components, state management, routing conventions
debugging.md|Cross-service errors and solutions
cross-service.md|Integration issues between frontend and backend"

# Slash commands to scaffold
COMMANDS="review.md
test.md
plan.md
smoke.md
lint.md"

# --- Substantive Rules Content ---

# shellcheck disable=SC2034
RULES_CONTENT_API_CONTRACTS='# API Contracts

> **When to use:** Adding or modifying API endpoints, implementing frontend API calls.
>
> **Read first for:** Any cross-service feature, new endpoint, data model changes.

## Base URL

- **Production:** `https://api.example.com/api/v1`
- **Local dev:** `http://localhost:8000/api/v1` (backend), `http://localhost:3000` (frontend)

## Authentication Flow

```
1. User clicks "Sign in" in frontend
2. Frontend redirects to: GET /api/v1/auth/login
3. Backend handles OAuth / credential verification
4. Backend issues JWT, returns to frontend
5. Frontend stores JWT, includes in Authorization header
6. Backend validates JWT on every protected request
```

### Token format
```json
{
  "sub": "user-id",
  "email": "user@example.com",
  "role": "user",
  "exp": 1708303600
}
```

## Request/Response Patterns

### Creating a resource
```
POST /api/v1/resources
Headers: Authorization: Bearer <jwt>
Body: { "name": "...", "description": "..." }
Response: 201 { "id": "...", "name": "...", ... }
```

### Listing (paginated)
```
GET /api/v1/resources?limit=50&offset=0&sort=created_at&order=desc
Response: { "items": [...], "total": 123, "offset": 0, "limit": 50 }
```

## Error Response Format

```json
{
  "detail": "Human-readable error message",
  "code": "NOT_FOUND",
  "status": 404
}
```

## Frontend API Client

```typescript
// composables/useApi.ts
const api = $fetch.create({
  baseURL: "/api/v1",
  headers: { Authorization: \`Bearer \${token.value}\` },
  onResponseError({ response }) {
    if (response.status === 401) navigateTo("/login")
  },
})
```'

# shellcheck disable=SC2034
RULES_CONTENT_ARCHITECTURE='# System Architecture

> **When to use:** Understanding service boundaries, planning cross-service features.
>
> **Read first for:** Any task spanning backend + frontend, auth changes, new service design.

## High-Level Architecture

```
          Users
            |
       [API Gateway / Proxy]
            |
     +------+------+
     |             |
  Backend       Frontend
  (API)         (SPA/SSR)
     |
  +--+--+
  |     |
  DB  Queue
```

## Service Boundaries

| Concern | Owner |
|---------|-------|
| Authentication, authorization | Backend |
| Data validation (business rules) | Backend |
| Input sanitization (UI) | Frontend |
| API response formatting | Backend |
| Routing, page rendering | Frontend |
| State management | Frontend |

**Rule:** All data flows through the backend API. The frontend NEVER accesses the
database or message queue directly. The backend is the security boundary.

## Data Flow

```
Frontend → API Request → Backend → Database
Frontend ← API Response ← Backend ← Database
```

For real-time updates:
```
Backend → WebSocket/SSE → Frontend
```

## Environment Separation

| Environment | Backend | Frontend |
|-------------|---------|----------|
| Development | localhost:8000 | localhost:3000 |
| Staging | api.staging.example.com | staging.example.com |
| Production | api.example.com | example.com |'

# shellcheck disable=SC2034
RULES_CONTENT_CROSS_SERVICE='# Cross-Service Patterns

> **When to use:** Ensuring consistency between frontend and backend.
>
> **Read first for:** Shared type definitions, error handling, date formats, env vars.

## Shared Types

Keep types in sync between frontend and backend. When changing an API response shape:
1. Update the backend schema/model
2. Update the frontend TypeScript type
3. Update any API contract documentation

## Date/Time Format

All timestamps use **ISO 8601 UTC**: `2026-01-01T12:00:00Z`

- Backend: `datetime.now(timezone.utc).isoformat()`
- Frontend: `new Date().toISOString()`

## ID Format

IDs are opaque strings. The frontend never parses or constructs IDs.

## Pagination

All list endpoints return:
```json
{ "items": [...], "total": 1234, "offset": 0, "limit": 50 }
```

Query params: `?limit=50&offset=0&sort=created_at&order=desc`

## Error Handling

Backend returns:
```json
{ "detail": "Message", "code": "ERROR_CODE", "status": 404 }
```

Frontend handles:
```typescript
try {
  const data = await api("/resources", { method: "POST", body })
} catch (error) {
  if (error.status === 422) {
    // Show field-level validation errors
  } else if (error.status === 429) {
    // Rate limited — show retry message
  } else {
    toast.error(error.data?.detail || "Something went wrong")
  }
}
```

## CORS Configuration

Backend must allow frontend origin:
```python
# FastAPI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Environment Variables

### Backend
| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Database connection string |
| `SECRET_KEY` | JWT signing key |
| `CORS_ORIGINS` | Allowed frontend origins |

### Frontend
| Variable | Description |
|----------|-------------|
| `API_BASE_URL` | Backend API URL |
| `PUBLIC_URL` | Frontend public URL |

**Secrets are NEVER exposed to the frontend.** All secret-dependent operations go through the backend.'

LINT_LANGUAGES="Python (ruff) or TypeScript/JS (eslint + prettier), YAML, JSON, Shell (shellcheck)"
