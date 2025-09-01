%{
  plugins: [
    Claude.Plugins.Base,
    Claude.Plugins.ClaudeCode,
    Claude.Plugins.Logging,
    {Claude.Plugins.Credo, strict?: true, pre_commit_check?: false}
  ],
  hooks: %{
    pre_tool_use: [
      {"test --warnings-as-errors", [when: "Bash", command: ~r/^git commit/]}
    ]
  },
  auto_install_deps?: true
}
