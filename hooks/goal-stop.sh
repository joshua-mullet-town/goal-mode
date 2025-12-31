#!/bin/bash
# Goal Mode Stop Hook
# Validates GOAL.md anatomy, enforces state machine, injects status-specific prompts
#
# State Machine: PENDING → IMPLEMENTING → VERIFYING → DONE
#                              ↓              ↓
#                            STUCK          STUCK
#
# The hook BLOCKS the stop and re-injects a prompt unless:
# - No GOAL.md exists
# - Status is DONE (with evidence)
# - Status is STUCK
# - Max iterations reached

set -e

# Read input from stdin
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# If no GOAL.md, allow normal stop (goal mode not active)
GOAL_FILE="$CWD/GOAL.md"
if [ ! -f "$GOAL_FILE" ]; then
  echo '{}'
  exit 0
fi

# Track iterations (macOS compatible with shasum)
ITER_FILE="/tmp/goal_iterations_$(echo "$CWD" | shasum | cut -c1-8)"
CURRENT_ITER=$(($(cat "$ITER_FILE" 2>/dev/null || echo 0) + 1))

# Parse GOAL.md header fields
STATUS=$(grep "^## Status:" "$GOAL_FILE" 2>/dev/null | head -1 | sed 's/^## Status:[[:space:]]*//' | tr -d '[:space:]')
MAX_ITER=$(grep "^## Max iterations:" "$GOAL_FILE" 2>/dev/null | head -1 | sed 's/[^0-9]*//g')
[ -z "$MAX_ITER" ] && MAX_ITER=10

# Helper: Check if Evidence section has real content (not just placeholder text in brackets)
evidence_has_content() {
  local content=$(sed -n "/^## Evidence/,/^## /p" "$GOAL_FILE" | tail -n +2 | grep -v "^## " | grep -v "^[[:space:]]*$" | grep -v "^\[.*\]$" | head -1)
  [ -n "$content" ]
}

# Validate anatomy - required sections
MISSING_SECTIONS=""
for section in "Objective" "Verification" "Evidence" "Notes"; do
  if ! grep -q "^## $section" "$GOAL_FILE"; then
    MISSING_SECTIONS="$MISSING_SECTIONS $section"
  fi
done

if [ -n "$MISSING_SECTIONS" ]; then
  REASON="═══════════════════════════════════════════════════════════════
GOAL MODE ERROR: Invalid GOAL.md anatomy
═══════════════════════════════════════════════════════════════

Missing required sections:$MISSING_SECTIONS

A valid GOAL.md must have these sections:
  ## Status: PENDING | IMPLEMENTING | VERIFYING | DONE | STUCK
  ## Max iterations: [number]
  ## Objective
  ## Verification
  ## Evidence
  ## Notes

Please add the missing sections or run /goal to create a new goal.
═══════════════════════════════════════════════════════════════"

  jq -n --arg reason "$REASON" '{ decision: "block", reason: $reason }'
  exit 2
fi

# Safety valve: max iterations reached
if [ "$CURRENT_ITER" -gt "$MAX_ITER" ]; then
  rm -f "$ITER_FILE"
  echo '{}'
  exit 0
fi

# ═══════════════════════════════════════════════════════════════
# STATE MACHINE
# ═══════════════════════════════════════════════════════════════

case "$STATUS" in

  # ─────────────────────────────────────────────────────────────
  # DONE: Only allow if Evidence section has real content
  # ─────────────────────────────────────────────────────────────
  "DONE")
    if ! evidence_has_content; then
      echo "$CURRENT_ITER" > "$ITER_FILE"
      REASON="═══════════════════════════════════════════════════════════════
GOAL MODE REJECTED: Cannot set DONE without evidence
Iteration $CURRENT_ITER of $MAX_ITER
═══════════════════════════════════════════════════════════════

You set Status to DONE, but the Evidence section is empty.

The Evidence section is how your work will be judged. You may ONLY
add evidence when you have EXTREME CONFIDENCE that the goal is
complete and verified.

REQUIRED ACTIONS:
1. Set Status back to VERIFYING
2. Run the verification commands from the Verification section
3. Compare actual outputs to expected outputs
4. If they match perfectly, paste the outputs in Evidence and set DONE
5. If they don't match, set Status to IMPLEMENTING and fix the issue

DO NOT set DONE without evidence. DO NOT add evidence unless you
are certain the verification passes.
═══════════════════════════════════════════════════════════════"

      jq -n --arg reason "$REASON" '{ decision: "block", reason: $reason }'
      exit 2
    fi
    # Evidence present - goal complete, allow stop
    rm -f "$ITER_FILE"
    echo '{}'
    exit 0
    ;;

  # ─────────────────────────────────────────────────────────────
  # STUCK: Agent has given up, needs human help
  # ─────────────────────────────────────────────────────────────
  "STUCK")
    rm -f "$ITER_FILE"
    echo '{}'
    exit 0
    ;;

  # ─────────────────────────────────────────────────────────────
  # PENDING: Initial state, needs to start implementation
  # ─────────────────────────────────────────────────────────────
  "PENDING")
    echo "$CURRENT_ITER" > "$ITER_FILE"
    REASON="═══════════════════════════════════════════════════════════════
