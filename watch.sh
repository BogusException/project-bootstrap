#!/usr/bin/env bash
# watch.sh — auto-commit and push any change to this project-bootstrap repo.
# Run once in a dedicated screen window; leave it running.
#
# Usage:
#   screen -S pb-watch bash -c 'cd ~/Projects/project-bootstrap && bash watch.sh'
#
# Requires: inotify-tools
#   sudo apt install inotify-tools

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v inotifywait &>/dev/null; then
    echo "ERROR: inotifywait not found."
    echo "Install it:  sudo apt install inotify-tools"
    exit 1
fi

echo "[watch] Monitoring $REPO_DIR"
echo "[watch] Press Ctrl-C to stop."
echo ""

commit_if_dirty() {
    cd "$REPO_DIR"

    local status
    status=$(git status --porcelain 2>/dev/null)
    [[ -z "$status" ]] && return

    # Build a readable commit message from changed paths (max 5 files listed)
    local files
    files=$(git status --porcelain | awk '{print $NF}' | head -5 | tr '\n' ' ' | sed 's/ $//')
    local count
    count=$(git status --porcelain | wc -l | tr -d ' ')
    local msg="Update: $files"
    [[ "$count" -gt 5 ]] && msg="Update: $files (+$((count - 5)) more)"

    git add -A
    git commit -m "$msg"
    git push origin main
    echo "[watch] Committed and pushed: $msg"
}

while true; do
    # Block until any file event (excluding .git internals and responses/)
    inotifywait -r -q \
        --exclude '(\.git/|responses/)' \
        -e modify,create,delete,move \
        "$REPO_DIR" 2>/dev/null || true

    # Debounce: drain further events for 3 seconds of quiet
    # (handles Claude writing multiple files in one response)
    while inotifywait -r -q -t 3 \
        --exclude '(\.git/|responses/)' \
        -e modify,create,delete,move \
        "$REPO_DIR" 2>/dev/null; do
        :
    done

    commit_if_dirty
done
