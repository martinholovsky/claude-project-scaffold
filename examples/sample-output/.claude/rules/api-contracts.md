# API Contracts

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
```
