#!/usr/bin/env bash
# Preset: Python/FastAPI backend

preset_name="python-fastapi"
preset_description="Python/FastAPI backend with API contracts, testing, database patterns"

# Rules files: newline-delimited "filename|description" pairs
RULES_FILES="api-contracts.md|API endpoint contracts, request/response shapes, auth flow
database.md|Database schema, migrations, query patterns"

# Technology stack entries
TECH_STACK="| Backend API | FastAPI, Python 3.12+, Pydantic v2 |
| Database | *PostgreSQL / SQLite / other* |
| Testing | pytest, httpx (async) |
| Linting | ruff (check + format) |
| Auth | *JWT / OAuth2 / session-based* |"

# Development workflow
WORKFLOW='```bash
# Setup
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt  # or: pip install -e ".[dev]"

# Run dev server
uvicorn app.main:app --reload --port 8000

# Run tests
pytest -v

# Lint
ruff check --fix . && ruff format .
```'

# Project conventions
PROJECT_CONVENTIONS='- API versioned at `/api/v1/`. All endpoints require `Authorization: Bearer <jwt>` unless noted.
- Run `ruff check --fix . && ruff format .` before committing.
- Run `pytest -v` to verify changes.'

# Smoke test scripts: "filename|title|checks_variable_name"
SMOKE_SCRIPTS="smoke-backend.sh|Backend Health Checks|SMOKE_BACKEND_CHECKS"

# Smoke test check bodies (referenced by variable name above)
# shellcheck disable=SC2034
SMOKE_BACKEND_CHECKS='section "Application"

if [[ -f "app/main.py" ]]; then
  pass "app/main.py exists"
else
  fail "app/main.py not found"
fi

if python3 -c "import fastapi" 2>/dev/null; then
  pass "FastAPI is installed"
else
  fail "FastAPI is not installed (pip install fastapi)"
fi

section "Configuration"

if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
  pass "Dependency file exists"
else
  warn "No requirements.txt or pyproject.toml found"
fi

section "Linting"

if command -v ruff >/dev/null 2>&1; then
  if ruff check --quiet app/ 2>/dev/null; then
    pass "ruff check passes"
  else
    warn "ruff check has findings"
  fi
else
  warn "ruff not installed"
fi

section "Tests"

if command -v pytest >/dev/null 2>&1; then
  if pytest --co -q 2>/dev/null | grep -q "test"; then
    pass "Tests discovered by pytest"
  else
    warn "No tests found"
  fi
else
  warn "pytest not installed"
fi'

# Troubleshooting sections
TROUBLESHOOTING_SECTIONS='### Symptom: `ModuleNotFoundError` when starting uvicorn

**Diagnosis:** Virtual environment not activated, or dependency not installed.

**Fix:**
```bash
source .venv/bin/activate
pip install -r requirements.txt
```

---

### Symptom: 422 Unprocessable Entity on POST requests

**Diagnosis:** Request body does not match the Pydantic schema. Check the response body `detail` array for which fields failed validation.

**Fix:** Compare your request body against the Pydantic model in `app/schemas/`.'

# Memory topics: "filename|description" pairs
MEMORY_TOPICS="api-patterns.md|Endpoint patterns, Pydantic schemas, middleware conventions
database-gotchas.md|Database query issues, migration problems, ORM patterns
debugging.md|Common errors encountered and their solutions"

# Slash commands to scaffold
COMMANDS="review.md
test.md
smoke.md
lint.md"

# --- Substantive Rules Content ---

# shellcheck disable=SC2034
RULES_CONTENT_API_CONTRACTS='# API Contracts

> Document your actual API endpoints here.

## Base URL

- **Local dev:** `http://localhost:8000/api/v1`
- **Production:** `https://api.example.com/api/v1`

## Authentication

All protected endpoints require `Authorization: Bearer <jwt>` header.

## Endpoints

*Add your real endpoints below as you build them:*

```
GET  /api/v1/resources          # List (paginated)
POST /api/v1/resources          # Create
GET  /api/v1/resources/{id}     # Get one
PATCH /api/v1/resources/{id}    # Update
```'

# shellcheck disable=SC2034
RULES_CONTENT_DATABASE='# Database Patterns

## Migrations

```bash
# Create a new migration
alembic revision --autogenerate -m "add_users_table"

# Apply migrations
alembic upgrade head

# Rollback one step
alembic downgrade -1
```

## Schema Naming Conventions

- Table names: lowercase plural (`users`, `items`, `organizations`)
- Primary keys: `id` (UUID or auto-increment)
- Timestamps: `created_at`, `updated_at` (UTC, auto-set)
- Foreign keys: `<table_singular>_id` (e.g., `user_id`, `org_id`)
- Indexes: name pattern `idx_<table>_<columns>`'

LINT_LANGUAGES="Python (ruff check + ruff format), YAML, JSON, Shell (shellcheck)"