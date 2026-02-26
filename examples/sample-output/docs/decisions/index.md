# Architecture Decision Records

> Decisions that shape inventory-api's architecture. Each ADR captures context,
> alternatives considered, and rationale so future contributors understand *why*.

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| — | *No decisions recorded yet* | — | — |

## How to Add a New ADR

1. Copy the template:
   ```bash
   cp docs/decisions/adr-template.md docs/decisions/NNN-short-title.md
   ```
2. Fill in the context, decision, alternatives, and consequences
3. Update this index table
4. Commit with the code change it relates to (or separately if it's a pre-implementation decision)

## Conventions

- Number ADRs sequentially: `001`, `002`, etc.
- Use kebab-case filenames: `001-use-postgres.md`
- **accepted** = active and followed
- **deprecated** = no longer relevant (but kept for history)
- **superseded** = replaced by a newer ADR (link to it)
