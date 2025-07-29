defmodule Claude do
  @moduledoc """
  Batteries-included Claude Code integration for Elixir projects.

  **Make Claude Code write production-ready Elixir, every time.**

  Claude ensures every line of code Claude writes is properly formatted, compiles without warnings,
  and follows your project's conventions—automatically.

  ## Features

  - 🎯 **Smart Hooks** - Format on save, compile checks, pre-commit validation
  - 🤖 **Sub-agents** - Specialized AI assistants with built-in best practices
  - 🔧 **Extensible** - Create custom hooks for your workflow
  - 🔌 **MCP Support** - Phoenix integration via Tidewave
  - 📚 **Best Practices** - Automatic usage rules from your dependencies

  ## Quick Start

      # Install via Igniter (recommended)
      mix igniter.install claude

      # Or add to your dependencies
      def deps do
        [
          {:claude, "~> 0.2.0", only: :dev, runtime: false}
        ]
      end

      # Then run
      mix claude.install

  For comprehensive documentation, examples, and configuration options, see the
  [README](https://github.com/bradleygolden/claude#readme).
  """
end
