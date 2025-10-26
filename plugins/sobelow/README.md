# Sobelow Security Analysis Plugin

Security-focused static analysis for Phoenix and Elixir projects using [Sobelow](https://github.com/nccgroup/sobelow).

## Overview

This plugin integrates Sobelow security scanning into your Claude Code workflow, providing automated security analysis for Phoenix and Elixir applications. Sobelow identifies potential security vulnerabilities including XSS, SQL injection, command injection, insecure configuration, and more.

## Features

- **Post-edit security scanning**: Automatically analyzes files after edits to identify security issues
- **Pre-commit validation**: Blocks commits that introduce medium or high confidence security vulnerabilities
- **Skip file support**: Respects `.sobelow-skips` file for managing false positives
- **Inline comment support**: Honors `# sobelow_skip` comments for function-level suppressions
- **Intelligent filtering**: Only runs on Elixir projects with Sobelow dependency
- **Confidence-based blocking**: Blocks commits on medium and high confidence findings, allowing low confidence issues to pass

## Installation

```bash
/plugin marketplace add github:bradleygolden/claude-marketplace-elixir
/plugin install sobelow@elixir
```

## Requirements

Your Elixir project must have Sobelow as a dependency:

```elixir
# mix.exs
def deps do
  [
    {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false}
  ]
end
```

Then run:
```bash
mix deps.get
```

## How It Works

### Post-Edit Security Scan

After editing `.ex` or `.exs` files, the plugin automatically:

1. Detects the Mix project root
2. Checks if Sobelow is a project dependency
3. Runs `mix sobelow --format json --skip` (respects your skip configuration)
4. Provides security findings to Claude as context
5. Suggests fixes or skip options for false positives

### Pre-Commit Validation

Before `git commit` commands, the plugin:

1. Runs `mix sobelow --skip` (respects your skip configuration)
2. Blocks the commit if **any** security findings are reported
3. Users control what gets reported via `.sobelow-conf` (threshold, ignore types, etc.)
4. Provides clear guidance on fixing or suppressing findings

**Default behavior**: Blocks on any findings. Use `.sobelow-conf` to customize (e.g., `--threshold medium` to only report medium/high confidence issues).

## Managing False Positives

Sobelow provides multiple ways to handle false positives:

### 1. Inline Comments (Function-level)

Add a comment before the function:

```elixir
# sobelow_skip ["SQL.Query", "XSS.Raw"]
def safe_function(params) do
  # Actually safe code that Sobelow flags
end
```

### 2. Mark All Current Findings

```bash
# In your project directory
mix sobelow --mark-skip-all
```

This adds all current findings to `.sobelow-skips` file as MD5 hashes.

### 3. Selective Marking (Recommended)

When you have mixed results (some real issues, some false positives):

```bash
# Mark only specific types as false positives
# Ignore the REAL issues first, then mark the rest
mix sobelow --ignore XSS.Raw,Config.HTTPS --mark-skip-all
```

This workflow:
1. Shows all findings
2. Ignores the real issues you want to fix (XSS.Raw, Config.HTTPS)
3. Marks only the remaining findings (false positives) in `.sobelow-skips`
4. Next run with `--skip` will only show the real issues

### 4. Configuration File

Create `.sobelow-conf` for persistent options:

```bash
mix sobelow --exit Low --verbose --save-config
```

The plugin automatically picks up this configuration. CLI options override config file settings.

## Understanding Skip Behavior

The plugin **always runs with `--skip`** to respect your skip decisions:

- **Inline comments** (`# sobelow_skip`): Automatically honored
- **Skip file** (`.sobelow-skips`): Automatically used if present
- **Configuration** (`.sobelow-conf`): Automatically loaded

This ensures you only see **new or unfixed** security findings, not known false positives.

## Workflow Example

```bash
# 1. Edit a file - Sobelow runs and finds issues
# Claude shows: "Sobelow found SQL.Query and XSS.Raw issues"

# 2. Review findings
# - SQL.Query: False positive (using parameterized query correctly)
# - XSS.Raw: Real issue (needs fixing)

# 3. Mark the false positive
mix sobelow --ignore XSS.Raw --mark-skip-all

# 4. Fix the real issue with Claude's help
# Claude helps refactor the XSS.Raw vulnerability

# 5. Commit - pre-commit hook runs
git commit -m "fix: resolve XSS vulnerability"
# ✅ Passes (SQL.Query skipped, XSS.Raw fixed)
```

## Hook Configuration

### PostToolUse Hook
- **Trigger**: After Edit, Write, or MultiEdit tools
- **Timeout**: 30 seconds
- **Behavior**: Non-blocking (always allows the edit)
- **Output**: Provides findings as `additionalContext` to Claude

### PreToolUse Hook
- **Trigger**: Before Bash tool (git commit commands)
- **Timeout**: 30 seconds
- **Behavior**: Blocking (JSON permissionDecision: "deny" prevents commit)
- **Threshold**: Medium and High confidence findings

## Customization

### Adjust Exit Threshold

Edit your `.sobelow-conf` or run:

```bash
# Block only on high confidence findings
mix sobelow --exit High --save-config

# Block on all findings (including low confidence)
mix sobelow --exit Low --save-config
```

### Ignore Specific Finding Types

```bash
# Permanently ignore certain types
mix sobelow --ignore Config.HTTPS,Traversal --save-config
```

### Verbose Output

```bash
# Show code snippets in findings
mix sobelow --verbose --save-config
```

## Troubleshooting

### Hook doesn't run

**Check if Sobelow is in dependencies**:
```bash
grep sobelow mix.exs
```

If missing, add it:
```elixir
{:sobelow, "~> 0.14", only: [:dev, :test], runtime: false}
```

### Too many false positives

Use the selective marking workflow:
```bash
# Review findings, then mark specific types as skips
mix sobelow --ignore RealIssue1,RealIssue2 --mark-skip-all
```

### Want to re-scan previously skipped findings

```bash
# Clear all skips
mix sobelow --clear-skip

# Or manually delete the skip file
rm .sobelow-skips
```

### Pre-commit blocking on low confidence findings

The plugin uses `--exit Medium` by default. To adjust:

```bash
# Only block on high confidence
mix sobelow --exit High --save-config
```

Or edit the pre-commit script at `plugins/sobelow/scripts/pre-commit-check.sh`.

## Security Best Practices

1. **Fix real issues first**: Don't skip findings without review
2. **Use selective marking**: `--ignore Real1,Real2 --mark-skip-all` prevents hiding real issues
3. **Regular re-scans**: Periodically run `mix sobelow --clear-skip` to verify old skips
4. **Code review**: Have security findings reviewed by team members
5. **CI/CD integration**: Consider running Sobelow in CI with `--exit High`

## Learn More

- [Sobelow Documentation](https://hexdocs.pm/sobelow/)
- [Sobelow GitHub](https://github.com/nccgroup/sobelow)
- [Phoenix Security Guide](https://hexdocs.pm/phoenix/security.html)

## License

MIT
