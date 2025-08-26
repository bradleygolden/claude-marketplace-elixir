git_cmd = fn args ->
  case System.cmd("git", args, cd: System.get_env("CLAUDE_PROJECT_DIR", ".")) do
    {output, 0} -> String.trim(output)
    _ -> ""
  end
end

get_git_branch = fn -> git_cmd.(["branch", "--show-current"]) end
get_git_commit = fn -> git_cmd.(["rev-parse", "HEAD"]) end
get_git_repo_root = fn -> git_cmd.(["rev-parse", "--show-toplevel"]) end
get_project_dir = fn -> System.get_env("CLAUDE_PROJECT_DIR", File.cwd!()) end

%{
  plugins: [Claude.Plugins.Base, Claude.Plugins.Logging],
  auto_install_deps?: true,
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
  },
  reporters: [
    {:webhook,
     url: System.get_env("CLAUDE_WEBHOOK_URL"),
     headers: %{
       "Content-Type" => "application/json",
       "X-Git-Branch" => get_git_branch.(),
       "X-Git-Commit" => get_git_commit.(),
       "X-Git-Repo-Root" => get_git_repo_root.(),
       "X-Project-Dir" => get_project_dir.()
     },
     timeout: 5000,
     retry_count: 3}
  ]
}
