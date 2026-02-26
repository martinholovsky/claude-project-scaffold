# Claude Project Scaffold

**One command. 20 files. Your Claude Code sessions stop forgetting everything.**

Most Claude Code setups are incomplete. You get a bare `CLAUDE.md`, sessions freeze mid-task and lose all context, and you repeat the same debugging conversations over and over. This scaffold fixes that — one command generates everything Claude Code can use to work smarter across sessions.

```bash
git clone https://github.com/martinholovsky/claude-project-scaffold.git ~/claude-project-scaffold

cd ~/my-project
~/claude-project-scaffold/scaffold.sh
```

**30 seconds of setup. Every session after that starts where the last one left off.**

## The Problem

You open Claude Code. You explain your project. You debug something tricky together. Then the session freezes. Or hits the context limit. Or you close the terminal.

Next session: you start from scratch. Every. Single. Time.

Meanwhile, you've seen the tips: *"Add a CLAUDE.md!"* *"Use rules files!"* *"Try slash commands!"* Each tip covers one small piece. None of them give you the full system that actually makes Claude Code reliable for real work.

This scaffold gives you that full system.

## What You Get

```
your-project/
├── CLAUDE.md                      # Project brain — context groups, plan protocol, tech stack
├── .claude/
│   ├── rules/                     # Real patterns (not TODO stubs) — 60-100 lines each
│   │   ├── api-contracts.md       # Endpoint patterns, schemas, error formats
│   │   ├── troubleshooting.md     # Symptom → Diagnosis → Fix playbook
│   │   └── ...                    # Database, security, deployment — depends on preset
│   ├── memory/                    # Persists knowledge across sessions
│   │   ├── MEMORY.md              # Index (always loaded by Claude Code)
│   │   └── *.md                   # Topic files: debugging, patterns, gotchas
│   ├── commands/                  # Slash commands: /review, /test, /plan, /lint, ...
│   ├── hooks/
│   │   └── lint-on-edit.sh        # Auto-lint every file Claude touches
│   └── settings.local.json
├── docs/
│   ├── plans/                     # Session-resilient task tracking
│   │   └── .plan-template.md      # "Continue the plan" = instant session recovery
│   └── decisions/                 # Architecture Decision Records
└── scripts/                       # Smoke tests with PASS/FAIL/WARN output
```

**Idempotent** — run it again anytime. Existing files are never overwritten.

## 5 Presets, One Command

The scaffold detects your project type and suggests the right preset:

| Preset | Detects | What It Adds |
|--------|---------|-------------|
| **python-fastapi** | `pyproject.toml` with FastAPI | API contracts, database patterns, Pydantic schemas, pytest smoke |
| **typescript-node** | `package.json` | API contracts, Zod validation patterns, `/typecheck` command |
| **fullstack** | `backend/` + `frontend/` dirs | Architecture rules, cross-service contracts, CORS patterns, 2 smoke tests |
| **kubernetes-gitops** | `kustomize/` / `helm/` / `manifests/` | Network policies, BPF map rules, deployment flow, cluster health checks |
| **generic** | Anything else | CLAUDE.md, plans, ADRs, troubleshooting, lint hook |

**Deep detection** reads your `pyproject.toml` / `package.json` to extract the project name, description, framework, test runner, and package manager — so you skip the prompts.

```bash
# Non-interactive
scaffold.sh --preset python-fastapi --name my-api --desc "REST API for widgets"

# See all presets
scaffold.sh --list-presets
```

## What Each Feature Actually Does For You

### Rules with real content

Other scaffolds create empty stubs. This one generates **60-100 lines of actual patterns** per file — API contracts with code examples, database query patterns, error handling conventions. Claude reads these before every task and follows your project's patterns from the start.

### Session memory

`.claude/memory/MEMORY.md` is loaded into every conversation. Claude writes what it learns here — database gotchas, API quirks, infrastructure state. Next session, it already knows. Topic files keep it organized: `api-patterns.md`, `database-gotchas.md`, `debugging.md`.

