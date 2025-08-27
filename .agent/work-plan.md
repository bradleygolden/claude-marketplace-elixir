# Claude 0.6.0 Release Documentation Work Plan

## Current Status
- README.md ✅ Already updated with plugin system features 
- CHANGELOG.md ✅ Already has 0.6.0 section with all key features
- .agent directory ✅ Created for scratchpad

## Key Features to Document (Since 0.5.1)

### Plugin System
- New architecture with Base, ClaudeCode, Phoenix, Webhook, Logging plugins
- Auto-detection capabilities (Phoenix projects get Tidewave)
- Smart configuration merging
- Custom plugin creation

### Reporter System  
- Webhook and JSONL event logging
- `Claude.Hooks.Reporter` behaviour
- Complete observability with all hook events

### SessionEnd Hook
- New hook event for cleanup
- Session end reasons and use cases

### URL Documentation References
- @reference system with caching
- Offline access capabilities

## Files to Review/Update

1. documentation/guide-plugins.md - ✅ Exists, need to review
2. documentation/guide-hooks.md - Need to add SessionEnd + reporters
3. cheatsheets/plugins.cheatmd - ✅ Exists, need to review 
4. mix.exs - Check ExDoc config

## Priority Order
1. Review existing plugin guide
2. Update hooks guide with SessionEnd + reporters  
3. Review plugin cheatsheet
4. Update ExDoc config if needed