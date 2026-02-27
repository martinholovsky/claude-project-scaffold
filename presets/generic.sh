#!/usr/bin/env bash
# Preset: Generic (minimal scaffolding for any project)

preset_name="generic"
preset_description="Minimal scaffolding — CLAUDE.md, ADR template, troubleshooting skeleton, lint hook"

# Rules files: newline-delimited "filename|description" pairs
RULES_FILES=""

# Technology stack entries (Markdown table rows)
TECH_STACK="| Language | *detected or specify* |"

# Development workflow
WORKFLOW='```bash
# Install dependencies
# ...

# Run development server
# ...

# Run tests
# ...
```'

# Project conventions
PROJECT_CONVENTIONS="*Add project-specific conventions here — things Claude would get wrong without being told.*"

# Smoke test scripts: newline-delimited "filename|title|checks_variable_name"
SMOKE_SCRIPTS=""

# Troubleshooting sections
TROUBLESHOOTING_SECTIONS='### Symptom: {describe what you observe}

**Diagnosis:** {explain the root cause}

**Fix:**
```bash
# commands to resolve
```'

# Memory topics: "filename|description" pairs
MEMORY_TOPICS="debugging.md|Common issues, error patterns, and solutions
patterns.md|Recurring patterns and conventions confirmed across sessions"

# Slash commands to scaffold
COMMANDS="review.md
test.md"

LINT_LANGUAGES="Detected from file extensions. Supports: Python (ruff), TypeScript/JS (eslint+prettier), Go (gofmt), Rust (rustfmt), YAML, JSON, Shell (shellcheck)."