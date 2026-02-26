---
description: Run linters and auto-fix issues
allowed-tools: Bash(ruff:*), Bash(eslint:*), Bash(prettier:*), Bash(npx:*), Bash(gofmt:*), Bash(rustfmt:*), Bash(shellcheck:*), Read, Edit
---

Run the project's linters and auto-fix what can be fixed automatically:

- Python: `ruff check --fix . && ruff format .`
- TypeScript/JS: `npx eslint --fix . && npx prettier --write .`
- Go: `gofmt -w . && goimports -w .`
- Rust: `cargo fmt`
- Shell: `shellcheck scripts/*.sh`

Report any issues that require manual intervention.

$ARGUMENTS
