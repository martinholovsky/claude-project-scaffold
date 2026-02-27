# Claude Project Scaffold

**Minimal, high-signal scaffolding for Claude Code. Only includes what Claude would get wrong without it.**

Research shows Claude's performance degrades with added context ([Anthropic's context study](https://www.anthropic.com/research/context-rot)), and their own guidelines recommend CLAUDE.md under 300 lines with only project-specific content. This scaffold follows that principle — no generic knowledge Claude already has, just the project-specific things it needs to be told.

```bash
git clone https://github.com/martinholovsky/claude-project-scaffold.git ~/claude-project-scaffold

cd ~/my-project
~/claude-project-scaffold/scaffold.sh
```

## What You Get

```
your-project/
├── CLAUDE.md                      # Tech stack, dev commands, project conventions (~25 lines)
├── .claude/
│   ├── rules/                     # Project-specific patterns only
│   │   ├── api-contracts.md       # Your actual endpoints (placeholder to fill in)
│   │   └── troubleshooting.md     # Symptom → Diagnosis → Fix playbook
│   ├── memory/                    # Persists knowledge across sessions
│   │   ├── MEMORY.md              # Index (always loaded by Claude Code)
│   │   └── *.md                   # Topic files: debugging, patterns, gotchas
│   ├── commands/                  # Slash commands: /review, /test, /lint, ...
│   ├── hooks/
│   │   └── lint-on-edit.sh        # Auto-lint every file Claude touches
│   └── settings.local.json
├── docs/
│   └── decisions/                 # Architecture Decision Records
└── scripts/                       # Smoke tests with PASS/FAIL/WARN output
```

**Idempotent** — run it again anytime. Existing files are never overwritten.

## 5 Presets, One Command

The scaffold detects your project type and suggests the right preset:

| Preset | Detects | What It Adds |
|--------|---------|-------------|
| **python-fastapi** | `pyproject.toml` with FastAPI | API contracts, database patterns, pytest smoke |
| **typescript-node** | `package.json` | API contracts, `/typecheck` command |
| **fullstack** | `backend/` + `frontend/` dirs | Architecture rules, cross-service contracts, 2 smoke tests |
| **kubernetes-gitops** | `kustomize/` / `helm/` / `manifests/` | Network policy critical rules, deployment checklist, cluster health |
| **generic** | Anything else | CLAUDE.md, ADRs, troubleshooting, lint hook |

**Deep detection** reads your `pyproject.toml` / `package.json` to extract the project name, description, framework, test runner, and package manager — so you skip the prompts.

```bash
# Non-interactive
scaffold.sh --preset python-fastapi --name my-api --desc "REST API for widgets"

# See all presets
scaffold.sh --list-presets

# Remove all scaffold files
scaffold.sh --clean
```

## Design Philosophy

**Only include what Claude would get wrong without it.**

- No HTTP status code tables — Claude knows REST
- No Pydantic/Zod examples — Claude knows these libraries
- No "never log passwords" — Claude knows security basics
- No pagination patterns — Claude knows how to paginate
- No YAML templates for things Claude can write from scratch

What *does* belong:
- Your actual API base URL and auth mechanism
- Your specific migration commands
- Cilium BPF map overflow gotchas (non-obvious, easy to get wrong)
- Your naming conventions and required labels
- Project-specific conventions Claude can't infer

The result: ~300 tokens of always-loaded CLAUDE.md instead of ~2,000+. Less context rot, better performance.

## What Each Feature Does

### Rules with project-specific content

Rules files contain placeholders for your actual endpoints, schemas, and patterns — not generic code examples Claude already knows. Fill them in with your real project details.

### Session memory

`.claude/memory/MEMORY.md` is loaded into every conversation. Claude writes what it learns here — database gotchas, API quirks, infrastructure state. Next session, it already knows.

### Slash commands

Type `/review` and Claude reviews your staged changes. Type `/test` and it runs your test suite. Kubernetes preset gets `/cluster-health`, `/deploy-check`, `/validate-policies`.

### Troubleshooting playbook

Every solved bug gets documented: **Symptom → Diagnosis → Fix**. Claude matches error patterns to known solutions.

### Auto-lint hook

Claude writes a `.py` file? Ruff runs automatically. `.ts` file? ESLint + Prettier. `.yaml`? Syntax validation. Supports Python, TypeScript, Go, Rust, YAML, JSON, and shell scripts.

### Smoke tests

Preset-specific validation scripts. The kubernetes-gitops preset checks node health, deployment readiness, and scans network policies for dangerous BPF patterns.

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
| `WORKFLOW` | Yes | Dev commands section |
| `PROJECT_CONVENTIONS` | Yes | Project-specific conventions (2-5 lines) |
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
  --clean            Remove all scaffold-generated files
  --help, -h         Show this help
```

## After Scaffolding

1. Open `CLAUDE.md` — review tech stack, fill in project conventions
2. Fill in `.claude/rules/` with your actual endpoints and patterns
3. Try `/review`, `/test`
4. Create your first ADR: `cp docs/decisions/adr-template.md docs/decisions/001-use-postgres.md`

## License

MIT