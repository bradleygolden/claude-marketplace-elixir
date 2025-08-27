# Claude 0.6.0 Release Documentation Update Plan

## Key Features to Document (Since 0.5.1)
- **Plugin System** - New architecture with Base, ClaudeCode, Phoenix, Webhook, Logging plugins
- **Reporter System** - Webhook and JSONL event logging  
- **SessionEnd Hook** - New hook event for cleanup
- **URL Documentation References** - @reference system with caching

## Work Order
1. ✅ Set up workspace
2. 🔄 Analyze current codebase 
3. Update README.md - Add plugin system features
4. Create CHANGELOG.md - 0.6.0 release section
5. Create documentation/guide-plugins.md - NEW comprehensive guide
6. Update documentation/guide-hooks.md - Add SessionEnd + reporters
7. Create cheatsheets/plugins.cheatmd - NEW quick reference
8. Update other guides and cheatsheets as needed
9. Update mix.exs - ExDoc config

## Status
- Started: 2025-08-27
- Current: Setting up and analyzing codebase