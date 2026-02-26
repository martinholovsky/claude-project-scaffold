#!/usr/bin/env bash
# Claude Project Scaffold — Interactive setup script
# Creates Claude Code scaffolding (CLAUDE.md, plan files, ADRs, hooks, smoke tests)
# in any project directory.
#
# Usage:
#   ~/claude-project-scaffold/scaffold.sh           # Interactive
#   ~/claude-project-scaffold/scaffold.sh --preset python-fastapi --name my-api
#   ~/claude-project-scaffold/scaffold.sh --help

set -euo pipefail

# --- Resolve script directory (works with symlinks) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
PRESETS_DIR="$SCRIPT_DIR/presets"
TARGET_DIR="$(pwd)"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- State ---
PROJECT_NAME=""
DESCRIPTION=""
SELECTED_PRESET=""
DETECTED_PRESET=""
CREATED_FILES=0
SKIPPED_FILES=0

# --- Preset variables (set by sourcing preset file) ---
# These use simple strings / newline-delimited pairs instead of associative arrays
# to avoid bash declare -A scoping issues when sourcing from within functions.
preset_name=""
preset_description=""
RULES_FILES=""          # newline-delimited "filename|description" pairs
TECH_STACK=""
CONTEXT_LOADING_TABLE=""
CONTEXT_GROUPS=""
WORKFLOW=""
PROJECT_OVERVIEW=""
WORKSPACE_STRUCTURE=""
SMOKE_SCRIPTS=""        # newline-delimited "filename|title|checks_var" entries
TROUBLESHOOTING_SECTIONS=""
LINT_LANGUAGES=""

# --- Helpers ---

print_banner() {
  printf "\n%b%b" "${CYAN}${BOLD}" ""
  cat <<'BANNER'
  ╭──────────────────────────────────╮
  │   Claude Project Scaffold        │
  │   Session-resilient AI scaffolding│
  ╰──────────────────────────────────╯
BANNER
  printf "%b\n" "${NC}"
}

info()    { printf "%b  INFO%b  %s\n" "$CYAN" "$NC" "$1"; }
created() { printf "%b     +%b  %s\n" "$GREEN" "$NC" "$1"; CREATED_FILES=$((CREATED_FILES + 1)); }
skipped() { printf "%b  skip%b  %s %b(already exists)%b\n" "$DIM" "$NC" "$1" "$DIM" "$NC"; SKIPPED_FILES=$((SKIPPED_FILES + 1)); }
warn()    { printf "%b  WARN%b  %s\n" "$YELLOW" "$NC" "$1"; }

LAST_OP=""  # "created" or "skipped" — set by write_if_missing / copy_if_missing

# Write file only if it doesn't exist (idempotent)
write_if_missing() {
  local filepath="$1"
  local content="$2"
  local dirpath
  dirpath="$(dirname "$filepath")"

  mkdir -p "$dirpath"
  if [[ -f "$filepath" ]]; then
    skipped "$filepath"
    LAST_OP="skipped"
    return 0
  fi
  printf '%s\n' "$content" > "$filepath"
  created "$filepath"
  LAST_OP="created"
  return 0
}

# Safe template substitution using Python
# Usage: _tmpl_sub template_file output_file "KEY1=value1" "KEY2=value2" ...
# Replaces all {{KEY}} placeholders with the corresponding values.
# Python handles special characters (& \ /) correctly, unlike bash ${//}.
_tmpl_sub() {
  local input_file="$1"
  local output_file="$2"
  shift 2

  # Write each replacement value to a temp file (avoids shell quoting issues)
  local tmpdir
  tmpdir=$(mktemp -d)
  local py_replacements=""
  local i=0
  for arg in "$@"; do
    local key="${arg%%=*}"
    local val="${arg#*=}"
    printf '%s' "$val" > "$tmpdir/$i"
    py_replacements="$py_replacements ('{{$key}}', '$tmpdir/$i'),"
    i=$((i + 1))
  done

  python3 -c "
import sys, os
with open(sys.argv[1]) as f:
    content = f.read()
for placeholder, val_file in [$py_replacements]:
    with open(val_file) as vf:
        content = content.replace(placeholder, vf.read())
with open(sys.argv[2], 'w') as f:
    f.write(content)
" "$input_file" "$output_file"

  rm -rf "$tmpdir"
}

# Copy file only if destination doesn't exist
copy_if_missing() {
  local src="$1"
  local dst="$2"
  local dirpath
  dirpath="$(dirname "$dst")"

  mkdir -p "$dirpath"
  if [[ -f "$dst" ]]; then
    skipped "$dst"
    LAST_OP="skipped"
    return 0
  fi
  cp "$src" "$dst"
  created "$dst"
  LAST_OP="created"
  return 0
}

# --- Detection ---

