# 0.6.0 Release Documentation Work Plan

## Features to Document (Since 0.5.1)

### ✅ Already Documented in README.md
- Plugin system overview
- Auto-detection capabilities  
- Built-in plugins
- Event reporting system
- SessionEnd hook
- URL documentation references with caching

### 🔄 Tasks Remaining
1. Update README.md with any missing details
2. Create CHANGELOG.md 0.6.0 release section
3. Verify/update comprehensive plugin guide (documentation/guide-plugins.md)
4. Update hooks guide with SessionEnd + reporters (documentation/guide-hooks.md)
5. Verify plugins cheat sheet (cheatsheets/plugins.cheatmd)
6. Update other guides and cheatsheets as needed
7. Update mix.exs ExDoc config

## Key Plugin System Components

### Plugins
- `Claude.Plugins.Base` - Standard hooks (:compile, :format, :unused_deps)
- `Claude.Plugins.ClaudeCode` - Documentation, Meta Agent subagent
- `Claude.Plugins.Phoenix` - Auto-detection, Tidewave MCP, nested memories
- `Claude.Plugins.Webhook` - Event reporting to webhook endpoints
- `Claude.Plugins.Logging` - JSONL file logging

### Reporter System
- `Claude.Hooks.Reporter` behavior
- `Claude.Hooks.Reporters.Webhook` - HTTP webhook delivery
- `Claude.Hooks.Reporters.Jsonl` - File-based JSONL logging
- Automatic dispatch to configured reporters
- Error handling and logging

### SessionEnd Hook
- New hook event for cleanup tasks
- Runs when Claude sessions end
- Useful for cleanup, logging session stats, saving state

### URL Documentation References  
- `@reference` system with caching
- Local cache files for offline access
- Integration with nested memories