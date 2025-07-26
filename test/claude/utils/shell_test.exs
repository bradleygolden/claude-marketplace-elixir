defmodule Claude.Utils.ShellTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Claude.Utils.Shell

  describe "info/1" do
    test "outputs message to stdout" do
      output =
        capture_io(fn ->
          Shell.info("Information message")
        end)

      assert output == "Information message\n"
    end
  end

  describe "success/1" do
    test "outputs message with checkmark to stdout" do
      output =
        capture_io(fn ->
          Shell.success("Success message")
        end)

      assert output == "✓ Success message\n"
    end
  end

  describe "error/1" do
    test "outputs message with X to stderr" do
      output =
        capture_io(:stderr, fn ->
          Shell.error("Error message")
        end)

      assert output == "❌ Error message\n"
    end

    test "does not output to stdout" do
      output =
        capture_io(fn ->
          capture_io(:stderr, fn ->
            Shell.error("Error message")
          end)
        end)

      assert output == ""
    end
  end

  describe "warn/1" do
    test "outputs message with warning symbol to stdout" do
      output =
        capture_io(fn ->
          Shell.warn("Warning message")
        end)

      assert output == "⚠️  Warning message\n"
    end
  end

  describe "bullet/1" do
    test "outputs message with bullet point to stdout" do
      output =
        capture_io(fn ->
          Shell.bullet("Bullet item")
        end)

      assert output == "  • Bullet item\n"
    end
  end

  describe "blank/0" do
    test "outputs a blank line" do
      output =
        capture_io(fn ->
          Shell.blank()
        end)

      assert output == "\n"
    end
  end
end
