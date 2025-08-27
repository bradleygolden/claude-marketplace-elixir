# Claude 0.6.0 Release Documentation Plan

## Key New Features to Document

### 1. Plugin System (MAJOR)
- **Base Plugin** - Standard hook configuration via `Claude.Plugins.Base`
- **ClaudeCode Plugin** - Documentation and memories for Claude Code features
- **Phoenix Plugin** - Auto-detection and configuration for Phoenix projects with Tidewave
- **Webhook Plugin** - Event reporting via webhooks
- **Logging Plugin** - Structured event logging to files
- **Plugin Behavior** - Extensible system for custom plugins

### 2. Reporter System (NEW)
- **Webhook Reporter** - HTTP endpoint event reporting
- **JSONL Reporter** - File-based event logging
- **Reporter Behavior** - Create custom reporters
- **Configuration** - Via `.claude.exs` reporters section

### 3. SessionEnd Hook Event (NEW)
- **New Hook Event** - Runs when Claude session ends
- **Use Cases** - Cleanup, logging, session statistics
- **Configuration** - Like other hook events

### 4. URL Documentation References (NEW)
- **@reference System** - URL-based documentation with local caching
- **Caching** - Auto-cache to local files for offline access
- **Nested Memories** - URL references in nested memory configurations

## Work Order

1. **README.md** - Add plugin system overview
2. **CHANGELOG.md** - Create 0.6.0 section with all new features
3. **documentation/guide-plugins.md** - NEW comprehensive plugin guide
4. **documentation/guide-hooks.md** - Add SessionEnd + reporter integration
5. **cheatsheets/plugins.cheatmd** - NEW quick reference for plugins
6. **Other guides** - Update as needed for plugin integration
7. **mix.exs** - Update ExDoc config for new modules

## Current State Analysis

### Already in Unreleased Section
- @reference system with URL caching ✓
- Plugin system for extending .claude.exs ✓ 
- Register all hook events when reporters configured ✓
- Webhook reporters fix ✓
- Stop hooks exit code 0 fix ✓

### Missing from Documentation
- Plugin system architecture and usage
- Individual plugin documentation
- Reporter system usage
- SessionEnd hook event
- URL reference system usage

## Implementation Notes

- Follow existing documentation patterns
- Use proper headings and structure  
- Include code examples
- Reference official Claude Code docs
- Keep cheatsheets concise
- Update all cross-references