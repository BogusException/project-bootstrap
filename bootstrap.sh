#!/usr/bin/env bash
# bootstrap.sh — project-bootstrap
# Run from an empty project directory to scaffold a complete Claude Code project.
# Usage: cd ~/Projects/myproject && proj
set -euo pipefail

BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$BOOTSTRAP_DIR/templates"
MARKETPLACE_HOOKS="$HOME/.claude/plugins/marketplaces/dotclaude/hooks"
MARKETPLACE_RULES="$HOME/.claude/plugins/marketplaces/dotclaude/rules"
REPOS_DIR="$HOME/Repositories"

PROJECT_DIR="$PWD"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
BARE_REPO="$REPOS_DIR/$PROJECT_NAME.git"
BARE_REPO_KEEP=false

# ─── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { printf "${GREEN}[bootstrap]${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}[bootstrap]${NC} %s\n" "$*"; }
err()  { printf "${RED}[bootstrap]${NC} %s\n" "$*" >&2; }

# ─── Help ─────────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--usage" ]]; then
    cat <<'EOF'

project-bootstrap — scaffold a complete Claude Code Python project

USAGE
  mkdir ~/Projects/<name>
  cd    ~/Projects/<name>
  proj

WHAT IT DOES (9 phases)
  1. Preflight      — safety checks (refuses live projects, handles bare-repo collisions)
  2. Git            — init local repo + bare repo in ~/Repositories/<name>.git
  3. Python         — creates .venv, installs requirements.txt
  4. Root files     — copies templates: README, .gitignore, .env.example, run.sh, test.sh, etc.
  5. Claude config  — writes .claude/settings.json, hooks (save-response, auto-commit, marketplace)
  6. Structure      — creates src/<name>/, tests/, docs/, tasks/, responses/
  7. Global setup   — adds auto-venv cd override to ~/.bashrc (idempotent)
  8. Initial commit — "Initial project scaffold" commit to bare repo
  9. Verify         — prints summary and next steps

PREREQUISITES
  ~/bin/proj must exist (run: bash ~/Projects/project-bootstrap/install.sh)
  ~/bin must be on PATH

NOTES
  Re-running is safe — every step is guarded by an existence check.
  bootstrap.sh lives in ~/Projects/project-bootstrap; proj calls it directly.
  Edit templates/ or bootstrap.sh to change what new projects look like.

EOF
    exit 0
fi

# ─── Screen ───────────────────────────────────────────────────────────────────
if [[ -z "${STY:-}" ]]; then
    log "Starting screen session: $PROJECT_NAME"
    exec screen -S "$PROJECT_NAME" bash -c "cd '$PROJECT_DIR' && '$BOOTSTRAP_DIR/bootstrap.sh'; exec bash"
fi

# ─── Phase 1: Preflight ───────────────────────────────────────────────────────
phase1_preflight() {
    log "=== Phase 1: Preflight ==="

    # Prerequisites
    local missing=()
    if ! python3 --version 2>/dev/null | grep -qE "3\.(1[2-9]|[2-9][0-9])"; then
        missing+=("Python 3.12+")
    fi
    command -v git &>/dev/null || missing+=("git")
    command -v jq  &>/dev/null || missing+=("jq")
    if [[ ${#missing[@]} -gt 0 ]]; then
        err "Missing prerequisites: ${missing[*]}"
        exit 1
    fi

    # Detect project work already in progress — always a mistake to run bootstrap then
    if git -C "$PROJECT_DIR" rev-parse --git-dir &>/dev/null 2>&1; then
        local count
        count=$(git -C "$PROJECT_DIR" rev-list --count HEAD 2>/dev/null || echo 0)
        if [[ "$count" -gt 1 ]]; then
            err "STOP: $PROJECT_NAME has $count commits — project work already exists."
            err "Recent commits:"
            git -C "$PROJECT_DIR" log --oneline -5 >&2
            err ""
            err "bootstrap is for initial setup only. Running it now would be a mistake."
            exit 1
        fi
        if [[ "$count" -eq 1 ]]; then
            local msg
            msg=$(git -C "$PROJECT_DIR" log --format="%s" -1)
            if [[ "$msg" != "Initial project scaffold" ]]; then
                err "STOP: Found 1 commit but it is not the scaffold commit:"
                err "  $msg"
                err "Cannot safely continue."
                exit 1
            fi
            warn "Scaffold commit found — recovering from partial run. Continuing idempotently."
        fi
    fi

    # Existing bare repo collision
    if [[ -d "$BARE_REPO" ]]; then
        warn ""
        warn "Bare repo already exists: $BARE_REPO"
        warn ""
        printf "  [d] Delete it and recreate fresh\n"
        printf "  [o] Keep it, reset remote URL only\n"
        printf "  [q] Quit (default)\n"
        printf "\n"
        read -r -p "Choice [d/o/q]: " choice
        case "${choice,,}" in
            d)
                warn "Deleting $BARE_REPO ..."
                rm -rf "$BARE_REPO"
                ;;
            o)
                warn "Keeping existing bare repo; will reset remote URL."
                BARE_REPO_KEEP=true
                ;;
            *)
                err "Aborted."
                exit 1
                ;;
        esac
    fi

    # ~/Repositories/ check
    if [[ ! -d "$REPOS_DIR" ]]; then
        warn "$REPOS_DIR does not exist — creating it."
        mkdir -p "$REPOS_DIR"
    fi

    log ""
    log "  Project : $PROJECT_NAME"
    log "  Dir     : $PROJECT_DIR"
    log "  Bare    : $BARE_REPO"
    log ""
    read -r -p "Proceed with bootstrap? [y/N]: " confirm
    [[ "${confirm,,}" == "y" ]] || { err "Aborted."; exit 1; }
}

