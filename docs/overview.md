# Overview

## What it is

`project-bootstrap` is a single command that turns an empty folder into a fully configured Claude Code development environment in under a minute. It is designed for developers who work via SSH and build Python projects with Claude Code as the primary coding assistant.

## What you get

Running `mkproj myproject` produces a project folder with:

- A local git repo + a bare remote repo in `~/Repositories/`
- A Python virtual environment (`.venv`)
- Claude Code hooks wired and ready (safety guards, auto-save, auto-commit, session start)
- A `settings.json` that controls what Claude Code is and is not allowed to do
- Standard project scaffolding: `docs/`, `tasks/`, `responses/`, `run.sh`, `test.sh`
- A `CLAUDE.md` with the standing instructions Claude reads at the start of every session
- A named `screen` session so the terminal survives SSH disconnects

## What it does not do

- Install Python packages -- you fill in `requirements.txt` first
- Write any application code
- Make any content-specific decisions -- everything is generic scaffolding

## How it is maintained

`project-bootstrap` lives at `~/Projects/project-bootstrap`. To change what new projects look like, edit files in `templates/` or the phase functions in `bootstrap.sh`. The `mkproj` command always executes the current version of `bootstrap.sh`, so changes take effect immediately.

## Reading order

| Doc | Audience |
|-----|----------|
| This file | Anyone evaluating the tool |
| [install.md](install.md) | First-time setup on a new machine |
| [usage.md](usage.md) | Day-to-day use |
| [how-it-works.md](how-it-works.md) | Understanding internals, debugging |
| [customizing.md](customizing.md) | Changing templates or adding phases |
| [troubleshooting.md](troubleshooting.md) | When something goes wrong |
