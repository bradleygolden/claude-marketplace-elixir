defmodule Claude.Plugins.PhoenixTest do
  use Claude.ClaudeCodeCase

  alias Claude.Plugins.Phoenix

  describe "config/1 - basic functionality" do
    test "detects Phoenix project and returns config" do
      igniter = phx_test_project()
      result = Phoenix.config(igniter: igniter)

      refute result == %{}
      assert Map.has_key?(result, :mcp_servers)
      assert Map.has_key?(result, :nested_memories)
      assert result.mcp_servers == [tidewave: [port: "${PORT:-4000}"]]
    end

    test "returns empty config for non-phoenix project" do
      igniter = test_project()
      result = Phoenix.config(igniter: igniter)

      assert result == %{}
    end
  end

  describe "config/1 - DaisyUI option" do
    test "includes DaisyUI docs by default" do
      igniter = phx_test_project()
      result = Phoenix.config(igniter: igniter)

      web_memories =
        result.nested_memories
        |> Enum.find(fn {path, _} -> String.contains?(path, "_web") end)
        |> elem(1)

      daisyui_entry =
        {:url, "https://daisyui.com/llms.txt",
         as: "DaisyUI Component Library", cache: "./ai/daisyui/llms.md"}

      assert daisyui_entry in web_memories
    end

    test "excludes DaisyUI docs when disabled" do
      igniter = phx_test_project()
      result = Phoenix.config(igniter: igniter, include_daisyui?: false)

      web_memories =
        result.nested_memories
        |> Enum.find(fn {path, _} -> String.contains?(path, "_web") end)
        |> elem(1)

      daisyui_entry =
        {:url, "https://daisyui.com/llms.txt",
         as: "DaisyUI Component Library", cache: "./ai/daisyui/llms.md"}

      refute daisyui_entry in web_memories
    end
  end

  describe "config/1 - usage rules" do
    test "includes universal usage rules for all directories" do
      igniter = phx_test_project()
      result = Phoenix.config(igniter: igniter)

      test_memories = result.nested_memories["test"]
      assert "usage_rules:elixir" in test_memories
      assert "usage_rules:otp" in test_memories

      {_app_dir, app_memories} =
        result.nested_memories
        |> Enum.find(fn {path, _} ->
          String.starts_with?(path, "lib/") and not String.contains?(path, "_web")
        end)

      assert "usage_rules:elixir" in app_memories
      assert "usage_rules:otp" in app_memories
    end

    test "includes phoenix-specific rules for newer Phoenix" do
      igniter = phx_test_project()
      result = Phoenix.config(igniter: igniter)

      web_memories =
        result.nested_memories
        |> Enum.find(fn {path, _} -> String.contains?(path, "_web") end)
        |> elem(1)

      assert "phoenix:phoenix" in web_memories
      assert "phoenix:html" in web_memories
      assert "phoenix:elixir" in web_memories
    end

    test "config includes inline_usage_rules for phoenix" do
      igniter = phx_test_project()
      result = Phoenix.config(igniter: igniter)

      assert result.inline_usage_rules == ["phoenix"]
    end
  end

  describe "config/1 - version detection with custom mix.lock" do
    test "version detection works as expected" do
      igniter = phx_test_project()
      result = Phoenix.config(igniter: igniter)

      web_memories =
        result.nested_memories
        |> Enum.find(fn {path, _} -> String.contains?(path, "_web") end)
        |> elem(1)

      assert "phoenix:phoenix" in web_memories
      assert "phoenix:html" in web_memories
      assert "phoenix:elixir" in web_memories
    end
  end

  describe "config/1 - dependency detection" do
    test "detects default Phoenix project dependencies" do
      igniter = phx_test_project()
      result = Phoenix.config(igniter: igniter)

      assert Map.has_key?(result, :nested_memories)
      assert is_map(result.nested_memories)
      assert map_size(result.nested_memories) > 0
    end
  end

  describe "config/1 - port customization" do
    test "uses default port 4000 when no port specified" do
      igniter = phx_test_project()
      result = Phoenix.config(igniter: igniter)

      assert result.mcp_servers == [tidewave: [port: "${PORT:-4000}"]]
    end

    test "uses custom port when specified" do
      igniter = phx_test_project()
      result = Phoenix.config(igniter: igniter, port: 4001)

      assert result.mcp_servers == [tidewave: [port: "${PORT:-4001}"]]
    end

    test "custom port preserves environment variable override capability" do
      igniter = phx_test_project()
      result = Phoenix.config(igniter: igniter, port: 3000)

      # Environment variable PORT should still override the custom port
      assert result.mcp_servers == [tidewave: [port: "${PORT:-3000}"]]
    end

    test "port option works with other options" do
      igniter = phx_test_project()
      result = Phoenix.config(igniter: igniter, port: 8080, include_daisyui?: false)

      assert result.mcp_servers == [tidewave: [port: "${PORT:-8080}"]]

      web_memories =
        result.nested_memories
        |> Enum.find(fn {path, _} -> String.contains?(path, "_web") end)
        |> elem(1)

      daisyui_entry =
        {:url, "https://daisyui.com/llms.txt",
         as: "DaisyUI Component Library", cache: "./ai/daisyui/llms.md"}

      refute daisyui_entry in web_memories
    end
  end
end
