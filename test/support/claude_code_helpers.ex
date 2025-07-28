defmodule Claude.Test.ClaudeCodeHelpers do
  @moduledoc """
  Helpers for invoking Claude Code in integration tests.
  
  This module provides utilities for running Claude Code commands
  with proper permissions and project isolation.
  """
  
  @doc """
  Runs Claude Code with a prompt in a specific project directory.
  
  ## Options
  
    * `:allowed_tools` - List of tools to allow (default: basic file operations)
    * `:extra_args` - Additional command line arguments
    * `:timeout` - Command timeout in milliseconds (default: 30_000)
  
  ## Examples
  
      # Basic usage
      {:ok, output} = run_claude("Create a hello.ex file", project)
      
      # With specific tools
      {:ok, output} = run_claude(
        "Edit the file",
        project,
        allowed_tools: ["Read", "Edit"]
      )
      
      # With extra arguments
      {:ok, output} = run_claude(
        "Explain this code",
        project,
        extra_args: ["--verbose"]
      )
  """
  def run_claude(prompt, project, opts \\ []) do
    # Default allowed tools for basic operations
    default_allowed_tools = [
      "Read",
      "Write", 
      "Edit",
      "MultiEdit",
      "Grep",
      "Glob",
      "LS"
    ]
    
    allowed_tools = Keyword.get(opts, :allowed_tools, default_allowed_tools)
    timeout = Keyword.get(opts, :timeout, 30_000)
    
    # Build command with print mode
    cmd_args = ["-p", prompt]
    
    # Add allowed tools
    cmd_args = Enum.reduce(allowed_tools, cmd_args, fn tool, acc ->
      acc ++ ["--allowedTools", tool]
    end)
    
    # Add extra args if any
    cmd_args = cmd_args ++ Keyword.get(opts, :extra_args, [])
    
    # Set up environment to point to test project
    env = [
      {"CLAUDE_PROJECT_DIR", project.root},
      {"PATH", System.get_env("PATH")}
    ]
    
    # Find claude executable
    claude_path = find_claude_executable()
    
    # Run claude command
    case System.cmd(claude_path, cmd_args, 
           env: env, 
           stderr_to_stdout: true,
           timeout: timeout) do
      {output, 0} -> 
        {:ok, output}
      {output, exit_code} -> 
        {:error, exit_code, output}
    end
  rescue
    e -> 
      {:error, :command_failed, Exception.message(e)}
  end
  
  @doc """
  Creates a test file and asks Claude to edit it with appropriate permissions.
  
  ## Examples
  
      claude_edit_file(
        "lib/test.ex",
        "defmodule Test do\\nend",
        "Add a hello/0 function",
        project
      )
  """
  def claude_edit_file(file_path, initial_content, edit_prompt, project, opts \\ []) do
    # Ensure file path is relative to project
    full_path = Path.join(project.root, file_path)
    
    # Create parent directory if needed
    full_path |> Path.dirname() |> File.mkdir_p!()
    
    # Create the file
    File.write!(full_path, initial_content)
    
    # Ensure Edit tool is allowed
    current_allowed = Keyword.get(opts, :allowed_tools, ["Read", "Write", "Edit", "MultiEdit"])
    opts = Keyword.put(opts, :allowed_tools, Enum.uniq(["Edit", "Read" | current_allowed]))
    
    # Ask Claude to edit it
    prompt = "Edit the file at #{file_path}. #{edit_prompt}"
    run_claude(prompt, project, opts)
  end
  
  @doc """
  Runs Claude with Bash tool permission.
  
  ## Options
  
    * `:bash_pattern` - Pattern to restrict bash commands (e.g., "git commit*")
    * All other options from `run_claude/3`
  
  ## Examples
  
      # Run any bash command
      claude_bash("ls -la", project)
      
      # Run specific git commands only
      claude_bash(
        "git commit -m 'Initial commit'",
        project,
        bash_pattern: "git commit*"
      )
  """
  def claude_bash(command, project, opts \\ []) do
    # Build bash permission string
    bash_permission = case Keyword.get(opts, :bash_pattern) do
      nil -> "Bash"
      pattern -> "Bash(#{pattern})"
    end
    
    # Add Bash to allowed tools
    current_allowed = Keyword.get(opts, :allowed_tools, [])
    opts = Keyword.put(opts, :allowed_tools, [bash_permission | current_allowed])
    
    prompt = "Run this command: #{command}"
    run_claude(prompt, project, opts)
  end
  
  @doc """
  Runs Claude to create a new file with specific content.
  
  ## Examples
  
      claude_create_file(
        "lib/calculator.ex",
        "Create a Calculator module with add/2 and subtract/2 functions",
        project
      )
  """
  def claude_create_file(file_path, description, project, opts \\ []) do
    # Ensure Write tool is allowed
    current_allowed = Keyword.get(opts, :allowed_tools, ["Write"])
    opts = Keyword.put(opts, :allowed_tools, Enum.uniq(["Write" | current_allowed]))
    
    prompt = "Create a file at #{file_path}. #{description}"
    run_claude(prompt, project, opts)
  end
  
  @doc """
  Runs Claude to search for files or patterns.
  
  ## Examples
  
      # Search for pattern in files
      claude_search("TODO", project, tool: :grep)
      
      # Find files by pattern
      claude_search("*.ex", project, tool: :glob)
  """
  def claude_search(pattern, project, opts \\ []) do
    tool = Keyword.get(opts, :tool, :grep)
    
    {prompt, tools} = case tool do
      :grep -> 
        {"Search for '#{pattern}' in all files", ["Grep"]}
      :glob -> 
        {"Find all files matching pattern '#{pattern}'", ["Glob"]}
      _ -> 
        raise ArgumentError, "Unknown search tool: #{tool}"
    end
    
    opts = Keyword.put(opts, :allowed_tools, tools)
    run_claude(prompt, project, opts)
  end
  
  # Private functions
  
  defp find_claude_executable do
    # First try to find in PATH
    case System.find_executable("claude") do
      nil ->
        # Try common installation locations
        paths = [
          "/usr/local/bin/claude",
          "/opt/homebrew/bin/claude",
          Path.expand("~/.local/bin/claude")
        ]
        
        Enum.find(paths, &File.exists?/1) || 
          raise """
          Claude executable not found. Please ensure Claude Code is installed and in your PATH.
          
          Installation instructions: https://docs.anthropic.com/en/docs/claude-code/quickstart
          
          For integration tests to work, Claude Code must be installed.
          """
      path -> 
        path
    end
  end
end