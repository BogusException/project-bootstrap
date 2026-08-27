#!/usr/bin/env bash
# install.sh — one-time setup: creates ~/bin/mkproj pointing to this bootstrap.
# Run once after cloning project-bootstrap to a new machine.
set -euo pipefail

BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/bin"
LAUNCHER="$BIN_DIR/mkproj"

mkdir -p "$BIN_DIR"

# Remove old conflicting launcher if present
if [[ -f "$BIN_DIR/proj" ]]; then
    rm "$BIN_DIR/proj"
    echo "Removed stale ~/bin/proj (conflicts with system proj)"
fi

cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
exec '$BOOTSTRAP_DIR/bootstrap.sh' "\$@"
EOF

chmod +x "$LAUNCHER"

echo "Installed: $LAUNCHER"
echo ""

# Check PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    echo "WARNING: $BIN_DIR is not in your PATH."
    echo "Add this line to ~/.bashrc then run: source ~/.bashrc"
    echo ""
    echo "  export PATH=\"\$HOME/bin:\$PATH\""
else
    echo "~/bin is in PATH. You can now run: mkproj"
fi
