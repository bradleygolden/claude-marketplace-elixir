# Quickstart

**Make Claude Code write production-ready Elixir, automatically.**

This guide gets you from zero to format-checking, error-detecting Elixir code quickly.

## What You'll Build

In this quickstart, you'll:
1. Watch Claude Code detect formatting issues in code with long lines
2. See compilation errors caught in real-time
3. Experience the productivity boost firsthand

## Prerequisites

- Elixir 1.18+ installed
- Claude Code CLI installed ([install guide](https://docs.anthropic.com/en/docs/claude-code/quickstart))
- An Elixir project

## Step 1: Install Claude

Run this single command:

```bash
mix igniter.install claude
```

When prompted:
- Press `Y` to install Igniter (if not already installed)
- Press `Y` to apply all changes

This automatically:
- ✅ Adds Claude to your dependencies
- ✅ Creates `.claude.exs` configuration
- ✅ Installs formatting and compilation hooks
- ✅ Sets up `.claude/` directory structure
- ✅ Installs bundled slash commands in `.claude/commands/`
- ✅ Syncs usage rules from dependencies to `CLAUDE.md`

## Step 2: Test Format Checking

Ask Claude Code to create a file with long lines:

```
Please create a file called lib/user_service.ex with this exact content:

defmodule UserService do
  def format_user_info(user) do
    "User: #{user.first_name} #{user.last_name} (#{user.email}) - Role: #{user.role}, Department: #{user.department}, Status: #{user.status}"
  end

  def build_response(user, account, preferences) do
    {:ok, %{user_id: user.id, account_id: account.id, name: user.name, email: user.email, preferences: preferences, created_at: user.created_at, updated_at: user.updated_at}}
  end
end
```

**Watch the feedback!** Claude will create the file, and immediately:
- 🎨 Format checking runs
- ⚠️ Claude is alerted that the file needs formatting (lines too long)
- 🔧 Claude can run `mix format` to fix it

## Step 3: Experience Compilation Checking

Ask Claude Code to introduce a warning:

```
Please edit lib/user_service.ex and rename the 'preferences' parameter to '_preferences'
in the build_response function (but still use 'preferences' in the function body)
```

**Watch what happens:**
- ⚠️ Compilation warning detected immediately
- 🔍 Warning details shown to Claude
- 🔧 Claude can fix it automatically

## Step 4: Try Pre-Commit Protection

Ask Claude Code to commit code with issues:

```
Please commit all changes with a descriptive message
```

If there are any formatting issues, compilation errors, or unused dependencies, Claude will:
- 🛑 Block the commit
- 📋 Show what needs fixing
- 🔄 Help resolve issues before committing

## Step 5: Try Slash Commands

Claude comes with bundled slash commands for common tasks. Type `/` in Claude Code to see all available commands, or try:

```
/mix:deps-check
```

This will check your dependency status using the bundled command. Other useful commands include:
- `/claude:status` - Check Claude installation status
- `/mix:deps-add` - Add new dependencies
- `/memory:nested-add` - Configure nested memories for directories

## What Just Happened?

You've just experienced Claude's core features:

1. **Format Checking** - Every `.ex` and `.exs` file is checked for proper formatting
2. **Instant Compilation Checks** - Warnings and errors caught immediately
3. **Pre-Commit Validation** - Only clean code gets committed
4. **Intelligent Feedback** - Claude sees and can fix issues automatically
5. **Bundled Commands** - Pre-configured slash commands for common tasks
6. **Best Practices** - Claude follows usage rules from your dependencies (see [Usage Rules Guide](guide-usage-rules.md))

## Next Steps

### Enable More Features

- **[Configure Additional Hooks](guide-hooks.md)** - Customize hook behavior and add custom checks
- **[Setup MCP Servers](guide-mcp.md)** - Configure Tidewave for Phoenix development (auto-configured for Phoenix projects)

## Troubleshooting

**Claude hooks not running?**
- Run `claude --version` to verify Claude Code CLI is installed
- Check `.claude/settings.json` exists
- Try `mix claude.install` to reinstall hooks

**Need help?**
- 💬 [GitHub Discussions](https://github.com/bradleygolden/claude/discussions)
- 🐛 [Issue Tracker](https://github.com/bradleygolden/claude/issues)

### Learn More

- 📖 [Overview](../README.md)
- 🎪 [Hooks Reference](guide-hooks.md)
- 💡 [Usage Rules Guide](guide-usage-rules.md)

---

**🎉 Congratulations!** You're now using Claude to write better Elixir code, automatically.
