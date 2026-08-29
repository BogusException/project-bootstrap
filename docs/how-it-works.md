# How It Works

## Repository layout

```
project-bootstrap/
├── .claude/
│   ├── hooks/              ← hooks active for this repo (same set new projects get)
│   ├── rules/              ← dotclaude code-quality rules
│   ├── skills/             ← auto-imported skills
│   └── settings.json       ← Claude Code permissions + hook wiring
├── docs/                   ← this documentation
├── responses/              ← Claude exchange archives (gitignored content)
├── tasks/                  ← todo.md, skills-manifest.md
├── templates/              ← every file that gets copied into a new project
│   ├── hooks/              ← save-response.sh, auto-commit.sh, auto-import-skill.sh
│   ├── docs/               ← 8 stub docs copied to new projects
│   ├── tasks/              ← stub todo.md and skills-manifest.md
│   ├── .env.example
│   ├── .gitattributes
│   ├── .gitignore
│   ├── CLAUDE.md           ← the standing-instructions file new projects receive
│   ├── README.md
│   ├── requirements.txt
│   ├── run.sh
│   └── test.sh
├── bootstrap.sh            ← all 9 phases; the actual implementation
├── install.sh              ← one-time: creates ~/bin/mkproj
└── projSetup.md            ← original spec (reference)
```

## Entry point and screen handling

`~/bin/mkproj` is a 3-line launcher that calls `exec bootstrap.sh`. It never changes.

`bootstrap.sh` checks `$STY` (set by screen). If unset, it re-launches itself inside a new named screen session:

```bash
exec screen -S "$PROJECT_NAME" bash -c "cd '$PROJECT_DIR' && '$BOOTSTRAP_DIR/bootstrap.sh'; exec bash"
```

`exec` replaces the current process. Inside screen `$STY` is set, so the script proceeds with the phases. After all phases finish, `exec bash` keeps the screen window alive.

## Phase-by-phase breakdown

| # | Phase | What it does | Idempotent guard |
|---|-------|-------------|-----------------|
| 1 | Preflight | Checks Python 3.12+, git, jq; refuses if project has existing work; handles bare-repo collision prompt; asks y/N to proceed | Exits if >1 commit, or 1 commit that is not the scaffold message |
| 2 | Git | `git init -b main`, bare repo at `$REPOS_ROOT/<name>.git` (configured in `~/.config/mkproj/config`), sets remote origin | Skips if `.git` already exists |
| 3 | Python | `python3 -m venv .venv`, `requirements.txt` stub | Skips if `.venv` exists |
| 4 | Root files | Copies `.gitignore`, `.gitattributes`, `.env.example`; writes `CLAUDE.md` and `README.md` with `{{PROJECT_NAME}}` substituted | Skips each file individually if it exists |
| 5 | Claude config | Copies all `*.sh` from marketplace hooks dir + 3 custom hooks, copies 4 rules, generates `settings.json` | Skips per-file; regenerates settings.json only if absent |
| 6 | Structure | Creates `responses/`, `tasks/todo.md`, `tasks/skills-manifest.md`, 8 `docs/` stubs, `run.sh`, `test.sh` | Skips per-file if exists |
| 7 | Global setup | Installs `auto-import-skill.sh` to `~/.claude/hooks/`, wires it into global `~/.claude/settings.json`, adds `CLAUDE_PROTECTED_BRANCHES` and auto-venv `cd` override to `~/.bashrc` | All guarded by grep/jq existence checks |
| 8 | Commit | `git add -A`, commits "Initial project scaffold", pushes to bare repo | Skips if HEAD already exists |
| 9 | Verify | Confirms all hooks are executable (fixes silently), confirms bare repo has the scaffold commit, prints next steps | — |

## Hook inventory

**Copied from dotclaude marketplace** (`~/.claude/plugins/marketplaces/dotclaude/hooks/`):

| Hook | Event | Matcher | Purpose |
|------|-------|---------|---------|
| `protect-files.sh` | PreToolUse | Edit\|Write | Blocks writes to sensitive paths (.env, keys, .git, lock files); requires confirmation before editing hook scripts |
| `warn-large-files.sh` | PreToolUse | Edit\|Write | Blocks writes to build artifacts and large binary dirs |
| `scan-secrets.sh` | PreToolUse | Edit\|Write | Blocks writes that contain hardcoded credentials |
| `block-dangerous-commands.sh` | PreToolUse | Bash | Blocks destructive shell commands (rm -rf /, force-push, DROP TABLE, etc.); branch protection configurable via `.claude/protected-branches` (empty file = disabled) |
| `auto-test.sh` | PostToolUse | Edit\|Write | Runs matching test file after source file is edited |
| `format-on-save.sh` | PostToolUse | Edit\|Write | Auto-formats edited files if a formatter config is present |
| `session-start.sh` | SessionStart | — | Loads project context fingerprint at session start |
| `notify.sh` | Notification | — | Sends desktop/terminal notifications |

**Bundled in `templates/hooks/`** (maintained in this repo):

| Hook | Event | Purpose |
|------|-------|---------|
| `save-response.sh` | Stop | Saves every query+response to `responses/YYYYMMDD-HHMMSS.txt`; handles both plain-string and array-of-blocks content formats |
| `auto-commit.sh` | Stop | Safety-net: stages and commits any files Claude left uncommitted |
| `auto-import-skill.sh` | PostToolUse/Skill | Copies invoked skills from `~/.claude/skills/` into the project's `.claude/skills/` |

## settings.json structure

Generated by `generate_settings_json()` in `bootstrap.sh`. Uses `<<'EOF'` heredoc so `$CLAUDE_PROJECT_DIR` is written as a literal string -- Claude Code expands it at runtime. Key sections:

- **`permissions.allow`** -- git operations, chmod, python, find, grep, ls, mkdir, hooks
- **`permissions.deny`** -- reads and writes to `.env`, secrets, `.pem`, `.key` files
- **`hooks`** -- maps each hook to its event type and matcher (see table above)
