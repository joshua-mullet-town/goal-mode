#!/bin/bash
# Autopilot Stop Hook
# Reads GOAL.md and decides whether Claude Code should continue working

set -e

# Read input from stdin
INPUT=$(cat)
HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# Safety: if already continuing from a previous stop hook, allow stop
# This prevents infinite loops
if [ "$HOOK_ACTIVE" = "true" ]; then
  echo '{}'
  exit 0
fi

# Check if GOAL.md exists in the working directory
GOAL_FILE="$CWD/GOAL.md"
if [ ! -f "$GOAL_FILE" ]; then
  # No goal file, allow normal stop
  echo '{}'
  exit 0
fi

# Track iterations to prevent runaway loops
ITER_FILE="/tmp/autopilot_iterations_$(echo "$CWD" | md5sum | cut -c1-8)"
CURRENT_ITER=$(($(cat "$ITER_FILE" 2>/dev/null || echo 0) + 1))

# Read max iterations from GOAL.md or default to 10
MAX_ITER=$(grep -oP 'Max iterations:\s*\K\d+' "$GOAL_FILE" 2>/dev/null || echo 10)

# Safety: give up after max iterations
if [ "$CURRENT_ITER" -gt "$MAX_ITER" ]; then
  rm -f "$ITER_FILE"
  echo '{"decision": null, "reason": "Max iterations reached. Stopping autopilot."}'
  exit 0
fi

# Check goal status
STATUS=$(grep -oP '^## Status:\s*\K\w+' "$GOAL_FILE" 2>/dev/null || echo "UNKNOWN")

if [ "$STATUS" = "DONE" ] || [ "$STATUS" = "STUCK" ]; then
  # Goal complete or stuck, allow stop and clean up
  rm -f "$ITER_FILE"
  echo '{}'
  exit 0
fi

# Goal not complete - block stop and continue working
echo "$CURRENT_ITER" > "$ITER_FILE"

# Build the continuation reason
REASON="AUTOPILOT ACTIVE (iteration $CURRENT_ITER of $MAX_ITER)

Read GOAL.md and continue working toward the goal.
- If you've made progress, update the Status and Notes sections
- If you're ready to test, run the Test Steps
- If tests pass, set Status to DONE
- If you're stuck and can't proceed, set Status to STUCK and explain in Notes

Current goal file: $GOAL_FILE"

jq -n --arg reason "$REASON" '{
  decision: "block",
  reason: $reason
}'
exit 2
