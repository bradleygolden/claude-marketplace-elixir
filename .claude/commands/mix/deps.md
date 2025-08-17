---
allowed-tools: [Bash, Read]
argument-hint: "[check|outdated|tree|help]"
description: Main dependency management command with subcommands
---

# Dependency Management

Command: `$ARGUMENTS`

## Available Subcommands

- `check` - Check dependency status
- `outdated` - Show outdated dependencies  
- `tree` - Display dependency tree
- `help` - Show this help message

## Execute Request

! case "$ARGUMENTS" in
  "outdated") mix hex.outdated ;;
  "tree") mix deps.tree ;;
  "check") mix deps ;;
  "help"|"") echo "Use: /mix/deps [check|outdated|tree|help]" && echo "Or use: /mix/deps-upgrade, /mix/deps-add, /mix/deps-remove for modifications" ;;
  *) mix deps ;;
esac

## Related Commands

- `/mix/deps-check` - Comprehensive dependency status check
- `/mix/deps-upgrade [packages]` - Smart upgrade with safety checks and Igniter support
- `/mix/deps-add package[@version]` - Add new dependencies
- `/mix/deps-remove package` - Remove dependencies

Choose the appropriate command based on your needs.
