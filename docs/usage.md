# Usage

## Starting a new project

```bash
cd ~/Projects
mkproj myproject
```

`mkproj` accepts the project name as an argument and creates the directory if it does not exist. Name rules: lowercase letters, digits, hyphens, underscores only (`my-tool`, `agent2`, `cambium_temp`).

What happens next:
1. A `screen` session named `myproject` is created
2. All 9 bootstrap phases run inside it
3. You land in a live bash shell in that screen session, ready to work

## Resuming after an interrupted run

If bootstrap fails mid-run (network blip, missing prereq, etc.), fix the issue and run `mkproj myproject` again. All phases are idempotent — existing files and the venv are skipped, only missing pieces are created.

The one exception: if the project already has more than one git commit, bootstrap refuses. That means real project work is present and running bootstrap would be a mistake.

## Existing bare repo collision

If `~/Repositories/myproject.git` already exists when you run `mkproj`, you are prompted:

```
[d] Delete and recreate fresh
[o] Keep it, reset remote URL only
[q] Quit (default)
```

Press Enter to abort safely. `d` is the right choice for a completely fresh start.

## After bootstrap completes

```bash
# Activate venv (auto-activated on cd if ~/.bashrc override is in place)
source .venv/bin/activate

# Add dependencies to requirements.txt, then install
pip install -r requirements.txt

# Copy and fill in API keys
cp .env.example .env

# Start Claude Code
claude
```

## What every new project receives

```
myproject/
├── .claude/
│   ├── hooks/          ← 11 hooks: safety guards, save-response, auto-commit, auto-import-skill
│   ├── rules/          ← 4 dotclaude code-quality rules
│   ├── skills/         ← auto-populated by auto-import-skill hook as skills are used
│   └── settings.json   ← permissions + full hook wiring
├── .venv/              ← Python virtual environment
├── docs/               ← 8 stub docs (fill in as the project evolves)
├── responses/          ← one .txt file per Claude exchange (gitignored content)
│   └── .gitkeep
├── tasks/
│   ├── todo.md         ← project task list
│   └── skills-manifest.md ← auto-updated by auto-import-skill
├── .env.example        ← template for API keys (copy to .env, never commit .env)
├── .gitattributes      ← LF line ending normalisation
├── .gitignore          ← covers Python, secrets, Claude responses, editor files
├── CLAUDE.md           ← standing instructions Claude reads every session
├── README.md           ← project overview stub
├── requirements.txt    ← Python dependency stub
├── run.sh              ← activates venv and runs main.py
└── test.sh             ← activates venv and runs tools/startup_tests.py
```

## Testing the bootstrap itself

`mkproj --test` runs all 9 phases against a throw-away directory in `/tmp`, then validates the result and cleans up. No screen session is started, so all output appears directly in the terminal (or in Claude Code's Bash tool output).

```bash
mkproj --test
```

This is designed to be run **from inside a Claude Code session**. Claude sees every line of output in real time and can spot and fix failures without you leaving the session.

What it checks after the phases complete:

- Every expected file and directory exists (CLAUDE.md, .gitignore, .venv, hooks, rules, docs, tasks, responses, src/)
- Every hook script is executable
- `settings.json` is valid JSON
- The bare repo contains the "Initial project scaffold" commit

Prints `PASS` or `FAIL` per check, then removes the temp project and bare repo.

Use this any time you edit `bootstrap.sh` or `templates/` to confirm nothing is broken before the next real `mkproj` run.
