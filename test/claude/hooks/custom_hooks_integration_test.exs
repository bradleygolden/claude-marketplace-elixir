defmodule Claude.Hooks.CustomHooksIntegrationTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  # Define a test hook that writes to a file when executed
  defmodule TestCustomHook do
    @behaviour Claude.Hooks.Hook.Behaviour

    def config do
      %Claude.Hooks.Hook{
        type: "command",
        command: "mix claude hooks run custom_hooks_integration_test.test_custom_hook",
        matcher: "Write"
      }
    end

    def description do
      "Test custom hook for integration testing"
    end

    def run(_tool_name, json_params) do
      # Parse params and write a marker file
      case Jason.decode(json_params) do
        {:ok, %{"file_path" => file_path}} ->
          marker_path = "#{file_path}.custom_hook_marker"
          File.write!(marker_path, "Custom hook was executed!")
          :ok

        _ ->
          {:error, "Invalid params"}
      end
    end
  end

  @test_dir Path.join(System.tmp_dir!(), "claude_custom_hooks_test_#{:rand.uniform(999_999)}")

  setup do
    File.mkdir_p!(@test_dir)
    original_cwd = File.cwd!()
    File.cd!(@test_dir)

    on_exit(fn ->
      File.cd!(original_cwd)
      File.rm_rf!(@test_dir)
    end)

    :ok
  end

  describe "custom hooks installation and execution" do
    test "installs and runs custom hooks from .claude.exs" do
      # Create .claude.exs with custom hook
      config_content = """
      %{
        enabled: true,
        hooks: [
          %{
            module: #{__MODULE__}.TestCustomHook,
            enabled: true
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      # Install hooks
      output =
        capture_io(fn ->
          assert {:ok, message} = Claude.Hooks.install()
          IO.puts(message)
        end)

      assert output =~ "Claude hooks installed successfully"
      assert output =~ "4 total, 1 custom"

      # Verify settings.json includes the custom hook
      assert {:ok, settings} = Claude.Core.Settings.read()
      assert Map.has_key?(settings, "hooks")

      post_tool_use_hooks = get_in(settings, ["hooks", "CustomHooksIntegrationTest"])
      assert is_list(post_tool_use_hooks)

      write_matcher =
        Enum.find(post_tool_use_hooks, fn m ->
          Map.get(m, "matcher") == "Write"
        end)

      assert write_matcher

      hook_commands = Enum.map(write_matcher["hooks"], & &1["command"])

      assert "mix claude hooks run custom_hooks_integration_test.test_custom_hook" in hook_commands
    end

    test "validates custom hooks during installation" do
      # Create .claude.exs with valid structure but non-existent module
      config_content = """
      %{
        hooks: [
          %{
            module: NonExistentModule,
            enabled: true
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      # Install hooks with warnings captured
      output =
        capture_io(:stderr, fn ->
          assert {:ok, _} = Claude.Hooks.install()
        end)

      assert output =~ "does not implement Claude.Hooks.Hook.Behaviour"
    end

    test "custom hook execution" do
      # Create test file
      test_file = Path.join(@test_dir, "test.ex")
      File.write!(test_file, "defmodule Test do\nend")

      # Create params for hook execution
      json_params = Jason.encode!(%{file_path: test_file})

      # Execute the custom hook directly
      assert :ok = TestCustomHook.run("Write", json_params)

      # Verify marker file was created
      marker_file = "#{test_file}.custom_hook_marker"
      assert File.exists?(marker_file)
      assert File.read!(marker_file) == "Custom hook was executed!"
    end

    test "uninstall removes custom hooks" do
      # Create and install custom hook
      config_content = """
      %{
        hooks: [
          %{
            module: #{__MODULE__}.TestCustomHook,
            enabled: true
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      # Install
      capture_io(fn -> Claude.Hooks.install() end)

      # Verify hook is installed
      assert {:ok, settings} = Claude.Core.Settings.read()
      assert Map.has_key?(settings, "hooks")

      # Uninstall
      capture_io(fn ->
        assert {:ok, _} = Claude.Hooks.uninstall()
      end)

      # Verify settings are removed or empty
      case Claude.Core.Settings.read() do
        {:error, :not_found} -> :ok
        {:ok, settings} -> assert settings == %{}
      end
    end
  end

  describe "hook configuration" do
    test "custom hooks receive configuration from .claude.exs" do
      # Define a hook that uses configuration
      defmodule ConfigurableHook do
        @behaviour Claude.Hooks.Hook.Behaviour

        def config do
          %Claude.Hooks.Hook{
            type: "command",
            command: "test",
            matcher: ".*"
          }
        end

        def description, do: "Configurable test hook"

        def run(_, _) do
          config = Claude.Hooks.Registry.hook_config(__MODULE__)

          # Write config to file for verification
          File.write!("hook_config.json", Jason.encode!(config))
          :ok
        end
      end

      # Create .claude.exs with hook configuration
      config_content = """
      %{
        hooks: [
          %{
            module: #{__MODULE__}.ConfigurableHook,
            enabled: true,
            config: %{
              option1: "value1",
              option2: 42,
              nested: %{key: "value"}
            }
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      # Run the hook
      ConfigurableHook.run("Test", "{}")

      # Verify configuration was passed correctly
      assert File.exists?("hook_config.json")
      config = Jason.decode!(File.read!("hook_config.json"))

      assert config["option1"] == "value1"
      assert config["option2"] == 42
      assert config["nested"]["key"] == "value"
    end
  end
end
