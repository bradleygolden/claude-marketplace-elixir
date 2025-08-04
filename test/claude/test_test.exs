defmodule Claude.TestTest do
  use ExUnit.Case, async: true
  alias Claude.Test
  alias Claude.Test.Fixtures

  defmodule MockHook do
    @moduledoc false
    def run(json_input) do
      # Parse input to verify it's valid JSON
      {:ok, _} = Jason.decode(json_input)

      # Output some JSON
      output = %{
        "decision" => "allow",
        "suppressOutput" => true,
        "reason" => "Test passed"
      }

      IO.puts(Jason.encode!(output))
      :ok
    end
  end

  describe "run_hook/2 and run_hook/3" do
    test "accepts a struct and returns parsed JSON" do
      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: "/test.ex")
        )

      json = Test.run_hook(MockHook, input)

      assert json["decision"] == "allow"
      assert json["suppressOutput"] == true
      assert json["reason"] == "Test passed"
    end

    test "accepts a JSON string and returns parsed JSON" do
      json_string =
        Jason.encode!(%{
          "tool_name" => "Write",
          "file_path" => "/test.ex"
        })

      json = Test.run_hook(MockHook, json_string)

      assert json["decision"] == "allow"
      assert json["suppressOutput"] == true
    end

    test "works inline with fixtures" do
      json = Test.run_hook(MockHook, Fixtures.post_tool_use_input())

      assert json["decision"] == "allow"
      assert json["suppressOutput"] == true
    end

    test "accepts stderr option" do
      # This hook simulates outputting to stderr
      defmodule StderrHook do
        def run(json_input) do
          {:ok, _} = Jason.decode(json_input)
          IO.puts(:stderr, "Some stderr output")
          IO.puts(Jason.encode!(%{"result" => "success"}))
          :ok
        end
      end

      json = Test.run_hook(StderrHook, %{"test" => true}, stderr: true)
      assert json["result"] == "success"
    end
  end
end
