# Install

## Requirements

- bash
- git
- Python 3.12+
- jq
- screen
- `~/bin` in PATH (must appear before `/usr/bin` to avoid conflicts)

## Steps

```bash
# 1. Clone to ~/Projects/
cd ~/Projects
git clone <repo-url> project-bootstrap

# 2. Run the one-time installer (creates ~/bin/mkproj)
cd project-bootstrap
bash install.sh

# 3. Ensure ~/bin is on PATH — add to ~/.bashrc if not already there
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 4. Verify
mkproj --help
```

## If mkproj is not found after install

Check that `~/bin` is on PATH and appears before `/usr/bin`:

```bash
echo $PATH | tr ':' '\n' | grep -n bin
```

`/home/<you>/bin` should appear before `/usr/bin`.

## Updating

```bash
cd ~/Projects/project-bootstrap
git pull
```

`~/bin/mkproj` does not need to be re-run after updates — it always calls the current `bootstrap.sh` directly.