# ─── Phase 2: Git ─────────────────────────────────────────────────────────────
phase2_git() {
    log "=== Phase 2: Git ==="

    if [[ ! -d "$PROJECT_DIR/.git" ]]; then
        git -C "$PROJECT_DIR" init -q
        git -C "$PROJECT_DIR" checkout -qb main
        log "  Initialised repo on branch main"
    else
        log "  .git exists — skipping init"
    fi

    if [[ "$BARE_REPO_KEEP" != "true" ]]; then
        git init --bare -q "$BARE_REPO"
        log "  Created bare repo: $BARE_REPO"
    fi

    if git -C "$PROJECT_DIR" remote get-url origin &>/dev/null 2>&1; then
        git -C "$PROJECT_DIR" remote set-url origin "$BARE_REPO"
        log "  Updated remote origin → $BARE_REPO"
    else
        git -C "$PROJECT_DIR" remote add origin "$BARE_REPO"
        log "  Added remote origin → $BARE_REPO"
    fi
}

# ─── Phase 3: Python ──────────────────────────────────────────────────────────
phase3_python() {
    log "=== Phase 3: Python ==="

    if [[ ! -d "$PROJECT_DIR/.venv" ]]; then
        python3 -m venv "$PROJECT_DIR/.venv"
        log "  Created .venv"
    else
        log "  .venv exists — skipping"
    fi

    if [[ ! -f "$PROJECT_DIR/requirements.txt" ]]; then
        cp "$TEMPLATES_DIR/requirements.txt" "$PROJECT_DIR/requirements.txt"
        log "  Created requirements.txt"
    else
        log "  requirements.txt exists — skipping"
    fi
}

# ─── Phase 4: Root files ──────────────────────────────────────────────────────
copy_template() {
    local src="$TEMPLATES_DIR/$1" dst="$PROJECT_DIR/$2"
    if [[ -f "$dst" ]]; then
        log "  exists — $2"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    log "  created — $2"
}

phase4_root_files() {
    log "=== Phase 4: Root files ==="

    copy_template ".gitignore"     ".gitignore"
    copy_template ".gitattributes" ".gitattributes"
    copy_template ".env.example"   ".env.example"

    for f in CLAUDE.md README.md; do
        local dst="$PROJECT_DIR/$f"
        if [[ ! -f "$dst" ]]; then
            sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$TEMPLATES_DIR/$f" > "$dst"
            log "  created — $f"
        else
            log "  exists — $f"
        fi
    done
}

