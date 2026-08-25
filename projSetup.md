# Project Bootstrap -- Proposed Steps

Skill name: `project-bootstrap`
Run from an empty project folder to scaffold a complete Claude Code project.

---

## Phase 1 -- Preflight

1. Read project name from current directory name

2. Verify prerequisites: Python 3.12+, git, jq -- report missing and stop if any absent
3. repo directory will be project name, appended by ".git" (without quotes). ex: ~/Projects/acme/ will use a repo called: ~/Repositories/acme.git/ 
4. Confirm bare repo target directory (`~/Repositories/`) -- create if missing. set up the project to push to this repo.

## Phase 2 -- Git

5. `git init` + `git checkout -b main`
6. `git init --bare ~/Repositories/<name>.git`
7. `git remote add origin ~/Repositories/<name>.git`

## Phase 3 -- Python

8. `python3 -m venv .venv`
9. Create `requirements.txt` stub with a comment to fill in project dependencies

## Phase 4 -- Root files

Note: apply default security settings for python to all .git* files.

10. Create `.gitignore` (full generic version: Claude Code, OS, editors, secrets, logs, runtime)
11. Create `.gitattributes` (LF normalization for all text/binary types)
12. Create `.env.example` stub (empty keys with comments explaining format rules, almost exclusively for LLM API keys and other environment vars.)
13. Create `CLAUDE.md` stub (Commands section only, with fill-in placeholders)

contents initially:

[START]

### Install dependencies (venv must be active)

source .venv/bin/activate

pip install -r requirements.txt

### git changes to filesystem
At the end of every response where any file was added, changed, or deleted:

git add (the specific changed files)

git commit -m "..." with a clear, descriptive message

git push origin main

The `auto-commit.sh` Stop hook is a safety net only. Claude must commit explicitly with a useful message. Never skip the push.

### asking questions

Whenever you ask a question, suggest your recommendation(s). 
You are the expert here, not the user, so be helpful, and don't wait to be asked.

###


[STOP]

14. Create `README.md` stub (project name + running + Claude Code setup sections)

## Phase 5 -- Claude Code config

15. Create `.claude/` directory structure (hooks/, rules/, skills/)
16. Copy all 8 hooks from dotclaude marketplace (`~/.claude/plugins/marketplaces/dotclaude/hooks/`)
17. Copy 4 rules from dotclaude marketplace (`code-quality.md`, `database.md`, `error-handling.md`, `security.md`) with generic `paths:` since project layout is unknown
18. Generate `settings.json` wiring all hooks, git permissions, and secret deny rules
19. Add `hooks/ allow` to `settings.json` permissions to prevent repeated prompts

## Phase 6 -- Project structure

20. Create `responses/` directory (populated automatically by Stop hook)
21. Create `tasks/todo.md` stub (empty checklist with section headers)
22. Create `tasks/skills-manifest.md` stub (empty table with headers)
23. Create `docs/` directory with 8 stub docs (install, running, api-keys, architecture, customizing, adding-agents, privacy-and-security, troubleshooting) -- headers only, no project-specific content. Add content to them as the app evolves.

## Response Archives

24. Every response is saved to `./responses/YYYYMMDD-HHMMSS.txt` automatically via the `save-response.sh` Stop hook. 
The entire ./responses/ directory and content must NEVER go to the git repo. Adjust .gitkeep and .gitignore accordingly. 
Every response file will show the query and response, as in this example:

[START]

=== QUERY ===

The query...

=== RESPONSE ===

Claude's response...

[STOP]

### dealing with claude code's memory issues

25. For every response of yours, make the first character a checkmark. Follow it with a newline, and then with the response.

26. At the end of each response, state the name of the /responses/ file created, and the fact that it was saved. When I don't see this message, and/or the checkmark, I know you have forgotten your context.

## Phase 7 -- Global setup (one-time, idempotent)

27. Check if `~/.claude/hooks/auto-import-skill.sh` exists -- if not, install it
28. Check if global `~/.claude/settings.json` has the PostToolUse Skill hook -- if not, wire it
29. Check if `~/.bashrc` has `CLAUDE_PROTECTED_BRANCHES=""` -- if not, add it
30. Check if `~/.bashrc` has the auto-venv `cd` override -- if not, add it

## Phase 8 -- Initial commit

31. `git add` all created files
32. `git commit -m "Initial project scaffold"`
33. `git push -u origin main`

## Phase 9 -- Verify

34. Confirm all hooks are executable
35. Confirm git log shows the initial commit in the bare repo
36. Print summary: what was created, what was skipped, what to do next

---
