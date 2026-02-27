# my-api

FastAPI REST API for widgets

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend API | FastAPI, Python 3.12+, Pydantic v2 |
| Database | *PostgreSQL / SQLite / other* |
| Testing | pytest, httpx (async) |
| Linting | ruff (check + format) |
| Auth | *JWT / OAuth2 / session-based* |

## Dev Commands

```bash
# Setup
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt  # or: pip install -e ".[dev]"

# Run dev server
uvicorn app.main:app --reload --port 8000

# Run tests
pytest -v

# Lint
ruff check --fix . && ruff format .
```

## Project Conventions

- API versioned at `/api/v1/`. All endpoints require `Authorization: Bearer <jwt>` unless noted.
- Run `ruff check --fix . && ruff format .` before committing.
- Run `pytest -v` to verify changes.