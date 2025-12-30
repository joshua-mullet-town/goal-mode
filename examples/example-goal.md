# GOAL: Add a greeting function to utils.js

## Status: PENDING
## Iteration: 0
## Max iterations: 5

---

## Objective

Create a simple greeting function in utils.js that takes a name and returns a greeting string. This is a test goal to verify autopilot is working.

## Success Criteria

- [ ] File `utils.js` exists
- [ ] Function `greet(name)` exists and is exported
- [ ] `greet("World")` returns `"Hello, World!"`
- [ ] Running `node -e "console.log(require('./utils').greet('Test'))"` outputs `Hello, Test!`

## Test Steps

1. Check that utils.js exists
2. Run: `node -e "console.log(require('./utils').greet('Autopilot'))"`
3. Verify output is exactly: `Hello, Autopilot!`

## Reset Steps

1. Delete utils.js if it exists: `rm -f utils.js`

## Notes

[Claude Code will write here as it works]

---

## Escape Conditions

- Max iterations: 5
- If stuck with no path forward, set Status to STUCK
- If all success criteria met, set Status to DONE
