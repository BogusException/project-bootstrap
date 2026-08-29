# Customizing

## 1. Changing what new projects receive

Every file bootstrap copies from `templates/` can be edited directly. Changes take effect on the next `mkproj` run -- no reinstall needed.

| To change | Edit |
|-----------|------|
| Default `.gitignore` | `templates/.gitignore` |
| Default `.gitattributes` | `templates/.gitattributes` |
| Standing Claude instructions | `templates/CLAUDE.md` |
| `.env.example` format | `templates/.env.example` |
| `run.sh` / `test.sh` patterns | `templates/run.sh`, `templates/test.sh` |
| `save-response.sh` behaviour | `templates/hooks/save-response.sh` |
| `auto-commit.sh` behaviour | `templates/hooks/auto-commit.sh` |
| Doc stubs new projects get | `templates/docs/*.md` |

## 2. Adding a new bootstrap phase

1. Add a `phaseN_name()` function to `bootstrap.sh`
2. Call it in `main()` in the correct order
3. Include an idempotency guard (check before creating/writing)
4. Add a row to the phase table in `docs/how-it-works.md §3`

## 3. Changing the command name

Edit `install.sh` -- change the `LAUNCHER` variable at the top, then re-run it:

```bash
bash ~/Projects/project-bootstrap/install.sh
```

## 4. Disabling branch protection for a repo

`block-dangerous-commands.sh` prevents pushes to `main` by default -- appropriate for team projects, but not for single-developer repos.

### 4.1 Disable protection entirely

```bash
touch .claude/protected-branches   # empty file = no protected branches
```

### 4.2 Protect specific branches other than main/master

```bash
echo "main" > .claude/protected-branches
echo "release" >> .claude/protected-branches
```

The file is read at hook-run time, so changes take effect immediately without restarting Claude Code.

## 5. Adding dotclaude marketplace hooks

No change needed. Bootstrap copies every `*.sh` it finds in the marketplace hooks directory, so new hooks added upstream are picked up automatically.

## 6. Adding custom hooks to all new projects

1. Place the hook script in `templates/hooks/`
2. Add it to the explicit copy loop in `phase5_claude_config()` in `bootstrap.sh`
3. Add the corresponding entry to `generate_settings_json()` with the correct event type and matcher
