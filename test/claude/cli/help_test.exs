defmodule Claude.CLI.HelpTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Claude.CLI.Help

  describe "run/1" do
    test "displays help information" do
      output =
        capture_io(fn ->
          assert :ok = Help.run([])
        end)

      assert output =~ "Claude - Opinionated Claude Code integration"
      assert output =~ "Usage:"
      assert output =~ "Commands:"
      assert output =~ "hooks"
      assert output =~ "help"
      assert output =~ "Examples:"
      assert output =~ "mix claude hooks install"
    end

    test "returns :ok" do
      capture_io(fn ->
        assert :ok = Help.run([])
      end)
    end

    test "ignores arguments" do
      output =
        capture_io(fn ->
          assert :ok = Help.run(["some", "args"])
        end)

      assert output =~ "Claude - Opinionated Claude Code integration"
    end
  end
end
