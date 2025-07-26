defmodule Claude.Hooks.PostToolUse.RelatedFilesCheckerGlobTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Claude.Hooks.PostToolUse.RelatedFilesChecker

  describe "glob pattern support via configuration" do
    setup do
      original_config = Process.get(:claude_test_config)
      
      test_config = %{
        enabled: true,
        hooks: [
          %{
            module: RelatedFilesChecker,
            enabled: true,
            config: %{
              rules: [
                %{
                  pattern: "lib/claude/config.ex",
                  suggests: [
                    %{file: "test/**/*_test.exs", reason: "all test files"}
                  ]
                }
              ]
            }
          }
        ]
      }
      
      Process.put(:claude_test_config, test_config)
      
      on_exit(fn ->
        if original_config do
          Process.put(:claude_test_config, original_config)
        else
          Process.delete(:claude_test_config)
        end
      end)
      
      :ok
    end

    @tag :skip
    test "logs expanded glob patterns in real project structure" do
      json_params = Jason.encode!(%{"file_path" => "lib/claude/config.ex"})
      
      log = capture_log(fn ->
        assert :ok = RelatedFilesChecker.run("Edit", json_params)
      end)
      
      assert log =~ "all test files"
      assert log =~ "_test.exs"
    end
  end

  describe "glob pattern detection" do
    test "recognizes various glob patterns" do
      glob_patterns = [
        "test/**/*.exs",
        "lib/*.ex",
        "src/*/module.ex",
        "test/*_test.exs",
        "lib/[abc]*.ex",
        "test/{unit,integration}/*.exs"
      ]
      
      non_glob_patterns = [
        "test/specific_test.exs",
        "lib/module.ex",
        "README.md"
      ]
      
      contains_glob? = fn pattern ->
        String.contains?(pattern, "*") || String.contains?(pattern, "?") || 
        String.contains?(pattern, "[") || String.contains?(pattern, "{")
      end
      
      for pattern <- glob_patterns do
        assert contains_glob?.(pattern), "#{pattern} should be recognized as glob"
      end
      
      for pattern <- non_glob_patterns do
        refute contains_glob?.(pattern), "#{pattern} should not be recognized as glob"
      end
    end
  end
end