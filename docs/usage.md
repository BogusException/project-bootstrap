# Usage

## Starting a new project

```bash
mkdir ~/Projects/myproject
cd ~/Projects/myproject
proj
```

That's it. `proj`:

1. Creates a `screen` session named `myproject`
2. Runs all 9 bootstrap phases inside it
3. Drops you into a live bash shell in the named session

## Resuming after an interrupted run

If bootstrap fails mid-run (network blip, missing prereq, etc.), fix the issue and run `proj` again from the same directory. All phases are idempotent — existing files and the venv are skipped, only missing pieces are created.

## Existing bare repo collision

If `~/Repositories/myproject.git` already exists when you run `proj`, you will be prompted:

```
[d] Delete and recreate
[o] Keep it, reset remote URL only
[q] Quit (default)
```

`q` is the default. Press Enter to abort safely.

## After bootstrap completes

```bash
# Activate venv (auto-activated on cd by the ~/.bashrc override)
source .venv/bin/activate

# Add dependencies to requirements.txt, then install
pip install -r requirements.txt

# Copy and fill in .env
cp .env.example .env

# Start Claude Code
claude
```
