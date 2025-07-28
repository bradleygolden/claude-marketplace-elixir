defmodule Claude.Test.ProjectBuilder do
  @moduledoc """
  Builder pattern for creating test Elixir projects with various configurations.
  
  Provides a fluent API for setting up test projects with Claude hooks,
  git repositories, and various file structures.
  """
  
  defstruct [:root, :name, :files, :hooks_installed, :git_initialized]
  
  @doc """
  Creates a new test project in a temporary directory using mix new.
  """
  def build_elixir_project(name \\ nil) do
    name = name || "test_project_#{:erlang.phash2(make_ref())}"
    parent_dir = System.tmp_dir!()
    root = Path.join(parent_dir, name)
    
    File.rm_rf!(root)
    
    # The --module flag avoids interactive prompts
    {output, 0} = System.cmd("mix", ["new", name, "--module", Macro.camelize(name)], 
      cd: parent_dir,
      stderr_to_stdout: true
    )
    
    unless File.exists?(root) do
      raise "Failed to create project: #{output}"
    end
    
    %__MODULE__{
      root: root,
      name: name,
      files: [],
      hooks_installed: false,
      git_initialized: false
    }
  end
  
  @doc """
  Installs Claude hooks in the test project.
  """
  def install_claude_hooks(%__MODULE__{} = project) do
    main_project_root = Path.expand("../..", __DIR__)
    
    System.cmd(
      "mix",
      ["claude", "hooks", "install"],
      cd: main_project_root,
      env: [{"CLAUDE_PROJECT_DIR", project.root}]
    )
    
    %{project | hooks_installed: true}
  end
  
  @doc """
  Initializes a git repository in the test project.
  """
  def init_git_repo(%__MODULE__{} = project) do
    System.cmd("git", ["init"], cd: project.root)
    System.cmd("git", ["config", "user.email", "test@example.com"], cd: project.root)
    System.cmd("git", ["config", "user.name", "Test User"], cd: project.root)
    
    %{project | git_initialized: true}
  end
  
  @doc """
  Creates a file in the test project.
  """
  def create_file(%__MODULE__{} = project, relative_path, content) do
    file_path = Path.join(project.root, relative_path)
    File.mkdir_p!(Path.dirname(file_path))
    File.write!(file_path, content)
    
    %{project | files: [relative_path | project.files]}
  end
  
  @doc """
  Creates multiple files in the test project.
  """
  def create_files(%__MODULE__{} = project, files) do
    Enum.reduce(files, project, fn {path, content}, proj ->
      create_file(proj, path, content)
    end)
  end
  
  @doc """
  Adds a dependency to the test project.
  """
  def add_dependency(%__MODULE__{} = project, dep_spec) do
    mix_file = Path.join(project.root, "mix.exs")
    content = File.read!(mix_file)
    
    new_content = String.replace(content, "defp deps do\n    [\n", 
      "defp deps do\n    [\n      #{inspect(dep_spec)},\n")
    
    File.write!(mix_file, new_content)
    project
  end
  
  @doc """
  Runs mix deps.get in the project.
  """
  def fetch_deps(%__MODULE__{} = project) do
    System.cmd("mix", ["deps.get"], cd: project.root)
    project
  end
  
  @doc """
  Stages all files in git.
  """
  def git_add_all(%__MODULE__{git_initialized: true} = project) do
    System.cmd("git", ["add", "."], cd: project.root)
    project
  end
  
  @doc """
  Creates an initial git commit.
  """
  def git_commit(%__MODULE__{git_initialized: true} = project, message) do
    System.cmd("git", ["commit", "-m", message], cd: project.root)
    project
  end
  
  @doc """
  Cleans up the test project.
  """
  def cleanup(%__MODULE__{} = project) do
    File.rm_rf!(project.root)
  end
end