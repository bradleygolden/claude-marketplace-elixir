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
    app = Keyword.get(opts, :app, :my_app)

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
            {:ash, "~> 3.0"}
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
