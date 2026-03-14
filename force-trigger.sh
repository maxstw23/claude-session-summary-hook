#!/bin/bash
# force-trigger.sh — Claude Code UserPromptSubmit hook.
#
# When the user says "update rolling memory", blocks immediately with a
# mandatory summary instruction so Claude writes it in the same response.

MEMORY_FILE="/home/maxwoo/.claude/projects/-home-maxwoo-Research-OmegaNet/memory/session_history.md"
TRIGGER="update rolling memory"

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' | tr '[:upper:]' '[:lower:]')

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
