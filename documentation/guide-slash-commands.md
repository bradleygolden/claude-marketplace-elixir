# Bundled Slash Commands

Claude provides pre-configured slash commands for common Elixir development tasks. These commands are automatically installed in `.claude/commands/` when you run `mix claude.install`.

## Available Commands

### Claude Management

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/claude:install` | `[--yes] [--with-auto-memories]` | Run claude.install to set up hooks, subagents, MCP servers, and nested memories |
| `/claude:config` | - | Display current Claude configuration from `.claude.exs` |
| `/claude:status` | - | Show installation status and health check |
| `/claude:uninstall` | `[--yes]` | Remove Claude hooks and configuration |

### Dependency Management

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/mix:deps` | - | List project dependencies with status |
| `/mix:deps-add` | `<package> [version]` | Add a new dependency to mix.exs |
| `/mix:deps-upgrade` | `[package]` | Upgrade dependencies (all or specific package) |
| `/mix:deps-check` | - | Check for unused or outdated dependencies |
| `/mix:deps-remove` | `<package>` | Remove dependency from mix.exs |

### Nested Memories Management  

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/memory:nested-add` | `[directory] [usage-rule ...]` or `--auto` | Add nested memory configuration for directories |
| `/memory:nested-list` | - | List current nested memory configuration |
| `/memory:nested-sync` | `[--force]` | Synchronize nested CLAUDE.md files with current configuration |
| `/memory:nested-remove` | `<directory>` | Remove nested memory configuration for a directory |
| `/memory:check` | - | Validate nested memory configuration and files |

### Elixir Development

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/elixir:compatibility` | - | Check Elixir/OTP version compatibility |
| `/elixir:upgrade` | `[version]` | Help upgrade Elixir version |
| `/elixir:version-check` | - | Display current Elixir/OTP versions |

## Usage Examples

### Setting Up a New Project

```
# Install Claude with automatic memory configuration
/claude:install --yes --with-auto-memories

# Check installation status
/claude:status
```

### Managing Dependencies

```
# Add a new dependency
/mix:deps-add jason "~> 1.4"

# Check for unused dependencies
/mix:deps-check

# Upgrade all dependencies
/mix:deps-upgrade
```

### Working with Nested Memories

```
# Auto-configure nested memories for standard directories
/memory:nested-add --auto

# Add specific directory with custom usage rules
/memory:nested-add lib/my_app usage_rules:elixir usage_rules:otp ash

# List current configuration
/memory:nested-list

# Synchronize files after configuration changes
/memory:nested-sync
```

## Command Features

### Smart Auto-Detection
- `/claude:install --with-auto-memories` automatically detects Phoenix projects and configures appropriate MCP servers
- `/memory:nested-add --auto` analyzes your project structure and adds relevant usage rules based on detected dependencies

### Safe Operations
- Commands prompt for confirmation on destructive operations unless `--yes` is provided
- Installation commands show before/after status for verification
- Dependency changes validate mix.exs integrity

### Integration with Claude Code
- Commands use Claude Code's built-in tools (Bash, Read, Edit, etc.)
- Results are formatted for easy understanding
- Commands handle project context automatically

## Accessing Commands

1. **In Claude Code CLI**: Type `/` to see all available commands with auto-completion
2. **View command help**: Most commands show usage when run without required arguments
3. **Command files**: Located in `.claude/commands/` after installation

## Customization

You can modify these commands by editing the files in `.claude/commands/` or create your own following the same format. See the [Slash Commands documentation](https://docs.anthropic.com/en/docs/claude-code/slash-commands) for details on creating custom commands.