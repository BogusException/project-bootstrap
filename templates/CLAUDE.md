# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Response format (required on every response)

**First character:** Begin every response with a single ✓ character, followed immediately by a newline, then the response body. This is a health indicator — when the user stops seeing the ✓, it means Claude Code has lost its instruction context and needs to be reminded.

**Last lines:** End every response with the following two lines, using the actual filename the Stop hook will create (formatted from the current timestamp):

```
---
Saved to responses/YYYYMMDD-hhmmss.txt via Stop hook.
```

The `save-response.sh` Stop hook fires after each exchange and writes the file to `responses/`. The filename format is `YYYYMMDD-hhmmss.txt` (year, month, day, hyphen, hour, minute, second). Use your best estimate of the current time — it will match the actual file within a few seconds. When the user does not see this confirmation line, they know the Stop hook did not fire or context was lost.

The file contains only the human-readable discussion text from the exchange — not tool call output, not intermediate computation. Format:

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
