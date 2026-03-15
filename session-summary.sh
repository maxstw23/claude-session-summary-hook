#!/bin/bash
# session-summary.sh — Claude Code stop hook: periodic session summary check-in.
#
# Asks Claude to update a rolling session log every COOLDOWN seconds.
# Silent for the first COOLDOWN seconds of a session.
# Resets the timer after each ask, regardless of Claude's response.

COOLDOWN=600       # seconds (10 min)

INPUT=$(cat)

# Derive project memory path from transcript_path or cwd
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')
if [ -n "$TRANSCRIPT" ]; then
  # transcript_path is like ~/.claude/projects/<slug>/...
  PROJECT_SLUG=$(echo "$TRANSCRIPT" | sed 's|.*/projects/\([^/]*\)/.*|\1|')
  MEMORY_FILE="/home/maxwoo/.claude/projects/${PROJECT_SLUG}/memory/session_history.md"
else
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
  if [ -z "$CWD" ]; then CWD=$(pwd); fi
  PROJECT_SLUG=$(echo "$CWD" | sed 's|/|-|g')
  MEMORY_FILE="/home/maxwoo/.claude/projects/${PROJECT_SLUG}/memory/session_history.md"
fi

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
