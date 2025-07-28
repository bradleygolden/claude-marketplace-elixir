defmodule Claude.Integration.ClaudeCodeHooksTest do
  use Claude.Test.ClaudeCodeCase, async: false
  
  import Claude.Test.TelemetryHelpers
  import Claude.Test.ClaudeCodeHelpers
  alias Claude.Test.ProjectBuilder
  
  @moduletag :integration
  @moduletag timeout: 120_000  # 2 minutes for integration tests
  
  setup do
    setup_telemetry()
  end
  
  describe "PostToolUse hooks - Elixir formatter" do
    setup do
      # Create a shared project for formatter tests
      project = ProjectBuilder.build_elixir_project()
        |> ProjectBuilder.install_claude_hooks()
        |> ProjectBuilder.compile()
      
      on_exit(fn -> ProjectBuilder.cleanup(project) end)
      
      {:ok, project: project}
    end
    
    test "formatter runs on Write tool for new files", %{project: project} do
      timestamp = System.unique_integer([:positive])
      file_name = "lib/formatter_test_#{timestamp}.ex"
      
      {:ok, _output} = claude_create_file(
        file_name,
        """
        Create a module FormatterTest#{timestamp} with a function greet/1 that takes a name 
        and returns "Hello, " concatenated with the name. Use poor formatting.
        """,
        project
      )
      
      # Assert formatter hook executed
      {measurements, _metadata} = assert_hook_success("post_tool_use.elixir_formatter",
        tool_name: "Write"
      )
      
      # Verify file exists and is properly formatted
      content = File.read!(Path.join(project.root, file_name))
      assert content =~ ~r/def greet\(name\) do/  # Properly formatted
      assert content =~ "\"Hello, \" <>"  # Elixir string concatenation
      assert measurements.duration < 1_000_000_000  # Less than 1 second
    end
    
    test "formatter runs on Edit tool for existing files", %{project: project} do
      timestamp = System.unique_integer([:positive])
      file_name = "lib/edit_test_#{timestamp}.ex"
      
      # Create initial file with poor formatting
      initial_content = """
      defmodule EditTest#{timestamp} do
        def   add(  a,b  )   do
          a+b
        end
      end
      """
      
      {:ok, _output} = claude_edit_file(
        file_name,
        initial_content,
        "Add a subtract/2 function that subtracts b from a",
        project
      )
      
      # Assert formatter ran on edit
      {_, _metadata} = assert_hook_success("post_tool_use.elixir_formatter",
        tool_name: "Edit"
      )
      
      # Verify formatting was applied
      content = File.read!(Path.join(project.root, file_name))
      assert content =~ ~r/def add\(a, b\) do/  # Formatted spacing
      assert content =~ ~r/def subtract\(a, b\) do/  # New function also formatted
    end
    
    test "formatter handles multiple files created in one operation", %{project: project} do
      timestamp = System.unique_integer([:positive])
      
      {:ok, _output} = run_claude(
        """
        Create two modules:
        1. lib/producer_#{timestamp}.ex with Producer#{timestamp} module containing a generate/0 function that returns a random number
        2. lib/consumer_#{timestamp}.ex with Consumer#{timestamp} module containing a consume/1 function that doubles the input
        """,
        project,
        allowed_tools: ["Write"]
      )
      
      # Wait for both formatter executions
      events = wait_for_events(2, fn {event, _, meta} ->
        event == [:claude, :hook, :stop] && 
        meta.hook_identifier == "post_tool_use.elixir_formatter" &&
        String.contains?(to_string(meta[:tool_input][:file_path] || ""), "#{timestamp}")
      end)
      
      assert length(events) == 2
      
      # Verify both files exist and are formatted
      for file <- ["producer_#{timestamp}.ex", "consumer_#{timestamp}.ex"] do
        path = Path.join([project.root, "lib", file])
        assert File.exists?(path)
        content = File.read!(path)
        assert content =~ ~r/defmodule/  # Has module definition
        assert content =~ ~r/def \w+\(/  # Has properly formatted function
      end
    end
  end
  
  describe "PostToolUse hooks - Compilation checker" do
    setup do
      project = ProjectBuilder.build_elixir_project()
        |> ProjectBuilder.install_claude_hooks()
        |> ProjectBuilder.compile()
      
      on_exit(fn -> ProjectBuilder.cleanup(project) end)
      
      {:ok, project: project}
    end
    
    test "compilation checker runs after file creation", %{project: project} do
      timestamp = System.unique_integer([:positive])
      
      {:ok, _output} = claude_create_file(
        "lib/valid_module_#{timestamp}.ex",
        """
        Create a module ValidModule#{timestamp} with:
        - A function double/1 that multiplies the input by 2
        - A function triple/1 that calls double/1 and adds the original value
        """,
        project
      )
      
      # Both hooks should run
      assert_hook_success("post_tool_use.elixir_formatter")
      {_, meta} = assert_hook_success("post_tool_use.compilation_checker")
      
      assert meta.result == :ok
      assert meta.tool_name == "Write"
    end
    
    test "compilation checker handles modules with warnings", %{project: project} do
      timestamp = System.unique_integer([:positive])
      
      {:ok, _output} = claude_create_file(
        "lib/warning_module_#{timestamp}.ex",
        """
        Create a module WarningModule#{timestamp} with:
        - A private function helper/1 that returns its input
        - A public function process/1 that returns :ok without using helper/1
        This should create an unused function warning.
        """,
        project
      )
      
      # Compilation checker should still complete
      assert_hook_success("post_tool_use.compilation_checker")
      
      # Output might contain warning about unused function
      # (Claude might optimize this away, so we don't assert on warnings)
    end
    
    test "compilation checker with module dependencies", %{project: project} do
      timestamp = System.unique_integer([:positive])
      
      # Create first module
      {:ok, _} = claude_create_file(
        "lib/base_#{timestamp}.ex",
        "Create module Base#{timestamp} with a function value/0 that returns 42",
        project
      )
      
      # Create dependent module
      {:ok, _} = claude_create_file(
        "lib/dependent_#{timestamp}.ex",
        """
        Create module Dependent#{timestamp} with a function calculate/0 
        that calls Base#{timestamp}.value/0 and multiplies the result by 2
        """,
        project,
        allowed_tools: ["Write", "Read", "Grep"]  # Might need to find the base module
      )
      
      # Both files should compile successfully
      events = collect_telemetry_events()
      
      compilation_events = Enum.filter(events, fn {event, _, meta} ->
        event == [:claude, :hook, :stop] && 
        meta.hook_identifier == "post_tool_use.compilation_checker" &&
        String.contains?(to_string(meta[:tool_input][:file_path] || ""), "#{timestamp}")
      end)
      
      assert length(compilation_events) >= 2
      Enum.each(compilation_events, fn {_, _, meta} ->
        assert meta.result == :ok
      end)
    end
  end
  
  describe "PreToolUse hooks - Pre-commit check" do
    setup do
      project = ProjectBuilder.build_elixir_project()
        |> ProjectBuilder.install_claude_hooks()
        |> ProjectBuilder.init_git_repo()
        |> ProjectBuilder.create_file("README.md", "# Test Project")
        |> ProjectBuilder.git_add_all()
        |> ProjectBuilder.git_commit("Initial commit")
      
      on_exit(fn -> ProjectBuilder.cleanup(project) end)
      
      {:ok, project: project}
    end
    
    test "pre-commit check runs before git commit", %{project: project} do
      timestamp = System.unique_integer([:positive])
      
      # Create a new branch for this test
      System.cmd("git", ["checkout", "-b", "feature-#{timestamp}"], cd: project.root)
      
      # Create and stage a new file
      ProjectBuilder.create_file(project, "lib/feature_#{timestamp}.ex", """
      defmodule Feature#{timestamp} do
        @moduledoc "A test feature"
        
        def execute(data) do
          {:ok, data}
        end
      end
      """)
      
      System.cmd("git", ["add", "."], cd: project.root)
      
      # Commit through Claude
      {:ok, _output} = claude_bash(
        "git commit -m 'Add feature #{timestamp}'",
        project,
        bash_pattern: "git commit*"
      )
      
      # Pre-commit hook should have executed
      {_, metadata} = assert_hook_success("pre_tool_use.pre_commit_check",
        tool_name: "Bash"
      )
      
      assert metadata.hook_event == :pre_tool_use
      
      # Verify commit was created
      {log_output, 0} = System.cmd("git", ["log", "--oneline", "-1"], cd: project.root)
      assert log_output =~ "Add feature #{timestamp}"
    end
    
    test "pre-commit check with multiple staged files", %{project: project} do
      timestamp = System.unique_integer([:positive])
      
      # Create a new branch
      System.cmd("git", ["checkout", "-b", "multi-file-#{timestamp}"], cd: project.root)
      
      # Create multiple files
      _files = for i <- 1..3 do
        filename = "lib/module_#{timestamp}_#{i}.ex"
        ProjectBuilder.create_file(project, filename, """
        defmodule Module#{timestamp}#{i} do
          def id, do: #{i}
        end
        """)
        filename
      end
      
      # Stage all files
      System.cmd("git", ["add", "."], cd: project.root)
      
      # Commit through Claude
      {:ok, _output} = claude_bash(
        "git commit -m 'Add multiple modules #{timestamp}'",
        project,
        bash_pattern: "git commit*"
      )
      
      # Pre-commit hook should have run once
      assert_hook_success("pre_tool_use.pre_commit_check")
      
      # Verify all files were committed
      {status_output, 0} = System.cmd("git", ["status", "--porcelain"], cd: project.root)
      assert status_output == ""  # No uncommitted changes
    end
  end
  
  describe "Complex multi-tool scenarios" do
    setup do
      project = ProjectBuilder.build_elixir_project()
        |> ProjectBuilder.install_claude_hooks()
        |> ProjectBuilder.add_dependency({:jason, "~> 1.4"})
        |> ProjectBuilder.fetch_deps()
        |> ProjectBuilder.compile()
        |> ProjectBuilder.init_git_repo()
        |> ProjectBuilder.git_add_all()
        |> ProjectBuilder.git_commit("Initial setup")
      
      on_exit(fn -> ProjectBuilder.cleanup(project) end)
      
      {:ok, project: project}
    end
    
    test "create API endpoint with JSON handling", %{project: project} do
      timestamp = System.unique_integer([:positive])
      
      {:ok, _output} = run_claude(
        """
        Create a module lib/api_endpoint_#{timestamp}.ex with:
        1. A module ApiEndpoint#{timestamp}
        2. A handle_request/1 function that:
           - Takes a JSON string as input
           - Parses it using Jason
           - Extracts a "command" field
           - Returns {:ok, response} or {:error, reason}
        3. Include proper error handling for invalid JSON
        """,
        project,
        allowed_tools: ["Write", "Read", "Grep"]
      )
      
      # Verify hooks executed
      assert_hook_success("post_tool_use.elixir_formatter")
      assert_hook_success("post_tool_use.compilation_checker")
      
      # Verify the file works correctly
      content = File.read!(Path.join(project.root, "lib/api_endpoint_#{timestamp}.ex"))
      assert content =~ "Jason.decode"
      assert content =~ "handle_request"
      assert content =~ "{:ok,"
      assert content =~ "{:error,"
    end
    
    test "refactor existing code across multiple files", %{project: project} do
      timestamp = System.unique_integer([:positive])
      
      # Create initial files
      ProjectBuilder.create_file(project, "lib/data_#{timestamp}.ex", """
      defmodule Data#{timestamp} do
        def get_value, do: 100
        def get_multiplier, do: 2
      end
      """)
      
      ProjectBuilder.create_file(project, "lib/calculator_#{timestamp}.ex", """
      defmodule Calculator#{timestamp} do
        def calculate do
          Data#{timestamp}.get_value() * Data#{timestamp}.get_multiplier()
        end
      end
      """)
      
      # Ask Claude to refactor
      {:ok, _output} = run_claude(
        """
        Refactor the code:
        1. Find all files containing Data#{timestamp} or Calculator#{timestamp}
        2. In Data#{timestamp}, rename get_value/0 to base_value/0
        3. In Data#{timestamp}, rename get_multiplier/0 to scaling_factor/0  
        4. Update Calculator#{timestamp} to use the new function names
        """,
        project,
        allowed_tools: ["Grep", "Read", "Edit", "MultiEdit"]
      )
      
      # Should have triggered multiple edit operations
      events = collect_telemetry_events()
      
      edit_events = Enum.filter(events, fn {event, _, meta} ->
        event == [:claude, :hook, :stop] &&
        meta.hook_identifier == "post_tool_use.elixir_formatter" &&
        (meta[:tool_name] == "Edit" || meta[:tool_name] == "MultiEdit") &&
        String.contains?(to_string(meta[:tool_input][:file_path] || ""), "#{timestamp}")
      end)
      
      assert length(edit_events) >= 1  # At least one edit operation
      
      # Verify the refactoring worked
      data_content = File.read!(Path.join(project.root, "lib/data_#{timestamp}.ex"))
      calc_content = File.read!(Path.join(project.root, "lib/calculator_#{timestamp}.ex"))
      
      assert data_content =~ "def base_value"
      assert data_content =~ "def scaling_factor"
      assert calc_content =~ "base_value()"
      assert calc_content =~ "scaling_factor()"
    end
    
    test "create, test, and commit a feature", %{project: project} do
      timestamp = System.unique_integer([:positive])
      
      # Create feature branch
      System.cmd("git", ["checkout", "-b", "feature-complete-#{timestamp}"], cd: project.root)
      
      # Create feature module
      {:ok, _} = claude_create_file(
        "lib/string_utils_#{timestamp}.ex",
        """
        Create StringUtils#{timestamp} module with:
        - reverse/1 that reverses a string
        - capitalize_words/1 that capitalizes each word in a string
        - word_count/1 that counts words in a string
        """,
        project
      )
      
      # Create test file
      {:ok, _} = claude_create_file(
        "test/string_utils_#{timestamp}_test.exs",
        """
        Create a test file for StringUtils#{timestamp} with:
        - Test cases for reverse/1 with "hello" -> "olleh"
        - Test cases for capitalize_words/1 with "hello world" -> "Hello World"  
        - Test cases for word_count/1 with "hello world" -> 2
        """,
        project
      )
      
      # Stage and commit
      System.cmd("git", ["add", "."], cd: project.root)
      
      {:ok, _} = claude_bash(
        "git commit -m 'Add StringUtils with tests'",
        project,
        bash_pattern: "git commit*"
      )
      
      # Verify all hooks ran
      events = collect_telemetry_events()
      
      # Should have formatter runs for both files
      formatter_events = Enum.filter(events, fn {_, _, meta} ->
        meta[:hook_identifier] == "post_tool_use.elixir_formatter" &&
        String.contains?(to_string(meta[:tool_input][:file_path] || ""), "#{timestamp}")
      end)
      
      assert length(formatter_events) >= 2
      
      # Should have pre-commit check
      pre_commit_events = Enum.filter(events, fn {_, _, meta} ->
        meta[:hook_identifier] == "pre_tool_use.pre_commit_check"
      end)
      
      assert length(pre_commit_events) >= 1
    end
  end
  
  describe "Hook error handling" do
    setup do
      project = ProjectBuilder.build_elixir_project()
        |> ProjectBuilder.install_claude_hooks()
      
      on_exit(fn -> ProjectBuilder.cleanup(project) end)
      
      {:ok, project: project}
    end
    
    test "hooks continue execution even with syntax errors", %{project: project} do
      timestamp = System.unique_integer([:positive])
      
      # Ask Claude to create a file with intentional syntax error
      {:ok, _output} = run_claude(
        """
        Create lib/syntax_error_#{timestamp}.ex with invalid Elixir syntax.
        Include: defmodule SyntaxError#{timestamp} do
        But leave out the closing 'end'
        """,
        project,
        allowed_tools: ["Write"]
      )
      
      # Hooks should still attempt to run
      events = collect_telemetry_events()
      
      # Look for any hook events related to this file
      related_events = Enum.filter(events, fn {_, _, meta} ->
        String.contains?(to_string(meta[:tool_input][:file_path] || ""), "syntax_error_#{timestamp}")
      end)
      
      # We should see at least start events for the hooks
      assert length(related_events) > 0
    end
  end
  
  describe "Permission edge cases" do
    setup do
      project = ProjectBuilder.build_elixir_project()
        |> ProjectBuilder.install_claude_hooks()
      
      on_exit(fn -> ProjectBuilder.cleanup(project) end)
      
      {:ok, project: project}
    end
    
    test "hooks don't run when tool is not permitted", %{project: project} do
      # Try to edit without permission
      {:error, _exit_code, output} = run_claude(
        "Edit lib/test.ex and add a comment",
        project,
        allowed_tools: ["Read"]  # No Edit permission
      )
      
      # Should indicate permission issue
      assert output =~ "Edit" || output =~ "permission" || output =~ "tool"
      
      # No edit hooks should have triggered
      Process.sleep(100)  # Give time for any events
      events = collect_telemetry_events()
      
      edit_events = Enum.filter(events, fn {_, _, meta} ->
        meta[:tool_name] == "Edit"
      end)
      
      assert length(edit_events) == 0
    end
    
    test "mixed permissions work correctly", %{project: project} do
      timestamp = System.unique_integer([:positive])
      
      # Create a file first
      ProjectBuilder.create_file(project, "lib/base_#{timestamp}.ex", """
      defmodule Base#{timestamp} do
        def value, do: 1
      end
      """)
      
      # Now use Claude with mixed permissions
      {:ok, _output} = run_claude(
        """
        1. Read lib/base_#{timestamp}.ex to see what value it returns
        2. Create lib/derived_#{timestamp}.ex that imports Base#{timestamp} and has a function double_value/0 that returns twice the base value
        3. List all .ex files in lib/
        """,
        project,
        allowed_tools: ["Read", "Write", "LS"]
      )
      
      # Verify appropriate hooks ran
      events = collect_telemetry_events()
      
      # Should see Write tool usage for creating derived file
      write_events = Enum.filter(events, fn {_, _, meta} ->
        meta[:tool_name] == "Write" &&
        String.contains?(to_string(meta[:tool_input][:file_path] || ""), "derived_#{timestamp}")
      end)
      
      assert length(write_events) > 0
      
      # Formatter should have run on the new file
      assert_hook_success("post_tool_use.elixir_formatter", tool_name: "Write")
    end
  end
end