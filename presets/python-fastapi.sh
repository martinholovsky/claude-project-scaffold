#!/usr/bin/env bash
# Preset: Python/FastAPI backend

preset_name="python-fastapi"
preset_description="Python/FastAPI backend with API contracts, testing, database patterns"

# Rules files: newline-delimited "filename|description" pairs
RULES_FILES="api-contracts.md|API endpoint contracts, request/response shapes, auth flow
database.md|Database schema, migrations, query patterns
cross-service.md|Shared patterns, error handling, environment variables"

# Technology stack entries
TECH_STACK="| Backend API | FastAPI, Python 3.12+, Pydantic v2 |
| Database | *PostgreSQL / SQLite / other* |
| Testing | pytest, httpx (async) |
| Linting | ruff (check + format) |
| Auth | *JWT / OAuth2 / session-based* |"

# Context loading table entries
CONTEXT_LOADING_TABLE="| **New API endpoint** | \`.claude/rules/api-contracts.md\`, \`app/routers/\` |
| **Database changes** | \`.claude/rules/database.md\`, \`app/models/\` |
| **Auth changes** | \`.claude/rules/api-contracts.md\` (Auth section), \`app/auth/\` |
| **Debugging** | \`.claude/rules/troubleshooting.md\` |
| **Architecture decisions** | \`docs/decisions/index.md\` |
| **Cross-service patterns** | \`.claude/rules/cross-service.md\` |"

# Context groups
CONTEXT_GROUPS='### `api`
Read: `.claude/rules/api-contracts.md`, `app/routers/`, `app/schemas/`

### `database`
Read: `.claude/rules/database.md`, `app/models/`, `app/db/`

### `auth`
Read: `.claude/rules/api-contracts.md` (Auth section), `app/auth/`

### `debug`
Read: `.claude/rules/troubleshooting.md`'

# Development workflow
WORKFLOW='```bash
# Setup
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt  # or: pip install -e ".[dev]"

# Run dev server
uvicorn app.main:app --reload --port 8000

# Run tests
pytest -v

# Lint
ruff check --fix .
ruff format .

# Type check (if using mypy)
mypy app/
```

### API Documentation

FastAPI auto-generates docs:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- OpenAPI JSON: `http://localhost:8000/openapi.json`'

# Project overview
PROJECT_OVERVIEW="FastAPI backend service. All API endpoints are under \`/api/v1/\`."

# Workspace structure
WORKSPACE_STRUCTURE='{{PROJECT_NAME}}/
├── CLAUDE.md
├── .claude/
│   ├── rules/
│   │   ├── api-contracts.md
│   │   ├── database.md
│   │   ├── cross-service.md
│   │   └── troubleshooting.md
│   ├── hooks/
│   │   └── lint-on-edit.sh
│   ├── memory/
│   │   ├── MEMORY.md
│   │   ├── api-patterns.md
│   │   ├── database-gotchas.md
│   │   └── debugging.md
│   └── commands/
│       ├── review.md
│       ├── test.md
│       ├── plan.md
│       ├── smoke.md
│       └── lint.md
├── app/
│   ├── main.py
│   ├── routers/
│   ├── models/
│   ├── schemas/
│   ├── services/
│   ├── db/
│   └── auth/
├── tests/
├── docs/
│   ├── plans/
│   │   └── .plan-template.md
│   └── decisions/
│       ├── index.md
│       └── adr-template.md
├── scripts/
│   └── smoke-backend.sh
├── requirements.txt
└── pyproject.toml'

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
TROUBLESHOOTING_SECTIONS='## 1. FastAPI / Uvicorn

### Symptom: `ModuleNotFoundError` when starting uvicorn

**Diagnosis:** Virtual environment not activated, or dependency not installed.

**Fix:**
```bash
source .venv/bin/activate
pip install -r requirements.txt
```

---

### Symptom: 422 Unprocessable Entity on POST requests

**Diagnosis:** Request body does not match the Pydantic schema. FastAPI returns 422
with field-level validation errors in the response body.

**Fix:** Check the response body `detail` array for which fields failed validation.
Compare your request body against the Pydantic model in `app/schemas/`.

---

## 2. Database

### Symptom: {describe database issue}

**Diagnosis:** {root cause}

**Fix:**
```bash
# commands to resolve
```

---

## 3. Authentication

*Add entries as you encounter auth-related issues.*

---

## 4. Testing

### Symptom: Tests pass locally but fail in CI

**Diagnosis:** Usually an environment difference (missing env var, database state, timezone).

**Fix:** Ensure CI sets the same environment variables as local `.env`. Check for
test isolation — tests should not depend on execution order.

---

*Add entries as you encounter and solve issues. Use the Symptom -> Diagnosis -> Fix format.*'

# Memory topics: "filename|description" pairs
MEMORY_TOPICS="api-patterns.md|Endpoint patterns, Pydantic schemas, middleware conventions
database-gotchas.md|Database query issues, migration problems, ORM patterns
debugging.md|Common errors encountered and their solutions"

# Slash commands to scaffold
COMMANDS="review.md
test.md
plan.md
smoke.md
lint.md"

# --- Substantive Rules Content ---

# shellcheck disable=SC2034
RULES_CONTENT_API_CONTRACTS='# API Contracts

> **When to use:** Adding or modifying API endpoints, debugging request/response mismatches.
>
> **Read first for:** Any new endpoint, schema changes, auth-related work.

## Base URL

- **Production:** `https://api.example.com/api/v1`
- **Local dev:** `http://localhost:8000/api/v1`

## Authentication

All protected endpoints require `Authorization: Bearer <jwt>` header.

```python
# dependencies.py
async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
    user = await get_user_by_id(payload["sub"])
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user
```

## Request/Response Patterns

