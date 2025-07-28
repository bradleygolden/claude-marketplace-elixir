defmodule Claude.Integration.VerifyHooksTest do
  use Claude.Test.ClaudeCodeCase, async: false
  alias Claude.Test.ProjectBuilder
  
  @moduletag :integration
  
  test "verify hooks are installed correctly" do
    project = ProjectBuilder.build_elixir_project()
      |> ProjectBuilder.install_claude_hooks()
    
    # Check if .claude directory exists
    claude_dir = Path.join(project.root, ".claude")
    IO.puts("Claude dir exists: #{File.exists?(claude_dir)}")
    IO.puts("Claude dir: #{claude_dir}")
    
    # Check if settings.json exists
    settings_path = Path.join(claude_dir, "settings.json")
    IO.puts("Settings exists: #{File.exists?(settings_path)}")
    
    if File.exists?(settings_path) do
      content = File.read!(settings_path)
      IO.puts("Settings content:")
      IO.puts(content)
      
      # Parse and check for hooks
      case Jason.decode(content) do
        {:ok, settings} ->
          IO.puts("\nHooks found: #{Map.has_key?(settings, "hooks")}")
          if Map.has_key?(settings, "hooks") do
            IO.inspect(settings["hooks"], label: "Hooks content")
          end
        {:error, reason} ->
          IO.puts("Failed to parse settings: #{inspect(reason)}")
      end
    end
    
    # Also check for .claude.exs
    claude_exs_path = Path.join(project.root, ".claude.exs")
    IO.puts("\n.claude.exs exists: #{File.exists?(claude_exs_path)}")
    
    if File.exists?(claude_exs_path) do
      IO.puts(".claude.exs content:")
      IO.puts(File.read!(claude_exs_path))
    end
    
    on_exit(fn -> ProjectBuilder.cleanup(project) end)
  end
end