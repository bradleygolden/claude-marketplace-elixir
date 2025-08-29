defmodule Claude.Plugins.AshTest do
  use Claude.ClaudeCodeCase

  alias Claude.Plugins.Ash

  describe "config/1 - basic functionality" do
    test "detects Ash project and returns config" do
      igniter = ash_test_project()
      result = Ash.config(igniter: igniter)

      refute result == %{}
      assert Map.has_key?(result, :hooks)
      assert Map.has_key?(result, :nested_memories)
    end

    test "returns empty config for non-ash project" do
      igniter = test_project()
      result = Ash.config(igniter: igniter)

      assert result == %{}
    end
  end

  describe "config/1 - hooks configuration" do
    test "includes ash.codegen --check hook for post_tool_use" do
      igniter = ash_test_project()
      result = Ash.config(igniter: igniter)

      assert result.hooks.post_tool_use == [
               {"ash.codegen --check", when: [:write, :edit, :multi_edit]}
             ]
    end

    test "hook is configured for write, edit, and multi_edit tools" do
      igniter = ash_test_project()
      result = Ash.config(igniter: igniter)

      [hook] = result.hooks.post_tool_use
      assert elem(hook, 0) == "ash.codegen --check"
      assert elem(hook, 1)[:when] == [:write, :edit, :multi_edit]
    end
  end

  describe "config/1 - nested memories" do
    test "includes ash usage rules for lib/app_name directory" do
      igniter = ash_test_project()
      result = Ash.config(igniter: igniter)

      assert Map.has_key?(result.nested_memories, "lib/my_app")
      assert "ash" in result.nested_memories["lib/my_app"]
      assert Map.has_key?(result.nested_memories, "test")
      assert "ash" in result.nested_memories["test"]
    end

    test "correctly determines app name from project" do
      igniter = ash_test_project()
      result = Ash.config(igniter: igniter)

      # Should have the app name in the path
      app_memory_path =
        result.nested_memories
        |> Map.keys()
        |> Enum.find(&String.starts_with?(&1, "lib/"))

      assert app_memory_path == "lib/my_app"
    end

    test "works with different app names" do
      igniter =
        ash_test_project(
          app: :different_app,
          files: %{
            "mix.exs" => """
            defmodule DifferentApp.MixProject do
              use Mix.Project

              def project do
                [
                  app: :different_app,
                  version: "0.1.0",
                  elixir: "~> 1.14",
                  deps: deps()
                ]
              end

              defp deps do
                [
                  {:ash, "~> 3.0"}
                ]
              end
            end
            """
          }
        )

      result = Ash.config(igniter: igniter)

      assert Map.has_key?(result.nested_memories, "lib/different_app")
      assert "ash" in result.nested_memories["lib/different_app"]
    end
  end

  describe "extension detection" do
    test "includes ash_postgres rules when dependency detected" do
      igniter = ash_test_project_with_extensions([:ash_postgres])
      result = Ash.config(igniter: igniter)

      assert "ash_postgres" in result.nested_memories["lib/my_app"]
      assert Map.has_key?(result.nested_memories, "priv/repo/migrations")
      assert "ash_postgres" in result.nested_memories["priv/repo/migrations"]
    end

    test "includes ash_phoenix rules when dependency detected" do
      igniter = ash_test_project_with_extensions([:ash_phoenix])
      result = Ash.config(igniter: igniter)

      assert Map.has_key?(result.nested_memories, "lib/my_app_web")
      assert "ash_phoenix" in result.nested_memories["lib/my_app_web"]
    end

    test "includes ash_ai rules when dependency detected" do
      igniter = ash_test_project_with_extensions([:ash_ai])
      result = Ash.config(igniter: igniter)

      assert "ash_ai" in result.nested_memories["lib/my_app"]
    end

    test "includes ash_oban rules when dependency detected" do
      igniter = ash_test_project_with_extensions([:ash_oban])
      result = Ash.config(igniter: igniter)

      assert "ash_oban" in result.nested_memories["lib/my_app"]
    end

    test "includes ash_json_api rules when dependency detected" do
      igniter = ash_test_project_with_extensions([:ash_json_api])
      result = Ash.config(igniter: igniter)

      assert Map.has_key?(result.nested_memories, "lib/my_app_web")
      assert "ash_json_api" in result.nested_memories["lib/my_app_web"]
    end

    test "combines multiple extensions correctly" do
      igniter = ash_test_project_with_extensions([:ash_postgres, :ash_phoenix, :ash_ai])
      result = Ash.config(igniter: igniter)

      # App directory should have base ash + postgres + ai
      app_rules = result.nested_memories["lib/my_app"]
      assert "ash" in app_rules
      assert "ash_postgres" in app_rules
      assert "ash_ai" in app_rules
      refute "ash_phoenix" in app_rules

      # Web directory should have phoenix
      web_rules = result.nested_memories["lib/my_app_web"]
      assert "ash_phoenix" in web_rules

      # Migrations directory should have postgres
      migration_rules = result.nested_memories["priv/repo/migrations"]
      assert "ash_postgres" in migration_rules
    end

    test "does not include web rules when no web extensions detected" do
      igniter = ash_test_project_with_extensions([:ash_postgres, :ash_ai])
      result = Ash.config(igniter: igniter)

      refute Map.has_key?(result.nested_memories, "lib/my_app_web")
    end

    test "does not include migration rules when ash_postgres not detected" do
      igniter = ash_test_project_with_extensions([:ash_phoenix, :ash_ai])
      result = Ash.config(igniter: igniter)

      refute Map.has_key?(result.nested_memories, "priv/repo/migrations")
    end

    test "handles all extensions together" do
      igniter =
        ash_test_project_with_extensions([
          :ash_postgres,
          :ash_phoenix,
          :ash_ai,
          :ash_oban,
          :ash_json_api
        ])

      result = Ash.config(igniter: igniter)

      # App directory rules
      app_rules = result.nested_memories["lib/my_app"]
      assert "ash" in app_rules
      assert "ash_postgres" in app_rules
      assert "ash_ai" in app_rules
      assert "ash_oban" in app_rules

      # Web directory rules  
      web_rules = result.nested_memories["lib/my_app_web"]
      assert "ash_phoenix" in web_rules
      assert "ash_json_api" in web_rules

      # Migration rules
      migration_rules = result.nested_memories["priv/repo/migrations"]
      assert "ash_postgres" in migration_rules

      # Test rules
      test_rules = result.nested_memories["test"]
      assert "ash" in test_rules
    end
  end

  describe "integration with plugin system" do
    test "can be loaded as a plugin" do
      assert {:ok, config} = Claude.Plugin.load_plugin(Ash, igniter: ash_test_project())

      assert Map.has_key?(config, :hooks)
      assert Map.has_key?(config, :nested_memories)
    end

    test "merges correctly with other configuration" do
      plugin_configs = [Ash.config(igniter: ash_test_project())]
      base_config = %{hooks: %{post_tool_use: [{"custom_task", when: [:write]}]}}

      final_config = Claude.Plugin.merge_configs(plugin_configs ++ [base_config])

      # Should have both the Ash hook and the custom hook
      assert length(final_config.hooks.post_tool_use) == 2

      assert {"ash.codegen --check", when: [:write, :edit, :multi_edit]} in final_config.hooks.post_tool_use

      assert {"custom_task", when: [:write]} in final_config.hooks.post_tool_use
    end
  end

  defp ash_test_project(opts \\ []) do
    ash_test_project_with_extensions([], opts)
  end

  defp ash_test_project_with_extensions(extensions, opts \\ []) do
    app = Keyword.get(opts, :app, :my_app)

    deps =
      [{:ash, "~> 3.0"}] ++
        Enum.map(extensions, fn ext -> {ext, "~> 3.0"} end)

    deps_string =
      deps
      |> Enum.map(&inspect/1)
      |> Enum.join(",\n            ")

    default_files = %{
      "mix.exs" => """
      defmodule MyApp.MixProject do
        use Mix.Project

        def project do
          [
            app: #{inspect(app)},
            version: "0.1.0",
            elixir: "~> 1.14",
            deps: deps()
          ]
        end

        defp deps do
          [
            #{deps_string}
          ]
        end
      end
      """
    }

    files = Map.merge(default_files, Keyword.get(opts, :files, %{}))
    opts = Keyword.put(opts, :files, files)

    test_project(opts)
  end
end
