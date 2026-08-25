# Troubleshooting

## `proj: command not found`

`~/bin` is not in PATH. Add to `~/.bashrc`:

```bash
export PATH="$HOME/bin:$PATH"
```

Then run `source ~/.bashrc`.

## `Missing prerequisites: Python 3.12+`

The system Python is too old. Install Python 3.12+ and ensure `python3` resolves to it:

```bash
python3 --version
```

## `STOP: X has N commits — project work already exists`

You ran `proj` in a directory that already has a real project. This is always a mistake. Bootstrap is for empty directories only.

If you genuinely want to re-scaffold a directory, delete it and start fresh:

```bash
cd ~
rm -rf ~/Projects/myproject
rm -rf ~/Repositories/myproject.git
mkdir ~/Projects/myproject && cd ~/Projects/myproject
proj
```

## Bare repo collision prompt

If you see the `[d/o/q]` prompt, the `~/Repositories/myproject.git` directory already exists. Choose:
- `d` — delete and recreate (safest for a fresh start)
- `o` — keep the bare repo and only reset the remote URL (use this if a previous run already pushed to it)
- `q` / Enter — abort and investigate first

## Screen session already exists

If a screen session named `myproject` already exists (from a previous run), screen will create a new one with a suffix like `myproject.1234`. You can reattach the original with:

```bash
screen -r myproject
```

## Global settings.json has no `.hooks` key

Phase 7 uses `jq` to append to `.hooks.PostToolUse`. If `~/.claude/settings.json` lacks a `hooks` key entirely, jq will create it. If the file is malformed JSON, fix it manually before re-running.

## Scrollback lost in terminal

Claude Code uses alternate screen mode which suppresses scrollback. This is already disabled via `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` (set by bootstrap in `~/.bashrc`). If you don't see it:

```bash
grep CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN ~/.bashrc
```

If missing, add it manually:

```bash
echo 'export CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1' >> ~/.bashrc
source ~/.bashrc
```

To monitor responses from a second terminal:

```bash
tail -f $(ls -t ~/Projects/myproject/responses/*.txt | head -1)
```
