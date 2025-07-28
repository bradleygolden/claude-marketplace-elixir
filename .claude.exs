%{
  mcp_servers: [{:tidewave, [port: 4000]}],
  subagents: [
    %{
      name: "Elixir Testing Expert",
      description: "Expert in ExUnit testing, test patterns, and test-driven development",
      prompt: "You are an expert in Elixir testing with deep knowledge of ExUnit, test patterns, and TDD practices.\nFocus on writing comprehensive, maintainable tests that follow Elixir community best practices.\nAlways consider edge cases, error handling, and test organization.\n",
      tools: [:read, :grep, :edit, :multi_edit, :write],
      usage_rules: ["ex_unit", "mox", "usage_rules:elixir", "usage_rules:otp"]
    }
  ]
}
