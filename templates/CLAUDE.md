# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Response format (required on every response)

**First character:** Begin every response with a single ✓ character, followed immediately by a newline, then the response body. This is a health indicator — when the user stops seeing the ✓, it means Claude Code has lost its instruction context and needs to be reminded.

**Second line:** Immediately after the ✓, read `responses/.last-saved` and report the actual filename saved by the previous Stop hook:

```
✓
Last saved: responses/20260828-214500.txt
```

If `responses/.last-saved` does not exist or is empty, write `Last saved: (none yet)`. This is real confirmation from disk -- not a prediction. When the filename stops appearing or doesn't change, the Stop hook is not firing.

The `save-response.sh` Stop hook fires after each exchange and writes to `responses/`. The file contains only the human-readable discussion text -- not tool call output. Format:

```
=== QUERY ===
<the user's message>

=== RESPONSE ===
<Claude's response>
```

The `responses/` directory is git-ignored (content only — the directory itself is tracked via `.gitkeep`). Never commit response files.

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
