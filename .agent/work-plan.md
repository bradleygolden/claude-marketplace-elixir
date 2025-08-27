# Claude 0.6.0 Documentation Update Work Plan

## Status: In Progress

## Key Features to Document (Since 0.5.1)

✅ **Plugin System** - Already well documented in README
- Base, ClaudeCode, Phoenix, Webhook, Logging plugins
- Auto-detection capabilities
- Smart merging

✅ **Reporter System** - Already well documented in README and CHANGELOG  
- Webhook and JSONL event logging
- Custom reporter behavior
- Event registration

✅ **SessionEnd Hook** - Already documented in README and CHANGELOG
- New hook event for cleanup
- Session end reasons

✅ **URL Documentation References** - Already documented in README and CHANGELOG
- @reference system with caching
- Local caching for offline access

## Analysis of Current State

### README.md - ✅ COMPLETE
- Already includes comprehensive 0.6.0 features
- Plugin system well documented (lines 56-64)
- Smart hooks section updated (lines 66-74)
- Roadmap section shows 0.6.0 as "Recently Added" (lines 203-221)

### CHANGELOG.md - ✅ COMPLETE  
- Has comprehensive 0.6.0 entry (lines 10-42)
- All major features documented with details
- Breaking changes and improvements noted

## Tasks Remaining

1. ✅ README.md - Already complete 
2. ✅ CHANGELOG.md - Already complete
3. ❓ Check documentation/guide-plugins.md - May need updates
4. ❓ Check documentation/guide-hooks.md - May need SessionEnd + reporters
5. ❓ Check cheatsheets/plugins.cheatmd - May need updates
6. ❓ Check mix.exs ExDoc config - May need updates
7. ❓ Verify all guides are up to date

## Next Steps
- Examine existing documentation files to see what needs updates
- Focus on guides and cheatsheets vs README which looks complete