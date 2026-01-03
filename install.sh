#!/bin/bash
# Goal Mode Installer
# Sets up the stop hook and slash command for Claude Code

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/hooks/goal-stop.sh"
COMMAND_FILE="$SCRIPT_DIR/commands/goal.md"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CLAUDE_COMMANDS="$HOME/.claude/commands"

echo "═══════════════════════════════════════════════════════════════"
echo "Goal Mode Installer"
echo "═══════════════════════════════════════════════════════════════"
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

# Add the hook to settings.json (preserving other hooks)
GOAL_HOOK=$(jq -n --arg cmd "$HOOK_SCRIPT" '{
  "matcher": "*",
  "hooks": [{
    "type": "command",
    "command": $cmd
  }]
}')

# Read existing settings
EXISTING=$(cat "$CLAUDE_SETTINGS")

# Check if goal-stop.sh is already in Stop hooks
if echo "$EXISTING" | jq -e '.hooks.Stop[]?.hooks[]?.command | select(contains("goal-stop.sh"))' > /dev/null 2>&1; then
  echo "✓ Goal mode hook already installed"
else
  # Add to existing Stop hooks array (or create it)
  NEW_SETTINGS=$(echo "$EXISTING" | jq --argjson hook "$GOAL_HOOK" '
    .hooks.Stop = ((.hooks.Stop // []) + [$hook])
  ')
  echo "$NEW_SETTINGS" > "$CLAUDE_SETTINGS"
  echo "✓ Added goal mode stop hook to $CLAUDE_SETTINGS"
fi

# Install slash command
mkdir -p "$CLAUDE_COMMANDS"
cp "$COMMAND_FILE" "$CLAUDE_COMMANDS/goal.md"
echo "✓ Installed /goal slash command to $CLAUDE_COMMANDS"

# Clean up old autopilot command if it exists
if [ -f "$CLAUDE_COMMANDS/autopilot.md" ]; then
  rm "$CLAUDE_COMMANDS/autopilot.md"
  echo "✓ Removed old /autopilot command"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "Installation complete!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "USAGE:"
echo ""
echo "  /goal         Start the goal creation flow (recommended)"
echo "                This guides you through creating a well-defined goal"
echo ""
echo "  Manual:       Copy templates/GOAL.md to your project and fill it in"
echo ""
echo "HOW IT WORKS:"
echo ""
echo "  1. A GOAL.md file triggers goal mode"
echo "  2. Agent loops: PENDING → IMPLEMENTING → VERIFYING → DONE"
echo "  3. Agent can only mark DONE after adding verification evidence"
echo "  4. Agent marks STUCK if it can't proceed (needs human help)"
echo ""
echo "TO UNINSTALL:"
echo ""
echo "  Remove the Stop hook from $CLAUDE_SETTINGS"
echo "  Delete $CLAUDE_COMMANDS/goal.md"
echo ""