detect_project() {
  DETECTED_PRESET=""

  if [[ -f "$TARGET_DIR/pyproject.toml" ]] || [[ -f "$TARGET_DIR/requirements.txt" ]]; then
    if grep -q "fastapi\|FastAPI" "$TARGET_DIR/pyproject.toml" "$TARGET_DIR/requirements.txt" 2>/dev/null; then
      DETECTED_PRESET="python-fastapi"
      info "Detected: FastAPI project (pyproject.toml/requirements.txt)"
      return
    fi
    DETECTED_PRESET="python-fastapi"
    info "Detected: Python project (pyproject.toml/requirements.txt)"
    return
  fi

  if [[ -f "$TARGET_DIR/package.json" ]]; then
    if [[ -d "$TARGET_DIR/backend" ]] && [[ -d "$TARGET_DIR/frontend" ]]; then
      DETECTED_PRESET="fullstack"
      info "Detected: Full-stack project (backend/ + frontend/)"
      return
    fi
    DETECTED_PRESET="typescript-node"
    info "Detected: Node.js/TypeScript project (package.json)"
    return
  fi

  if [[ -d "$TARGET_DIR/kustomize" ]] || [[ -d "$TARGET_DIR/helm" ]] || [[ -d "$TARGET_DIR/manifests" ]]; then
    DETECTED_PRESET="kubernetes-gitops"
    info "Detected: Kubernetes/GitOps project"
    return
  fi

  if [[ -f "$TARGET_DIR/Cargo.toml" ]]; then
    DETECTED_PRESET="generic"
    info "Detected: Rust project (Cargo.toml) — using generic preset"
    return
  fi

  if [[ -f "$TARGET_DIR/go.mod" ]]; then
    DETECTED_PRESET="generic"
    info "Detected: Go project (go.mod) — using generic preset"
    return
  fi

  info "No specific framework detected — will use generic preset"
  DETECTED_PRESET="generic"
}

# --- Interactive Prompts ---

prompt_text() {
  local prompt="$1"
  local default="${2:-}"
  local result

  if [[ -n "$default" ]]; then
    printf "%b? %b%s %b(%s)%b: " "$BOLD" "$NC" "$prompt" "$DIM" "$default" "$NC"
  else
    printf "%b? %b%s: " "$BOLD" "$NC" "$prompt"
  fi
  read -r result
  if [[ -z "$result" ]]; then
    result="$default"
  fi
  printf '%s' "$result"
}

