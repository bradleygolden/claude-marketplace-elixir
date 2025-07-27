defmodule Claude.Hooks.ToolInputsTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.ToolInputs

  describe "Task" do
    test "creates struct from map" do
      attrs = %{
        "description" => "Find and fix bugs",
        "prompt" => "Search for compilation errors in the codebase"
      }

      task = ToolInputs.Task.new(attrs)

      assert task.description == "Find and fix bugs"
      assert task.prompt == "Search for compilation errors in the codebase"
    end
  end

  describe "Bash" do
    test "creates struct from map with all fields" do
      attrs = %{
        "command" => "mix test",
        "description" => "Run tests",
        "timeout" => 30000
      }

      bash = ToolInputs.Bash.new(attrs)

      assert bash.command == "mix test"
      assert bash.description == "Run tests"
      assert bash.timeout == 30000
    end

    test "handles missing optional fields" do
      attrs = %{"command" => "ls"}

      bash = ToolInputs.Bash.new(attrs)

      assert bash.command == "ls"
      assert bash.description == nil
      assert bash.timeout == nil
    end
  end

  describe "Edit" do
    test "creates struct from map" do
      attrs = %{
        "file_path" => "/test.ex",
        "old_string" => "def hello",
        "new_string" => "def hello_world",
        "replace_all" => true
      }

      edit = ToolInputs.Edit.new(attrs)

      assert edit.file_path == "/test.ex"
      assert edit.old_string == "def hello"
      assert edit.new_string == "def hello_world"
      assert edit.replace_all == true
    end

    test "defaults replace_all to false" do
      attrs = %{
        "file_path" => "/test.ex",
        "old_string" => "old",
        "new_string" => "new"
      }

      edit = ToolInputs.Edit.new(attrs)
      assert edit.replace_all == false
    end
  end

  describe "MultiEdit" do
    test "creates struct with multiple edits" do
      attrs = %{
        "file_path" => "/test.ex",
        "edits" => [
          %{"old_string" => "foo", "new_string" => "bar", "replace_all" => true},
          %{"old_string" => "baz", "new_string" => "qux"}
        ]
      }

      multi_edit = ToolInputs.MultiEdit.new(attrs)

      assert multi_edit.file_path == "/test.ex"
      assert length(multi_edit.edits) == 2
      assert hd(multi_edit.edits) == %{old_string: "foo", new_string: "bar", replace_all: true}

      assert List.last(multi_edit.edits) == %{
               old_string: "baz",
               new_string: "qux",
               replace_all: false
             }
    end

    test "handles empty edits list" do
      attrs = %{"file_path" => "/test.ex"}

      multi_edit = ToolInputs.MultiEdit.new(attrs)
      assert multi_edit.edits == []
    end
  end

  describe "Write" do
    test "creates struct from map" do
      attrs = %{
        "file_path" => "/new_file.ex",
        "content" => "defmodule NewFile do\nend"
      }

      write = ToolInputs.Write.new(attrs)

      assert write.file_path == "/new_file.ex"
      assert write.content == "defmodule NewFile do\nend"
    end
  end

  describe "Read" do
    test "creates struct with all fields" do
      attrs = %{
        "file_path" => "/test.ex",
        "limit" => 100,
        "offset" => 50
      }

      read = ToolInputs.Read.new(attrs)

      assert read.file_path == "/test.ex"
      assert read.limit == 100
      assert read.offset == 50
    end

    test "handles missing optional fields" do
      attrs = %{"file_path" => "/test.ex"}

      read = ToolInputs.Read.new(attrs)

      assert read.file_path == "/test.ex"
      assert read.limit == nil
      assert read.offset == nil
    end
  end

  describe "Glob" do
    test "creates struct from map" do
      attrs = %{
        "path" => "/src",
        "pattern" => "**/*.ex"
      }

      glob = ToolInputs.Glob.new(attrs)

      assert glob.path == "/src"
      assert glob.pattern == "**/*.ex"
    end

    test "handles missing path" do
      attrs = %{"pattern" => "*.txt"}

      glob = ToolInputs.Glob.new(attrs)

      assert glob.path == nil
      assert glob.pattern == "*.txt"
    end
  end

  describe "Grep" do
    test "creates struct with all fields" do
      attrs = %{
        "pattern" => "TODO",
        "path" => "/src",
        "type" => "elixir",
        "glob" => "*.ex",
        "output_mode" => "content",
        "head_limit" => 20,
        "multiline" => true,
        "-A" => 2,
        "-B" => 2,
        "-C" => 3,
        "-i" => true,
        "-n" => true
      }

      grep = ToolInputs.Grep.new(attrs)

      assert grep.pattern == "TODO"
      assert grep.path == "/src"
      assert grep.type == "elixir"
      assert grep.glob == "*.ex"
      assert grep.output_mode == :content
      assert grep.head_limit == 20
      assert grep.multiline == true
      assert Map.get(grep, :"-A") == 2
      assert Map.get(grep, :"-B") == 2
      assert Map.get(grep, :"-C") == 3
      assert Map.get(grep, :"-i") == true
      assert Map.get(grep, :"-n") == true
    end

    test "parses output_mode correctly" do
      assert ToolInputs.Grep.new(%{"pattern" => "test", "output_mode" => "content"}).output_mode ==
               :content

      assert ToolInputs.Grep.new(%{"pattern" => "test", "output_mode" => "files_with_matches"}).output_mode ==
               :files_with_matches

      assert ToolInputs.Grep.new(%{"pattern" => "test", "output_mode" => "count"}).output_mode ==
               :count

      assert ToolInputs.Grep.new(%{"pattern" => "test", "output_mode" => "invalid"}).output_mode ==
               :files_with_matches
    end
  end

  describe "LS" do
    test "creates struct from map" do
      attrs = %{
        "path" => "/home/user",
        "ignore" => [".git", "node_modules"]
      }

      ls = ToolInputs.LS.new(attrs)

      assert ls.path == "/home/user"
      assert ls.ignore == [".git", "node_modules"]
    end
  end

  describe "NotebookRead" do
    test "creates struct from map" do
      attrs = %{
        "notebook_path" => "/notebook.ipynb",
        "cell_id" => "cell_123"
      }

      notebook_read = ToolInputs.NotebookRead.new(attrs)

      assert notebook_read.notebook_path == "/notebook.ipynb"
      assert notebook_read.cell_id == "cell_123"
    end
  end

  describe "NotebookEdit" do
    test "creates struct with all fields" do
      attrs = %{
        "notebook_path" => "/notebook.ipynb",
        "new_source" => "print('Hello')",
        "cell_id" => "cell_123",
        "cell_type" => "code",
        "edit_mode" => "replace"
      }

      notebook_edit = ToolInputs.NotebookEdit.new(attrs)

      assert notebook_edit.notebook_path == "/notebook.ipynb"
      assert notebook_edit.new_source == "print('Hello')"
      assert notebook_edit.cell_id == "cell_123"
      assert notebook_edit.cell_type == :code
      assert notebook_edit.edit_mode == :replace
    end

    test "parses cell_type and edit_mode correctly" do
      assert ToolInputs.NotebookEdit.new(%{
               "notebook_path" => "n.ipynb",
               "new_source" => "x",
               "cell_type" => "code"
             }).cell_type == :code

      assert ToolInputs.NotebookEdit.new(%{
               "notebook_path" => "n.ipynb",
               "new_source" => "x",
               "cell_type" => "markdown"
             }).cell_type == :markdown

      assert ToolInputs.NotebookEdit.new(%{
               "notebook_path" => "n.ipynb",
               "new_source" => "x",
               "edit_mode" => "insert"
             }).edit_mode == :insert

      assert ToolInputs.NotebookEdit.new(%{
               "notebook_path" => "n.ipynb",
               "new_source" => "x",
               "edit_mode" => "delete"
             }).edit_mode == :delete
    end
  end

  describe "WebFetch" do
    test "creates struct from map" do
      attrs = %{
        "url" => "https://example.com",
        "prompt" => "Extract the main content"
      }

      web_fetch = ToolInputs.WebFetch.new(attrs)

      assert web_fetch.url == "https://example.com"
      assert web_fetch.prompt == "Extract the main content"
    end
  end

  describe "WebSearch" do
    test "creates struct from map" do
      attrs = %{
        "query" => "elixir documentation",
        "allowed_domains" => ["hexdocs.pm"],
        "blocked_domains" => ["spam.com"]
      }

      web_search = ToolInputs.WebSearch.new(attrs)

      assert web_search.query == "elixir documentation"
      assert web_search.allowed_domains == ["hexdocs.pm"]
      assert web_search.blocked_domains == ["spam.com"]
    end
  end

  describe "TodoWrite" do
    test "creates struct with todos" do
      attrs = %{
        "todos" => [
          %{
            "content" => "Fix bug",
            "status" => "in_progress",
            "priority" => "high",
            "id" => "1"
          },
          %{
            "content" => "Write tests",
            "status" => "pending",
            "priority" => "medium",
            "id" => "2"
          }
        ]
      }

      todo_write = ToolInputs.TodoWrite.new(attrs)

      assert length(todo_write.todos) == 2

      first_todo = hd(todo_write.todos)
      assert first_todo.content == "Fix bug"
      assert first_todo.status == :in_progress
      assert first_todo.priority == :high
      assert first_todo.id == "1"

      second_todo = List.last(todo_write.todos)
      assert second_todo.content == "Write tests"
      assert second_todo.status == :pending
      assert second_todo.priority == :medium
      assert second_todo.id == "2"
    end

    test "handles invalid status and priority" do
      attrs = %{
        "todos" => [
          %{
            "content" => "Task",
            "status" => "invalid",
            "priority" => "invalid",
            "id" => "1"
          }
        ]
      }

      todo_write = ToolInputs.TodoWrite.new(attrs)
      todo = hd(todo_write.todos)

      # default
      assert todo.status == :pending
      # default
      assert todo.priority == :medium
    end
  end

  describe "parse_tool_input/2" do
    test "parses Write tool input" do
      tool_input = %{"file_path" => "/test.ex", "content" => "defmodule Test do\nend"}

      assert {:ok, input} = ToolInputs.parse_tool_input("Write", tool_input)
      assert %ToolInputs.Write{file_path: "/test.ex"} = input
    end

    test "parses Edit tool input" do
      tool_input = %{
        "file_path" => "/test.ex",
        "old_string" => "old",
        "new_string" => "new"
      }

      assert {:ok, input} = ToolInputs.parse_tool_input("Edit", tool_input)
      assert %ToolInputs.Edit{file_path: "/test.ex"} = input
    end

    test "parses Bash tool input" do
      tool_input = %{"command" => "mix test"}

      assert {:ok, input} = ToolInputs.parse_tool_input("Bash", tool_input)
      assert %ToolInputs.Bash{command: "mix test"} = input
    end

    test "returns raw map for unknown tools" do
      tool_input = %{"some" => "data"}

      assert {:ok, input} = ToolInputs.parse_tool_input("UnknownTool", tool_input)
      assert input == %{"some" => "data"}
    end

    test "parses all known tools" do
      tools = [
        {"Task", %{"description" => "d", "prompt" => "p"}, ToolInputs.Task},
        {"Bash", %{"command" => "ls"}, ToolInputs.Bash},
        {"Edit", %{"file_path" => "f", "old_string" => "o", "new_string" => "n"},
         ToolInputs.Edit},
        {"MultiEdit", %{"file_path" => "f", "edits" => []}, ToolInputs.MultiEdit},
        {"Write", %{"file_path" => "f", "content" => "c"}, ToolInputs.Write},
        {"Read", %{"file_path" => "f"}, ToolInputs.Read},
        {"Glob", %{"pattern" => "*.ex"}, ToolInputs.Glob},
        {"Grep", %{"pattern" => "TODO"}, ToolInputs.Grep},
        {"LS", %{"path" => "/"}, ToolInputs.LS},
        {"NotebookRead", %{"notebook_path" => "n.ipynb"}, ToolInputs.NotebookRead},
        {"NotebookEdit", %{"notebook_path" => "n.ipynb", "new_source" => "s"},
         ToolInputs.NotebookEdit},
        {"WebFetch", %{"url" => "http://example.com", "prompt" => "p"}, ToolInputs.WebFetch},
        {"WebSearch", %{"query" => "elixir"}, ToolInputs.WebSearch},
        {"TodoWrite", %{"todos" => []}, ToolInputs.TodoWrite}
      ]

      for {tool_name, tool_input, expected_module} <- tools do
        assert {:ok, input} = ToolInputs.parse_tool_input(tool_name, tool_input)

        assert match?(%^expected_module{}, input),
               "Expected #{inspect(expected_module)} for #{tool_name}"
      end
    end
  end
end
