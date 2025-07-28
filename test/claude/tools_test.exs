defmodule Claude.ToolsTest do
  use ExUnit.Case, async: true
  alias Claude.Tools

  describe "all_tools/0" do
    test "returns all tool atoms" do
      tools = Tools.all_tools()

      assert :bash in tools
      assert :edit in tools
      assert :glob in tools
      assert :grep in tools
      assert :ls in tools
      assert :multi_edit in tools
      assert :notebook_edit in tools
      assert :notebook_read in tools
      assert :read in tools
      assert :task in tools
      assert :todo_write in tools
      assert :web_fetch in tools
      assert :web_search in tools
      assert :write in tools
      assert length(tools) == 14
    end
  end

  describe "tools_requiring_permission/0" do
    test "returns tools that need permission" do
      tools = Tools.tools_requiring_permission()

      assert :bash in tools
      assert :edit in tools
      assert :multi_edit in tools
      assert :notebook_edit in tools
      assert :web_fetch in tools
      assert :web_search in tools
      assert :write in tools
      assert length(tools) == 7
    end

    test "does not include tools that don't need permission" do
      tools = Tools.tools_requiring_permission()

      refute :read in tools
      refute :grep in tools
      refute :glob in tools
      refute :ls in tools
    end
  end

  describe "tool_to_string/1" do
    test "converts tool atoms to Claude Code strings" do
      assert Tools.tool_to_string(:bash) == "Bash"
      assert Tools.tool_to_string(:edit) == "Edit"
      assert Tools.tool_to_string(:multi_edit) == "MultiEdit"
      assert Tools.tool_to_string(:notebook_edit) == "NotebookEdit"
      assert Tools.tool_to_string(:ls) == "LS"
      assert Tools.tool_to_string(:todo_write) == "TodoWrite"
    end
  end

  describe "from_string/1" do
    test "converts Claude Code strings to tool atoms" do
      assert Tools.from_string("Bash") == {:ok, :bash}
      assert Tools.from_string("Edit") == {:ok, :edit}
      assert Tools.from_string("MultiEdit") == {:ok, :multi_edit}
      assert Tools.from_string("NotebookEdit") == {:ok, :notebook_edit}
      assert Tools.from_string("LS") == {:ok, :ls}
      assert Tools.from_string("TodoWrite") == {:ok, :todo_write}
    end

    test "returns error for unknown tools" do
      assert Tools.from_string("UnknownTool") == {:error, "Unknown tool: UnknownTool"}
      assert Tools.from_string("bash") == {:error, "Unknown tool: bash"}
      assert Tools.from_string("") == {:error, "Unknown tool: "}
    end
  end

  describe "from_string!/1" do
    test "converts Claude Code strings to tool atoms" do
      assert Tools.from_string!("Bash") == :bash
      assert Tools.from_string!("WebSearch") == :web_search
    end

    test "raises for unknown tools" do
      assert_raise ArgumentError, "Unknown tool: InvalidTool", fn ->
        Tools.from_string!("InvalidTool")
      end
    end
  end

  describe "validate_tools/1" do
    test "returns :ok for valid tools" do
      assert Tools.validate_tools([:bash, :edit, :read]) == :ok
      assert Tools.validate_tools([]) == :ok
      assert Tools.validate_tools([:grep]) == :ok
    end

    test "returns error for invalid tools" do
      assert Tools.validate_tools([:bash, :invalid_tool]) ==
               {:error, "Invalid tools: invalid_tool"}

      assert Tools.validate_tools([:unknown, :another_unknown]) ==
               {:error, "Invalid tools: unknown, another_unknown"}
    end
  end

  describe "requires_permission?/1" do
    test "returns true for tools requiring permission" do
      assert Tools.requires_permission?(:bash) == true
      assert Tools.requires_permission?(:edit) == true
      assert Tools.requires_permission?(:write) == true
      assert Tools.requires_permission?(:web_fetch) == true
    end

    test "returns false for tools not requiring permission" do
      assert Tools.requires_permission?(:read) == false
      assert Tools.requires_permission?(:grep) == false
      assert Tools.requires_permission?(:glob) == false
      assert Tools.requires_permission?(:ls) == false
    end
  end

  describe "to_strings/1" do
    test "converts a list of tool atoms to Claude Code strings" do
      tools = [:bash, :edit, :grep]
      result = Tools.to_strings(tools)

      assert result == ["Bash", "Edit", "Grep"]
    end

    test "handles empty list" do
      assert Tools.to_strings([]) == []
    end
  end

  describe "from_strings/1" do
    test "converts a list of Claude Code strings to tool atoms" do
      strings = ["Bash", "Edit", "Grep"]
      assert Tools.from_strings(strings) == {:ok, [:bash, :edit, :grep]}
    end

    test "returns error if any string is invalid" do
      strings = ["Bash", "InvalidTool", "Grep"]
      assert Tools.from_strings(strings) == {:error, "Unknown tool: InvalidTool"}
    end

    test "handles empty list" do
      assert Tools.from_strings([]) == {:ok, []}
    end
  end
end
