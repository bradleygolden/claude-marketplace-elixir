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

If Claude formats the file, it will look like:
```elixir
defmodule UserService do
  def format_user_info(user) do
    "User: #{user.first_name} #{user.last_name} (#{user.email}) - Role: #{user.role}, Department: #{user.department}, Status: #{user.status}"
  end

  def build_response(user, account, preferences) do
    {:ok,
     %{
       user_id: user.id,
       account_id: account.id,
       name: user.name,
       email: user.email,
       preferences: preferences,
       created_at: user.created_at,
       updated_at: user.updated_at
     }}
  end
end
```

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

You'll see feedback like:
```
warning: variable "preferences" does not exist
```

## Step 4: Try Pre-Commit Protection

Ask Claude Code to commit code with issues:

```
Please commit all changes with a descriptive message
```

If there are any formatting issues, compilation errors, or unused dependencies, Claude will:
- 🛑 Block the commit
- 📋 Show what needs fixing
- 🔄 Help resolve issues before committing

## What Just Happened?

You've just experienced Claude's core features:

1. **Format Checking** - Every `.ex` and `.exs` file is checked for proper formatting
2. **Instant Compilation Checks** - Warnings and errors caught immediately
3. **Pre-Commit Validation** - Only clean code gets committed
4. **Intelligent Feedback** - Claude sees and can fix issues automatically

## Next Steps

### Enable More Features

- **[Create Sub-Agents](subagents.md)** - Use `mix claude.gen.subagent` to build specialized AI assistants
- **[Configure Additional Hooks](hooks.md)** - Customize hook behavior and add custom checks
- **Phoenix MCP Server** - Add `mcp_servers: [:tidewave]` to your `.claude.exs` (creates `.mcp.json` automatically)

### Learn More

- 📖 [Full Documentation](https://hexdocs.pm/claude)
- 🎪 [Hooks Reference](hooks.md)
- 🤖 [Sub-Agents Reference](subagents.md)
- 💡 [Usage Rules](https://hexdocs.pm/usage_rules)

## Troubleshooting

**Claude hooks not running?**
- Run `claude --version` to verify Claude Code CLI is installed
- Check `.claude/settings.json` exists
- Try `mix claude.install` to reinstall hooks

**Can't install Igniter?**
- Ensure you're using Elixir 1.18 or later
- Run `mix deps.get` after manual installation

**Need help?**
- 💬 [GitHub Discussions](https://github.com/bradleygolden/claude/discussions)
- 🐛 [Issue Tracker](https://github.com/bradleygolden/claude/issues)

---

**🎉 Congratulations!** You're now using Claude to write better Elixir code, automatically.