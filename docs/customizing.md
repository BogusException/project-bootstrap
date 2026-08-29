# Customizing

## Changing what new projects receive

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

## Adding a new bootstrap phase

1. Add a `phaseN_name()` function to `bootstrap.sh`
2. Call it in `main()` in the correct order
3. Include an idempotency guard (check before creating/writing)
4. Add a row to the phase table in `docs/how-it-works.md`

## Changing the command name

Edit `install.sh` -- change the `LAUNCHER` variable at the top, then re-run it:

```bash
bash ~/Projects/project-bootstrap/install.sh
```

## Adding dotclaude marketplace hooks

No change needed. Bootstrap copies every `*.sh` it finds in the marketplace hooks directory, so new hooks added upstream are picked up automatically.

## Adding custom hooks to all new projects

1. Place the hook script in `templates/hooks/`
2. Add it to the explicit copy loop in `phase5_claude_config()` in `bootstrap.sh`
3. Add the corresponding entry to `generate_settings_json()` with the correct event type and matcher
