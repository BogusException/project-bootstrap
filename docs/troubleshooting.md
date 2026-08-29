# Troubleshooting

## `mkproj: command not found`

`~/bin` is not in PATH, or appears after `/usr/bin`. Add to `~/.bashrc`:

```bash
export PATH="$HOME/bin:$PATH"
```

Then run `source ~/.bashrc`. Verify with `which mkproj`.

## `Missing prerequisites: Python 3.12+`

The system Python is too old. Install Python 3.12+ and confirm:

```bash
python3 --version
```

## `STOP: X has N commits — project work already exists`

You ran `mkproj` on a directory that already has real commits. Bootstrap is for empty directories only. This check is intentional and cannot be bypassed.

To start completely fresh:

```bash
rm -rf ~/Projects/myproject
rm -rf ~/Repositories/myproject.git
mkproj myproject
```

## Bare repo collision prompt `[d/o/q]`

`~/Repositories/myproject.git` already exists. Options:
- `d` — delete and recreate (use for a completely fresh start)
- `o` — keep the bare repo, reset the remote URL only (use if a previous run already pushed to it)
- `q` / Enter — abort and investigate

## Screen session name conflict

If a session named `myproject` already exists, screen creates a new one with a suffix (`myproject.1234`). You can list sessions and reattach:

```bash
screen -ls
screen -r myproject
```

## Global settings.json missing `.hooks` key

Phase 7 uses `jq` to append to `.hooks.PostToolUse`. If `~/.claude/settings.json` is missing the `hooks` key, jq creates it. If the file is malformed JSON, fix it manually before re-running.

## Scrollback lost in terminal

Claude Code's alternate screen mode suppresses SSH terminal scrollback. Bootstrap adds `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` to `~/.bashrc`. Confirm it is there:

```bash
grep CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN ~/.bashrc
```

If missing:

```bash
echo 'export CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1' >> ~/.bashrc
source ~/.bashrc
```

## Stop hook fires but `responses/` stays empty

The hook fires (you can verify with `ls /tmp/mkproj-stop-hook-fired`) but the jq query against the transcript returns empty. To capture the raw hook input for diagnosis:

```bash
# Temporarily add to save-response.sh after `INPUT=$(cat)`:
printf '%s' "$INPUT" > /tmp/stop-hook-input.json
```

Then inspect `/tmp/stop-hook-input.json` after the next response to see the actual JSON structure Claude Code is sending.

## Stop hook not firing at all

Hooks defined in `.claude/settings.json` only activate when Claude Code loads the project. If you added `settings.json` mid-session, restart Claude Code. Confirm the hook fires by checking:

```bash
ls /tmp/mkproj-stop-hook-fired
```

## `protect-files.sh` asks for confirmation on hook edits

This is expected behavior. Hook scripts now use `ask` (confirmation prompt) instead of `deny` (hard block), so edits to `.claude/hooks/*.sh` require a one-time confirmation rather than being silently rejected.

To follow the most recent response file from a second terminal:

```bash
tail -f $(ls -t ~/Projects/myproject/responses/*.txt | head -1)
```
