# Autopilot

Autonomous goal-driven loops for Claude Code. Define a goal, let Claude Code run until it's done or stuck.

## How It Works

1. You create a `GOAL.md` file with clear success criteria
2. You start Claude Code and tell it to work on the goal
3. A stop hook checks `GOAL.md` after each response
4. If Status isn't `DONE` or `STUCK`, Claude Code continues automatically
5. Claude Code loops until the goal is achieved or it gets stuck

## Installation

```bash
git clone https://github.com/yourusername/autopilot
cd autopilot
./install.sh
```

This adds a stop hook to your `~/.claude/settings.json`.

## Usage

### 1. Create a Goal

Copy the template to your project:

```bash
cp /path/to/autopilot/templates/GOAL.md ./GOAL.md
```

Fill in:
- **Objective**: What you're trying to achieve
- **Success Criteria**: Checkboxes that define "done"
- **Test Steps**: How to verify each criterion
- **Reset Steps**: (Optional) How to clean up for re-testing

### 2. Start Claude Code

```bash
claude
```

Then tell Claude Code to work on the goal:

```
Read GOAL.md and implement the goal. Update the Status and Notes as you work.
```

### 3. Walk Away

Claude Code will:
- Implement the solution
- Test against success criteria
- Update Notes with observations
- Loop until Status is `DONE` or `STUCK`

### 4. Check Back

When you return, check `GOAL.md`:
- **Status: DONE** - Goal achieved, success criteria met
- **Status: STUCK** - Claude Code hit a wall, needs human help
- **Notes section** - See what was tried and what happened

## GOAL.md Format

```markdown
# GOAL: Short description

## Status: PENDING | IMPLEMENTING | TESTING | DONE | STUCK
## Iteration: 0
## Max iterations: 10

---

## Objective
What you're trying to achieve and why.

## Success Criteria
- [ ] Testable criterion 1
- [ ] Testable criterion 2

## Test Steps
1. How to verify criterion 1
2. How to verify criterion 2

## Reset Steps
1. How to clean up for re-testing

## Notes
[Claude Code writes here as it works]
```

## Safety Features

- **Iteration limit**: Stops after N iterations (default 10)
- **stop_hook_active check**: Prevents infinite loops
- **STUCK status**: Claude Code can bail out if it can't proceed
- **Per-project tracking**: Each project's iteration count is tracked separately

## Uninstall

Remove the Stop hook from `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": []  // Remove the autopilot entry
  }
}
```

## License

MIT
