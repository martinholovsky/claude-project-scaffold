#!/usr/bin/env bash
# Claude Code post-tool hook: lint files on Write/Edit
# Runs the appropriate linter based on file extension.
# Exit 0 = success (non-blocking), Exit 2 = block the edit (YAML syntax errors)

set -euo pipefail

FILE="${CLAUDE_FILE_PATH:-}"
if [[ -z "$FILE" ]]; then
  exit 0
fi

EXT="${FILE##*.}"

case "$EXT" in
  py)
    if command -v ruff >/dev/null 2>&1; then
      ruff check --fix --quiet "$FILE" 2>&1 || true
      ruff format --quiet "$FILE" 2>&1 || true
    elif command -v black >/dev/null 2>&1; then
      black --quiet "$FILE" 2>&1 || true
    fi
    ;;

  ts|tsx|js|jsx|mjs|cjs)
    if command -v eslint >/dev/null 2>&1; then
      eslint --fix --quiet "$FILE" 2>&1 || true
    fi
    if command -v prettier >/dev/null 2>&1; then
      prettier --write --log-level silent "$FILE" 2>&1 || true
    fi
    ;;

  go)
    if command -v gofmt >/dev/null 2>&1; then
      gofmt -w "$FILE" 2>&1 || true
    fi
    if command -v goimports >/dev/null 2>&1; then
      goimports -w "$FILE" 2>&1 || true
    fi
    ;;

  rs)
    if command -v rustfmt >/dev/null 2>&1; then
      rustfmt --edition 2021 "$FILE" 2>&1 || true
    fi
    ;;

  yaml|yml)
    if command -v python3 >/dev/null 2>&1; then
      if ! python3 -c "
import sys, yaml
try:
    with open(sys.argv[1]) as f:
        yaml.safe_load(f)
except yaml.YAMLError as e:
    print(f'YAML syntax error: {e}', file=sys.stderr)
    sys.exit(1)
" "$FILE" 2>&1; then
        echo "YAML validation failed for $FILE — blocking edit" >&2
        exit 2
      fi
    fi
    ;;

  json)
    if command -v python3 >/dev/null 2>&1; then
      if ! python3 -c "
import sys, json
try:
    with open(sys.argv[1]) as f:
        json.load(f)
except json.JSONDecodeError as e:
    print(f'JSON syntax error: {e}', file=sys.stderr)
    sys.exit(1)
" "$FILE" 2>&1; then
        echo "JSON validation failed for $FILE — blocking edit" >&2
        exit 2
      fi
    fi
    ;;

  sh|bash)
    if command -v shellcheck >/dev/null 2>&1; then
      shellcheck "$FILE" 2>&1 || true
    fi
    ;;
esac

exit 0
