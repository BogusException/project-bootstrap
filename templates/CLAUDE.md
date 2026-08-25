# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Install dependencies (venv must be active)

```bash
source .venv/bin/activate
pip install -r requirements.txt
```

### git changes to filesystem

At the end of every response where any file was added, changed, or deleted:

```bash
git add <the specific changed files>
git commit -m "clear, descriptive message"
git push origin main
```

The `auto-commit.sh` Stop hook is a safety net only. Claude must commit explicitly with a useful message. Never skip the push.

### Asking questions

Whenever you ask a question, suggest your recommendation(s).
You are the expert here, not the user, so be helpful, and don't wait to be asked.
