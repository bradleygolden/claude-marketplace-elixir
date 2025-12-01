# precommit

Runs `mix precommit` before git commits when the alias exists.

## Overview

Phoenix 1.8+ projects ship with a standard `precommit` alias:

```elixir
precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
```

This plugin detects and runs that alias before commits.

## Installation

```bash
/plugin marketplace add github:bradleygolden/claude-marketplace-elixir
/plugin install precommit@elixir
```

## How It Works

1. Detects if `precommit` alias exists via `mix help precommit`
2. If exists: runs `mix precommit`, blocks commit on failure
3. If not exists: skips silently (other plugins handle validation)

**Coordination**: When this plugin runs, other plugins (core, credo, ex_unit, etc.) skip their precommit checks to avoid duplicate validation.

## Customizing

Modify your `mix.exs`:

```elixir
defp aliases do
  [
    precommit: [
      "compile --warnings-as-errors",
      "deps.unlock --unused",
      "format",
      "credo --strict",
      "test --stale"
    ]
  ]
end
```

## License

MIT
