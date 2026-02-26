# Claude Project Scaffold

Generate session-resilient [Claude Code](https://claude.com/claude-code) scaffolding for any project. One command gives you a complete `CLAUDE.md`, plan files, troubleshooting playbook, ADR templates, lint hooks, and smoke test scripts.

## Quick Start

```bash
cd ~/my-project
~/claude-project-scaffold/scaffold.sh
```

The interactive wizard detects your project type and suggests a preset. You can also run non-interactively:

```bash
scaffold.sh --preset python-fastapi --name my-api --desc "REST API for widgets"
```

## What Gets Created

```
your-project/
├── CLAUDE.md                      # Project instructions with context groups + plan protocol
├── .claude/
│   ├── rules/
│   │   ├── troubleshooting.md     # Symptom → Diagnosis → Fix playbook
│   │   └── ...                    # Preset-specific rule files
│   ├── hooks/
│   │   └── lint-on-edit.sh        # Auto-lint on Write/Edit (multi-language)
│   └── settings.local.json        # Hook configuration
├── docs/
│   ├── plans/
│   │   └── .plan-template.md      # Session-resilient plan template
│   └── decisions/
│       ├── index.md               # ADR index
│       └── adr-template.md        # ADR template
└── scripts/
    └── ...                        # Smoke test scripts (preset-specific)
```

**Idempotent** — safe to re-run. Existing files are never overwritten.

## Presets

| Preset | Best For | Creates |
|--------|----------|---------|
| `generic` | Any project | CLAUDE.md, plans, ADRs, troubleshooting, lint hook |
| `python-fastapi` | Python/FastAPI backends | + API contracts, database rules, backend smoke test |
| `typescript-node` | TypeScript/Node.js | + API contracts, app smoke test, eslint/prettier hook |
| `fullstack` | Backend + frontend | + architecture, cross-service, API contracts, 2 smoke tests |
| `kubernetes-gitops` | K8s infrastructure | + deployment flow, network policies, security, cluster smoke, CNP validation |

Auto-detection works from existing files:
- `pyproject.toml` / `requirements.txt` → `python-fastapi`
- `package.json` → `typescript-node`
- `backend/` + `frontend/` → `fullstack`
- `kustomize/` / `helm/` / `manifests/` → `kubernetes-gitops`

## Why This Exists

Claude Code sessions can freeze or hit context limits. When that happens, you lose the entire conversation context. This scaffolding solves that with:

1. **Plan files** — Multi-step tasks are tracked in `docs/plans/`. Each plan has a progress log. When a session dies, the next session reads the plan file and resumes from where you left off. Say "Continue the plan" or "Resume docs/plans/plan-topic.md".

2. **Troubleshooting playbook** — Every time you solve a tricky bug, document it in `.claude/rules/troubleshooting.md` using the Symptom → Diagnosis → Fix format. Next time the same error appears, Claude finds the fix immediately instead of debugging from scratch.

3. **Context groups** — Named sets of files to load for specific task types. Instead of manually telling Claude which files to read, say "load auth context" or "load deploy context".

4. **ADRs** — Architecture Decision Records capture *why* you chose a particular approach. When Claude (or a human) encounters the code later, the ADR explains the rationale.

5. **Lint hook** — Auto-runs the appropriate linter whenever Claude writes or edits a file. Catches issues before they accumulate.

6. **Smoke tests** — Quick validation scripts to run after changes. Colored output with PASS/FAIL/WARN counters.

## Customization

### After Scaffolding

1. **Edit `CLAUDE.md`** — Fill in your project overview, architecture diagram, and technology stack
2. **Populate rule files** — The preset creates stubs in `.claude/rules/`. Add your patterns and contracts
3. **Add context groups** — Map your file paths to context group names in `CLAUDE.md`
4. **Create ADRs** — `cp docs/decisions/adr-template.md docs/decisions/001-use-postgres.md`

### Adding Custom Rules

Create any `.md` file in `.claude/rules/`. Claude Code auto-loads these as project instructions. Good candidates:
- `api-contracts.md` — Request/response shapes for every endpoint
- `database.md` — Schema patterns, migration procedures
- `deployment-flow.md` — CI/CD pipeline documentation
- `security-controls.md` — Security policies and requirements

### Session Recovery Workflow

1. Claude freezes mid-task
2. Start a new session
3. Say: "Check docs/plans/ for active plans"
4. Claude reads the plan, sees progress log, resumes from last completed step

## CLI Options

```
scaffold.sh [options]

Options:
  --name NAME        Project name (default: directory name)
  --desc DESCRIPTION Project description
  --preset PRESET    Skip interactive selection
  --help, -h         Show this help
```

## Lint Hook

The `lint-on-edit.sh` hook auto-detects and runs linters based on file extension:

| Extension | Linter | Action |
|-----------|--------|--------|
| `.py` | ruff | Check + format (non-blocking) |
| `.ts`, `.tsx`, `.js`, `.jsx` | eslint + prettier | Fix + format (non-blocking) |
| `.go` | gofmt + goimports | Format (non-blocking) |
| `.rs` | rustfmt | Format (non-blocking) |
| `.yaml`, `.yml` | Python yaml.safe_load | **Blocks on syntax errors** |
| `.json` | Python json.load | **Blocks on syntax errors** |
| `.sh`, `.bash` | shellcheck | Check (non-blocking) |

Each linter is only invoked if the command exists on your system.

## License

MIT
