#!/bin/bash
# force-trigger.sh — Claude Code UserPromptSubmit hook.
#
# When the user says "update rolling memory", blocks immediately with a
# mandatory summary instruction so Claude writes it in the same response.

TRIGGER="update rolling memory"

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' | tr '[:upper:]' '[:lower:]')

# Derive MEMORY_FILE — same logic as session-summary.sh so they always agree.
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')
if [ -n "$TRANSCRIPT" ]; then
  PROJECT_SLUG=$(echo "$TRANSCRIPT" | sed 's|.*/projects/\([^/]*\)/.*|\1|')
else
  SESSION_ROOT_FILE="/tmp/claude_session_root_${SESSION_ID}"
  if [ -f "$SESSION_ROOT_FILE" ]; then
    CWD=$(cat "$SESSION_ROOT_FILE")
  else
    CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
    if [ -z "$CWD" ]; then CWD=$(pwd); fi
    echo "$CWD" > "$SESSION_ROOT_FILE"
  fi
  PROJECT_SLUG=$(echo "$CWD" | sed 's|/|-|g')
fi
MEMORY_FILE="${HOME}/.claude/projects/${PROJECT_SLUG}/memory/session_history.md"

if echo "$PROMPT" | grep -qF "$TRIGGER"; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Prepend a one-sentence summary of this session to the '## Sessions (newest first)' list in ${MEMORY_FILE} (keep only the 5 most recent entries, drop the oldest if needed). Format: '1. **YYYY-MM-DD** — <one sentence>.'"
}
EOF
  exit 0
fi

exit 0
