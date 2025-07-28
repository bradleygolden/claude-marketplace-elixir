defmodule Features.HooksFeatureTest do
  @moduledoc """
  Feature tests for Claude Code hooks functionality.
  
  Tests the complete user experience when using Claude Code hooks including:
  - Automatic formatting checks (PostToolUse hook)
  - Compilation validation (PostToolUse hook)
  - Pre-commit safeguards (PreToolUse hook)
  """
  use Claude.Test.ClaudeCodeCase, async: false
  
  alias Claude.Test.{FeatureHelpers, ProjectBuilder}
  
  describe "Feature: Automatic formatting checks" do
    setup do
      project = ProjectBuilder.build_elixir_project()
      {:ok, project: project}
    end
    
    test "Scenario: Claude edits an Elixir file with formatting issues", %{project: project} do
      # Given: An Elixir project with Claude hooks installed
      project
      |> ProjectBuilder.install_claude_hooks()
      
      # And: A properly formatted Elixir file exists
      file_path = Path.join(project.root, "lib/example.ex")
      File.write!(file_path, """
      defmodule Example do
        def hello(name) do
          "Hello, \#{name}!"
        end
      end
      """)
      
      # When: Claude edits the file and introduces formatting issues
      claude_edit = %{
        tool: "Edit",
        file_path: file_path,
        old_string: "def hello(name) do",
        new_string: "def hello(  name  )  do"
      }
      
      result = FeatureHelpers.simulate_claude_edit(project, claude_edit)
      
      # Then: The formatter hook warns about formatting issues
      assert result.hook_output =~ "File needs formatting"
      assert result.hook_output =~ file_path
      
      # And: The file remains unchanged (hook doesn't auto-format)
      assert File.read!(file_path) =~ "def hello(  name  )  do"
      
      # And: Claude receives feedback to run mix format
      assert result.claude_feedback =~ "File needs formatting"
    end
    
    test "Scenario: Claude uses MultiEdit to refactor files", %{project: project} do
      # Given: Multiple Elixir files exist
      project
      |> ProjectBuilder.install_claude_hooks()
      |> ProjectBuilder.create_file("lib/user.ex", """
        defmodule User do
          defstruct [:name, :email]
        end
        """)
      |> ProjectBuilder.create_file("lib/account.ex", """
        defmodule Account do
          def create_user(name, email) do
            %User{name: name, email: email}
          end
        end
        """)
      
      # When: Claude uses MultiEdit to refactor both files
      claude_multiedit = %{
        tool: "MultiEdit",
        file_path: Path.join(project.root, "lib/account.ex"),
        edits: [
          %{
            old_string: "def create_user(name, email) do",
            new_string: "def create_user(  name,email  ) do"
          }
        ]
      }
      
      result = FeatureHelpers.simulate_claude_multiedit(project, claude_multiedit)
      
      # Then: Formatting issues are detected
      assert result.hook_output =~ "File needs formatting"
      
      # And: The specific file with issues is identified
      assert result.hook_output =~ "lib/account.ex"
    end
  end
  
  describe "Feature: Compilation checking" do
    setup do
      project = ProjectBuilder.build_elixir_project()
      {:ok, project: project}
    end
    
    test "Scenario: Claude creates code with compilation errors", %{project: project} do
      # Given: An Elixir project with Claude hooks installed
      project
      |> ProjectBuilder.install_claude_hooks()
      
      # When: Claude writes a new file with compilation errors
      file_path = Path.join(project.root, "lib/broken.ex")
      claude_write = %{
        tool: "Write",
        file_path: file_path,
        content: """
        defmodule Broken do
          def calculate(x, y) do
            # Calling undefined function
            magical_function(x, y)
          end
        end
        """
      }
      
      result = FeatureHelpers.simulate_claude_write(project, claude_write)
      
      # Then: The compilation checker detects the error
      assert result.hook_output =~ "Compilation error"
      assert result.hook_output =~ "undefined function magical_function/2"
      
      # And: Claude receives actionable feedback
      assert result.claude_feedback =~ "undefined function magical_function"
    end
  end
  
  describe "Feature: Pre-commit safeguards" do
    setup do
      project = ProjectBuilder.build_elixir_project()
      |> ProjectBuilder.init_git_repo()
      {:ok, project: project}
    end
    
    test "Scenario: Preventing commits with code quality issues", %{project: project} do
      # Given: A git repository with Claude hooks installed
      project
      |> ProjectBuilder.install_claude_hooks()
      
      # And: There are unformatted files in the repository
      File.write!(Path.join(project.root, "lib/messy.ex"), """
      defmodule  Messy  do
        def hello,  do:  :world
      end
      """)
      
      System.cmd("git", ["add", "."], cd: project.root)
      
      # When: Claude tries to create a commit
      claude_command = %{
        tool: "Bash",
        command: "git commit -m \"Add new feature\"",
        description: "Creating a commit"
      }
      
      result = FeatureHelpers.simulate_claude_bash(project, claude_command)
      
      # Then: The pre-commit hook blocks the commit
      assert result.blocked == true
      assert result.exit_code == 2
      
      # And: Claude receives clear feedback about what needs fixing
      assert result.hook_output =~ "Formatting check failed!"
      assert result.hook_output =~ "lib/messy.ex"
      assert result.hook_output =~ "Please run 'mix format'"
      
      # And: No commit was created
      {log_output, _} = System.cmd("git", ["log", "--oneline"], cd: project.root)
      refute log_output =~ "Add new feature"
    end
    
    test "Scenario: Successful commit with clean code", %{project: project} do
      # Given: A git repository with Claude hooks installed
      project
      |> ProjectBuilder.install_claude_hooks()
      
      # And: All files are properly formatted and compile
      File.write!(Path.join(project.root, "lib/clean.ex"), """
      defmodule Clean do
        def hello, do: :world
      end
      """)
      
      System.cmd("git", ["add", "."], cd: project.root)
      
      # When: Claude creates a commit
      claude_command = %{
        tool: "Bash", 
        command: "git commit -m \"Add clean feature\"",
        description: "Creating a commit"
      }
      
      result = FeatureHelpers.simulate_claude_bash(project, claude_command)
      
      # Then: The commit succeeds
      assert result.blocked == false
      assert result.exit_code == 0
      
      # And: Claude sees the validation progress
      assert result.hook_output =~ "Pre-commit validation triggered"
      assert result.hook_output =~ "Code formatting is correct"
      assert result.hook_output =~ "Compilation successful"
      assert result.hook_output =~ "No unused dependencies found"
    end
  end
  
  describe "Feature: Hook configuration" do
    setup do
      project = ProjectBuilder.build_elixir_project()
      {:ok, project: project}
    end
    
    test "Scenario: Hooks are properly configured in settings.json", %{project: project} do
      # Given: A project without hooks
      settings_path = Path.join(project.root, ".claude/settings.json")
      refute File.exists?(settings_path)
      
      # When: Claude hooks are installed
      project |> ProjectBuilder.install_claude_hooks()
      
      # Then: Settings file is created with proper hook configuration
      assert File.exists?(settings_path)
      settings = Jason.decode!(File.read!(settings_path))
      
      # And: PostToolUse hooks are configured for file edits
      assert Map.has_key?(settings["hooks"], "PostToolUse")
      post_hooks = settings["hooks"]["PostToolUse"]
      assert Enum.any?(post_hooks, &(&1["matcher"] == "Write|Edit|MultiEdit"))
      
      # And: PreToolUse hooks are configured for Bash commands
      assert Map.has_key?(settings["hooks"], "PreToolUse")
      pre_hooks = settings["hooks"]["PreToolUse"]
      assert Enum.any?(pre_hooks, &(&1["matcher"] == "Bash"))
    end
  end
end