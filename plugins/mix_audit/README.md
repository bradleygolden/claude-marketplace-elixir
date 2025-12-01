# mix_audit

Dependency security audit plugin for Claude Code that scans Mix dependencies for known vulnerabilities before commits.

## Overview

The mix_audit plugin integrates the [mix_audit](https://hex.pm/packages/mix_audit) Elixir dependency security scanner into Claude Code workflows. It automatically scans your project's dependencies against a database of known security vulnerabilities and blocks commits if vulnerable dependencies are detected.

## Features

- **Pre-commit validation**: Automatically runs `mix deps.audit` before git commits
- **Blocking behavior**: Prevents commits containing vulnerable dependencies
- **Automatic detection**: Only runs if `mix_audit` is in your project dependencies
- **Clear feedback**: Provides detailed vulnerability information with truncated output for readability
- **Zero configuration**: Works out of the box once installed

## Requirements

- Elixir installed and available in PATH
- Mix available (included with Elixir)
- Git for version control
- An Elixir project with `mix.exs` file
- mix_audit package installed in your project (see Installation below)

## Installation

### 1. Add mix_audit to your Elixir project

```elixir
# mix.exs
def deps do
  [
    {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false}
  ]
end
```

Then run:
```bash
mix deps.get
```

### 2. Install the Claude Code plugin

```bash
/plugin marketplace add github:bradleygolden/claude-marketplace-elixir
/plugin install mix_audit@elixir
```

## How It Works

### Pre-Commit Hook

When you or Claude attempt to create a git commit, the plugin:

1. Detects if the command is `git commit`
2. Finds the Mix project root
3. Checks if `mix_audit` is in dependencies
4. Runs `mix deps.audit` in the project root
5. **Blocks the commit** if vulnerabilities are found (via JSON permissionDecision: "deny")
6. Provides vulnerability details to Claude for context

**Note**: Skips if project has a `precommit` alias (defers to precommit plugin)

### Example Output

When vulnerabilities are detected:

```
Pass: project depends on safe version of phoenix
Fail: project depends on unsafe version of plug (1.10.0)

Known affected package: plug (1.10.0)
Vulnerability: Arbitrary Code Execution in Plug.Static
Patched versions: >= 1.10.4
CVE: CVE-2021-32...
```

The commit is blocked until you update the vulnerable dependency.

## What is mix_audit?

mix_audit is an Elixir security vulnerability scanner that:

- Scans `mix.lock` against the GitHub Advisory Database
- Identifies packages with known security vulnerabilities
- Works offline (no API keys required)
- Syncs with security advisories every 6 hours
- Complements `mix hex.audit` (which checks for retired packages)

Similar to:
- `npm audit` for Node.js
- `bundler-audit` for Ruby
- `cargo audit` for Rust

## Configuration

### Ignoring Vulnerabilities

If you need to temporarily ignore specific vulnerabilities, use mix_audit's ignore flags:

```bash
# In your project
mix deps.audit --ignore-advisory-ids=uuid-1,uuid-2
```

For permanent ignores, create a `.audit.exs` ignore file:

```bash
mix deps.audit --ignore-file=.audit.exs
```

See [mix_audit documentation](https://hexdocs.pm/mix_audit/) for details.

### Hook Timeout

The pre-commit hook has a 30-second timeout (configurable in `hooks/hooks.json`). This is typically sufficient for dependency audits.

## Complementary Plugins

Consider installing these related security plugins:

- **sobelow@elixir**: Scans Phoenix and Elixir code for security vulnerabilities
- **dialyzer@elixir**: Static type analysis to catch type errors
- **credo@elixir**: Code quality and consistency analysis

Together, these provide comprehensive security and quality coverage.

## Troubleshooting

### Plugin doesn't run

**Cause**: `mix_audit` is not in your project dependencies

**Solution**: Add `{:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false}` to `mix.exs`

### False positives

**Cause**: Advisory applies to usage you don't have

**Solution**: Use `--ignore-advisory-ids` or create `.audit.exs` ignore file

### Slow audits

**Cause**: First run fetches the advisory database

**Solution**: Subsequent runs are faster (database is cached locally)

## Running Manually

To audit dependencies without committing:

```bash
# In your project root
mix deps.audit

# With JSON output
mix deps.audit --format json

# Check specific path
mix deps.audit --path=/path/to/project
```

## Resources

- **mix_audit package**: https://hex.pm/packages/mix_audit
- **GitHub Advisory Database**: https://github.com/advisories
- **Security advisories**: https://github.com/mirego/elixir-security-advisories
- **Marketplace**: https://github.com/bradleygolden/claude-marketplace-elixir

## License

MIT
