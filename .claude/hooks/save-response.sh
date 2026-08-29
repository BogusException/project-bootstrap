#!/usr/bin/env bash
# Saves the last user query + Claude's response to responses/YYYYMMDD-HHMMSS.txt
# Wired as a Stop hook -- fires after every Claude response.

set -uo pipefail

if ! command -v jq >/dev/null 2>&1; then exit 0; fi

PROJ="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
RESPONSES_DIR="$PROJ/responses"

INPUT=$(cat)

QUERY=$(printf '%s' "$INPUT" | jq -r '
  [.transcript[] | select(.role == "user")] | last | .content // empty
' 2>/dev/null)

RESPONSE=$(printf '%s' "$INPUT" | jq -r '
  [.transcript[] | select(.role == "assistant")] | last | .content // empty
' 2>/dev/null)

[ -z "$RESPONSE" ] && exit 0

mkdir -p "$RESPONSES_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
FILE="$RESPONSES_DIR/${TIMESTAMP}.txt"

{
  if [ -n "$QUERY" ]; then
    printf '=== QUERY ===\n'
    printf '%s\n' "$QUERY"
    printf '\n=== RESPONSE ===\n'
  fi
  printf '%s\n' "$RESPONSE"
} > "$FILE"
