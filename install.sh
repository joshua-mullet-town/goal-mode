#!/bin/bash
# Autopilot Installer
# Sets up the stop hook for Claude Code

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/hooks/autopilot-stop.sh"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

echo "Autopilot Installer"
echo "==================="
echo ""

# Make hook executable
chmod +x "$HOOK_SCRIPT"
echo "✓ Made hook script executable"

# Check if settings.json exists
if [ ! -f "$CLAUDE_SETTINGS" ]; then
  mkdir -p "$HOME/.claude"
  echo '{}' > "$CLAUDE_SETTINGS"
  echo "✓ Created $CLAUDE_SETTINGS"
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
  echo "✗ jq is required but not installed. Please install jq first."
  echo "  brew install jq"
  exit 1
fi

# Add the hook to settings.json
# This is a bit tricky - we need to merge with existing hooks
HOOK_CONFIG=$(jq -n --arg cmd "$HOOK_SCRIPT" '{
  "Stop": [{
    "matcher": ".*",
    "hooks": [{
      "type": "command",
      "command": $cmd
    }]
  }]
}')

# Read existing settings and merge
EXISTING=$(cat "$CLAUDE_SETTINGS")
EXISTING_HOOKS=$(echo "$EXISTING" | jq '.hooks // {}')

# Merge hooks (autopilot Stop hook will be added/replaced)
NEW_HOOKS=$(echo "$EXISTING_HOOKS" | jq --argjson new "$HOOK_CONFIG" '. * $new')
NEW_SETTINGS=$(echo "$EXISTING" | jq --argjson hooks "$NEW_HOOKS" '.hooks = $hooks')

# Write back
echo "$NEW_SETTINGS" > "$CLAUDE_SETTINGS"
echo "✓ Added autopilot stop hook to $CLAUDE_SETTINGS"

echo ""
echo "Installation complete!"
echo ""
echo "To use autopilot:"
echo "  1. Copy templates/GOAL.md to your project"
echo "  2. Fill in the goal details"
echo "  3. Start Claude Code and tell it to work on the goal"
echo "  4. Claude Code will loop until Status is DONE or STUCK"
echo ""
echo "To uninstall, remove the Stop hook from $CLAUDE_SETTINGS"
