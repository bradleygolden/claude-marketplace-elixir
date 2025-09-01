%{
  plugins: [
    Claude.Plugins.Base,
    Claude.Plugins.ClaudeCode,
    {Claude.Plugins.Credo, strict?: true},
    {Claude.Plugins.Dialyzer, post_edit_check?: true, pre_commit_check?: false},
    Claude.Plugins.ExDoc,
    Claude.Plugins.Logging
  ],
  hooks: %{
    pre_tool_use: [
      {"test --warnings-as-errors", [when: "Bash", command: ~r/^git commit/]}
    ]
  },
  auto_install_deps?: true
}