# ─── Phase 5: Claude Code config ──────────────────────────────────────────────
phase5_claude_config() {
    log "=== Phase 5: Claude Code config ==="

    mkdir -p "$PROJECT_DIR/.claude/hooks"
    mkdir -p "$PROJECT_DIR/.claude/rules"
    mkdir -p "$PROJECT_DIR/.claude/skills"

    # 8 dotclaude marketplace hooks
    local hook_count=0
    if [[ -d "$MARKETPLACE_HOOKS" ]]; then
        while IFS= read -r -d '' hook; do
            local name; name="$(basename "$hook")"
            local dst="$PROJECT_DIR/.claude/hooks/$name"
            if [[ ! -f "$dst" ]]; then
                cp "$hook" "$dst"
                chmod +x "$dst"
                log "  hook (marketplace): $name"
                ((hook_count++)) || true
            fi
        done < <(find "$MARKETPLACE_HOOKS" -maxdepth 1 -name "*.sh" -print0 2>/dev/null)
    else
        warn "  Marketplace hooks not found: $MARKETPLACE_HOOKS"
    fi

    # 2 custom hooks bundled with project-bootstrap
    for hook in save-response.sh auto-commit.sh; do
        local dst="$PROJECT_DIR/.claude/hooks/$hook"
        if [[ ! -f "$dst" ]]; then
            cp "$TEMPLATES_DIR/hooks/$hook" "$dst"
            chmod +x "$dst"
            log "  hook (custom): $hook"
            ((hook_count++)) || true
        fi
    done

    [[ $hook_count -eq 0 ]] && log "  all hooks already present — skipping"

    # 4 rules from marketplace
    local rule_count=0
    for rule in code-quality.md database.md error-handling.md security.md; do
        local src="$MARKETPLACE_RULES/$rule"
        local dst="$PROJECT_DIR/.claude/rules/$rule"
        if [[ -f "$src" && ! -f "$dst" ]]; then
            cp "$src" "$dst"
            log "  rule: $rule"
            ((rule_count++)) || true
        elif [[ ! -f "$src" ]]; then
            warn "  rule not found in marketplace: $rule"
        fi
    done
    [[ $rule_count -eq 0 ]] && log "  all rules already present — skipping"

    # settings.json
    if [[ ! -f "$PROJECT_DIR/.claude/settings.json" ]]; then
        generate_settings_json > "$PROJECT_DIR/.claude/settings.json"
        log "  generated settings.json"
    else
        log "  settings.json exists — skipping"
    fi
}

generate_settings_json() {
    cat <<'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git push *)",
      "Bash(git push)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git branch *)",
      "Bash(git stash *)",
      "Bash(git fetch *)",
      "Bash(git checkout *)",
      "Bash(git switch *)",
      "Bash(git remote *)",
      "Bash(git init *)",
      "Bash(git mv *)",
      "Bash(chmod +x *)",
      "Bash(python3 *)",
      "Bash(python *)",
      "Bash(find *)",
      "Bash(grep *)",
      "Bash(ls *)",
      "Bash(mkdir *)",
      "Bash(touch *)",
      "Bash(.claude/hooks/*.sh)"
    ],
    "deny": [
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/secrets/**)",
      "Read(**/*.pem)",
      "Read(**/*.key)",
      "Write(**/.env)",
      "Write(**/.env.*)",
      "Write(**/secrets/**)",
      "Write(**/*.pem)",
      "Write(**/*.key)",
      "Edit(**/.env)",
      "Edit(**/.env.*)",
      "Edit(**/secrets/**)",
      "Edit(**/*.pem)",
      "Edit(**/*.key)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/protect-files.sh",        "timeout": 10, "statusMessage": "Checking file protections..."},
          {"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/warn-large-files.sh",     "timeout": 10, "statusMessage": "Checking for build artifacts..."},
          {"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/scan-secrets.sh",         "timeout": 10, "statusMessage": "Scanning for secrets..."}
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-dangerous-commands.sh", "timeout": 10, "statusMessage": "Checking command safety..."}
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/auto-test.sh",            "timeout": 30, "statusMessage": "Running tests..."},
          {"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/format-on-save.sh",       "timeout": 10, "statusMessage": "Formatting..."}
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh",        "timeout": 10, "statusMessage": "Loading project context..."}
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/notify.sh",               "timeout": 10}
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/save-response.sh",        "timeout": 15, "statusMessage": "Saving response..."},
          {"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/auto-commit.sh",          "timeout": 30, "statusMessage": "Auto-committing changes..."}
        ]
      }
    ]
  }
}
EOF
}

# ─── Phase 6: Project structure ───────────────────────────────────────────────
phase6_structure() {
    log "=== Phase 6: Project structure ==="

    # responses/ — git tracks the dir but never the content
    mkdir -p "$PROJECT_DIR/responses"
    if [[ ! -f "$PROJECT_DIR/responses/.gitkeep" ]]; then
        touch "$PROJECT_DIR/responses/.gitkeep"
        log "  created responses/"
    else
        log "  responses/ exists — skipping"
    fi

    copy_template "tasks/todo.md"            "tasks/todo.md"
    copy_template "tasks/skills-manifest.md" "tasks/skills-manifest.md"

    for doc in install running api-keys architecture customizing adding-agents privacy-and-security troubleshooting; do
        copy_template "docs/$doc.md" "docs/$doc.md"
    done

    for script in run.sh test.sh; do
        local dst="$PROJECT_DIR/$script"
        if [[ ! -f "$dst" ]]; then
            cp "$TEMPLATES_DIR/$script" "$dst"
            chmod +x "$dst"
            log "  created $script (executable)"
        else
            log "  exists — $script"
        fi
    done
}

