defmodule Claude.Test.HookTestHelpers do
  @moduledoc """
  Helper functions for testing Claude hooks.
  
  Provides utilities to reduce boilerplate in hook tests, including:
  - Test project setup
  - Common JSON input builders
  - File creation helpers
  - Environment management
  """

  @doc """
  Sets up a temporary test project with mix.exs and lib directory.
  
  Returns the test directory path.
  """
  def setup_test_project(opts \\ []) do
    test_id = Keyword.get(opts, :test_id, :erlang.phash2(make_ref()))
    dir_name = Keyword.get(opts, :dir_name, "claude_hook_test_#{test_id}")
    test_dir = Path.join(System.tmp_dir!(), dir_name)
    
    File.rm_rf!(test_dir)
    File.mkdir_p!(test_dir)
    
    mix_content = Keyword.get(opts, :mix_exs, default_mix_exs())
    File.write!(Path.join(test_dir, "mix.exs"), mix_content)
    
    File.mkdir_p!(Path.join(test_dir, "lib"))
    
    for dir <- Keyword.get(opts, :dirs, []) do
      File.mkdir_p!(Path.join(test_dir, dir))
    end
    
    for {path, content} <- Keyword.get(opts, :files, []) do
      full_path = Path.join(test_dir, path)
      File.mkdir_p!(Path.dirname(full_path))
      File.write!(full_path, content)
    end
    
    if Keyword.get(opts, :compile, true) do
      System.cmd("mix", ["compile"], cd: test_dir)
    end
    
    test_dir
  end
  
  @doc """
  Sets up the test environment for a hook test.
  
  This should be called in your test's setup block. It:
  - Creates a test project
  - Changes to the test directory
  - Sets CLAUDE_PROJECT_DIR (needed for hooks that use absolute paths)
  - Returns cleanup function for on_exit
  """
  def setup_hook_test(opts \\ []) do
    test_dir = setup_test_project(opts)
    original_cwd = File.cwd!()
    
    File.cd!(test_dir)
    System.put_env("CLAUDE_PROJECT_DIR", test_dir)
    cleanup = fn ->
      System.delete_env("CLAUDE_PROJECT_DIR")
      File.cd!(original_cwd)
      File.rm_rf!(test_dir)
    end
    
    {test_dir, cleanup}
  end
  
  @doc """
  Builds JSON input for edit tools (Edit, Write, MultiEdit).
  
  ## Options
    - :tool_name - The tool name (default: "Edit")
    - :file_path - The file path (required)
    - :content - For Write tool
    - :old_string - For Edit tool
    - :new_string - For Edit tool
    - :edits - For MultiEdit tool
    - :extra - Additional fields to include
  """
  def build_tool_input(opts) do
    tool_name = Keyword.get(opts, :tool_name, "Edit")
    file_path = Keyword.fetch!(opts, :file_path)
    
    tool_input = 
      case tool_name do
        "Write" ->
          %{
            "file_path" => file_path,
            "content" => Keyword.get(opts, :content, "")
          }
          
        "Edit" ->
          %{
            "file_path" => file_path,
            "old_string" => Keyword.get(opts, :old_string, ""),
            "new_string" => Keyword.get(opts, :new_string, "")
          }
          
        "MultiEdit" ->
          %{
            "file_path" => file_path,
            "edits" => Keyword.get(opts, :edits, [])
          }
          
        _ ->
          %{"file_path" => file_path}
      end
    
    base_input = %{
      "tool_name" => tool_name,
      "tool_input" => tool_input
    }
    
    Map.merge(base_input, Keyword.get(opts, :extra, %{}))
    |> Jason.encode!()
  end
  
  @doc """
  Creates a test Elixir module file with the given content.
  
  If content is not provided, creates a simple valid module.
  """
  def create_elixir_file(test_dir, relative_path, content \\ nil) do
    content = content || default_module_content(relative_path)
    full_path = Path.join(test_dir, relative_path)
    File.mkdir_p!(Path.dirname(full_path))
    File.write!(full_path, content)
    full_path
  end
  @doc """
  Captures stderr output from a function.
  
  This is a convenience wrapper around ExUnit.CaptureIO.capture_io/2.
  """
  def capture_stderr(fun) do
    ExUnit.CaptureIO.capture_io(:stderr, fun)
  end
  
  defp default_mix_exs do
    """
    defmodule TestProject.MixProject do
      use Mix.Project

      def project do
        [
          app: :test_project,
          version: "0.1.0",
          elixir: "~> 1.14",
          deps: deps()
        ]
      end

      def application do
        [extra_applications: [:logger]]
      end

      defp deps do
        []
      end
    end
    """
  end
  
  defp default_module_content(path) do
    module_name = path_to_module_name(path)
    
    """
    defmodule #{module_name} do
      @moduledoc false
      
      def hello(name) do
        "Hello, \#{name}!"
      end
    end
    """
  end
  
  defp path_to_module_name(path) do
    path
    |> Path.basename(".ex")
    |> Path.basename(".exs")
    |> Macro.camelize()
  end
end