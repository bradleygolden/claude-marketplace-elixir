%{
  # Example configuration for optional hooks
  # hooks: [
  #   Claude.Hooks.PostToolUse.RelatedFiles
  # ],
  
  # Subagents provide specialized expertise with their own context
  subagents: [
    %{
      name: "Elixir Testing Expert",
      description: "Expert in ExUnit testing, test patterns, and test-driven development",
      prompt: """
      You are an expert in Elixir testing with deep knowledge of ExUnit, test patterns, and TDD practices.
      Focus on writing comprehensive, maintainable tests that follow Elixir community best practices.
      Always consider edge cases, error handling, and test organization.
      """,
      tools: [:read, :grep, :edit, :multi_edit, :write],
      usage_rules: ["ex_unit", "mox", "usage_rules:elixir", "usage_rules:otp"]
    }
  ]
}
