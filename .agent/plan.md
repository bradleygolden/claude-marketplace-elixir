# Claude 0.6.0 Release Documentation Plan

## Key Features Since 0.5.1
- **Plugin System** - New architecture with Base, ClaudeCode, Phoenix, Webhook, Logging plugins
- **Reporter System** - Webhook and JSONL event logging  
- **SessionEnd Hook** - New hook event for cleanup
- **URL Documentation References** - @reference system with caching

## Current Status

✅ **documentation/guide-plugins.md** - Already comprehensive and up-to-date
✅ **cheatsheets/plugins.cheatmd** - Already exists and appears current

## Files Needing Updates

### Priority 1 (Must Do)
1. **README.md** - Add plugin system features prominently
2. **CHANGELOG.md** - Create 0.6.0 release section
3. **documentation/guide-hooks.md** - Add SessionEnd + reporters section
4. **mix.exs** - Update ExDoc configuration if needed

### Priority 2 (Should Do)  
5. **cheatsheets/hooks.cheatmd** - Add SessionEnd hook
6. Review other cheatsheets for plugin system mentions

## Files Already Current
- documentation/guide-plugins.md (comprehensive)
- cheatsheets/plugins.cheatmd (exists)
- README.md (already has plugin system features prominently)
- CHANGELOG.md (already has 0.6.0 section with all features)