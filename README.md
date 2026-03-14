# claude-session-summary-hook

A Claude Code [stop hook](https://docs.anthropic.com/en/docs/claude-code/hooks) that periodically asks Claude to maintain a rolling session log — without spamming you on every turn.

## How it works

- **Silent for the first 10 minutes** of a session (nothing meaningful to summarize yet).
- **Blocks once every 10 minutes** after that, asking Claude to prepend a one-sentence summary to your session log.
- **Timer resets automatically** after each ask, regardless of whether Claude writes anything.
- If there's nothing meaningful to add, Claude ignores the message silently.

This avoids the naive stop hook trap where Claude gets asked to write a summary after *every single turn*, causing an infinite block loop.

## Setup

### 1. Create your session log

Create a markdown file at a path of your choice with this section:

```markdown
## Sessions (newest first)

```

For example: `~/.claude/projects/my-project/memory/session_history.md`

### 2. Configure the hook

Edit `session-summary.sh` and set `MEMORY_FILE` to your log path:

```bash
MEMORY_FILE="/your/path/to/session_history.md"
```

You can also adjust `COOLDOWN` (default: 600 seconds / 10 minutes).

### 3. Register in Claude Code

Add both hooks to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash /path/to/session-summary.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash /path/to/force-trigger.sh"
          }
        ]
      }
    ]
  }
}
```

### 4. Make executable

```bash
chmod +x /path/to/session-summary.sh /path/to/force-trigger.sh
```

## Force update

To trigger an immediate summary outside the normal 10-minute window, just say:

> **"update rolling memory"**

`force-trigger.sh` intercepts this phrase via `UserPromptSubmit` and blocks with a mandatory summary instruction before Claude generates its response — so the summary is written in the same turn, with no extra round-trip.

## Requirements

- `jq` (for parsing hook input JSON)
- `bash`, `date`, `stat`, `find` (standard Unix tools)

## Design notes

Claude Code's stop hook fires after **every assistant turn**, not just when you exit. A naive hook that always blocks will loop: Claude responds to the block → hook fires again → Claude responds again → ∞.

This hook avoids that with two mechanisms:
1. `stop_hook_active` guard — exits immediately if Claude is stopping mid-block-response.
2. `LAST_ASKED` timer — touched at block time, so the 10-min cooldown resets the moment Claude responds, making subsequent turns silent.
