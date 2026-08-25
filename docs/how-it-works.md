# How It Works

## Entry point

`~/bin/proj` is a 3-line launcher that delegates to `bootstrap.sh`. It never changes.

## Screen handling

`bootstrap.sh` checks `$STY` (set by screen). If unset, it does:

```bash
exec screen -S <project-name> bash -c "cd '$PROJECT_DIR' && bootstrap.sh; exec bash"
```

`exec` replaces the current process. Inside screen, `$STY` is set, so the script proceeds. After all phases finish, `exec bash` keeps the screen window alive.

## Phases

| Phase | What it does | Idempotent guard |
|-------|-------------|-----------------|
| 1 Preflight | Checks Python 3.12+, git, jq; detects existing project work; handles bare repo collision; asks for confirmation | Exits if >1 commit or commit is not the scaffold |
| 2 Git | `git init`, bare repo at `~/Repositories/<name>.git`, sets remote | Skips if `.git` exists |
| 3 Python | `python3 -m venv .venv`, `requirements.txt` stub | Skips if `.venv` exists |
| 4 Root files | `.gitignore`, `.gitattributes`, `.env.example`, `CLAUDE.md`, `README.md` | Skips each if it exists |
| 5 Claude config | Copies 8 marketplace hooks + 2 custom hooks, 4 rules, generates `settings.json` | Skips per-file if exists |
| 6 Structure | `responses/`, `tasks/`, `docs/`, `run.sh`, `test.sh` | Skips per-file if exists |
| 7 Global setup | Installs `auto-import-skill.sh` globally, wires global `settings.json`, adds bashrc entries | Guards with grep/jq checks |
| 8 Commit | `git add -A`, commit "Initial project scaffold", push | Skips if HEAD already exists |
| 9 Verify | Confirms hooks are executable, bare repo has commit, prints next steps | Fixes +x silently |

## Hook inventory

**Copied from dotclaude marketplace** (`~/.claude/plugins/marketplaces/dotclaude/hooks/`):

| Hook | Event | Matcher |
|------|-------|---------|
| `protect-files.sh` | PreToolUse | Edit\|Write |
| `warn-large-files.sh` | PreToolUse | Edit\|Write |
| `scan-secrets.sh` | PreToolUse | Edit\|Write |
| `block-dangerous-commands.sh` | PreToolUse | Bash |
| `auto-test.sh` | PostToolUse | Edit\|Write |
| `format-on-save.sh` | PostToolUse | Edit\|Write |
| `session-start.sh` | SessionStart | — |
| `notify.sh` | Notification | — |

**Bundled in `templates/hooks/`** (custom, maintained here):

| Hook | Event | Purpose |
|------|-------|---------|
| `save-response.sh` | Stop | Saves every query+response to `responses/YYYYMMDD-HHMMSS.txt` |
| `auto-commit.sh` | Stop | Safety-net: commits any uncommitted changes at session end |

**Installed globally** (`~/.claude/hooks/`):

| Hook | Event | Purpose |
|------|-------|---------|
| `auto-import-skill.sh` | PostToolUse/Skill | Copies used skills from `~/.claude/skills/` into the project |
