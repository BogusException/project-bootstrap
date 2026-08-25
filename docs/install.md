# Install

## Requirements

- bash
- git
- Python 3.12+
- jq
- screen
- `~/bin` in PATH (or any directory on PATH)

## Steps

```bash
# 1. Clone to ~/Projects/
cd ~/Projects
git clone <repo-url> project-bootstrap

# 2. Run the installer (creates ~/bin/proj)
cd project-bootstrap
bash install.sh

# 3. Reload your shell
source ~/.bashrc

# 4. Verify
proj --help 2>/dev/null || echo "proj is available"
```

## If ~/bin is not in PATH

Add to `~/.bashrc`:

```bash
export PATH="$HOME/bin:$PATH"
```

## Updating

```bash
cd ~/Projects/project-bootstrap
git pull
```

The `~/bin/proj` launcher does not need to be re-run after updates — it always executes the current `bootstrap.sh`.
