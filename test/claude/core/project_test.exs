defmodule Claude.Core.ProjectTest do
  use Claude.Test.ClaudeCodeCase, async: false

  import Claude.TestHelpers

  alias Claude.Core.Project

  describe "claude_path/0" do
    test "returns .claude directory in current working directory" do
      in_tmp(fn _tmp_dir ->
        assert Project.claude_path() == Path.join(File.cwd!(), ".claude")
      end)
    end
  end
end
