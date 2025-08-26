defmodule Claude.Plugins.PhoenixTest do
  use Claude.ClaudeCodeCase

  alias Claude.Plugins.Phoenix

  setup do
    Mimic.copy(Igniter.Project.Deps)
    Mimic.copy(Igniter.Project.Module)
    Mimic.copy(File)
    :ok
  end

  defp mock_phoenix_project(igniter, version, deps) do
    stub(Igniter.Project.Deps, :has_dep?, fn ^igniter, dep ->
      case dep do
        :phoenix -> true
        :ecto -> :ecto in deps
        :ecto_sql -> :ecto_sql in deps
        :phoenix_live_view -> :phoenix_live_view in deps
        _ -> false
      end
    end)

    expect(Igniter.Project.Module, :module_name_prefix, fn ^igniter -> MyApp end)

    expect(File, :read, fn "mix.lock" ->
      {:ok, ~s|"phoenix": {:hex, :phoenix, "#{version}", [], :hexpm}|}
    end)

    igniter
  end

  describe "config/1 - Phoenix >= 1.8" do
    test "includes usage rules for Phoenix 1.8" do
      igniter = Igniter.new()
      mock_phoenix_project(igniter, "1.8.0", [])

      result = Phoenix.config(igniter: igniter)

      assert %{
               mcp_servers: [tidewave: [port: "${PORT:-4000}"]],
               nested_memories: %{
                 "test" => ["usage_rules:elixir", "usage_rules:otp"],
                 "lib/my_app" => ["usage_rules:elixir", "usage_rules:otp"],
                 "lib/my_app_web" => [
                   {:url, "https://daisyui.com/llms.txt",
                    as: "DaisyUI Component Library", cache: "./ai/daisyui/llms.md"},
                   "usage_rules:elixir",
                   "usage_rules:otp",
                   "phoenix:phoenix",
                   "phoenix:html",
                   "phoenix:elixir"
                 ]
               }
             } = result
    end

    test "includes usage_rules system for Phoenix 1.8.0" do
      igniter = Igniter.new()
      mock_phoenix_project(igniter, "1.8.0", [])

      result = Phoenix.config(igniter: igniter)

      assert "usage_rules:elixir" in result.nested_memories["test"]
      assert "usage_rules:otp" in result.nested_memories["test"]
      assert "usage_rules:elixir" in result.nested_memories["lib/my_app"]
      assert "usage_rules:elixir" in result.nested_memories["lib/my_app_web"]
    end
  end

  describe "config/1 - Phoenix 1.7" do
    test "includes universal usage rules but no phoenix-specific rules for Phoenix 1.7.x" do
      igniter = Igniter.new()
      mock_phoenix_project(igniter, "1.7.0", [])

      result = Phoenix.config(igniter: igniter)

      # Phoenix 1.7 gets universal usage rules everywhere
      assert result.nested_memories["test"] == ["usage_rules:elixir", "usage_rules:otp"]
      assert result.nested_memories["lib/my_app"] == ["usage_rules:elixir", "usage_rules:otp"]

      # Web directory gets universal rules but no phoenix-specific ones
      web_memories = result.nested_memories["lib/my_app_web"]
      assert "usage_rules:elixir" in web_memories
      assert "usage_rules:otp" in web_memories

      # Should not have phoenix-specific usage rules
      refute "phoenix:phoenix" in web_memories
      refute "phoenix:html" in web_memories
      refute "phoenix:elixir" in web_memories
    end
  end

  describe "config/1 - DaisyUI option" do
    test "includes DaisyUI docs by default" do
      igniter = Igniter.new()
      mock_phoenix_project(igniter, "1.8.0", [])

      result = Phoenix.config(igniter: igniter)

      web_memories = result.nested_memories["lib/my_app_web"]

      daisyui_entry =
        {:url, "https://daisyui.com/llms.txt",
         as: "DaisyUI Component Library", cache: "./ai/daisyui/llms.md"}

      assert daisyui_entry in web_memories
    end

    test "includes DaisyUI docs when explicitly enabled" do
      igniter = Igniter.new()
      mock_phoenix_project(igniter, "1.8.0", [])

      result = Phoenix.config(igniter: igniter, include_daisyui?: true)

      web_memories = result.nested_memories["lib/my_app_web"]

      daisyui_entry =
        {:url, "https://daisyui.com/llms.txt",
         as: "DaisyUI Component Library", cache: "./ai/daisyui/llms.md"}

      assert daisyui_entry in web_memories
    end

    test "excludes DaisyUI docs when disabled" do
      igniter = Igniter.new()
      mock_phoenix_project(igniter, "1.8.0", [])

      result = Phoenix.config(igniter: igniter, include_daisyui?: false)

      web_memories = result.nested_memories["lib/my_app_web"]

      daisyui_entry =
        {:url, "https://daisyui.com/llms.txt",
         as: "DaisyUI Component Library", cache: "./ai/daisyui/llms.md"}

      refute daisyui_entry in web_memories
    end
  end

  describe "config/1 - dependency detection" do
    test "includes LiveView rules when dependency exists" do
      igniter = Igniter.new()
      mock_phoenix_project(igniter, "1.8.0", [:phoenix_live_view])

      result = Phoenix.config(igniter: igniter)

      web_memories = result.nested_memories["lib/my_app_web"]
      assert "phoenix:liveview" in web_memories
    end

    test "includes Ecto rules when ecto dependency exists" do
      igniter = Igniter.new()
      mock_phoenix_project(igniter, "1.8.0", [:ecto])

      result = Phoenix.config(igniter: igniter)

      app_memories = result.nested_memories["lib/my_app"]
      web_memories = result.nested_memories["lib/my_app_web"]
      assert "phoenix:ecto" in app_memories
      assert "phoenix:ecto" in web_memories
    end

    test "includes Ecto rules when ecto_sql dependency exists" do
      igniter = Igniter.new()
      mock_phoenix_project(igniter, "1.8.0", [:ecto_sql])

      result = Phoenix.config(igniter: igniter)

      app_memories = result.nested_memories["lib/my_app"]
      web_memories = result.nested_memories["lib/my_app_web"]
      assert "phoenix:ecto" in app_memories
      assert "phoenix:ecto" in web_memories
    end

    test "includes both LiveView and Ecto rules when both exist" do
      igniter = Igniter.new()
      mock_phoenix_project(igniter, "1.8.0", [:phoenix_live_view, :ecto])

      result = Phoenix.config(igniter: igniter)

      web_memories = result.nested_memories["lib/my_app_web"]
      assert "phoenix:liveview" in web_memories
      assert "phoenix:ecto" in web_memories
    end
  end

  describe "config/1 - edge cases" do
    test "returns empty config for non-phoenix project" do
      igniter = Igniter.new()
      stub(Igniter.Project.Deps, :has_dep?, fn ^igniter, :phoenix -> false end)

      result = Phoenix.config(igniter: igniter)

      assert result == %{}
    end

    test "generates correct app name from complex module prefix" do
      igniter = Igniter.new()

      stub(Igniter.Project.Deps, :has_dep?, fn ^igniter, dep ->
        case dep do
          :phoenix -> true
          _ -> false
        end
      end)

      expect(Igniter.Project.Module, :module_name_prefix, fn ^igniter -> MyComplexApp end)

      expect(File, :read, fn "mix.lock" ->
        {:ok, ~s|"phoenix": {:hex, :phoenix, "1.8.0", [], :hexpm}|}
      end)

      result = Phoenix.config(igniter: igniter)

      assert Map.has_key?(result.nested_memories, "lib/my_complex_app")
      assert Map.has_key?(result.nested_memories, "lib/my_complex_app_web")
    end
  end

  describe "config/1 - MCP servers" do
    test "configures Tidewave MCP server" do
      igniter = Igniter.new()
      mock_phoenix_project(igniter, "1.8.0", [])

      result = Phoenix.config(igniter: igniter)

      assert result.mcp_servers == [tidewave: [port: "${PORT:-4000}"]]
    end
  end
end