### Slash commands

Type `/review` and Claude reviews your staged changes for bugs, security issues, and style. Type `/test` and it runs your test suite, reads failures, and suggests fixes. Type `/plan <task>` and it creates a session-resilient plan file. Kubernetes preset gets `/cluster-health`, `/deploy-check`, `/validate-policies`.

### Plan files (session recovery)

Every multi-step task gets a plan file with a progress log. When a session dies:

```
"Continue the plan"
```

Claude reads the plan, sees where it stopped, and picks up from there. No re-explaining.

### Troubleshooting playbook

Every solved bug gets documented: **Symptom → Diagnosis → Fix**. Claude matches error patterns to known solutions. You stop debugging the same issue twice.

### Auto-lint hook

Claude writes a `.py` file? Ruff runs automatically. `.ts` file? ESLint + Prettier. `.yaml`? Syntax validation that **blocks on errors**. Supports Python, TypeScript, Go, Rust, YAML, JSON, and shell scripts.

### Smoke tests

Preset-specific validation scripts. The kubernetes-gitops preset checks node health, deployment readiness, and scans network policies for dangerous patterns (like BPF map overflow). Colored PASS/FAIL/WARN output.

## Community Presets

Create your own presets and share them:

```bash
mkdir -p ~/.claude-scaffold/presets
cp ~/claude-project-scaffold/presets/generic.sh ~/.claude-scaffold/presets/my-preset.sh
# Edit to fit your stack
```

Community presets appear in the interactive menu alongside built-in ones.

<details>
<summary><strong>Preset variable API</strong> (for creating custom presets)</summary>

Every preset is a bash script that sets these variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `preset_name` | Yes | Short identifier |
| `preset_description` | Yes | One-line description for the menu |
| `RULES_FILES` | Yes | `"filename\|description"` pairs (newline-delimited) |
| `TECH_STACK` | Yes | Markdown table rows |
| `CONTEXT_LOADING_TABLE` | Yes | "Task → Read First" table rows |
| `CONTEXT_GROUPS` | Yes | Named file sets for context loading |
| `WORKFLOW` | Yes | Dev workflow section |
| `PROJECT_OVERVIEW` | Yes | Default overview text |
| `WORKSPACE_STRUCTURE` | Yes | ASCII directory tree |
| `TROUBLESHOOTING_SECTIONS` | Yes | Playbook content |
| `LINT_LANGUAGES` | Yes | Linter description |
| `SMOKE_SCRIPTS` | No | `"filename\|title\|checks_var"` entries |
| `MEMORY_TOPICS` | No | `"filename\|description"` pairs for memory topic files |
| `COMMANDS` | No | Command filenames to copy from `templates/commands/` |
| `RULES_CONTENT_*` | No | Substantive content for rules files |

To provide real content for a rules file instead of a TODO stub:

```bash
# api-contracts.md → RULES_CONTENT_API_CONTRACTS
# cross-service.md → RULES_CONTENT_CROSS_SERVICE

# shellcheck disable=SC2034
RULES_CONTENT_API_CONTRACTS='# API Contracts

> **When to use:** Adding or modifying endpoints...

## Base URL
...'
```

</details>

## CLI

```
scaffold.sh [options]

  --name NAME        Project name (default: directory name or detected from config)
  --desc DESCRIPTION Project description
  --preset PRESET    Skip interactive selection
  --list-presets     Show all available presets (bundled + community)
  --help, -h         Show this help
```

## After Scaffolding

1. Open `CLAUDE.md` — review and customize the overview, tech stack, and context groups
2. Check `.claude/rules/` — the preset filled in real content; tailor it to your specifics
3. Try `/review`, `/test`, `/plan implement auth flow`
4. Create your first ADR: `cp docs/decisions/adr-template.md docs/decisions/001-use-postgres.md`
5. Start a plan: `cp docs/plans/.plan-template.md docs/plans/plan-feature-name.md`

## License

MIT
