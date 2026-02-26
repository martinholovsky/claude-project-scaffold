# Cross-Service Patterns

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
```
