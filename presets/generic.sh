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
│   └── hooks/
│       └── lint-on-edit.sh
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

LINT_LANGUAGES="Detected from file extensions. Supports: Python (ruff), TypeScript/JS (eslint+prettier), Go (gofmt), Rust (rustfmt), YAML, JSON, Shell (shellcheck)."
