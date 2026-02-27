# Database Patterns

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
- Indexes: name pattern `idx_<table>_<columns>`
