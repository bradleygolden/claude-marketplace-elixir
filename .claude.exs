%{
  hooks: %{
    stop: [
      {"compile --warnings-as-errors", stop_on_failure?: true},
      "format --check-formatted"
    ],
    post_tool_use: [
      {"compile --warnings-as-errors",
       when: [:write, :edit, :multi_edit], stop_on_failure?: true},
      {"format --check-formatted {{tool_input.file_path}}", when: [:write, :edit]}
    ],
    pre_tool_use: [
      # Block git commit with --no-verify flag
      {"cmd echo 'Error: --no-verify is not allowed' >&2; exit 2",
       when: "Bash", command: ~r/^git commit.*--no-verify/, stop_on_failure?: true},
      # Run compilation check for normal git commits (but NOT with --no-verify)
      {"compile --warnings-as-errors",
       when: "Bash", command: ~r/^git commit(?!.*--no-verify)/, stop_on_failure?: true}
    ]
  }
}
