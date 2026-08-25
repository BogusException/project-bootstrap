# Customizing

## Modifying what gets created in new projects

Every file bootstrap creates from `templates/` can be edited directly. Changes take effect for the next `proj` run — no reinstall needed.

| To change | Edit |
|-----------|------|
| Default `.gitignore` | `templates/.gitignore` |
| Default `CLAUDE.md` directives | `templates/CLAUDE.md` |
| `save-response.sh` behaviour | `templates/hooks/save-response.sh` |
| `auto-commit.sh` behaviour | `templates/hooks/auto-commit.sh` |
| `run.sh` / `test.sh` patterns | `templates/run.sh`, `templates/test.sh` |
| New project's doc stubs | `templates/docs/*.md` |

## Adding a new bootstrap phase

1. Add a `phaseN_name()` function to `bootstrap.sh`
2. Call it in `main()` in the correct order
3. Document it in `docs/how-it-works.md`

## Changing the `~/bin/proj` command name

Re-run `install.sh` after editing `BIN_DIR` or `LAUNCHER` at the top of that file, or create additional symlinks manually:

```bash
ln -s ~/bin/proj ~/bin/newname
```

## Adding new dotclaude hooks

The bootstrap copies all `*.sh` files it finds in the marketplace hooks directory. New hooks added to the marketplace are picked up automatically on the next `proj` run.

## Adding custom hooks to all new projects

Place the hook script in `templates/hooks/` and add it to the explicit copy loop in `phase5_claude_config()` alongside `save-response.sh` and `auto-commit.sh`. Also add the appropriate entry to `generate_settings_json()`.
