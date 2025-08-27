# 0.6.0 Release Documentation Plan

## Key Features to Document
Based on code review and CHANGELOG.md, these are the major new features:

### 1. Plugin System
- **Base Plugin**: Standard hooks with shortcuts (`:compile`, `:format`, `:unused_deps`)
- **ClaudeCode Plugin**: Comprehensive documentation and Meta Agent
- **Phoenix Plugin**: Auto-detects Phoenix projects, configures Tidewave MCP
- **Webhook Plugin**: Event reporting to HTTP endpoints  
- **Logging Plugin**: Structured event logging to files
- Configuration merging, plugin loading mechanism

### 2. Reporter System
- `Claude.Hooks.Reporter` behaviour for custom reporters
- Built-in webhook and JSONL reporters
- Event dispatching infrastructure
- Integration with hook system for monitoring

### 3. SessionEnd Hook Event
- New hook event that runs when Claude Code sessions end
- Use cases: cleanup, logging stats, saving state
- Same configuration patterns as other hooks

### 4. URL Documentation References
- `@reference` system with local caching
- URL-based docs that cache for offline access
- Nested memory integration
- Performance improvements with cached files

## Files to Update

### Priority 1 - Core User-Facing Docs
1. **README.md** - Add plugin system highlights
2. **CHANGELOG.md** - Already complete ✓
3. **documentation/guide-plugins.md** - NEW comprehensive guide
4. **documentation/guide-hooks.md** - Add SessionEnd + reporters
5. **cheatsheets/plugins.cheatmd** - NEW quick reference

### Priority 2 - Supporting Docs  
6. Other guides as needed (quickstart, subagents, etc.)
7. mix.exs - ExDoc config already updated ✓

## Current State Analysis
- CHANGELOG.md: Complete with 0.6.0 section ✓
- mix.exs: Version set to 0.6.0, ExDoc config includes new files ✓
- Plugin files: All implemented with good docstrings
- Existing guides need review for updates
- Missing: comprehensive plugin guide, plugin cheatsheet