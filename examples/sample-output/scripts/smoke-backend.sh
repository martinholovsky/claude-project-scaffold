#!/usr/bin/env bash
# Backend Health Checks — my-api
# Run: ./scripts/smoke-backend.sh [--help]

set -euo pipefail

# --- Colors & Counters ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0
TOTAL=0

pass() { ((PASS++)); ((TOTAL++)); printf "${GREEN}  PASS${NC}  %s\n" "$1"; }
fail() { ((FAIL++)); ((TOTAL++)); printf "${RED}  FAIL${NC}  %s\n" "$1"; }
warn() { ((WARN++)); ((TOTAL++)); printf "${YELLOW}  WARN${NC}  %s\n" "$1"; }
info() { printf "${CYAN}  INFO${NC}  %s\n" "$1"; }
section() { printf "\n${BOLD}── %s ──${NC}\n" "$1"; }

# --- Help ---
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Usage: smoke-backend.sh [--help]

Backend Health Checks for my-api

Exit codes:
  0 — all checks passed
  1 — one or more checks failed
EOF
  exit 0
fi

# --- Checks ---

section "Application"

if [[ -f "app/main.py" ]]; then
  pass "app/main.py exists"
else
  fail "app/main.py not found"
fi

if python3 -c "import fastapi" 2>/dev/null; then
  pass "FastAPI is installed"
else
  fail "FastAPI is not installed (pip install fastapi)"
fi

section "Configuration"

if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
  pass "Dependency file exists"
else
  warn "No requirements.txt or pyproject.toml found"
fi

section "Linting"

if command -v ruff >/dev/null 2>&1; then
  if ruff check --quiet app/ 2>/dev/null; then
    pass "ruff check passes"
  else
    warn "ruff check has findings"
  fi
else
  warn "ruff not installed"
fi

section "Tests"

if command -v pytest >/dev/null 2>&1; then
  if pytest --co -q 2>/dev/null | grep -q "test"; then
    pass "Tests discovered by pytest"
  else
    warn "No tests found"
  fi
else
  warn "pytest not installed"
fi

# --- Summary ---
printf "\n${BOLD}═══════════════════════════════════════${NC}\n"
printf "${BOLD}  Results:${NC} ${GREEN}%d PASS${NC}  ${RED}%d FAIL${NC}  ${YELLOW}%d WARN${NC}  (total: %d)\n" \
  "$PASS" "$FAIL" "$WARN" "$TOTAL"
printf "${BOLD}═══════════════════════════════════════${NC}\n"

if ((FAIL > 0)); then
  exit 1
fi
exit 0
