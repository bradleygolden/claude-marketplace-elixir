# Claude 0.6.0 Release Documentation Work Plan

## Key Features Added Since 0.5.1
- **Plugin System** - New architecture with Base, ClaudeCode, Phoenix, Webhook, Logging plugins
- **Reporter System** - Webhook and JSONL event logging  
- **SessionEnd Hook** - New hook event for cleanup
- **URL Documentation References** - @reference system with caching

## Work Order
1. ✅ Set up .agent directory as scratchpad
2. [ ] Update README.md with plugin system features
3. [ ] Create CHANGELOG.md 0.6.0 release section
4. [ ] Create comprehensive documentation/guide-plugins.md
5. [ ] Update documentation/guide-hooks.md with SessionEnd + reporters
6. [ ] Create cheatsheets/plugins.cheatmd quick reference
7. [ ] Review and update other guides and cheatsheets as needed
8. [ ] Update mix.exs ExDoc config if needed

## Notes
- Need to explore the codebase to understand the new plugin architecture
- Must commit and push after every file edit
- Document any bugs or issues in .agent/noted-issues.md
✅ README.md already updated with 0.6.0 features including:
- Plugin system with Base, ClaudeCode, Phoenix, Webhook, Logging plugins
- Reporter system for webhook and JSONL event logging
- SessionEnd hook event
- URL documentation references

No additional updates needed to README.md.