### Creating a resource
```
POST /api/v1/resources
Body: { "name": "...", "description": "..." }
Response: 201 { "id": "...", "name": "...", ... }
```

### Listing resources (paginated)
```
GET /api/v1/resources?limit=50&offset=0&sort=created_at&order=desc
Response: { "items": [...], "total": 123, "offset": 0, "limit": 50 }
```

### Getting a single resource
```
GET /api/v1/resources/{id}
Response: 200 { full resource }
Response: 404 { "detail": "Resource not found", "code": "NOT_FOUND" }
```

### Updating a resource
```
PATCH /api/v1/resources/{id}
Body: { fields to update }
Response: 200 { updated resource }
```

## Pydantic Schema Conventions

```python
from pydantic import BaseModel, Field
from datetime import datetime

class ResourceCreate(BaseModel):
    """Schema for creating a resource."""
    name: str = Field(..., min_length=1, max_length=255)
    description: str | None = None

class ResourceResponse(BaseModel):
    """Schema for resource responses."""
    id: str
    name: str
    description: str | None
    created_at: datetime
    updated_at: datetime

class ResourceList(BaseModel):
    """Paginated list response."""
    items: list[ResourceResponse]
    total: int
    offset: int
    limit: int
```

## Error Response Format

```json
{
  "detail": "Human-readable error message",
  "code": "ERROR_CODE",
  "status": 404
}
```

| Status | Code | When |
|--------|------|------|
| 400 | `BAD_REQUEST` | Malformed input |
| 401 | `UNAUTHORIZED` | Missing or invalid token |
| 403 | `FORBIDDEN` | Valid token but insufficient permissions |
| 404 | `NOT_FOUND` | Resource does not exist |
| 422 | `VALIDATION_ERROR` | Pydantic validation failed |
| 429 | `RATE_LIMITED` | Too many requests |

## Health Endpoints

```
GET /health          # Kubernetes liveness (no auth required)
GET /ready           # Kubernetes readiness (no auth required)
GET /api/v1/health   # Detailed health with dependency checks (auth required)
```'

# shellcheck disable=SC2034
RULES_CONTENT_DATABASE='# Database Patterns

> **When to use:** Schema changes, new queries, migration work, debugging data issues.
>
> **Read first for:** Any database-related task.

## Connection Management

```python
# db.py — singleton async connection
from contextlib import asynccontextmanager

@asynccontextmanager
async def get_db():
    """Get database session. Use as async context manager."""
    session = SessionLocal()
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()
```

## Migration Patterns

```bash
# Create a new migration
alembic revision --autogenerate -m "add_users_table"

# Apply migrations
alembic upgrade head

# Rollback one step
alembic downgrade -1
```

**Rules:**
- Never modify a migration that has been applied to production
- Always review auto-generated migrations before applying
- Add indexes in the same migration as the table they index

## Query Patterns

### Pagination
```python
async def list_items(db, offset: int = 0, limit: int = 50) -> tuple[list, int]:
    total = await db.scalar(select(func.count()).select_from(Item))
    items = await db.scalars(
        select(Item).offset(offset).limit(limit).order_by(Item.created_at.desc())
    )
    return list(items), total
```

### Filtering
```python
async def search_items(db, query: str, status: str | None = None):
    stmt = select(Item)
    if query:
        stmt = stmt.where(Item.name.ilike(f"%{query}%"))
    if status:
        stmt = stmt.where(Item.status == status)
    return list(await db.scalars(stmt))
```

## Schema Conventions

- Table names: lowercase plural (`users`, `items`, `organizations`)
- Primary keys: `id` (UUID or auto-increment)
- Timestamps: `created_at`, `updated_at` (UTC, auto-set)
- Foreign keys: `<table_singular>_id` (e.g., `user_id`, `org_id`)
- Indexes: name pattern `idx_<table>_<columns>`'

# shellcheck disable=SC2034
RULES_CONTENT_CROSS_SERVICE='# Cross-Service Patterns

> **When to use:** Ensuring consistency, understanding shared conventions.
>
> **Read first for:** Error handling, date formats, environment variables.

## Date/Time Format

All timestamps use **ISO 8601 UTC**: `2026-01-01T12:00:00Z`

```python
from datetime import datetime, timezone
now = datetime.now(timezone.utc)
```

## Error Handling

```python
from fastapi import HTTPException

# Standard error response
raise HTTPException(
    status_code=404,
    detail="Resource not found"
)

# With custom error code
from fastapi.responses import JSONResponse
return JSONResponse(
    status_code=404,
    content={"detail": "Resource not found", "code": "NOT_FOUND", "status": 404}
)
```

## Environment Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `DATABASE_URL` | `.env` / Secret | Database connection string |
| `SECRET_KEY` | Secret | JWT signing key |
| `CORS_ORIGINS` | Config | Allowed CORS origins (comma-separated) |
| `LOG_LEVEL` | Config | Logging level (DEBUG, INFO, WARNING, ERROR) |

**Secrets are NEVER committed to git.** Use `.env` locally, secrets manager in production.

## Logging

```python
import structlog

logger = structlog.get_logger()

logger.info("resource_created", resource_id=resource.id, user_id=user.id)
logger.error("database_error", error=str(e), query=query_name)
```

**Never log:** passwords, tokens, PII, full request bodies with sensitive data.

## Testing Conventions

```python
import pytest
from httpx import AsyncClient

@pytest.fixture
async def client(app):
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

async def test_create_resource(client):
    response = await client.post("/api/v1/resources", json={"name": "test"})
    assert response.status_code == 201
    assert response.json()["name"] == "test"
```'

LINT_LANGUAGES="Python (ruff check + ruff format), YAML, JSON, Shell (shellcheck)"