prompt_preset() {
  local presets=("generic" "python-fastapi" "typescript-node" "fullstack" "kubernetes-gitops")
  local descriptions=(
    "Minimal — CLAUDE.md, plans, ADRs, hooks"
    "Python/FastAPI backend"
    "TypeScript/Node.js"
    "Full-stack (backend + frontend)"
    "Kubernetes/GitOps infrastructure"
  )

  printf "\n%b? %bSelect preset:\n" "$BOLD" "$NC"

  local i
  for i in "${!presets[@]}"; do
    local marker="  "
    local suffix=""
    if [[ "${presets[$i]}" == "$DETECTED_PRESET" ]]; then
      marker="${GREEN}> "
      suffix=" (detected)${NC}"
    fi
    printf "  %b%d) %-22s %b%s%b%b\n" "$marker" "$((i + 1))" "${presets[$i]}" "$DIM" "${descriptions[$i]}" "$suffix" "$NC"
  done

  local default_num=1
  for i in "${!presets[@]}"; do
    if [[ "${presets[$i]}" == "$DETECTED_PRESET" ]]; then
      default_num=$((i + 1))
      break
    fi
  done

  printf "%b? %bChoice %b(%d)%b: " "$BOLD" "$NC" "$DIM" "$default_num" "$NC"
  local choice
  read -r choice
  choice="${choice:-$default_num}"

  if [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#presets[@]} ]]; then
    SELECTED_PRESET="${presets[$((choice - 1))]}"
  else
    warn "Invalid choice, using detected preset"
    SELECTED_PRESET="$DETECTED_PRESET"
  fi

  info "Using preset: $SELECTED_PRESET"
}

# --- Scaffolding ---

scaffold() {
  local preset_file="$PRESETS_DIR/${SELECTED_PRESET}.sh"
  if [[ ! -f "$preset_file" ]]; then
    printf "%bERROR:%b Preset file not found: %s\n" "$RED" "$NC" "$preset_file" >&2
    exit 1
  fi

  # Source the preset (sets all global variables)
  # shellcheck source=/dev/null
  source "$preset_file"

  printf "\n%bCreating scaffolding...%b\n\n" "$BOLD" "$NC"

  # --- 1. .claude/rules/ ---
  local rules_created=0

  # Troubleshooting (always created)
  if [[ ! -f ".claude/rules/troubleshooting.md" ]]; then
    mkdir -p .claude/rules
    _tmpl_sub "$TEMPLATES_DIR/troubleshooting.md.tmpl" ".claude/rules/troubleshooting.md" \
      "TROUBLESHOOTING_SECTIONS=$TROUBLESHOOTING_SECTIONS"
    created ".claude/rules/troubleshooting.md"
    rules_created=$((rules_created + 1))
  else
    skipped ".claude/rules/troubleshooting.md"
  fi

  # Preset-specific rules files (parse newline-delimited "filename|description" pairs)
  if [[ -n "$RULES_FILES" ]]; then
    local line rule_file rule_desc
    while IFS='|' read -r rule_file rule_desc; do
      [[ -z "$rule_file" ]] && continue
      local stub
      stub="# ${rule_file%.md}

> **When to use:** ${rule_desc}

*TODO: Document the patterns, contracts, and conventions for this area.*"
      write_if_missing ".claude/rules/$rule_file" "$stub"
      if [[ "$LAST_OP" == "created" ]]; then
        rules_created=$((rules_created + 1))
      fi
    done <<< "$RULES_FILES"
  fi

  # --- 2. .claude/hooks/ ---
  copy_if_missing "$TEMPLATES_DIR/lint-on-edit.sh" ".claude/hooks/lint-on-edit.sh"
  chmod +x ".claude/hooks/lint-on-edit.sh" 2>/dev/null || true

  # --- 3. .claude/settings.local.json ---
  copy_if_missing "$TEMPLATES_DIR/settings.local.json.tmpl" ".claude/settings.local.json"

  # --- 4. CLAUDE.md ---
  # Use Python for template substitution (bash ${//} corrupts & in replacements)
  if [[ ! -f "CLAUDE.md" ]]; then
    # Pre-process workspace structure to replace inner {{PROJECT_NAME}}
    local ws_tmp
    ws_tmp=$(mktemp)
    printf '%s' "$WORKSPACE_STRUCTURE" > "$ws_tmp"
    local ws
    ws=$(python3 -c "
with open('$ws_tmp') as f:
    print(f.read().replace('{{PROJECT_NAME}}', '$PROJECT_NAME'), end='')
")
    rm -f "$ws_tmp"
    _tmpl_sub "$TEMPLATES_DIR/CLAUDE.md.tmpl" "CLAUDE.md" \
      "PROJECT_NAME=$PROJECT_NAME" \
      "DESCRIPTION=$DESCRIPTION" \
      "PROJECT_OVERVIEW=$PROJECT_OVERVIEW" \
      "TECH_STACK=$TECH_STACK" \
      "CONTEXT_LOADING_TABLE=$CONTEXT_LOADING_TABLE" \
      "CONTEXT_GROUPS=$CONTEXT_GROUPS" \
      "WORKFLOW=$WORKFLOW" \
      "WORKSPACE_STRUCTURE=$ws"
    created "CLAUDE.md"
  else
    skipped "CLAUDE.md"
  fi

  # --- 5. docs/plans/.plan-template.md ---
  copy_if_missing "$TEMPLATES_DIR/plan-template.md" "docs/plans/.plan-template.md"

  # --- 6. docs/decisions/ ---
  if [[ ! -f "docs/decisions/index.md" ]]; then
    mkdir -p docs/decisions
    _tmpl_sub "$TEMPLATES_DIR/adr-index.md.tmpl" "docs/decisions/index.md" \
      "PROJECT_NAME=$PROJECT_NAME"
    created "docs/decisions/index.md"
  else
    skipped "docs/decisions/index.md"
  fi

  copy_if_missing "$TEMPLATES_DIR/adr-template.md" "docs/decisions/adr-template.md"

  # --- 7. Smoke test scripts ---
  local smoke_count=0
  if [[ -n "$SMOKE_SCRIPTS" ]]; then
    local script_name script_title checks_var
    while IFS='|' read -r script_name script_title checks_var; do
      [[ -z "$script_name" ]] && continue
      smoke_count=$((smoke_count + 1))

      local checks="${!checks_var:-}"
      if [[ -z "$checks" ]]; then
        checks='section "TODO"
info "Add your checks here"
warn "No checks implemented yet"'
      fi

      if [[ ! -f "scripts/$script_name" ]]; then
        mkdir -p scripts
        _tmpl_sub "$TEMPLATES_DIR/smoke-test.sh.tmpl" "scripts/$script_name" \
          "PROJECT_NAME=$PROJECT_NAME" \
          "SMOKE_TITLE=$script_title" \
          "SMOKE_FILENAME=$script_name" \
          "SMOKE_DESCRIPTION=$script_title for $PROJECT_NAME" \
          "SMOKE_CHECKS=$checks"
        chmod +x "scripts/$script_name" 2>/dev/null || true
        created "scripts/$script_name"
      else
        skipped "scripts/$script_name"
      fi
    done <<< "$SMOKE_SCRIPTS"
  fi

  # Ensure scripts/ directory exists even if no smoke scripts
  mkdir -p scripts

  # --- Summary ---
  printf "\n%b%bDone!%b " "$GREEN" "$BOLD" "$NC"
  printf "Created %b%d%b files, skipped %b%d%b existing.\n" "$GREEN" "$CREATED_FILES" "$NC" "$DIM" "$SKIPPED_FILES" "$NC"

  printf "\n%bWhat was created:%b\n" "$BOLD" "$NC"
  printf "  %bCLAUDE.md%b                       Project instructions with Plan Protocol + Context Groups\n" "$CYAN" "$NC"
  printf "  %b.claude/rules/%b                  %d rule files (troubleshooting + preset-specific)\n" "$CYAN" "$NC" "$rules_created"
  printf "  %b.claude/hooks/lint-on-edit.sh%b   Auto-lint on Write/Edit\n" "$CYAN" "$NC"
  printf "  %bdocs/plans/.plan-template.md%b    Session-resilient plan template\n" "$CYAN" "$NC"
  printf "  %bdocs/decisions/%b                 ADR index + template\n" "$CYAN" "$NC"
  if [[ "$smoke_count" -gt 0 ]]; then
    printf "  %bscripts/%b                        %d smoke test script(s)\n" "$CYAN" "$NC" "$smoke_count"
  fi

  printf "\n%bNext steps:%b\n" "$BOLD" "$NC"
  printf "  1. Review and customize %bCLAUDE.md%b\n" "$CYAN" "$NC"
  printf "  2. Fill in rule stubs in %b.claude/rules/%b\n" "$CYAN" "$NC"
  printf "  3. Add your architecture diagram to %bCLAUDE.md%b\n" "$CYAN" "$NC"
  printf "  4. Create your first ADR:\n"
  printf "     %bcp docs/decisions/adr-template.md docs/decisions/001-your-decision.md%b\n" "$DIM" "$NC"
  printf "  5. Start a plan:\n"
  printf "     %bcp docs/plans/.plan-template.md docs/plans/plan-feature-name.md%b\n" "$DIM" "$NC"
  printf "\n"
}

# --- CLI Argument Parsing ---

show_help() {
  cat <<'EOF'
Claude Project Scaffold — Generate Claude Code scaffolding for any project

Usage:
  scaffold.sh [options]

Options:
  --name NAME        Project name (default: directory name)
  --desc DESCRIPTION Project description
  --preset PRESET    Skip interactive selection (generic, python-fastapi,
                     typescript-node, fullstack, kubernetes-gitops)
  --help, -h         Show this help

Examples:
  # Interactive (recommended)
  cd ~/my-project && ~/claude-project-scaffold/scaffold.sh

  # Non-interactive
  scaffold.sh --preset python-fastapi --name my-api --desc "REST API for widgets"

  # Minimal
  scaffold.sh --preset generic --name my-project
EOF
  exit 0
}

# Parse args
ARG_NAME=""
ARG_DESC=""
ARG_PRESET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)   ARG_NAME="$2"; shift 2 ;;
    --desc)   ARG_DESC="$2"; shift 2 ;;
    --preset) ARG_PRESET="$2"; shift 2 ;;
    --help|-h) show_help ;;
    *) printf "%bUnknown option: %s%b\n" "$RED" "$1" "$NC"; show_help ;;
  esac
