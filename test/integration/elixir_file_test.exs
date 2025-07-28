defmodule Claude.Integration.ElixirFileTest do
  use Claude.Test.ClaudeCodeCase, async: false
  
  import Claude.Test.TelemetryHelpers
  import Claude.Test.ClaudeCodeHelpers
  alias Claude.Test.ProjectBuilder
  
  @moduletag :integration
  @moduletag timeout: 30_000
  
  setup do
    setup_telemetry()
  end
  
  test "create Elixir file triggers formatter hook" do
    project = ProjectBuilder.build_elixir_project()
      |> ProjectBuilder.install_claude_hooks()
      |> ProjectBuilder.compile()
    
    IO.puts("\n=== Creating Elixir file ===")
    IO.puts("Project root: #{project.root}")
    
    # Create an Elixir file with poor formatting
    result = run_claude(
      """
      Create a file lib/test_module.ex with this content:
      defmodule TestModule do
      def hello(name) do
      "Hello, \#{name}"
      end
      end
      """,
      project,
      allowed_tools: ["Write"]
    )
    
    case result do
      {:ok, output} ->
        IO.puts("Claude output: #{output}")
        
        # Check if file was created
        file_path = Path.join(project.root, "lib/test_module.ex")
        
        if File.exists?(file_path) do
          IO.puts("\nFile content:")
          IO.puts(File.read!(file_path))
        end
        
      {:error, code, output} ->
        IO.puts("Error! Exit code: #{code}")
        IO.puts("Output: #{output}")
    end
    
    # Give hooks time to potentially run
    Process.sleep(2000)
    
    # Check telemetry events
    events = collect_telemetry_events()
    IO.puts("\nTelemetry events received: #{length(events)}")
    
    for {event, _measurements, metadata} <- events do
      if metadata[:hook_identifier] do
        IO.puts("Hook event: #{inspect(event)} - #{metadata.hook_identifier}")
      end
    end
    
    on_exit(fn -> ProjectBuilder.cleanup(project) end)
  end
end