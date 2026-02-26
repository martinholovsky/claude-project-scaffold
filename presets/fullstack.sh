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
│   └── hooks/
│       └── lint-on-edit.sh
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

LINT_LANGUAGES="Python (ruff) or TypeScript/JS (eslint + prettier), YAML, JSON, Shell (shellcheck)"
