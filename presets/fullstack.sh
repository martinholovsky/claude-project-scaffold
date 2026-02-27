#!/usr/bin/env bash
# Preset: Full-stack (backend + frontend)

preset_name="fullstack"
preset_description="Full-stack project with backend API, frontend, and cross-service contracts"

# Rules files: newline-delimited "filename|description" pairs
RULES_FILES="api-contracts.md|Inter-service API contracts — the source of truth for request/response shapes
architecture.md|System architecture, service boundaries"

# Technology stack entries
TECH_STACK="| Frontend | *React / Vue / Svelte / Next.js / Nuxt* |
| Backend API | *FastAPI / Express / Hono / other* |
| Database | *PostgreSQL / MongoDB / other* |
| Auth | *JWT / OAuth2 / session-based* |
| Testing | *pytest + Vitest / Jest* |"

# Development workflow
WORKFLOW='```bash
# Backend
cd backend && # install deps && start dev server

# Frontend (separate terminal)
cd frontend && # install deps && start dev server
```'

# Project conventions
PROJECT_CONVENTIONS='- Monorepo: implement backend (contract producer) first, then frontend (consumer).
- Backend is the security boundary — frontend never accesses DB or queue directly.
- Run backend and frontend dev servers in separate terminals.'

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
TROUBLESHOOTING_SECTIONS='### Symptom: Frontend gets CORS errors when calling backend

**Diagnosis:** Backend not configured to allow requests from the frontend origin.

**Fix:** Configure CORS on the backend to allow the frontend dev server origin.

---

### Symptom: Frontend receives 401 but user is logged in

**Diagnosis:** JWT token not being sent in the Authorization header, or token expired.

**Fix:** Check the frontend API client includes `Authorization: Bearer <token>`. Verify token expiry. Implement token refresh logic.'

# Memory topics: "filename|description" pairs
MEMORY_TOPICS="api-patterns.md|API endpoint patterns and contract decisions
frontend-patterns.md|UI components, state management, routing conventions
debugging.md|Cross-service errors and solutions
cross-service.md|Integration issues between frontend and backend"

# Slash commands to scaffold
COMMANDS="review.md
test.md
smoke.md
lint.md"

# --- Substantive Rules Content ---

# shellcheck disable=SC2034
RULES_CONTENT_API_CONTRACTS='# API Contracts

> Document your actual API endpoints here. This is the source of truth for frontend-backend communication.

## Base URLs

- **Backend dev:** `http://localhost:8000/api/v1`
- **Frontend dev:** `http://localhost:3000`

## Authentication Flow

```
1. User clicks "Sign in" in frontend
2. Frontend redirects to: GET /api/v1/auth/login
3. Backend handles OAuth / credential verification
4. Backend issues JWT, returns to frontend
5. Frontend stores JWT, includes in Authorization header
6. Backend validates JWT on every protected request
```

## Endpoints

*Add your real endpoints below as you build them:*

```
GET  /api/v1/resources          # List (paginated)
POST /api/v1/resources          # Create
GET  /api/v1/resources/{id}     # Get one
PATCH /api/v1/resources/{id}    # Update
```'

# shellcheck disable=SC2034
RULES_CONTENT_ARCHITECTURE='# System Architecture

## Service Boundaries

| Concern | Owner |
|---------|-------|
| Authentication, authorization | Backend |
| Data validation (business rules) | Backend |
| Input sanitization (UI) | Frontend |
| API response formatting | Backend |
| Routing, page rendering | Frontend |

**Rule:** All data flows through the backend API. The frontend NEVER accesses the
database or message queue directly. The backend is the security boundary.'

LINT_LANGUAGES="Python (ruff) or TypeScript/JS (eslint + prettier), YAML, JSON, Shell (shellcheck)"