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
COMMANDS_DIR="$TEMPLATES_DIR/commands"
COMMUNITY_PRESETS_DIR="$HOME/.claude-scaffold/presets"
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
MEMORY_TOPICS=""        # newline-delimited "filename|description" pairs for memory topic files
COMMANDS=""             # newline-delimited command filenames to copy from templates/commands/

# Deep detection results (populated by deep_detect)
DEEP_PROJECT_NAME=""
DEEP_DESCRIPTION=""
DEEP_FRAMEWORK=""
DEEP_DEPENDENCIES=""
DEEP_TEST_FRAMEWORK=""
DEEP_PKG_MANAGER=""

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

# --- Deep Detection ---

deep_detect() {
  # Parse pyproject.toml for Python projects
  if [[ -f "$TARGET_DIR/pyproject.toml" ]]; then
    local py_result
    py_result=$(python3 -c "
import sys
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        sys.exit(0)
with open('$TARGET_DIR/pyproject.toml', 'rb') as f:
    data = tomllib.load(f)
proj = data.get('project', {})
name = proj.get('name', '')
desc = proj.get('description', '')
deps = [d.split('>')[0].split('<')[0].split('=')[0].split('[')[0].strip().lower() for d in proj.get('dependencies', [])]
has_pytest = 'tool' in data and 'pytest' in data['tool']
print(f'NAME={name}')
print(f'DESC={desc}')
print(f'DEPS={\"|\".join(deps)}')
print(f'PYTEST={has_pytest}')
" 2>/dev/null || true)

    if [[ -n "$py_result" ]]; then
      DEEP_PROJECT_NAME=$(echo "$py_result" | grep '^NAME=' | cut -d= -f2-)
      DEEP_DESCRIPTION=$(echo "$py_result" | grep '^DESC=' | cut -d= -f2-)
      local deps_str
      deps_str=$(echo "$py_result" | grep '^DEPS=' | cut -d= -f2-)
      DEEP_DEPENDENCIES="$deps_str"
      local has_pytest
      has_pytest=$(echo "$py_result" | grep '^PYTEST=' | cut -d= -f2-)

      # Detect framework
      if echo "$deps_str" | grep -qi "fastapi"; then
        DEEP_FRAMEWORK="fastapi"
      elif echo "$deps_str" | grep -qi "django"; then
        DEEP_FRAMEWORK="django"
      elif echo "$deps_str" | grep -qi "flask"; then
        DEEP_FRAMEWORK="flask"
      fi

      if [[ "$has_pytest" == "True" ]]; then
        DEEP_TEST_FRAMEWORK="pytest"
      fi
    fi
  fi

  # Parse package.json for Node.js projects
  if [[ -f "$TARGET_DIR/package.json" ]]; then
    local js_result
    js_result=$(python3 -c "
import json, sys
with open('$TARGET_DIR/package.json') as f:
    data = json.load(f)
name = data.get('name', '')
desc = data.get('description', '')
deps = list(data.get('dependencies', {}).keys())
dev_deps = list(data.get('devDependencies', {}).keys())
all_deps = deps + dev_deps
scripts = list(data.get('scripts', {}).keys())
print(f'NAME={name}')
print(f'DESC={desc}')
print(f'DEPS={\"|\".join(all_deps)}')
print(f'SCRIPTS={\"|\".join(scripts)}')
" 2>/dev/null || true)

    if [[ -n "$js_result" ]]; then
      DEEP_PROJECT_NAME=$(echo "$js_result" | grep '^NAME=' | cut -d= -f2-)
      DEEP_DESCRIPTION=$(echo "$js_result" | grep '^DESC=' | cut -d= -f2-)
      local deps_str
      deps_str=$(echo "$js_result" | grep '^DEPS=' | cut -d= -f2-)
      DEEP_DEPENDENCIES="$deps_str"

      # Detect framework
      if echo "$deps_str" | grep -qi "nuxt"; then
        DEEP_FRAMEWORK="nuxt"
      elif echo "$deps_str" | grep -qi "next"; then
        DEEP_FRAMEWORK="next"
      elif echo "$deps_str" | grep -qi "react"; then
        DEEP_FRAMEWORK="react"
      elif echo "$deps_str" | grep -qi "vue"; then
        DEEP_FRAMEWORK="vue"
      elif echo "$deps_str" | grep -qi "svelte"; then
        DEEP_FRAMEWORK="svelte"
      elif echo "$deps_str" | grep -qi "express"; then
        DEEP_FRAMEWORK="express"
      elif echo "$deps_str" | grep -qi "fastify"; then
        DEEP_FRAMEWORK="fastify"
      elif echo "$deps_str" | grep -qi "hono"; then
        DEEP_FRAMEWORK="hono"
      fi

      # Detect test framework
      if echo "$deps_str" | grep -qi "vitest"; then
        DEEP_TEST_FRAMEWORK="vitest"
      elif echo "$deps_str" | grep -qi "jest"; then
        DEEP_TEST_FRAMEWORK="jest"
      fi

      # Detect package manager
      if [[ -f "$TARGET_DIR/bun.lockb" ]] || [[ -f "$TARGET_DIR/bun.lock" ]]; then
        DEEP_PKG_MANAGER="bun"
      elif [[ -f "$TARGET_DIR/pnpm-lock.yaml" ]]; then
        DEEP_PKG_MANAGER="pnpm"
      elif [[ -f "$TARGET_DIR/yarn.lock" ]]; then
        DEEP_PKG_MANAGER="yarn"
      else
        DEEP_PKG_MANAGER="npm"
      fi
    fi
  fi

  # Report findings
  if [[ -n "$DEEP_PROJECT_NAME" ]]; then
    info "Deep detect: name=$DEEP_PROJECT_NAME"
  fi
  if [[ -n "$DEEP_FRAMEWORK" ]]; then
    info "Deep detect: framework=$DEEP_FRAMEWORK"
  fi
  if [[ -n "$DEEP_TEST_FRAMEWORK" ]]; then
    info "Deep detect: test=$DEEP_TEST_FRAMEWORK"
  fi
  if [[ -n "$DEEP_PKG_MANAGER" ]]; then
    info "Deep detect: pkg=$DEEP_PKG_MANAGER"
  fi
}

# --- Detection ---

detect_project() {
  DETECTED_PRESET=""

  # Run deep detection first
  deep_detect

  if [[ -f "$TARGET_DIR/pyproject.toml" ]] || [[ -f "$TARGET_DIR/requirements.txt" ]]; then
    if [[ "$DEEP_FRAMEWORK" == "fastapi" ]] || grep -q "fastapi\|FastAPI" "$TARGET_DIR/pyproject.toml" "$TARGET_DIR/requirements.txt" 2>/dev/null; then
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

  printf "\n"
  if [[ -n "$default" ]]; then
    printf "  %b?%b %s [%s]: " "$CYAN" "$NC" "$prompt" "$default"
  else
    printf "  %b?%b %s: " "$CYAN" "$NC" "$prompt"
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

  # Discover community presets
  if [[ -d "$COMMUNITY_PRESETS_DIR" ]]; then
    local community_file
    for community_file in "$COMMUNITY_PRESETS_DIR"/*.sh; do
      [[ -f "$community_file" ]] || continue
      local cname cdesc
      cname=$(basename "$community_file" .sh)
      # Skip if same name as bundled preset
      local is_dup=false
      for p in "${presets[@]}"; do
        [[ "$p" == "$cname" ]] && is_dup=true && break
      done
      $is_dup && continue
      # Extract description from preset file
      cdesc=$(grep '^preset_description=' "$community_file" 2>/dev/null | head -1 | sed 's/^preset_description="//' | sed 's/"$//' || echo "Community preset")
      presets+=("$cname")
      descriptions+=("$cdesc")
    done
  fi

  printf "\n  %b?%b Select preset:\n" "$CYAN" "$NC"

  local i
  for i in "${!presets[@]}"; do
    local marker="  "
    local suffix=""
    if [[ "${presets[$i]}" == "$DETECTED_PRESET" ]]; then
      marker="${GREEN}> "
      suffix=" (detected)${NC}"
    fi
    # Mark community presets
    local community_tag=""
    if [[ $i -ge 5 ]]; then
      community_tag=" ${DIM}[community]${NC}"
    fi
    printf "  %b%d) %-22s %b%s%b%b%b\n" "$marker" "$((i + 1))" "${presets[$i]}" "$DIM" "${descriptions[$i]}" "$suffix" "$community_tag" "$NC"
  done

  local default_num=1
  for i in "${!presets[@]}"; do
    if [[ "${presets[$i]}" == "$DETECTED_PRESET" ]]; then
      default_num=$((i + 1))
      break
    fi
  done

  printf "\n  %b?%b Choice [%d]: " "$CYAN" "$NC" "$default_num"
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

# --- List Presets ---

list_presets() {
  printf "%b%bAvailable Presets%b\n\n" "$BOLD" "$CYAN" "$NC"

  printf "%b  Bundled:%b\n" "$BOLD" "$NC"
  local preset_file
  for preset_file in "$PRESETS_DIR"/*.sh; do
    [[ -f "$preset_file" ]] || continue
    local pname pdesc
    pname=$(basename "$preset_file" .sh)
    pdesc=$(grep '^preset_description=' "$preset_file" 2>/dev/null | head -1 | sed 's/^preset_description="//' | sed 's/"$//')
    printf "    %-22s %b%s%b\n" "$pname" "$DIM" "$pdesc" "$NC"
  done

  if [[ -d "$COMMUNITY_PRESETS_DIR" ]]; then
    local has_community=false
    for preset_file in "$COMMUNITY_PRESETS_DIR"/*.sh; do
      [[ -f "$preset_file" ]] || continue
      if ! $has_community; then
        printf "\n%b  Community (%s):%b\n" "$BOLD" "$COMMUNITY_PRESETS_DIR" "$NC"
        has_community=true
      fi
      local pname pdesc
      pname=$(basename "$preset_file" .sh)
      pdesc=$(grep '^preset_description=' "$preset_file" 2>/dev/null | head -1 | sed 's/^preset_description="//' | sed 's/"$//')
      printf "    %-22s %b%s%b\n" "$pname" "$DIM" "$pdesc" "$NC"
    done
    if ! $has_community; then
      printf "\n%b  Community:%b %bNo custom presets found in %s%b\n" "$BOLD" "$NC" "$DIM" "$COMMUNITY_PRESETS_DIR" "$NC"
    fi
  else
    printf "\n%b  Community:%b %bCreate presets in %s%b\n" "$BOLD" "$NC" "$DIM" "$COMMUNITY_PRESETS_DIR" "$NC"
  fi
  printf "\n"
  exit 0
}

# --- Scaffolding ---

scaffold() {
  local preset_file="$PRESETS_DIR/${SELECTED_PRESET}.sh"
  if [[ ! -f "$preset_file" ]]; then
    # Check community presets
    preset_file="$COMMUNITY_PRESETS_DIR/${SELECTED_PRESET}.sh"
    if [[ ! -f "$preset_file" ]]; then
      printf "%bERROR:%b Preset file not found: %s\n" "$RED" "$NC" "${SELECTED_PRESET}.sh" >&2
      exit 1
    fi
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
      # Check for substantive content variable: RULES_CONTENT_API_CONTRACTS for api-contracts.md
      local var_name="RULES_CONTENT_$(echo "${rule_file%.md}" | tr '[:lower:]-' '[:upper:]_')"
      local content="${!var_name:-}"
      if [[ -z "$content" ]]; then
        # Fall back to stub
        content="# ${rule_file%.md}

> **When to use:** ${rule_desc}

*TODO: Document the patterns, contracts, and conventions for this area.*"
      fi
      write_if_missing ".claude/rules/$rule_file" "$content"
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

  # --- 7. .claude/memory/ ---
  local memory_count=0
  if [[ -n "$MEMORY_TOPICS" ]]; then
    # Build topic table for MEMORY.md template
    local topic_table=""
    local topic_file topic_desc
    while IFS='|' read -r topic_file topic_desc; do
      [[ -z "$topic_file" ]] && continue
      topic_table="${topic_table}| \`${topic_file}\` | ${topic_desc} |
"
      # Create empty topic file
      write_if_missing ".claude/memory/$topic_file" "# ${topic_file%.md}

*Add notes as you work. This file persists across sessions.*"
      if [[ "$LAST_OP" == "created" ]]; then
        memory_count=$((memory_count + 1))
      fi
    done <<< "$MEMORY_TOPICS"

    # Create MEMORY.md from template
    if [[ ! -f ".claude/memory/MEMORY.md" ]]; then
      mkdir -p .claude/memory
      _tmpl_sub "$TEMPLATES_DIR/memory-index.md.tmpl" ".claude/memory/MEMORY.md" \
        "PROJECT_NAME=$PROJECT_NAME" \
        "MEMORY_TOPIC_TABLE=$topic_table"
      created ".claude/memory/MEMORY.md"
      memory_count=$((memory_count + 1))
    else
      skipped ".claude/memory/MEMORY.md"
    fi
  fi

  # --- 8. .claude/commands/ ---
  local commands_count=0
  if [[ -n "$COMMANDS" ]]; then
    local cmd_file
    while IFS= read -r cmd_file; do
      [[ -z "$cmd_file" ]] && continue
      if [[ -f "$COMMANDS_DIR/$cmd_file" ]]; then
        copy_if_missing "$COMMANDS_DIR/$cmd_file" ".claude/commands/$cmd_file"
        if [[ "$LAST_OP" == "created" ]]; then
          commands_count=$((commands_count + 1))
        fi
      else
        warn "Command template not found: $cmd_file"
      fi
    done <<< "$COMMANDS"
  fi

  # --- 9. Smoke test scripts ---
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
  if [[ "$memory_count" -gt 0 ]]; then
    printf "  %b.claude/memory/%b                 MEMORY.md index + %d topic files\n" "$CYAN" "$NC" "$memory_count"
  fi
  if [[ "$commands_count" -gt 0 ]]; then
    printf "  %b.claude/commands/%b               %d slash commands (/review, /test, etc.)\n" "$CYAN" "$NC" "$commands_count"
  fi
  printf "  %bdocs/plans/.plan-template.md%b    Session-resilient plan template\n" "$CYAN" "$NC"
  printf "  %bdocs/decisions/%b                 ADR index + template\n" "$CYAN" "$NC"
  if [[ "$smoke_count" -gt 0 ]]; then
    printf "  %bscripts/%b                        %d smoke test script(s)\n" "$CYAN" "$NC" "$smoke_count"
  fi

  printf "\n%bNext steps:%b\n" "$BOLD" "$NC"
  printf "  1. Review and customize %bCLAUDE.md%b\n" "$CYAN" "$NC"
  printf "  2. Customize rules in %b.claude/rules/%b for your project\n" "$CYAN" "$NC"
  printf "  3. Add your architecture diagram to %bCLAUDE.md%b\n" "$CYAN" "$NC"
  printf "  4. Create your first ADR:\n"
  printf "     %bcp docs/decisions/adr-template.md docs/decisions/001-your-decision.md%b\n" "$DIM" "$NC"
  printf "  5. Start a plan:\n"
  printf "     %bcp docs/plans/.plan-template.md docs/plans/plan-feature-name.md%b\n" "$DIM" "$NC"
  if [[ "$commands_count" -gt 0 ]]; then
    printf "  6. Try a slash command: %b/review%b, %b/test%b, %b/plan <task>%b\n" "$CYAN" "$NC" "$CYAN" "$NC" "$CYAN" "$NC"
  fi
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
                     typescript-node, fullstack, kubernetes-gitops, or custom)
  --list-presets     List all available presets (bundled + community)
  --help, -h         Show this help

Examples:
  # Interactive (recommended)
  cd ~/my-project && ~/claude-project-scaffold/scaffold.sh

  # Non-interactive
  scaffold.sh --preset python-fastapi --name my-api --desc "REST API for widgets"

  # Minimal
  scaffold.sh --preset generic --name my-project

  # List available presets
  scaffold.sh --list-presets

Community presets:
  Place custom preset .sh files in ~/.claude-scaffold/presets/
  They appear alongside bundled presets in the interactive menu.
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
    --list-presets) list_presets ;;
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

  # Project name (pre-fill from deep detection)
  local dir_name
  dir_name="$(basename "$TARGET_DIR")"
  local default_name="${DEEP_PROJECT_NAME:-$dir_name}"
  if [[ -n "$ARG_NAME" ]]; then
    PROJECT_NAME="$ARG_NAME"
  else
    PROJECT_NAME=$(prompt_text "Project name" "$default_name")
  fi

  # Description (pre-fill from deep detection)
  local default_desc="${DEEP_DESCRIPTION:-}"
  if [[ -n "$ARG_DESC" ]]; then
    DESCRIPTION="$ARG_DESC"
  else
    DESCRIPTION=$(prompt_text "Description" "$default_desc")
  fi
  DESCRIPTION="${DESCRIPTION:-$PROJECT_NAME}"

  # Preset selection
  if [[ -n "$ARG_PRESET" ]]; then
    SELECTED_PRESET="$ARG_PRESET"
    info "Using preset: $SELECTED_PRESET"
  else
    prompt_preset
  fi

  # Validate preset exists (bundled or community)
  if [[ ! -f "$PRESETS_DIR/${SELECTED_PRESET}.sh" ]] && [[ ! -f "$COMMUNITY_PRESETS_DIR/${SELECTED_PRESET}.sh" ]]; then
    printf "%bERROR:%b Unknown preset '%s'. Run --list-presets to see available presets.\n" "$RED" "$NC" "$SELECTED_PRESET" >&2
    exit 1
  fi

  # Scaffold
  scaffold
}

main
