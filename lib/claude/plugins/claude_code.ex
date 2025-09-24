defmodule Claude.Plugins.ClaudeCode do
  @moduledoc """
  Claude Code plugin providing comprehensive Claude Code documentation and memories.

  This plugin configures nested memories with official Claude Code documentation
  to help Claude understand and implement Claude Code features correctly.

  ## Usage

  Add to your `.claude.exs`:

      %{
        plugins: [Claude.Plugins.ClaudeCode]
      }

  ## Configuration Generated

  * Root directory gets Claude Code documentation for hooks, memory management, and settings
  * Test directory gets Elixir and OTP usage rules

  The plugin provides URL-based memories that are automatically cached locally
  for offline access and faster loading.
  """

  @behaviour Claude.Plugin

  @doc "Get the standard set of Claude Code documentation memories"
  def claude_code_memories do
    [
      {:url, "https://docs.anthropic.com/en/docs/claude-code/hooks.md",
       as: "Claude Code Hooks Reference", cache: "./ai/claude_code/hooks_reference.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/slash-commands.md",
       as: "Claude Code Slash Commands", cache: "./ai/claude_code/slash_commands.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/hooks-guide.md",
       as: "Claude Code Hooks Guide", cache: "./ai/claude_code/hooks_guide.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/memory.md",
       as: "Claude Code Memory Configuration", cache: "./ai/claude_code/memory.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/settings.md",
       as: "Claude Code Settings Configuration", cache: "./ai/claude_code/settings.md"}
    ]
  end

  def config(_opts) do
    %{
      nested_memories: %{
        "." => claude_code_memories(),
        "test" => [
          "usage_rules:elixir",
          "usage_rules:otp"
        ]
      }
    }
  end
end
