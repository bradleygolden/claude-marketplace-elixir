defmodule Claude.Core.ProjectTest do
  use Claude.Test.ClaudeCodeCase, async: false

  import Claude.TestHelpers

  alias Claude.Core.Project

  describe "claude_path/0" do
    test "returns .claude directory in current working directory" do
      in_tmp(fn _tmp_dir ->
        # Clear any existing CLAUDE_PROJECT_DIR to test default behavior
        original_env = System.get_env("CLAUDE_PROJECT_DIR")
        System.delete_env("CLAUDE_PROJECT_DIR")

        expected_path = Path.join(File.cwd!(), ".claude") |> Path.expand()
        actual_path = Project.claude_path() |> Path.expand()

        assert actual_path == expected_path

        # Restore original env if it existed
        if original_env do
          System.put_env("CLAUDE_PROJECT_DIR", original_env)
        end
      end)
    end
  end
end
