#!/usr/bin/env bash
# Saves the last user query + Claude's response to responses/YYYYMMDD-HHMMSS.txt
# Wired as a Stop hook -- fires after every Claude response.

set -uo pipefail
touch /tmp/mkproj-stop-hook-fired

if ! command -v jq >/dev/null 2>&1; then exit 0; fi

PROJ="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
RESPONSES_DIR="$PROJ/responses"

INPUT=$(cat)
printf '%s' "$INPUT" > /tmp/stop-hook-input.json

extract_text() {
  # Handles both plain string content and array-of-blocks content
  jq -r '
    if type == "string" then .
    elif type == "array" then [.[] | select(.type == "text") | .text] | join("\n")
    else empty
    end
  ' 2>/dev/null
}

QUERY=$(printf '%s' "$INPUT" | jq -c '
  [.transcript[] | select(.role == "user")] | last | .content // empty
' 2>/dev/null | extract_text)

RESPONSE=$(printf '%s' "$INPUT" | jq -c '
  [.transcript[] | select(.role == "assistant")] | last | .content // empty
' 2>/dev/null | extract_text)

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
