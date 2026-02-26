# Database Patterns

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
- Indexes: name pattern `idx_<table>_<columns>`
