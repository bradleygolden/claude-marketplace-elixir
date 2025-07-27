defmodule Claude.Hooks.HookTest do
  use Claude.Test.ClaudeCodeCase

  alias Claude.Hooks.Hook

  describe "new/1" do
    test "creates a hook struct with all fields" do
      attrs = %{
        type: "command",
        command: "mix format"
      }

      hook = Hook.new(attrs)

      assert %Hook{} = hook
      assert hook.type == "command"
      assert hook.command == "mix format"
    end

    test "creates a hook struct with keyword list" do
      attrs = [
        type: "command",
        command: "mix test"
      ]

      hook = Hook.new(attrs)

      assert %Hook{} = hook
      assert hook.type == "command"
      assert hook.command == "mix test"
    end

    test "raises when invalid fields are provided" do
      assert_raise KeyError, fn ->
        Hook.new(%{invalid_field: "value"})
      end
    end

    test "allows nil values for fields" do
      hook = Hook.new(%{type: nil, command: nil})

      assert %Hook{} = hook
      assert hook.type == nil
      assert hook.command == nil
    end
  end

  describe "Jason.Encoder" do
    test "encodes hook struct to JSON" do
      hook =
        Hook.new(%{
          type: "command",
          command: "echo 'hello'"
        })

      json = Jason.encode!(hook)
      decoded = Jason.decode!(json)

      assert decoded == %{
               "type" => "command",
               "command" => "echo 'hello'"
             }
    end

    test "encodes nested hook in larger structure" do
      hook =
        Hook.new(%{
          type: "command",
          command: "mix compile"
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
                     "command" => "mix compile"
                   }
                 ]
               }
             }
    end
  end
end
