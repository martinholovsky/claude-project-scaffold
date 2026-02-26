# CLAUDE.md — inventory-api

REST API for inventory management

## Project Overview

FastAPI backend service. All API endpoints are under `/api/v1/`.

## Workspace Structure

```
inventory-api/
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
└── pyproject.toml
```

## Technology Stack

| Component | Technology |
|-----------|-----------|
| Backend API | FastAPI, Python 3.12+, Pydantic v2 |
| Database | *PostgreSQL / SQLite / other* |
| Testing | pytest, httpx (async) |
| Linting | ruff (check + format) |
| Auth | *JWT / OAuth2 / session-based* |

## Proactive Context Loading

**Before starting ANY task, read the relevant rules files.**

| Task | Read First |
|------|-----------|
| **New API endpoint** | `.claude/rules/api-contracts.md`, `app/routers/` |
| **Database changes** | `.claude/rules/database.md`, `app/models/` |
| **Auth changes** | `.claude/rules/api-contracts.md` (Auth section), `app/auth/` |
| **Debugging** | `.claude/rules/troubleshooting.md` |
| **Architecture decisions** | `docs/decisions/index.md` |
| **Cross-service patterns** | `.claude/rules/cross-service.md` |

## Development Workflow

```bash
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
- OpenAPI JSON: `http://localhost:8000/openapi.json`

## Context Groups

**Use these to quickly load all relevant files for a task type.** Say "load {group} context" to trigger.

### `api`
Read: `.claude/rules/api-contracts.md`, `app/routers/`, `app/schemas/`

### `database`
Read: `.claude/rules/database.md`, `app/models/`, `app/db/`

### `auth`
Read: `.claude/rules/api-contracts.md` (Auth section), `app/auth/`

### `debug`
Read: `.claude/rules/troubleshooting.md`

## Plan Execution Protocol (SESSION RECOVERY)

**All multi-step tasks MUST use a plan file.** This prevents context loss when sessions freeze.

### When to Create a Plan File

- Any task with 3+ steps
- Any task touching multiple files or repos
- Any infrastructure change
- When the user asks to "plan", "implement", or work on a non-trivial feature

### Workflow

1. **Before coding**, create a plan file from the template:
   ```
   cp docs/plans/.plan-template.md docs/plans/plan-{topic}.md
   ```
2. **Fill in** the objective, context, and steps
3. **Update the checklist** as each step completes — mark `[x]` and add notes to the Progress Log
4. **Commit the plan file** alongside code changes (or separately if no code yet)
5. **On completion**, set status to `completed` and update the final Progress Log entry

### Session Recovery

When starting a new session and an active plan exists:
1. Check `docs/plans/` for any plan with `Status: in-progress`
2. Read the plan file to restore full context
3. Resume from the last completed step in the Progress Log
4. The user can say: **"Continue the plan"** or **"Resume docs/plans/plan-{topic}.md"**

### Rules

- **One active plan per topic** — don't create duplicates
- **Update Progress Log after every completed step** — this is the lifeline for recovery
- **"Stopped at" is mandatory** — always record where you stopped and what's next
- **Commit plan updates** with code changes so they survive across sessions
- **Delete or mark `abandoned`** plans that are no longer relevant
