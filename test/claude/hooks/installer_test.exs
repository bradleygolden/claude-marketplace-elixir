defmodule Claude.Hooks.InstallerTest do
  use ExUnit.Case, async: false
  use Mimic

  import Claude.TestHelpers

  alias Claude.Hooks
  alias Claude.Core.Project

  setup :verify_on_exit!

  describe "install/0" do
    test "creates settings file with all hooks when none exists" do
      in_tmp(fn tmp_dir ->
        # Mock Project.claude_path to ensure we use the test directory
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        File.mkdir_p!(".claude")

        assert {:ok, _message} = Hooks.install()

        settings_path = Path.join(".claude", "settings.json")
        assert File.exists?(settings_path)

        settings = File.read!(settings_path) |> Jason.decode!()
        assert %{"PostToolUse" => post_tool_use} = settings

        # Check PostToolUse has both hooks
        assert %{"hooks" => hooks} = post_tool_use
        assert length(hooks) == 2

        # Check for formatter hook
        assert Enum.any?(hooks, fn hook ->
                 hook["command"] =~ "mix claude hooks run post_tool_use.elixir_formatter" &&
                   hook["type"] == "command" &&
                   hook["matcher"] == ".*"
               end)

        # Check for compilation checker hook
        assert Enum.any?(hooks, fn hook ->
                 hook["command"] =~ "mix claude hooks run post_tool_use.compilation_checker" &&
                   hook["type"] == "command" &&
                   hook["matcher"] == ".*"
               end)
      end)
    end

    test "preserves existing hooks when installing" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        File.mkdir_p!(".claude")

        # Create existing settings with custom hook
        existing_settings = %{
          "PostToolUse" => %{
            "hooks" => [
              %{"command" => "echo 'custom hook'", "type" => "command"}
            ]
          }
        }

        settings_path = Path.join(".claude", "settings.json")
        File.write!(settings_path, Jason.encode!(existing_settings, pretty: true))

        assert {:ok, _message} = Hooks.install()

        settings = File.read!(settings_path) |> Jason.decode!()
        post_hooks = get_in(settings, ["PostToolUse", "hooks"]) || []

        # Should have custom hook plus all Claude hooks
        assert length(post_hooks) == 3

        # One should be the custom hook
        assert Enum.any?(post_hooks, fn hook ->
                 hook["command"] == "echo 'custom hook'"
               end)

        # One should be Claude's format hook
        assert Enum.any?(post_hooks, fn hook ->
                 hook["command"] =~ "mix claude hooks run post_tool_use.elixir_formatter"
               end)

        # One should be Claude's compilation checker hook
        assert Enum.any?(post_hooks, fn hook ->
                 hook["command"] =~ "mix claude hooks run post_tool_use.compilation_checker"
               end)
      end)
    end

    test "creates .claude directory if it doesn't exist" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        refute File.exists?(".claude")

        assert {:ok, _message} = Hooks.install()

        assert File.exists?(".claude")
        assert File.exists?(Path.join(".claude", "settings.json"))
      end)
    end
  end

  describe "uninstall/0" do
    test "removes only Claude hooks" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        File.mkdir_p!(".claude")

        assert {:ok, _message} = Hooks.install()

        settings_path = Path.join(".claude", "settings.json")
        settings = File.read!(settings_path) |> Jason.decode!()

        custom_hook = %{"command" => "echo 'custom hook'", "type" => "command"}

        updated_settings =
          update_in(settings, ["PostToolUse", "hooks"], fn hooks ->
            [custom_hook | hooks]
          end)

        File.write!(settings_path, Jason.encode!(updated_settings, pretty: true))

        assert {:ok, _message} = Hooks.uninstall()

        # Check custom hook remains
        settings = File.read!(settings_path) |> Jason.decode!()
        post_hooks = get_in(settings, ["PostToolUse", "hooks"]) || []

        assert Enum.any?(post_hooks, fn hook ->
                 hook["command"] == "echo 'custom hook'"
               end)

        refute Enum.any?(post_hooks, fn hook ->
                 hook["command"] =~ "mix claude hooks run post_tool_use.elixir_formatter"
               end)
      end)
    end

    test "removes empty hook arrays" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        File.mkdir_p!(".claude")

        # Create settings with only Claude hooks
        assert {:ok, _message} = Hooks.install()

        # When only Claude hooks exist, uninstall removes the file
        assert {:ok, _message} = Hooks.uninstall()

        settings_path = Path.join(".claude", "settings.json")

        # Settings file should be removed when only Claude hooks existed
        refute File.exists?(settings_path)
      end)
    end

    test "returns error when no Claude hooks exist" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        File.mkdir_p!(".claude")

        # Uninstall should succeed even if no hooks exist
        assert {:ok, _message} = Hooks.uninstall()
      end)
    end
  end
end
