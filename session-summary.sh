#!/bin/bash
# session-summary.sh — Claude Code stop hook: periodic session summary check-in.
#
# Asks Claude to update a rolling session log every COOLDOWN seconds.
# Silent for the first COOLDOWN seconds of a session.
# Resets the timer after each ask, regardless of Claude's response.
#
# Setup:
#   1. Set MEMORY_FILE to your session log path.
#   2. Register in ~/.claude/settings.json (see README).
#   3. Create MEMORY_FILE with a '## Sessions (newest first)' section.

MEMORY_FILE="$HOME/.claude/projects/$(basename $PWD)/memory/session_history.md"
COOLDOWN=600       # seconds (10 min)
FORCE_FLAG="$HOME/.claude/force-summary"

INPUT=$(cat)

HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
SESSION_START="/tmp/claude_session_start_${SESSION_ID}"
LAST_ASKED="/tmp/claude_session_last_asked_${SESSION_ID}"

if [ ! -f "$SESSION_START" ]; then
  touch "$SESSION_START"
fi

# Force flag: bypass cooldown, then remove the flag. Summary is mandatory.
if [ -f "$FORCE_FLAG" ]; then
  rm -f "$FORCE_FLAG"
  touch "$LAST_ASKED"
  cat <<EOF
{
  "decision": "block",
  "reason": "Prepend a one-sentence summary of this session to the '## Sessions (newest first)' list in ${MEMORY_FILE} (keep only the 5 most recent entries, drop the oldest if needed). Format: '1. **YYYY-MM-DD** — <one sentence>.'"
}
EOF
  exit 0
fi

NOW=$(date +%s)

if [ -f "$LAST_ASKED" ]; then
  LAST_ASKED_AGE=$(( NOW - $(stat -c %Y "$LAST_ASKED") ))
  if [ "$LAST_ASKED_AGE" -lt "$COOLDOWN" ]; then
    exit 0
  fi
fi

SESSION_AGE=$(( NOW - $(stat -c %Y "$SESSION_START") ))
if [ "$SESSION_AGE" -lt "$COOLDOWN" ]; then
  exit 0
fi

touch "$LAST_ASKED"
cat <<EOF
{
  "decision": "block",
  "reason": "If anything meaningful happened in this session, prepend a one-sentence summary to the '## Sessions (newest first)' list in ${MEMORY_FILE} (keep only the 5 most recent entries, drop the oldest if needed). Format: '1. **YYYY-MM-DD** — <one sentence>.' Otherwise ignore this message."
}
EOF
