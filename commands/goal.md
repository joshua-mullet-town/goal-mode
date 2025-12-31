# Goal Mode - Goal Creation

You are about to help the user create a GOAL.md file that will enable autonomous execution. This is a powerful feature that requires careful setup.

## What is Goal Mode?

Goal Mode is a system that allows Claude Code to work autonomously toward a well-defined goal. Once a GOAL.md file is created in the working directory:

1. A stop hook will detect it and prevent the session from ending
2. The agent will be guided through a state machine: PENDING → IMPLEMENTING → VERIFYING → DONE
3. The agent loops automatically until the goal is verified complete or it gets STUCK
4. The user can walk away and return when the goal is achieved

## Why This Matters

The quality of the GOAL.md directly determines whether goal mode succeeds or fails. A vague goal leads to wasted iterations. A goal without testable verification leads to false "done" claims. You must gather enough information to create a bulletproof goal.

## The GOAL.md Anatomy

A valid GOAL.md has these sections:

```
# GOAL: [Short description]

## Status: PENDING
## Max iterations: 10

---

## Objective
[WHAT to accomplish and HOW to do it - specific enough for independent work]

## Verification
[Commands that prove success, with expected outputs]

## Evidence
[Left empty - agent fills during verification]

## Notes
[Agent logs progress here]
```

## Your Task: Gather Information

You must NOT create the GOAL.md until you have complete clarity on:

1. **The Objective**: What exactly needs to be done? What are the specific steps or approach? What constraints exist?

2. **The Verification**: How will we PROVE it works? What exact commands can be run? What exact outputs indicate success?

3. **Max Iterations**: How many attempts should be allowed before giving up?

## Rules for This Conversation

- **DO NOT rush to create the file.** Ask questions until you fully understand.
- **DO NOT create a goal with vague verification.** If you can't define exact commands and expected outputs, the goal isn't ready.
- **DO NOT proceed if the user is unclear.** Push back and ask for specifics.
- **DO ask about edge cases.** What could go wrong? What should the agent do if X happens?
- **DO confirm your understanding** before creating the file by summarizing what you'll write.

## Questions to Consider Asking

Depending on the goal, you might ask:

- "What specific files or systems will this touch?"
- "What command can I run to verify this worked?"
- "What exact output should I expect if it's successful?"
- "Are there any constraints on how this should be implemented?"
- "What should happen if [edge case]?"
- "How many iterations should I allow before marking it stuck?"
- "Is there anything that might block this that I should watch for?"

## When You're Ready

Only after you have gathered sufficient information:

1. Summarize what you understand the goal to be
2. Confirm the verification commands and expected outputs
3. Ask the user: "Does this look correct? Should I create the GOAL.md?"
4. If confirmed, create the GOAL.md file with Status: PENDING
5. Inform the user that goal mode will activate on the next agent response

## Begin

Ask the user what goal they want to accomplish. Be thorough in your questioning. Do not create the GOAL.md until you have extreme confidence in every section.
