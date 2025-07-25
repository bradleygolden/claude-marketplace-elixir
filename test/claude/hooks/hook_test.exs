defmodule Claude.Hooks.HookTest do
  use ExUnit.Case, async: true

  alias Claude.Hooks.Hook

  describe "new/1" do
    test "creates a hook struct with all fields" do
      attrs = %{
        type: "command",
        command: "mix format",
        matcher: "*.ex"
      }

      hook = Hook.new(attrs)

      assert %Hook{} = hook
      assert hook.type == "command"
      assert hook.command == "mix format"
      assert hook.matcher == "*.ex"
    end

    test "creates a hook struct with keyword list" do
      attrs = [
        type: "command",
        command: "mix test",
        matcher: "*.exs"
      ]

      hook = Hook.new(attrs)

      assert %Hook{} = hook
      assert hook.type == "command"
      assert hook.command == "mix test"
      assert hook.matcher == "*.exs"
    end

    test "raises when invalid fields are provided" do
      assert_raise KeyError, fn ->
        Hook.new(%{invalid_field: "value"})
      end
    end

    test "allows nil values for fields" do
      hook = Hook.new(%{type: nil, command: nil, matcher: nil})

      assert %Hook{} = hook
      assert hook.type == nil
      assert hook.command == nil
      assert hook.matcher == nil
    end
  end

  describe "Jason.Encoder" do
    test "encodes hook struct to JSON" do
      hook =
        Hook.new(%{
          type: "command",
          command: "echo 'hello'",
          matcher: ".*"
        })

      json = Jason.encode!(hook)
      decoded = Jason.decode!(json)

      assert decoded == %{
               "type" => "command",
               "command" => "echo 'hello'",
               "matcher" => ".*"
             }
    end

    test "encodes nested hook in larger structure" do
      hook =
        Hook.new(%{
          type: "command",
          command: "mix compile",
          matcher: "*.ex"
        })

      structure = %{
        "PostToolUse" => %{
          "hooks" => [hook]
        }
      }

      json = Jason.encode!(structure)
      decoded = Jason.decode!(json)

      assert decoded == %{
               "PostToolUse" => %{
                 "hooks" => [
                   %{
                     "type" => "command",
                     "command" => "mix compile",
                     "matcher" => "*.ex"
                   }
                 ]
               }
             }
    end
  end
end
