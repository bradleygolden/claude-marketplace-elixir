# ExDoc Plugin

ExDoc documentation validation plugin for Claude Code that ensures documentation quality by checking for issues before commits.

## Overview

This plugin integrates ExDoc's documentation validation into your development workflow by running `mix docs --warnings-as-errors` before git commits. It prevents commits when documentation issues are detected, helping maintain high documentation quality in your Elixir projects.

## Installation

```bash
/plugin marketplace add github:bradleygolden/claude-marketplace-elixir
/plugin install ex_doc@elixir
```

## Features

### Pre-Commit Documentation Validation

Automatically runs before `git commit` commands to validate documentation quality:

- **Undefined reference detection** - Catches references to non-existent modules, functions, types, or callbacks
- **Broken link detection** - Identifies links to missing files in documentation
- **Configuration validation** - Ensures valid ExDoc configuration
- **Asset validation** - Checks image formats and other assets
- **Blocks commits** - Prevents committing code with documentation issues

## How It Works

### PreToolUse Hook (Blocking)

The plugin uses a single PreToolUse hook that:

1. Triggers before `git commit` commands execute
2. Detects if the project uses ExDoc (checks for `{:ex_doc` in `mix.exs`)
3. Runs `mix docs --warnings-as-errors` to validate documentation
4. Blocks the commit (exit code 2) if validation fails
5. Allows the commit (exit code 0) if validation passes

### Why Pre-Commit Only?

Unlike other plugins that provide post-edit feedback, the ExDoc plugin only validates at commit time because:

- **Performance** - `mix docs` regenerates entire documentation (10-30+ seconds), which would slow down every file edit
- **Similar to Dialyzer** - Follows the same pattern as the Dialyzer plugin, which also only runs pre-commit due to analysis time
- **Quality gate** - Ensures documentation quality without interrupting the development workflow
- **Manual checking available** - Developers can run `mix docs` manually anytime for immediate feedback

## Usage

Once installed, the plugin automatically validates documentation before commits:

```bash
# Make changes to your code
# Edit lib/my_module.ex - add functions with @doc

# Attempt to commit
git commit -m "Add new feature"

# If documentation issues found:
# ❌ Commit is BLOCKED
# Error output shows documentation warnings/errors

# Fix the documentation issues
# Edit documentation to resolve issues

# Try commit again
git commit -m "Add new feature"

# If documentation is valid:
# ✅ Commit proceeds normally
```

## Detected Issues

The plugin catches common documentation problems:

### Undefined References

```elixir
@doc """
This function calls `NonExistent.function/1`  # ⚠️ Warning: undefined reference
"""
def my_function do
  # ...
end
```

### Broken File Links

```elixir
@moduledoc """
See [guide](guides/missing.md) for details  # ⚠️ Warning: file doesn't exist
"""
```

### Invalid Configuration

```elixir
# In mix.exs
docs: [
  main: "NonExistentPage"  # ⚠️ Warning: main page not found
]
```

## Configuration

The plugin works with your existing ExDoc configuration in `mix.exs`:

```elixir
def project do
  [
    # ... other config
    docs: [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_url: "https://github.com/user/repo",

      # Optional: Suppress specific warnings
      skip_undefined_reference_warnings_on: [
        "CHANGELOG.md",
        "DeprecatedModule"
      ]
    ]
  ]
end
```

## Requirements

- ExDoc must be in your project dependencies (`{:ex_doc` in `mix.exs`)
- Mix project with `mix.exs` file
- Git repository (validation only runs on `git commit`)
- **Timeout**: 45 seconds (sufficient for most projects; increase if extensive documentation takes longer)

## Disabling the Plugin

If you need to commit without documentation validation temporarily:

```bash
# Uninstall the plugin
/plugin uninstall ex_doc@elixir

# Or use git commit --no-verify (bypasses all pre-commit hooks)
git commit --no-verify -m "WIP: Fix coming in next commit"
```

## Comparison with Other Plugins

| Plugin | Validation Type | When It Runs | Performance Impact |
|--------|----------------|--------------|-------------------|
| **Core** | Format/Compile | Post-edit + Pre-commit | Low (fast) |
| **Credo** | Code Quality | Post-edit + Pre-commit | Low-Medium |
| **Ash** | Codegen | Post-edit + Pre-commit | Medium |
| **Dialyzer** | Type Analysis | Pre-commit only | High (slow) |
| **ExDoc** | Documentation | Pre-commit only | Medium-High (slow) |
| **Sobelow** | Security | Post-edit + Pre-commit | Medium |

## Troubleshooting

### Commit Blocked with Documentation Warnings

**Solution**: Fix the documentation issues shown in the error output, then commit again.

### ExDoc Not Found

**Error**: Hook exits silently, commit proceeds without validation

**Solution**: Add ExDoc to your dependencies:

```elixir
defp deps do
  [
    {:ex_doc, "~> 0.34", only: :dev, runtime: false}
  ]
end
```

Then run: `mix deps.get`

### Timeout Errors

**Error**: Hook times out after 45 seconds

**Solution**:
- Your documentation generation is taking too long
- Consider optimizing your docs configuration
- You may need to commit without validation using `git commit --no-verify`

### Want Immediate Feedback?

**Solution**: Run `mix docs --warnings-as-errors` manually during development:

```bash
# Check documentation while working
mix docs --warnings-as-errors

# Or watch for changes (requires file watcher)
mix test.watch --only docs
```

## Contributing

Issues and pull requests welcome at https://github.com/bradleygolden/claude-marketplace-elixir

## License

MIT License - see repository LICENSE file
