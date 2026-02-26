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
│   └── hooks/
│       └── lint-on-edit.sh
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

LINT_LANGUAGES="Python (ruff check + ruff format), YAML, JSON, Shell (shellcheck)"
