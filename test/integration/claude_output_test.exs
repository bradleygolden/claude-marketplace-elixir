defmodule Claude.Integration.ClaudeOutputTest do
  use Claude.Test.ClaudeCodeCase, async: false
  
  import Claude.Test.TelemetryHelpers
  import Claude.Test.ClaudeCodeHelpers
  alias Claude.Test.ProjectBuilder
  
  @moduletag :integration
  
  setup do
    setup_telemetry()
  end
  
  test "check Claude output for file creation" do
    project = ProjectBuilder.build_elixir_project()
      |> ProjectBuilder.install_claude_hooks()
    
    IO.puts("\n=== Running Claude to create file ===")
    IO.puts("Project root: #{project.root}")
    
    # Run Claude with verbose output
    result = run_claude(
      "Create a file test.txt with content 'Hello World'",
      project,
      allowed_tools: ["Write"],
      extra_args: ["--verbose"]
    )
    
    case result do
      {:ok, output} ->
        IO.puts("Success! Output:")
        IO.puts(output)
        
        # Check if file was created
        file_path = Path.join(project.root, "test.txt")
        IO.puts("\nFile exists in project: #{File.exists?(file_path)}")
        
        if File.exists?(file_path) do
          IO.puts("File content: #{File.read!(file_path)}")
        end
        
        # Check current directory too
        cwd_file = Path.join(File.cwd!(), "test.txt")
        IO.puts("File exists in cwd: #{File.exists?(cwd_file)}")
        if File.exists?(cwd_file) do
          IO.puts("CWD file content: #{File.read!(cwd_file)}")
        end
        
        # List files in project root
        IO.puts("\nFiles in project root:")
        File.ls!(project.root) |> Enum.each(&IO.puts/1)
        
      {:error, code, output} ->
        IO.puts("Error! Exit code: #{code}")
        IO.puts("Output:")
        IO.puts(output)
    end
    
    # Give hooks time to run
    Process.sleep(1000)
    
    # Check telemetry events
    events = collect_telemetry_events()
    IO.puts("\nTelemetry events received: #{length(events)}")
    
    for {event, measurements, metadata} <- events do
      IO.puts("Event: #{inspect(event)}")
      if metadata[:hook_identifier] do
        IO.puts("  Hook: #{metadata.hook_identifier}")
        IO.puts("  Tool: #{metadata[:tool_name]}")
      end
    end
    
    on_exit(fn -> ProjectBuilder.cleanup(project) end)
  end
end