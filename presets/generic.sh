#!/usr/bin/env bash
# Preset: Generic (minimal scaffolding for any project)

preset_name="generic"
preset_description="Minimal scaffolding — CLAUDE.md, plan template, ADR template, troubleshooting skeleton, lint hook"

# Rules files: newline-delimited "filename|description" pairs
RULES_FILES="cross-service.md|Shared patterns, conventions, and error handling"

# Technology stack entries (Markdown table rows)
TECH_STACK="| Language | *detected or specify* |"

# Context loading table entries
CONTEXT_LOADING_TABLE="| **Any task** | \`CLAUDE.md\`, relevant \`.claude/rules/\` files |
| **Debugging** | \`.claude/rules/troubleshooting.md\` |
| **Architecture decisions** | \`docs/decisions/index.md\` |"

# Context groups
CONTEXT_GROUPS='### `debug`
Read: `.claude/rules/troubleshooting.md`

### `architecture`
Read: `docs/decisions/index.md`, then relevant ADR files'

# Development workflow
WORKFLOW='```bash
# Install dependencies
# ...

# Run development server
# ...

# Run tests
# ...
```'

# Project overview
PROJECT_OVERVIEW="*Add a 1-2 sentence description of what this project does.*"

# Workspace structure
WORKSPACE_STRUCTURE='{{PROJECT_NAME}}/
├── CLAUDE.md
├── .claude/
│   ├── rules/
│   │   └── troubleshooting.md
│   ├── hooks/
│   │   └── lint-on-edit.sh
│   ├── memory/
│   │   ├── MEMORY.md
│   │   ├── debugging.md
│   │   └── patterns.md
│   └── commands/
│       ├── review.md
│       ├── test.md
│       └── plan.md
├── docs/
│   ├── plans/
│   │   └── .plan-template.md
│   └── decisions/
│       ├── index.md
│       └── adr-template.md
└── scripts/'

# Smoke test scripts: newline-delimited "filename|title|checks_variable_name"
SMOKE_SCRIPTS=""

# Troubleshooting sections
TROUBLESHOOTING_SECTIONS='## 1. Common Issues

### Symptom: {describe what you observe}

**Diagnosis:** {explain the root cause}

**Fix:**
```bash
# commands to resolve
```

---

*Add entries as you encounter and solve issues. Use the Symptom → Diagnosis → Fix format
consistently so Claude can match error patterns to known solutions.*'

# Memory topics: "filename|description" pairs
MEMORY_TOPICS="debugging.md|Common issues, error patterns, and solutions
patterns.md|Recurring patterns and conventions confirmed across sessions"

# Slash commands to scaffold
COMMANDS="review.md
test.md
plan.md"

# --- Substantive Rules Content ---
# Variable naming: RULES_CONTENT_<FILENAME_UPPER> where hyphens become underscores

# shellcheck disable=SC2034
RULES_CONTENT_CROSS_SERVICE='# Cross-Service Patterns

> **When to use:** Ensuring consistency across modules, understanding shared conventions.
>
> **Read first for:** Error handling patterns, date formats, ID conventions.

## Date/Time Format

All timestamps use **ISO 8601 UTC**: `2026-01-01T12:00:00Z`

## ID Format

Use string IDs consistently. Frontend treats IDs as opaque strings — never parse or
construct IDs client-side.

## Error Handling

Return structured errors:
```json
{
  "detail": "Human-readable error message",
  "code": "ERROR_CODE",
  "status": 404
}
```

Handle errors consistently:
- 400 — Bad request (malformed input)
- 401 — Not authenticated
- 403 — Authenticated but not authorized
- 404 — Resource not found
- 422 — Validation error (field-level details in response)
- 429 — Rate limited (check Retry-After header)
- 500 — Internal server error (log, do not expose internals)

## Pagination

All list endpoints use offset-based pagination:
```json
{
  "items": [...],
  "total": 1234,
  "offset": 0,
  "limit": 50
}
```

Query params: `?limit=50&offset=0&sort=created_at&order=desc`

## Environment Variables

| Variable | Source | Description |
|----------|--------|-------------|
| *Add your env vars here* | | |

**Secrets are NEVER committed to git.** Use environment variables or a secrets manager.

## Logging

Use structured JSON logging:
```json
{
  "timestamp": "2026-01-01T12:00:00Z",
  "level": "INFO",
  "message": "Description of what happened",
  "service": "my-service"
}
```

**Never log:** passwords, tokens, PII, or full request bodies containing sensitive data.'

LINT_LANGUAGES="Detected from file extensions. Supports: Python (ruff), TypeScript/JS (eslint+prettier), Go (gofmt), Rust (rustfmt), YAML, JSON, Shell (shellcheck)."