GOAL MODE ACTIVE - Status: PENDING
Iteration $CURRENT_ITER of $MAX_ITER
═══════════════════════════════════════════════════════════════

A goal has been defined. Read GOAL.md to understand what needs to
be accomplished.

YOUR TASK:
1. Read the Objective section carefully
2. Set Status to IMPLEMENTING
3. Begin working on the goal
4. Log your progress in the Notes section

IMPORTANT RULES:
- You may ONLY modify: the files needed for the goal, Status, and Notes
- Do NOT touch the Objective, Verification, or Evidence sections
- Do NOT skip ahead to DONE - you must go through VERIFYING first

Begin by reading GOAL.md and setting Status to IMPLEMENTING.
═══════════════════════════════════════════════════════════════"

    jq -n --arg reason "$REASON" '{ decision: "block", reason: $reason }'
    exit 2
    ;;

  # ─────────────────────────────────────────────────────────────
  # IMPLEMENTING: Actively working on the goal
  # ─────────────────────────────────────────────────────────────
  "IMPLEMENTING")
    echo "$CURRENT_ITER" > "$ITER_FILE"
    REASON="═══════════════════════════════════════════════════════════════
GOAL MODE ACTIVE - Status: IMPLEMENTING
Iteration $CURRENT_ITER of $MAX_ITER
═══════════════════════════════════════════════════════════════

Continue working toward the goal defined in GOAL.md.

YOUR TASK:
1. Review the Objective section
2. Continue implementation work
3. When you believe implementation is COMPLETE, set Status to VERIFYING

WHEN TO MOVE TO VERIFYING:
- You have completed all the work described in Objective
- You are ready to run the verification commands
- You believe the goal should be achieved

IMPORTANT RULES:
- Do NOT skip to DONE - you must verify first
- Do NOT add anything to Evidence yet

REQUIRED: Before this iteration ends, add a concise summary to the
Notes section describing what you did this iteration. Example:
  \"- Iteration 3: Fixed the parsing bug in utils.js, now handles nulls\"
This log is essential for tracking progress across iterations.
═══════════════════════════════════════════════════════════════"

    jq -n --arg reason "$REASON" '{ decision: "block", reason: $reason }'
    exit 2
    ;;

  # ─────────────────────────────────────────────────────────────
  # VERIFYING: Implementation complete, now verify it works
  # ─────────────────────────────────────────────────────────────
  "VERIFYING")
    echo "$CURRENT_ITER" > "$ITER_FILE"
    REASON="═══════════════════════════════════════════════════════════════
GOAL MODE ACTIVE - Status: VERIFYING
Iteration $CURRENT_ITER of $MAX_ITER
═══════════════════════════════════════════════════════════════

You have completed implementation. Now you must VERIFY it works.

YOUR TASK:
1. Read the Verification section in GOAL.md
2. Run each verification command EXACTLY as written
3. Compare the ACTUAL output to the EXPECTED output
4. Make your decision based on the results:

IF VERIFICATION PASSES (outputs match expected):
  → Paste the actual outputs in the Evidence section
  → Set Status to DONE
  → The Evidence section is how your work will be judged
  → Only add evidence when you have EXTREME CONFIDENCE

IF VERIFICATION FAILS (outputs don't match):
  → Do NOT add anything to Evidence
  → Decide: Is this fixable or not?

  FIXABLE (you know what to change):
    → Set Status back to IMPLEMENTING
    → Log what failed and your fix plan in Notes
    → Continue working

  NOT FIXABLE (external issue, same error repeatedly, no solution):
    → Set Status to STUCK
    → Explain in Notes why you cannot proceed
    → Examples: login expired, API down, permissions issue,
      same error after multiple fix attempts

CRITICAL: Do NOT add evidence unless verification truly passes.
The Evidence section proves the goal is complete. Do not fake it.

REQUIRED: Before this iteration ends, add a concise summary to the
Notes section describing what you verified and the result. Example:
  \"- Iteration 5: Ran 'cat output.txt', got 'success' - matches expected\"
  \"- Iteration 6: Verification failed - output was 'error', going back to fix\"
═══════════════════════════════════════════════════════════════"

    jq -n --arg reason "$REASON" '{ decision: "block", reason: $reason }'
    exit 2
    ;;

  # ─────────────────────────────────────────────────────────────
  # UNKNOWN: Invalid status value
  # ─────────────────────────────────────────────────────────────
  *)
    echo "$CURRENT_ITER" > "$ITER_FILE"
    REASON="═══════════════════════════════════════════════════════════════
GOAL MODE ERROR: Unknown Status
Iteration $CURRENT_ITER of $MAX_ITER
═══════════════════════════════════════════════════════════════

The Status field has an unrecognized value: '$STATUS'

Valid statuses are:
  PENDING      - Goal defined, work not started
  IMPLEMENTING - Actively working on the goal
  VERIFYING    - Implementation done, verifying it works
  DONE         - Verified complete (requires evidence)
  STUCK        - Cannot proceed, need human help

Please set Status to one of these valid values.
═══════════════════════════════════════════════════════════════"

    jq -n --arg reason "$REASON" '{ decision: "block", reason: $reason }'
    exit 2
    ;;

esac
