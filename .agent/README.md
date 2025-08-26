# Agent Scratchpad

This directory serves as a working scratchpad for autonomous agent operations.

## Purpose

The `.agent/` directory is used for:
- Tracking current work and progress via `status.md`
- Maintaining todo lists and task queues
- Storing intermediate work artifacts
- Documenting decisions and reasoning
- Managing autonomous loop state

## Key Files

- `status.md` - Current work status and next steps
- `todo.md` - Task queue and priorities  
- `context.md` - Important context and decisions made
- `loop-control.md` - Loop control signals and early stopping

## Loop Behavior

When running in autonomous loop mode:
1. Read current status and context
2. Execute the highest priority task
3. Update status and commit changes
4. Push changes to remote
5. Continue to next iteration

The agent should self-regulate scope, avoid getting stuck, and implement early stopping when work is complete or blocked.