# ─── Phase 7: Global setup (idempotent) ───────────────────────────────────────
phase7_global() {
    log "=== Phase 7: Global setup ==="

    # auto-import-skill.sh global hook
    local global_hook="$HOME/.claude/hooks/auto-import-skill.sh"
    if [[ ! -f "$global_hook" ]]; then
        mkdir -p "$(dirname "$global_hook")"
        cp "$TEMPLATES_DIR/hooks/auto-import-skill.sh" "$global_hook"
        chmod +x "$global_hook"
        log "  installed ~/.claude/hooks/auto-import-skill.sh"
    else
        log "  auto-import-skill.sh already installed"
    fi

    # Global settings.json — wire PostToolUse/Skill if missing
    local global_settings="$HOME/.claude/settings.json"
    if [[ -f "$global_settings" ]]; then
        if ! jq -e '.hooks.PostToolUse[]? | select(.matcher == "Skill") | .hooks[]? | select(.command | contains("auto-import-skill"))' \
                "$global_settings" &>/dev/null 2>&1; then
            local tmp; tmp="$(mktemp)"
            jq '.hooks.PostToolUse += [{"matcher":"Skill","hooks":[{"type":"command","command":"~/.claude/hooks/auto-import-skill.sh","timeout":15,"statusMessage":"Checking skill locality..."}]}]' \
                "$global_settings" > "$tmp" && mv "$tmp" "$global_settings"
            log "  wired auto-import-skill in global settings.json"
        else
            log "  global auto-import-skill already wired"
        fi
    else
        warn "  ~/.claude/settings.json not found — skipping global hook wiring"
    fi

    # ~/.bashrc: CLAUDE_PROTECTED_BRANCHES
    local bashrc="$HOME/.bashrc"
    if ! grep -q "CLAUDE_PROTECTED_BRANCHES" "$bashrc" 2>/dev/null; then
        printf '\nexport CLAUDE_PROTECTED_BRANCHES=""\n' >> "$bashrc"
        log "  added CLAUDE_PROTECTED_BRANCHES to ~/.bashrc"
    else
        log "  CLAUDE_PROTECTED_BRANCHES already in ~/.bashrc"
    fi

    # ~/.bashrc: auto-venv cd override
    if ! grep -q "auto-venv cd override" "$bashrc" 2>/dev/null; then
        cat >> "$bashrc" <<'BASHRC'

# auto-venv cd override
cd() {
    builtin cd "$@"
    if [[ -f ".venv/bin/activate" && -z "${VIRTUAL_ENV:-}" ]]; then
        source .venv/bin/activate
    fi
}
BASHRC
        log "  added auto-venv cd override to ~/.bashrc"
    else
        log "  auto-venv cd override already in ~/.bashrc"
    fi
}

# ─── Phase 8: Initial commit ──────────────────────────────────────────────────
phase8_commit() {
    log "=== Phase 8: Initial commit ==="

    if git -C "$PROJECT_DIR" rev-parse HEAD &>/dev/null 2>&1; then
        log "  already committed — skipping"
        return
    fi

    git -C "$PROJECT_DIR" add -A
    git -C "$PROJECT_DIR" commit -q -m "Initial project scaffold"
    git -C "$PROJECT_DIR" push -u origin main -q
    log "  committed and pushed to $BARE_REPO"
}

# ─── Phase 9: Verify ──────────────────────────────────────────────────────────
phase9_verify() {
    log "=== Phase 9: Verify ==="

    local ok=true

    # All hooks must be executable — fix silently if not
    while IFS= read -r -d '' hook; do
        if [[ ! -x "$hook" ]]; then
            chmod +x "$hook"
            warn "  Fixed missing +x: $(basename "$hook")"
        fi
    done < <(find "$PROJECT_DIR/.claude/hooks" -type f -name "*.sh" -print0 2>/dev/null)
    log "  All hooks executable"

    # Bare repo must have the scaffold commit
    if git -C "$BARE_REPO" log --oneline 2>/dev/null | grep -q "Initial project scaffold"; then
        log "  Bare repo: initial commit confirmed"
    else
        warn "  Initial commit not found in bare repo"
        ok=false
    fi

    echo ""
    if [[ "$ok" == "true" ]]; then
        log "Bootstrap complete. $PROJECT_NAME is ready."
        echo ""
        log "Next steps:"
        log "  1. Edit requirements.txt"
        log "     source .venv/bin/activate && pip install -r requirements.txt"
        log "  2. Copy .env.example → .env and fill in API keys"
        log "  3. Update CLAUDE.md with project-specific commands"
        log "  4. Start coding: claude"
    else
        warn "Bootstrap finished with warnings — see above."
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    echo ""
    log "project-bootstrap → $PROJECT_NAME"
    echo ""

    phase1_preflight
    phase2_git
    phase3_python
    phase4_root_files
    phase5_claude_config
    phase6_structure
    phase7_global
    phase8_commit
    phase9_verify
}

main "$@"
