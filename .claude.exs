# Claude project configuration - dogfooding our own extensible hooks!
%{
  enabled: true,
  
  hooks: [
    # Our built-in related files checker
    %{
      module: Claude.Hooks.PostToolUse.RelatedFilesChecker,
      enabled: true,
      config: %{
        # Custom rules specific to the Claude project
        rules: [
          # When settings.ex changes, check hooks that use settings
          %{
            pattern: "lib/claude/core/settings.ex",
            suggests: [
              %{file: "lib/claude/hooks.ex", reason: "uses Settings module"},
              %{file: "lib/claude/hooks/installer_test.exs", reason: "tests settings functionality"}
            ]
          },
          
          # When adding new hooks, update the registry tests
          %{
            pattern: "lib/claude/hooks/post_tool_use/*",
            suggests: [
              %{file: "test/claude/hooks/registry_test.exs", reason: "might need to test new hook discovery"}
            ]
          },
          
          # When modifying hook behavior, check CLI runner
          %{
            pattern: "lib/claude/hooks/hook/behaviour.ex",
            suggests: [
              %{file: "lib/claude/cli/hooks/run.ex", reason: "executes hooks"},
              %{file: "lib/claude/hooks.ex", reason: "defines hook structure"}
            ]
          },
          
          # Documentation updates
          %{
            pattern: "**/*.exs.example",
            suggests: [
              %{file: "README.md", reason: "example documentation"}
            ]
          },
          
          # When modifying any implementation file, check related tests using glob
          %{
            pattern: "lib/**/*.ex",
            suggests: [
              %{file: "test/**/*_test.exs", reason: "related test files might need updates"}
            ]
          },
          
          # When modifying config.ex, check all files that might use it
          %{
            pattern: "lib/claude/config.ex",
            suggests: [
              %{file: "lib/claude/**/*.ex", reason: "files that might use Config module"}
            ]
          }
        ]
      }
    }
  ]
}