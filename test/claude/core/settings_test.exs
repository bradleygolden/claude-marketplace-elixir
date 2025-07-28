defmodule Claude.Core.SettingsTest do
  use Claude.Test.ClaudeCodeCase, async: false
  use Mimic

  import Claude.TestHelpers

  alias Claude.Core.Settings
  alias Claude.Core.Project

  setup :verify_on_exit!

  describe "path/0" do
    test "returns correct settings path" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        expected_path = Path.join([tmp_dir, ".claude", "settings.json"])
        assert Settings.path() == expected_path
      end)
    end
  end

  describe "read/0" do
    test "returns empty map when file doesn't exist" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        assert {:ok, %{}} = Settings.read()
      end)
    end

    test "reads existing settings file" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        File.mkdir_p!(Path.join(tmp_dir, ".claude"))
        settings = %{"key" => "value", "nested" => %{"foo" => "bar"}}
        File.write!(Path.join(tmp_dir, ".claude/settings.json"), Jason.encode!(settings))

        assert {:ok, ^settings} = Settings.read()
      end)
    end

    test "returns error for invalid JSON" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        File.mkdir_p!(Path.join(tmp_dir, ".claude"))
        File.write!(Path.join(tmp_dir, ".claude/settings.json"), "invalid json {]")

        assert {:error, :invalid_json} = Settings.read()
      end)
    end

    test "returns error for other file errors" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        File.mkdir_p!(Path.join(tmp_dir, ".claude"))
        settings_path = Path.join(tmp_dir, ".claude/settings.json")
        File.write!(settings_path, "content")
        File.chmod!(settings_path, 0o000)

        assert {:error, :eacces} = Settings.read()

        File.chmod!(settings_path, 0o644)
      end)
    end
  end

  describe "write/1" do
    test "writes settings to file" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        settings = %{"test" => "data"}
        assert :ok = Settings.write(settings)

        settings_path = Path.join(tmp_dir, ".claude/settings.json")
        assert File.exists?(settings_path)
        written = File.read!(settings_path) |> Jason.decode!()
        assert written == settings
      end)
    end

    test "creates directory if it doesn't exist" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        claude_dir = Path.join(tmp_dir, ".claude")
        refute File.exists?(claude_dir)

        assert :ok = Settings.write(%{})

        assert File.exists?(claude_dir)
        assert File.exists?(Path.join(claude_dir, "settings.json"))
      end)
    end

    test "formats JSON with pretty printing" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        settings = %{"key" => "value", "nested" => %{"foo" => "bar"}}
        Settings.write(settings)

        content = File.read!(Path.join(tmp_dir, ".claude/settings.json"))
        assert content =~ "{\n"
        assert content =~ "  \"key\": \"value\""
      end)
    end
  end

  describe "update/1" do
    test "updates existing settings" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        Settings.write(%{"existing" => "value"})

        assert :ok =
                 Settings.update(fn settings ->
                   Map.put(settings, "new", "data")
                 end)

        {:ok, updated} = Settings.read()
        assert updated == %{"existing" => "value", "new" => "data"}
      end)
    end

    test "creates new settings if none exist" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)

        assert :ok =
                 Settings.update(fn _settings ->
                   %{"created" => "new"}
                 end)

        {:ok, created} = Settings.read()
        assert created == %{"created" => "new"}
      end)
    end
  end

  describe "get/2" do
    test "gets value from settings" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)

        Settings.write(%{
          "hooks" => %{
            "PostToolUse" => %{"hooks" => ["hook1", "hook2"]}
          }
        })

        assert Settings.get(["hooks", "PostToolUse", "hooks"]) == ["hook1", "hook2"]
        assert Settings.get(["hooks", "PostToolUse"]) == %{"hooks" => ["hook1", "hook2"]}
      end)
    end

    test "returns default when key doesn't exist" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        Settings.write(%{"other" => "value"})

        assert Settings.get(["nonexistent"], "default") == "default"
        assert Settings.get(["nonexistent"]) == nil
      end)
    end

    test "returns default when settings don't exist" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        assert Settings.get(["any", "path"], "default") == "default"
      end)
    end
  end

  describe "put/2" do
    test "sets value in settings" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        assert :ok = Settings.put(["new", "key"], "value")

        {:ok, settings} = Settings.read()
        assert get_in(settings, ["new", "key"]) == "value"
      end)
    end

    test "creates nested structures" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        assert :ok = Settings.put(["deeply", "nested", "value"], 42)

        {:ok, settings} = Settings.read()
        assert settings == %{"deeply" => %{"nested" => %{"value" => 42}}}
      end)
    end

    test "updates existing nested values" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        Settings.write(%{"existing" => %{"nested" => %{"old" => "value"}}})

        assert :ok = Settings.put(["existing", "nested", "new"], "data")

        {:ok, settings} = Settings.read()
        assert settings["existing"]["nested"] == %{"old" => "value", "new" => "data"}
      end)
    end
  end

  describe "exists?/0" do
    test "returns true when settings file exists" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        Settings.write(%{})
        assert Settings.exists?() == true
      end)
    end

    test "returns false when settings file doesn't exist" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        assert Settings.exists?() == false
      end)
    end
  end

  describe "remove/0" do
    test "removes existing settings file" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        Settings.write(%{"data" => "value"})
        settings_path = Path.join(tmp_dir, ".claude/settings.json")
        assert File.exists?(settings_path)

        assert :ok = Settings.remove()
        refute File.exists?(settings_path)
      end)
    end

    test "returns ok when file doesn't exist" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        assert :ok = Settings.remove()
      end)
    end
  end

  describe "empty?/1" do
    test "returns true for empty map" do
      assert Settings.empty?(%{}) == true
    end

    test "returns true for map with only empty hooks" do
      assert Settings.empty?(%{"hooks" => %{}}) == true
    end

    test "returns false for non-empty settings" do
      assert Settings.empty?(%{"key" => "value"}) == false
      assert Settings.empty?(%{"hooks" => %{"PostToolUse" => []}}) == false
    end
  end

  describe "read/0 with .claude.exs" do
    test "reads and merges .claude.exs with settings.json" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        stub(Project, :root, fn -> tmp_dir end)
        File.mkdir_p!(Path.join(tmp_dir, ".claude"))

        # Write settings.json
        json_settings = %{"json_key" => "json_value", "shared" => "from_json"}
        File.write!(Path.join(tmp_dir, ".claude/settings.json"), Jason.encode!(json_settings))

        # Write .claude.exs
        exs_content = """
        %{
          exs_key: "exs_value",
          shared: "from_exs"
        }
        """

        File.write!(Path.join(tmp_dir, ".claude.exs"), exs_content)

        # Change to tmp_dir so .claude.exs is found
        original_cwd = File.cwd!()
        File.cd!(tmp_dir)

        try do
          assert {:ok, settings} = Settings.read()
          assert settings["json_key"] == "json_value"
          assert settings["exs_key"] == "exs_value"
          # .claude.exs takes precedence
          assert settings["shared"] == "from_exs"
        after
          File.cd!(original_cwd)
        end
      end)
    end

    test "works with only .claude.exs file" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        stub(Project, :root, fn -> tmp_dir end)

        # Write only .claude.exs
        exs_content = """
        %{
          test_key: "test_value"
        }
        """

        File.write!(Path.join(tmp_dir, ".claude.exs"), exs_content)

        original_cwd = File.cwd!()
        File.cd!(tmp_dir)

        try do
          assert {:ok, settings} = Settings.read()
          assert settings["test_key"] == "test_value"
        after
          File.cd!(original_cwd)
        end
      end)
    end

    test "handles invalid .claude.exs gracefully" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        File.mkdir_p!(Path.join(tmp_dir, ".claude"))

        # Write valid settings.json
        json_settings = %{"json_key" => "json_value"}
        File.write!(Path.join(tmp_dir, ".claude/settings.json"), Jason.encode!(json_settings))

        # Write invalid .claude.exs
        File.write!(Path.join(tmp_dir, ".claude.exs"), "invalid elixir code {{")

        original_cwd = File.cwd!()
        File.cd!(tmp_dir)

        try do
          # Should still read JSON settings and log warning
          assert {:ok, settings} = Settings.read()
          assert settings["json_key"] == "json_value"
        after
          File.cd!(original_cwd)
        end
      end)
    end

    test "handles .claude.exs returning non-map" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        File.mkdir_p!(Path.join(tmp_dir, ".claude"))

        # Write valid settings.json
        json_settings = %{"json_key" => "json_value"}
        File.write!(Path.join(tmp_dir, ".claude/settings.json"), Jason.encode!(json_settings))

        # Write .claude.exs that returns a list
        File.write!(Path.join(tmp_dir, ".claude.exs"), "[1, 2, 3]")

        original_cwd = File.cwd!()
        File.cd!(tmp_dir)

        try do
          # Should ignore invalid .claude.exs and use JSON
          assert {:ok, settings} = Settings.read()
          assert settings["json_key"] == "json_value"
        after
          File.cd!(original_cwd)
        end
      end)
    end

    test "converts atom keys to strings in .claude.exs" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)
        stub(Project, :root, fn -> tmp_dir end)

        # Write .claude.exs with atom keys
        exs_content = """
        %{
          atom_key: "value",
          nested: %{
            another_atom: "nested_value"
          }
        }
        """

        File.write!(Path.join(tmp_dir, ".claude.exs"), exs_content)

        original_cwd = File.cwd!()
        File.cd!(tmp_dir)

        try do
          assert {:ok, settings} = Settings.read()
          assert settings["atom_key"] == "value"
          assert settings["nested"]["another_atom"] == "nested_value"
        after
          File.cd!(original_cwd)
        end
      end)
    end
  end
end
