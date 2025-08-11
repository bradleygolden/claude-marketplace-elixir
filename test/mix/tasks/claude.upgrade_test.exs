defmodule Mix.Tasks.Claude.UpgradeTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Claude.Upgrade

  describe "upgrade check" do
    test "detects old list-based hooks format and shows instructions" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Claude.Hooks.PostToolUse.ElixirFormatter,
                Claude.Hooks.PostToolUse.CompilationChecker,
                Claude.Hooks.PreToolUse.PreCommitCheck
              ]
            }
            """
          }
        )
        |> Upgrade.igniter()

      assert Enum.any?(igniter.issues, fn issue ->
               String.contains?(issue, "outdated hooks format") and
                 String.contains?(issue, "manually update your .claude.exs file")
             end)
    end

    test "shows success message for new map-based format" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                stop: [:compile, :format],
                post_tool_use: [:compile]
              }
            }
            """
          }
        )
        |> Upgrade.igniter()

      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "already up to date")
             end)

      assert igniter.issues == []
    end

    test "handles missing .claude.exs file" do
      igniter =
        test_project(files: %{})
        |> Upgrade.igniter()

      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "No .claude.exs file found")
             end)

      assert igniter.issues == []
    end

    test "handles .claude.exs with no hooks key" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: []
            }
            """
          }
        )
        |> Upgrade.igniter()

      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "already up to date")
             end)
    end

    test "handles invalid .claude.exs syntax gracefully" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            this is not valid elixir code
            """
          }
        )
        |> Upgrade.igniter()

      assert igniter.issues == []
      assert igniter.notices == []
    end

    test "shows correct upgrade instructions" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Claude.Hooks.PostToolUse.ElixirFormatter
              ]
            }
            """
          }
        )
        |> Upgrade.igniter()

      issue =
        Enum.find(igniter.issues, fn issue ->
          String.contains?(issue, "outdated hooks format")
        end)

      assert issue
      assert String.contains?(issue, "stop: [:compile, :format]")
      assert String.contains?(issue, "subagent_stop: [:compile, :format]")
      assert String.contains?(issue, "post_tool_use: [:compile, :format]")
      assert String.contains?(issue, "pre_tool_use: [:compile, :format, :unused_deps]")
      assert String.contains?(issue, "run `mix claude.install` to regenerate")
    end
  end
end