done

# --- Main ---

main() {
  print_banner

  info "Target directory: $TARGET_DIR"

  # Detect project type
  detect_project

  # Project name
  local dir_name
  dir_name="$(basename "$TARGET_DIR")"
  if [[ -n "$ARG_NAME" ]]; then
    PROJECT_NAME="$ARG_NAME"
  else
    PROJECT_NAME=$(prompt_text "Project name" "$dir_name")
  fi

  # Description
  if [[ -n "$ARG_DESC" ]]; then
    DESCRIPTION="$ARG_DESC"
  else
    DESCRIPTION=$(prompt_text "Description" "")
  fi
  DESCRIPTION="${DESCRIPTION:-$PROJECT_NAME}"

  # Preset selection
  if [[ -n "$ARG_PRESET" ]]; then
    SELECTED_PRESET="$ARG_PRESET"
    info "Using preset: $SELECTED_PRESET"
  else
    prompt_preset
  fi

  # Validate preset exists
  if [[ ! -f "$PRESETS_DIR/${SELECTED_PRESET}.sh" ]]; then
    printf "%bERROR:%b Unknown preset '%s'. Available: generic, python-fastapi, typescript-node, fullstack, kubernetes-gitops\n" "$RED" "$NC" "$SELECTED_PRESET" >&2
    exit 1
  fi

  # Scaffold
  scaffold
}

main
