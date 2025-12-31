# Goal Mode

Autonomous goal-driven loops for Claude Code. Define a goal with verification criteria, let Claude Code work until it's done or stuck.

## Quick Start

```bash
# Install
git clone https://github.com/joshua-mullet-town/goal-mode.git
cd goal-mode
./install.sh

# Restart Claude Code, then:
/goal
```

That's it. The `/goal` command walks you through creating a well-defined goal.

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                      GOAL.md exists                         │
│                           ↓                                 │
│  PENDING → IMPLEMENTING → VERIFYING → DONE                  │
│                 ↓              ↓                            │
│               STUCK          STUCK                          │
│                                                             │
│  Stop hook re-injects prompts until DONE/STUCK/max reached  │
└─────────────────────────────────────────────────────────────┘
```

1. You create a GOAL.md with clear objectives and verification commands
2. The stop hook detects it and prevents the session from ending
3. Agent works through the state machine with status-specific guidance
4. Agent can only mark DONE after pasting verification evidence
5. Agent marks STUCK when it hits an unfixable issue

## Requirements

- Claude Code CLI
- `jq` (for install script) - `brew install jq`
- macOS or Linux

## Installation

```bash
git clone https://github.com/joshua-mullet-town/goal-mode.git
cd goal-mode
./install.sh
```

This installs:
- Stop hook → `~/.claude/settings.json`
- Slash command → `~/.claude/commands/goal.md`

**Important:** Restart Claude Code after installing for changes to take effect.

## Usage

### Recommended: Use the slash command

```
/goal
```

This starts a guided conversation that:
- Explains what goal mode is
- Asks detailed questions about your goal
- Ensures verification is well-defined
- Creates the GOAL.md only when ready

### Manual: Create GOAL.md yourself

Copy `templates/GOAL.md` to your project and fill it in.

## Example

Here's a simple goal that increments a counter:

```markdown
# GOAL: Increment counter to 5

## Status: PENDING
## Max iterations: 10

---

## Objective

Increment the value in `counter.txt` from 0 to 5, one step at a time.

How to do it:
1. Read the current value from counter.txt
2. If value is less than 5, increment by exactly 1
3. Write the new value back to counter.txt
4. Repeat until value reaches 5

Important: Increment by 1 each iteration. Do NOT jump from 0 to 5.

## Verification

- Command: `cat counter.txt`
- Expected: `5`

## Evidence

[Agent fills this when verifying]

## Notes

[Agent logs progress here]
```

The agent will loop through IMPLEMENTING → VERIFYING until the counter reaches 5, then paste the evidence and mark DONE.

## GOAL.md Anatomy

```markdown
# GOAL: Short description

## Status: PENDING
## Max iterations: 10

---

## Objective
[WHAT to accomplish and HOW - specific enough for independent work]

## Verification
[Commands to prove success with expected outputs]
- Command: `cat output.txt`
- Expected: `success`

## Evidence
[Agent fills this during VERIFYING - proves the goal is complete]

## Notes
[Agent logs progress, errors, observations]
```

### Sections Explained

| Section | Purpose | Who Edits |
|---------|---------|-----------|
| Status | State machine position | Agent |
| Max iterations | Safety limit | User (at creation) |
| Objective | What to do and how | User (at creation) |
| Verification | How to prove success | User (at creation) |
| Evidence | Proof of completion | Agent (only when verified) |
| Notes | Progress log | Agent |

### State Machine

| Status | Meaning | Next States |
|--------|---------|-------------|
| PENDING | Goal defined, not started | IMPLEMENTING |
| IMPLEMENTING | Actively working | VERIFYING, STUCK |
| VERIFYING | Checking if it works | DONE, IMPLEMENTING, STUCK |
| DONE | Verified complete | (terminal) |
| STUCK | Needs human help | (terminal) |

## The Evidence Rule

The agent can only set Status to DONE if the Evidence section has real content.

- Evidence must contain actual command outputs
- Agent is instructed to only add evidence with "extreme confidence"
- This prevents optimistic false completion

## Safety Features

- **Max iterations**: Hard limit prevents infinite loops
- **Evidence requirement**: Can't claim DONE without proof
- **STUCK escape hatch**: Agent can bail when truly blocked
- **Anatomy validation**: Hook errors if GOAL.md is malformed

## What Each Piece Does

### Stop Hook (`hooks/goal-stop.sh`)

Runs after every agent response. It:
1. Checks if GOAL.md exists (no file = no goal mode)
2. Validates anatomy (all required sections present)
3. Reads current Status
4. Either allows stop (DONE/STUCK) or blocks with status-specific prompt
5. Tracks iterations to enforce max limit

### Slash Command (`commands/goal.md`)

Prompt that guides goal creation:
1. Explains the system and why quality matters
2. Lists questions to ask the user
3. Instructs agent not to create file until fully ready
4. Ensures verification is concrete and testable

### Template (`templates/GOAL.md`)

Skeleton file with all sections and inline guidance.

## Uninstall

```bash
# Remove hook from settings (edit the file manually)
nano ~/.claude/settings.json
# Delete the "Stop" section under "hooks"

# Remove slash command
rm ~/.claude/commands/goal.md
```

## Credits

Inspired by [Ralph Wiggum](https://github.com/whatif-dev/thoughts-ralph_wiggum) - the original Claude Code autonomous loop implementation.

## License

MIT
