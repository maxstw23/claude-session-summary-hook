#!/bin/bash
# force-trigger.sh — Claude Code UserPromptSubmit hook.
#
# Watches for a trigger phrase in the user's message and touches the force flag,
# causing session-summary.sh to block on the next turn regardless of cooldown.
#
# Trigger phrase (case-insensitive): "update rolling memory"
# Force flag: ~/.claude/force-summary

FORCE_FLAG="$HOME/.claude/force-summary"
TRIGGER="update rolling memory"

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' | tr '[:upper:]' '[:lower:]')

if echo "$PROMPT" | grep -qF "$TRIGGER"; then
  touch "$FORCE_FLAG"
fi

exit 0
