%{
  plugins: [Claude.Plugins.Base, Claude.Plugins.Worktrees],
  nested_memories: %{
    "." => [
      {:url, "https://docs.anthropic.com/en/docs/claude-code/hooks.md",
       as: "Claude Code Hooks Reference", cache: "./ai/claude_code/hooks_reference.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/slash-commands.md",
       as: "Claude Code Slash Commands", cache: "./ai/claude_code/slash_commands.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/sub-agents.md",
       as: "Claude Code Subagents", cache: "./ai/claude_code/sub-agents.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/hooks-guide.md",
       as: "Claude Code Hooks Guide", cache: "./ai/claude_code/hooks_guide.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/memory.md",
       as: "Claude Code Memory Configuration", cache: "./ai/claude_code/memory.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/settings.md",
       as: "Claude Code Settings Configuration", cache: "./ai/claude_code/settings.md"}
    ],
    "test" => [
      "usage_rules:elixir",
      "usage_rules:otp"
    ]
  },
  hooks: %{
    pre_tool_use: [
      {"test --warnings-as-errors", when: "Bash", command: ~r/^git commit/}
    ],
    stop: [
      {"test --warnings-as-errors --stale", blocking?: false}
    ],
    subagent_stop: [
      {"test --warnings-as-errors --stale", blocking?: false}
    ]
  }
}
