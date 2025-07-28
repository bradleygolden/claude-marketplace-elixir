defmodule Claude.Test.FeatureHelpers do
  @moduledoc """
  Helper functions for feature-level testing of Claude Code workflows.
  
  Provides high-level functions to simulate Claude Code operations
  and capture their results including hook outputs.
  """
  
  @doc """
  Simulates Claude using the Edit tool and captures hook outputs.
  """
  def simulate_claude_edit(project, %{tool: "Edit"} = edit_params) do
    hook_input = build_hook_input("PostToolUse", "Edit", %{
      "file_path" => edit_params.file_path,
      "old_string" => edit_params.old_string,
      "new_string" => edit_params.new_string
    }, project)
    
    file_content = File.read!(edit_params.file_path)
    new_content = String.replace(file_content, edit_params.old_string, edit_params.new_string)
    File.write!(edit_params.file_path, new_content)
    
    run_hook_and_capture(project, "post_tool_use.elixir_formatter", hook_input)
  end
  
  @doc """
  Simulates Claude using the Write tool and captures hook outputs.
  """
  def simulate_claude_write(project, %{tool: "Write"} = write_params) do
    hook_input = build_hook_input("PostToolUse", "Write", %{
      "file_path" => write_params.file_path,
      "content" => write_params.content
    }, project)
    
    File.write!(write_params.file_path, write_params.content)
    
    formatter_result = run_hook_and_capture(project, "post_tool_use.elixir_formatter", hook_input)
    compiler_result = run_hook_and_capture(project, "post_tool_use.compilation_checker", hook_input)
    
    %{
      hook_output: formatter_result.hook_output <> "\n" <> compiler_result.hook_output,
      claude_feedback: extract_claude_feedback(formatter_result, compiler_result),
      exit_code: max(formatter_result.exit_code, compiler_result.exit_code)
    }
  end
  
  @doc """
  Simulates Claude using the Bash tool and captures hook outputs.
  """
  def simulate_claude_bash(project, %{tool: "Bash"} = bash_params) do
    hook_input = build_hook_input("PreToolUse", "Bash", %{
      "command" => bash_params.command,
      "description" => bash_params.description
    }, project)
    
    result = run_hook_and_capture(project, "pre_tool_use.pre_commit_check", hook_input)
    
    %{
      hook_output: result.hook_output,
      claude_feedback: result.hook_output,
      exit_code: result.exit_code,
      blocked: result.exit_code == 2
    }
  end
  
  @doc """
  Simulates Claude using the MultiEdit tool and captures hook outputs.
  """
  def simulate_claude_multiedit(project, %{tool: "MultiEdit"} = multiedit_params) do
    hook_input = build_hook_input("PostToolUse", "MultiEdit", %{
      "file_path" => multiedit_params.file_path,
      "edits" => multiedit_params.edits
    }, project)
    
    file_content = File.read!(multiedit_params.file_path)
    new_content = Enum.reduce(multiedit_params.edits, file_content, fn edit, content ->
      String.replace(content, edit.old_string, edit.new_string)
    end)
    File.write!(multiedit_params.file_path, new_content)
    
    run_hook_and_capture(project, "post_tool_use.elixir_formatter", hook_input)
  end
  
  defp build_hook_input(event_name, tool_name, tool_input, project) do
    %{
      "session_id" => "test_#{:erlang.phash2(make_ref())}",
      "transcript_path" => Path.join(project.root, ".claude/test_transcript.jsonl"),
      "cwd" => project.root,
      "hook_event_name" => event_name,
      "tool_name" => tool_name,
      "tool_input" => tool_input,
      "tool_response" => %{
        "success" => true,
        "filePath" => Map.get(tool_input, "file_path", "")
      }
    }
  end
  
  defp run_hook_and_capture(project, hook_identifier, hook_input) do
    json_input = Jason.encode!(hook_input)
    
    input_file = Path.join(project.root, "hook_input_#{:erlang.phash2(make_ref())}.json")
    File.write!(input_file, json_input)
    
    try do
        main_project_root = Path.expand("../..", __DIR__)
      
      {output, exit_code} = System.cmd(
        "sh",
        ["-c", "cd #{main_project_root} && cat #{input_file} | mix claude hooks run #{hook_identifier}"],
        stderr_to_stdout: true,
        env: [{"CLAUDE_PROJECT_DIR", project.root}]
      )
      
      %{
        hook_output: output,
        exit_code: exit_code,
        claude_feedback: extract_actionable_feedback(output)
      }
    after
      File.rm!(input_file)
    end
  end
  
  defp extract_actionable_feedback(output) do
    output
    |> String.split("\n")
    |> Enum.filter(&String.contains?(&1, ["Please", "run", "fix", "needs", "error", "undefined", "failed"]))
    |> Enum.join("\n")
  end
  
  defp extract_claude_feedback(formatter_result, compiler_result) do
    [formatter_result.claude_feedback, compiler_result.claude_feedback]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end
end