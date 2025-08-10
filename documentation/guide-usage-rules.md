# Usage Rules

Usage rules provide best practices and conventions directly from package authors to improve how Claude Code writes code for your project.

## What are Usage Rules?

Usage rules are markdown files containing library-specific guidelines, patterns, and best practices that help AI assistants write better code. When Claude installs in your project, it automatically:

1. Adds the `usage_rules` dependency (dev only)
2. Syncs all available usage rules to your `CLAUDE.md` file
3. Makes these rules available to sub-agents

This ensures Claude Code follows the exact patterns and conventions that library authors recommend.

## How Claude Uses Usage Rules

### Automatic Syncing

When you run `mix claude.install`, Claude automatically runs:

```bash
mix usage_rules.sync CLAUDE.md --all --inline usage_rules:all --link-to-folder deps
```

This command:
- Gathers usage rules from all dependencies that provide them
- Adds them inline to your `CLAUDE.md` file
- Creates links to the source files in `deps/`
- Ensures Claude Code always has access to current best practices

### In Your CLAUDE.md

After installation, your `CLAUDE.md` will contain sections like:

```markdown
## ash usage
_A declarative, extensible framework for building Elixir applications._

[ash usage rules](deps/ash/usage-rules.md)

## phoenix usage  
_Productive. Reliable. Fast._

[phoenix usage rules](deps/phoenix/usage-rules.md)

## usage_rules:elixir usage
# Elixir Core Usage Rules

## Pattern Matching
- Use pattern matching over conditional logic when possible
- Prefer to match on function heads instead of using `if`/`else`
...
```

Claude Code reads this file at the start of every session, ensuring it follows these guidelines.

## Usage Rules in Sub-Agents

Sub-agents can include specific usage rules to ensure they follow library best practices:

```elixir
%{
  subagents: [
    %{
      name: "Code Generation Expert",
      description: "Expert in code generation and project setup",
      prompt: "You are a code generation expert...",
      tools: [:read, :write, :edit],
      usage_rules: [:igniter, :usage_rules_elixir]
    }
  ]
}
```

### Available Usage Rules

Common usage rules that can be included:

- **`:usage_rules_elixir`** - Elixir language best practices
- **`:usage_rules_otp`** - OTP patterns and conventions
- **Package-specific** - Any package that provides usage rules (`:igniter`, or others when available)

### Loading Patterns

Usage rules can be loaded in different ways:

- **`:package_name`** - Loads the main usage rules file (`deps/package_name/usage-rules.md`)
- **`"package_name:all"`** - Loads all usage rules from a package (`deps/package_name/usage-rules/`)
- **`"package_name:specific_rule"`** - Loads a specific rule file (`deps/package_name/usage-rules/specific_rule.md`)

## Creating Your Own Usage Rules

You can add project-specific usage rules by creating markdown files in your project:

1. **Create `usage-rules.md`** in your project root for general rules
2. **Create `usage-rules/` directory** for multiple rule files
3. These will be included when other projects depend on yours

Example `usage-rules.md`:

```markdown
# MyProject Usage Rules

## API Conventions
- Always use `{:ok, result}` or `{:error, reason}` tuples
- Validate input at the edge with Ecto changesets
- Use context modules for business logic

## Testing Patterns  
- Test behavior, not implementation
- Use factories for test data
- Mock external services at the boundary
```

## Checking Available Usage Rules

To see what usage rules are available in your project:

```bash
# List all available usage rules in dependencies
mix usage_rules.sync --list

# Search for specific patterns in documentation
mix usage_rules.search_docs "pattern matching"

# View documentation for a specific module or function
mix usage_rules.docs Enum
mix usage_rules.docs Enum.zip
```

## Benefits

1. **Consistency** - Claude follows the same patterns throughout your codebase
2. **Best Practices** - Automatically uses library author recommendations
3. **Fewer Errors** - Avoids common mistakes and anti-patterns
4. **Better Integration** - Code that works well with your dependencies
5. **Learning** - Usage rules document patterns for your team too

## The usage_rules Package

Claude integrates with the [usage_rules](https://hexdocs.pm/usage_rules) package, which:

- Aggregates best practices from Elixir packages
- Provides mix tasks for managing and searching rules
- Enables AI assistants to write idiomatic Elixir code
- Maintains a growing collection of community-contributed rules

Learn more at [hexdocs.pm/usage_rules](https://hexdocs.pm/usage_rules).

## Examples

### Current Project

This Claude project includes these usage rules:

- `:usage_rules` - The main usage_rules package documentation
- `:usage_rules_elixir` or `"usage_rules:elixir"` - Core Elixir language patterns
- `:usage_rules_otp` or `"usage_rules:otp"` - OTP patterns and conventions  
- `:igniter` - Code generation and project patching patterns

### When More Packages Add Usage Rules

As packages add usage rules, they'll automatically be available. For example:

- If Phoenix adds usage rules, you could use `:phoenix`
- If Ecto adds usage rules, you could use `:ecto`
- If Ash adds usage rules, you could use `:ash`

The usage_rules package ecosystem is growing, and more packages are adding rules over time.

## Troubleshooting

**Usage rules not appearing in CLAUDE.md?**
- Run `mix usage_rules.sync CLAUDE.md --all`
- Check that `usage_rules` is in your dependencies
- Verify packages have `usage-rules.md` or `usage-rules/` directory

**Sub-agent not following usage rules?**
- Verify the rules are listed in the sub-agent's `usage_rules` field
- Check that the package name matches exactly
- Run `mix claude.install` to regenerate sub-agents

**Need help?**
- 💬 [GitHub Discussions](https://github.com/bradleygolden/claude/discussions)
- 🐛 [Issue Tracker](https://github.com/bradleygolden/claude/issues)
- 📖 [usage_rules Documentation](https://hexdocs.pm/usage_rules)