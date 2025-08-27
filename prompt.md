# Claude 0.6.0 Release Documentation Update

Your job is to prepare this project for the next release, 0.6.0. You have access to this worktree, which is a branch off the main branch.

## Instructions

- Make a commit and push your changes after every single file edit
- Use the .agent directory as a scratchpad for your work  
- Store long-term plans and to-do lists there
- Continue until you have updated all user-facing documentation on ExDoc
- Prioritize: guides, cheat sheets, quickstarts, README.md over module documentation
- If you come across bugs or issues worth noting, document them in .agent/noted-issues.md
- If bugs cause issues, work around them but document the problems

## Key Features to Document (Since 0.5.1)

- **Plugin System** - New architecture with Base, ClaudeCode, Phoenix, Webhook, Logging plugins
- **Reporter System** - Webhook and JSONL event logging  
- **SessionEnd Hook** - New hook event for cleanup
- **URL Documentation References** - @reference system with caching

## Work Order

1. README.md - Add plugin system features
2. CHANGELOG.md - Create 0.6.0 release section
3. documentation/guide-plugins.md - NEW comprehensive guide
4. documentation/guide-hooks.md - Add SessionEnd + reporters
5. cheatsheets/plugins.cheatmd - NEW quick reference
6. Other guides and cheatsheets as needed
7. mix.exs - Update ExDoc config