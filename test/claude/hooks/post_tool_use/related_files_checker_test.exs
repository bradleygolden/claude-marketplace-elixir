defmodule Claude.Hooks.PostToolUse.RelatedFilesCheckerTest do
  use ExUnit.Case, async: true

  alias Claude.Hooks.PostToolUse.RelatedFilesChecker

  import ExUnit.CaptureLog

  describe "run/2" do
    test "suggests test file when lib file is edited" do
      json_params = Jason.encode!(%{"file_path" => "lib/example/module.ex"})
      
      log = capture_log(fn ->
        assert :ok = RelatedFilesChecker.run("Edit", json_params)
      end)
      
      assert log =~ "test/example/module_test.exs"
      assert log =~ "corresponding test file"
    end

    test "suggests implementation file when test file is edited" do
      json_params = Jason.encode!(%{"file_path" => "test/example/module_test.exs"})
      
      log = capture_log(fn ->
        assert :ok = RelatedFilesChecker.run("Edit", json_params)
      end)
      
      assert log =~ "lib/example/module.ex"
      assert log =~ "implementation file"
    end

    test "returns :ok without logging when no related files found" do
      json_params = Jason.encode!(%{"file_path" => "random/path.txt"})
      
      log = capture_log(fn ->
        assert :ok = RelatedFilesChecker.run("Edit", json_params)
      end)
      
      assert log == ""
    end

    test "handles Write tool" do
      json_params = Jason.encode!(%{"file_path" => "lib/new_module.ex"})
      
      log = capture_log(fn ->
        assert :ok = RelatedFilesChecker.run("Write", json_params)
      end)
      
      assert log =~ "test/new_module_test.exs"
    end

    test "handles MultiEdit tool" do
      json_params = Jason.encode!(%{"file_path" => "lib/multi_edit.ex", "edits" => []})
      
      log = capture_log(fn ->
        assert :ok = RelatedFilesChecker.run("MultiEdit", json_params)
      end)
      
      assert log =~ "test/multi_edit_test.exs"
    end

    test "returns :ok for unsupported tools" do
      json_params = Jason.encode!(%{"file_path" => "lib/example.ex"})
      
      assert :ok = RelatedFilesChecker.run("Read", json_params)
    end

    test "returns :ok for invalid JSON" do
      assert :ok = RelatedFilesChecker.run("Edit", "invalid json")
    end
  end

  describe "config/0" do
    test "returns correct hook configuration" do
      config = RelatedFilesChecker.config()
      
      assert config.type == "command"
      assert config.command =~ "related_files_checker"
      assert config.matcher == "Edit|MultiEdit|Write"
    end
  end

  describe "description/0" do
    test "returns a description" do
      assert is_binary(RelatedFilesChecker.description())
    end
  end
end