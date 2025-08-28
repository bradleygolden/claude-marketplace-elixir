%{
  plugins: [Claude.Plugins.Base, Claude.Plugins.ClaudeCode, Claude.Plugins.Logging],
  auto_install_deps?: true,
  hooks: %{
    pre_tool_use: [
      {"test --warnings-as-errors", when: "Bash", command: ~r/^git commit/}
    ]
  }
}
