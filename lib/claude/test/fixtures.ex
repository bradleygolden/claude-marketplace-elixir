defmodule Claude.Test.Fixtures do
  @moduledoc """
  Test fixtures for Claude hook events that mirror Claude Code's hook structure.

  Organized by:
  - Hook Input fixtures (what hooks receive from Claude Code)
  - Tool Input fixtures (nested within hook inputs)

  ## Usage

      # Testing a hook's run/1 function
      input = Fixtures.pre_tool_use_input()
      json = Jason.encode!(input)
      MyHook.run(json)
      
      # Testing with specific tool
      input = Fixtures.post_tool_use_input(
        tool_name: "Write",
        tool_input: Fixtures.tool_input(:write, file_path: "/test.ex")
      )
  """

  alias Claude.Hooks.Events
  alias Claude.Hooks.ToolInputs

  # ==================== HOOK INPUTS ====================
  # These match what Claude Code sends to hooks via stdin

  @doc """
  PreToolUse hook input - sent before tool execution.
  Matches Claude Code's PreToolUse JSON structure.
  """
  def pre_tool_use_input(attrs \\ %{}) do
    %Events.PreToolUse.Input{
      session_id: attrs[:session_id] || "test-session-123",
      transcript_path: attrs[:transcript_path] || "~/.claude/projects/test/transcript.jsonl",
      cwd: attrs[:cwd] || "/test/project",
      hook_event_name: "PreToolUse",
      tool_name: attrs[:tool_name] || "Edit",
      tool_input: attrs[:tool_input] || tool_input(:edit)
    }
  end

  @doc """
  PostToolUse hook input - sent after tool execution.
  Includes both tool_input and tool_response.
  """
  def post_tool_use_input(attrs \\ %{}) do
    %Events.PostToolUse.Input{
      session_id: attrs[:session_id] || "test-session-123",
      transcript_path: attrs[:transcript_path] || "~/.claude/projects/test/transcript.jsonl",
      cwd: attrs[:cwd] || "/test/project",
      hook_event_name: "PostToolUse",
      tool_name: attrs[:tool_name] || "Edit",
      tool_input: attrs[:tool_input] || tool_input(:edit),
      tool_response: attrs[:tool_response] || %{"success" => true}
    }
  end

  @doc """
  Notification hook input - sent when Claude needs to notify user.
  """
  def notification_input(attrs \\ %{}) do
    %Events.Notification.Input{
      session_id: attrs[:session_id] || "test-session-123",
      transcript_path: attrs[:transcript_path] || "~/.claude/projects/test/transcript.jsonl",
      cwd: attrs[:cwd] || "/test/project",
      hook_event_name: "Notification",
      message: attrs[:message] || "Claude needs your permission to use Bash"
    }
  end

  @doc """
  UserPromptSubmit hook input - sent when user submits a prompt.
  """
  def user_prompt_submit_input(attrs \\ %{}) do
    %Events.UserPromptSubmit.Input{
      session_id: attrs[:session_id] || "test-session-123",
      transcript_path: attrs[:transcript_path] || "~/.claude/projects/test/transcript.jsonl",
      cwd: attrs[:cwd] || "/test/project",
      hook_event_name: "UserPromptSubmit",
      prompt: attrs[:prompt] || "Write a function to calculate factorial"
    }
  end

  @doc """
  Stop hook input - sent when Claude finishes responding.
  """
  def stop_input(attrs \\ %{}) do
    %Events.Stop.Input{
      session_id: attrs[:session_id] || "test-session-123",
      transcript_path: attrs[:transcript_path] || "~/.claude/projects/test/transcript.jsonl",
      hook_event_name: "Stop",
      stop_hook_active: attrs[:stop_hook_active] || false
    }
  end

  @doc """
  SubagentStop hook input - sent when a subagent finishes.
  """
  def subagent_stop_input(attrs \\ %{}) do
    %Events.SubagentStop.Input{
      session_id: attrs[:session_id] || "test-session-123",
      transcript_path: attrs[:transcript_path] || "~/.claude/projects/test/transcript.jsonl",
      hook_event_name: "SubagentStop",
      stop_hook_active: attrs[:stop_hook_active] || false
    }
  end

  @doc """
  PreCompact hook input - sent before compaction.
  """
  def pre_compact_input(attrs \\ %{}) do
    %Events.PreCompact.Input{
      session_id: attrs[:session_id] || "test-session-123",
      transcript_path: attrs[:transcript_path] || "~/.claude/projects/test/transcript.jsonl",
      hook_event_name: "PreCompact",
      trigger: attrs[:trigger] || :manual,
      custom_instructions: attrs[:custom_instructions] || ""
    }
  end

  # ==================== TOOL INPUTS ====================
  # These are nested within hook inputs

  @doc """
  Generic tool input fixture creator.

  ## Examples
      
      tool_input(:edit, file_path: "/test.ex", old_string: "foo")
      tool_input(:write, file_path: "/new.ex", content: "content")
      tool_input(:bash, command: "mix test")
  """
  def tool_input(tool, attrs \\ %{})

  def tool_input(:edit, attrs) do
    %ToolInputs.Edit{
      file_path: attrs[:file_path] || "/test/file.ex",
      old_string: attrs[:old_string] || "old content",
      new_string: attrs[:new_string] || "new content",
      replace_all: attrs[:replace_all] || false
    }
  end

  def tool_input(:write, attrs) do
    %ToolInputs.Write{
      file_path: attrs[:file_path] || "/test/file.ex",
      content: attrs[:content] || "defmodule Test do\n  def hello, do: :world\nend"
    }
  end

  def tool_input(:bash, attrs) do
    %ToolInputs.Bash{
      command: attrs[:command] || "echo 'test'",
      description: attrs[:description],
      timeout: attrs[:timeout]
    }
  end

  def tool_input(:multi_edit, attrs) do
    %ToolInputs.MultiEdit{
      file_path: attrs[:file_path] || "/test/file.ex",
      edits:
        attrs[:edits] ||
          [
            %{old_string: "foo", new_string: "bar", replace_all: false}
          ]
    }
  end

  def tool_input(:read, attrs) do
    %ToolInputs.Read{
      file_path: attrs[:file_path] || "/test/file.ex",
      limit: attrs[:limit],
      offset: attrs[:offset]
    }
  end

  def tool_input(:glob, attrs) do
    %ToolInputs.Glob{
      path: attrs[:path],
      pattern: attrs[:pattern] || "**/*.ex"
    }
  end

  def tool_input(:grep, attrs) do
    %ToolInputs.Grep{
      pattern: attrs[:pattern] || "TODO",
      path: attrs[:path],
      type: attrs[:type],
      glob: attrs[:glob],
      output_mode: attrs[:output_mode],
      head_limit: attrs[:head_limit],
      multiline: attrs[:multiline],
      "-A": attrs[:"-A"],
      "-B": attrs[:"-B"],
      "-C": attrs[:"-C"],
      "-i": attrs[:"-i"],
      "-n": attrs[:"-n"]
    }
  end

  def tool_input(:ls, attrs) do
    %ToolInputs.LS{
      path: attrs[:path] || "/",
      ignore: attrs[:ignore]
    }
  end

  def tool_input(:notebook_read, attrs) do
    %ToolInputs.NotebookRead{
      notebook_path: attrs[:notebook_path] || "/notebook.ipynb",
      cell_id: attrs[:cell_id]
    }
  end

  def tool_input(:notebook_edit, attrs) do
    %ToolInputs.NotebookEdit{
      notebook_path: attrs[:notebook_path] || "/notebook.ipynb",
      new_source: attrs[:new_source] || "print('Hello')",
      cell_id: attrs[:cell_id],
      cell_type: attrs[:cell_type],
      edit_mode: attrs[:edit_mode]
    }
  end

  def tool_input(:web_fetch, attrs) do
    %ToolInputs.WebFetch{
      url: attrs[:url] || "https://example.com",
      prompt: attrs[:prompt] || "Extract main content"
    }
  end

  def tool_input(:web_search, attrs) do
    %ToolInputs.WebSearch{
      query: attrs[:query] || "elixir documentation",
      allowed_domains: attrs[:allowed_domains],
      blocked_domains: attrs[:blocked_domains]
    }
  end

  def tool_input(:todo_write, attrs) do
    %ToolInputs.TodoWrite{
      todos: attrs[:todos] || []
    }
  end

  def tool_input(:task, attrs) do
    %ToolInputs.Task{
      description: attrs[:description] || "Perform task",
      prompt: attrs[:prompt] || "Complete the following task"
    }
  end
end
