defmodule Claude.ConfigTest do
  use ExUnit.Case

  @test_config_dir Path.join(System.tmp_dir!(), "claude_config_test_#{:rand.uniform(999_999)}")

  setup do
    File.mkdir_p!(@test_config_dir)
    original_cwd = File.cwd!()
    File.cd!(@test_config_dir)

    on_exit(fn ->
      File.cd!(original_cwd)
      File.rm_rf!(@test_config_dir)
    end)

    :ok
  end

  describe "load/0" do
    test "returns default config when no .claude.exs exists" do
      assert {:ok, config} = Claude.Config.load()
      assert config == %{hooks: [], enabled: true}
    end

    test "loads valid .claude.exs configuration" do
      config_content = """
      %{
        enabled: true,
        hooks: [
          %{
            module: MyApp.TestHook,
            enabled: true,
            config: %{test: "value"}
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      assert {:ok, config} = Claude.Config.load()
      assert config.enabled == true
      assert length(config.hooks) == 1
      assert hd(config.hooks).module == MyApp.TestHook
      assert hd(config.hooks).config == %{test: "value"}
    end

    test "merges with default config" do
      config_content = """
      %{
        hooks: [
          %{module: MyApp.TestHook}
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      assert {:ok, config} = Claude.Config.load()
      # From default
      assert config.enabled == true
      assert length(config.hooks) == 1
    end

    test "returns error for invalid Elixir syntax" do
      File.write!(".claude.exs", "invalid elixir code {")

      assert {:error, message} = Claude.Config.load()
      assert message =~ "Failed to load .claude.exs"
    end
  end

  describe "find_config_file/0" do
    test "finds .claude.exs in current directory" do
      File.write!(".claude.exs", "%{}")

      assert {:ok, path} = Claude.Config.find_config_file()
      assert Path.basename(path) == ".claude.exs"
    end

    test "finds .claude.exs in parent directory" do
      subdir = Path.join(@test_config_dir, "subdir")
      File.mkdir_p!(subdir)
      File.write!(Path.join(@test_config_dir, ".claude.exs"), "%{}")
      File.cd!(subdir)

      assert {:ok, path} = Claude.Config.find_config_file()
      assert Path.basename(path) == ".claude.exs"
    end

    test "returns error when no config file found" do
      assert :error = Claude.Config.find_config_file()
    end
  end

  describe "load_from_file/1" do
    test "validates hook configuration" do
      config_content = """
      %{
        hooks: [
          %{module: "not_an_atom"}
        ]
      }
      """

      path = Path.join(@test_config_dir, "test.claude.exs")
      File.write!(path, config_content)

      assert {:error, "Invalid hook configuration"} = Claude.Config.load_from_file(path)
    end

    test "validates enabled field" do
      config_content = """
      %{
        enabled: "not_a_boolean"
      }
      """

      path = Path.join(@test_config_dir, "test.claude.exs")
      File.write!(path, config_content)

      assert {:error, "enabled must be a boolean"} = Claude.Config.load_from_file(path)
    end

    test "validates event_type field in hooks" do
      config_content = """
      %{
        hooks: [
          %{
            module: MyApp.TestHook,
            event_type: "InvalidEventType"
          }
        ]
      }
      """

      path = Path.join(@test_config_dir, "test.claude.exs")
      File.write!(path, config_content)

      assert {:error, "Invalid hook configuration"} = Claude.Config.load_from_file(path)
    end

    test "accepts valid event_type values" do
      config_content = """
      %{
        hooks: [
          %{
            module: MyApp.TestHook1,
            event_type: "PostToolUse"
          },
          %{
            module: MyApp.TestHook2,
            event_type: "PreToolUse"
          },
          %{
            module: MyApp.TestHook3,
            event_type: "UserPromptSubmit"
          }
        ]
      }
      """

      path = Path.join(@test_config_dir, "test.claude.exs")
      File.write!(path, config_content)

      assert {:ok, config} = Claude.Config.load_from_file(path)
      assert length(config.hooks) == 3
    end

    test "event_type is optional in hooks" do
      config_content = """
      %{
        hooks: [
          %{
            module: MyApp.TestHook
          }
        ]
      }
      """

      path = Path.join(@test_config_dir, "test.claude.exs")
      File.write!(path, config_content)

      assert {:ok, config} = Claude.Config.load_from_file(path)
      assert length(config.hooks) == 1
    end
  end
end
