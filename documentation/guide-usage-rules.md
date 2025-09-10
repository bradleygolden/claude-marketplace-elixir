# Usage Rules

Usage rules provide best practices and conventions directly from package authors to improve how Claude Code writes code for your project.

> 📋 **Quick Reference**: See the [Usage Rules Cheatsheet](../cheatsheets/usage-rules.cheatmd) for a concise reference of configuration options and patterns.

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
mix usage_rules.sync CLAUDE.md --all --link-to-folder deps --inline phoenix,ash
```

This command:
- Gathers usage rules from all dependencies that provide them
- Creates links to the usage rules files in `deps/` instead of inlining content
- Inlines core rules for selected packages (here Phoenix and Ash) while linking others
- Keeps your root `CLAUDE.md` file lean and reduces context window usage
- Ensures Claude Code always has access to current best practices when needed

Plugins can configure which packages are always inlined. For example, the Phoenix and Ash plugins
embed their core rules directly while keeping other dependency rules referenced.

### In Your CLAUDE.md

After installation, your `CLAUDE.md` will contain links to usage rules instead of full content:

```markdown
## ash usage
_A declarative, extensible framework for building Elixir applications._

[ash usage rules](deps/ash/usage-rules.md)

## phoenix usage
_Productive. Reliable. Fast._

[phoenix usage rules](deps/phoenix/usage-rules.md)

## usage_rules usage
_A dev tool for Elixir projects to gather LLM usage rules from dependencies_

[usage_rules usage rules](deps/usage_rules/usage-rules.md)
```

This keeps the root CLAUDE.md file lean while Claude Code can still access the full usage rules when needed. For core Elixir rules and critical guidelines that are frequently referenced, some packages may still be inlined.

## Nested Memories

Claude supports distributing CLAUDE.md files across different directories in your project for context-specific guidance:

```elixir
%{
  nested_memories: %{
    "lib/my_app_web" => ["phoenix", "ash_phoenix"],
    "lib/my_app/accounts" => ["ash"]
  }
}
```

This creates separate `CLAUDE.md` files in each directory with the relevant usage rules inlined for focused context:
- `lib/my_app_web/CLAUDE.md` - Phoenix and Ash Phoenix integration rules for web code (inlined)
- `lib/my_app/accounts/CLAUDE.md` - Ash framework rules for business logic (inlined)

Benefits of nested memories:
- **Context-aware guidance** - Different rules for different parts of your codebase
- **Inlined for focus** - Nested memory files have rules inlined since they're context-specific
- **Reduced noise** - Claude only sees relevant rules for the current context
- **Better organization** - Keep domain-specific guidance with the code

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

## Benefits

1. **Consistency** - Claude follows the same patterns throughout your codebase
2. **Best Practices** - Automatically uses library author recommendations
3. **Fewer Errors** - Avoids common mistakes and anti-patterns
4. **Better Integration** - Code that works well with your dependencies
5. **Learning** - Usage rules document patterns for your team too

Learn more at [hexdocs.pm/usage_rules](https://hexdocs.pm/usage_rules).

## Examples

### Current Project

This Claude project includes these usage rules which you can see in the [CLAUDE.md](https://github.com/bradleygolden/claude/blob/main/CLAUDE.md) file.

### When More Packages Add Usage Rules

As packages add usage rules, they'll automatically be available. For example:

- If Phoenix adds usage rules, you could use `:phoenix`
- If Ecto adds usage rules, you could use `:ecto`
- If Ash adds usage rules, you could use `:ash`

The usage_rules package ecosystem is growing, and more packages are adding rules over time.

## Troubleshooting

**Usage rules not appearing in CLAUDE.md?**
- Check that `usage_rules` is in your dependencies
- Run `mix claude.install`
- Verify packages have `usage-rules.md` or `usage-rules/` directory

**Sub-agent not following usage rules?**
- Verify the rules are listed in the sub-agent's `usage_rules` field
- Check that the package name matches exactly
- Run `mix claude.install` to regenerate sub-agents

**Need help?**
- 💬 [GitHub Discussions](https://github.com/bradleygolden/claude/discussions)
- 🐛 [Issue Tracker](https://github.com/bradleygolden/claude/issues)

## Learn More

- 📖 [usage_rules Documentation](https://hexdocs.pm/usage_rules) - Full documentation for the usage_rules package
- 🎯 [Creating Usage Rules](https://hexdocs.pm/usage_rules/creating-usage-rules.html) - How to add usage rules to your own packages
- 🔍 [Mix Tasks Reference](https://hexdocs.pm/usage_rules/Mix.Tasks.UsageRules.html) - Available mix tasks for working with usage rules
