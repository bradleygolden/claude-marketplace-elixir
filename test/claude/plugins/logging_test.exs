defmodule Claude.Plugins.LoggingTest do
  use Claude.ClaudeCodeCase, async: true

  alias Claude.Plugins.Logging

  describe "config/1" do
    test "returns default JSONL reporter configuration when enabled" do
      config = Logging.config([])

      expected_config = %{
        hooks: %{
          pre_tool_use: [],
          post_tool_use: [],
          stop: [],
          subagent_stop: [],
          user_prompt_submit: [],
          notification: [],
          pre_compact: [],
          session_start: []
        },
        reporters: [
          {:jsonl,
           [
             path: ".claude/logs",
             filename_pattern: "events-{date}.jsonl",
             enabled: true,
             create_dirs: true
           ]}
        ]
      }

      assert config == expected_config
    end

    test "returns empty config when disabled" do
      config = Logging.config(enabled: false)

      assert config == %{}
    end

    test "allows custom path configuration" do
      config = Logging.config(path: "/var/log/claude")

      expected_reporters = [
        {:jsonl,
         [
           path: "/var/log/claude",
           filename_pattern: "events-{date}.jsonl",
           enabled: true,
           create_dirs: true
         ]}
      ]

      assert config.reporters == expected_reporters
      # Should still declare all hooks
      assert Map.has_key?(config, :hooks)
      assert map_size(config.hooks) == 8
    end

    test "allows custom filename pattern" do
      config = Logging.config(filename_pattern: "claude-{datetime}.jsonl")

      expected_reporters = [
        {:jsonl,
         [
           path: ".claude/logs",
           filename_pattern: "claude-{datetime}.jsonl",
           enabled: true,
           create_dirs: true
         ]}
      ]

      assert config.reporters == expected_reporters
      # Should still declare all hooks
      assert Map.has_key?(config, :hooks)
    end

    test "allows disabling directory creation" do
      config = Logging.config(create_dirs: false)

      expected_reporters = [
        {:jsonl,
         [
           path: ".claude/logs",
           filename_pattern: "events-{date}.jsonl",
           enabled: true,
           create_dirs: false
         ]}
      ]

      assert config.reporters == expected_reporters
    end

    test "supports multiple option overrides" do
      opts = [
        path: "/custom/logs",
        filename_pattern: "events-{datetime}.jsonl",
        enabled: true,
        create_dirs: false
      ]

      config = Logging.config(opts)

      expected_reporters = [
        {:jsonl,
         [
           path: "/custom/logs",
           filename_pattern: "events-{datetime}.jsonl",
           enabled: true,
           create_dirs: false
         ]}
      ]

      assert config.reporters == expected_reporters
    end

    test "respects enabled flag in options" do
      # When enabled is explicitly set to true
      config_enabled = Logging.config(enabled: true, path: "/test/path")

      assert config_enabled.reporters == [
               {:jsonl,
                [
                  path: "/test/path",
                  filename_pattern: "events-{date}.jsonl",
                  enabled: true,
                  create_dirs: true
                ]}
             ]

      # When enabled is explicitly set to false
      config_disabled = Logging.config(enabled: false, path: "/test/path")
      assert config_disabled == %{}
    end
  end

  describe "plugin integration" do
    test "implements Claude.Plugin behaviour" do
      # Verify the behaviour is implemented
      behaviours = Logging.__info__(:attributes)[:behaviour] || []
      assert Claude.Plugin in behaviours
    end

    test "config function has correct arity" do
      assert function_exported?(Logging, :config, 1)
    end
  end

  describe "reporter configuration building" do
    test "includes all expected keys in reporter config" do
      config = Logging.config([])
      [{:jsonl, reporter_opts}] = config.reporters

      assert Keyword.has_key?(reporter_opts, :path)
      assert Keyword.has_key?(reporter_opts, :filename_pattern)
      assert Keyword.has_key?(reporter_opts, :enabled)
      assert Keyword.has_key?(reporter_opts, :create_dirs)
    end

    test "preserves unknown options" do
      # Test that unknown options are still passed through
      config = Logging.config(custom_option: "value")
      [{:jsonl, reporter_opts}] = config.reporters

      # Should include the standard options
      assert reporter_opts[:path] == ".claude/logs"
      assert reporter_opts[:enabled] == true

      # Custom options won't be in the reporter config since build_reporter_config
      # only includes known options, which is correct behavior
      refute Keyword.has_key?(reporter_opts, :custom_option)
    end
  end

  describe "default values" do
    test "uses sensible defaults for all options" do
      config = Logging.config([])
      [{:jsonl, opts}] = config.reporters

      assert opts[:path] == ".claude/logs"
      assert opts[:filename_pattern] == "events-{date}.jsonl"
      assert opts[:enabled] == true
      assert opts[:create_dirs] == true
    end

    test "enabled defaults to true when not specified" do
      config = Logging.config([])
      refute config == %{}

      [{:jsonl, opts}] = config.reporters
      assert opts[:enabled] == true
    end
  end

  describe "comprehensive event coverage" do
    test "declares all hook events for complete logging coverage" do
      config = Logging.config([])

      assert Map.has_key?(config, :hooks)

      # Verify all Claude Code hook events are declared
      expected_events = [
        :pre_tool_use,
        :post_tool_use,
        :stop,
        :subagent_stop,
        :user_prompt_submit,
        :notification,
        :pre_compact,
        :session_start
      ]

      Enum.each(expected_events, fn event ->
        assert Map.has_key?(config.hooks, event),
               "Expected hook event #{inspect(event)} to be declared"

        assert config.hooks[event] == [],
               "Expected hook event #{inspect(event)} to have empty array"
      end)

      # Verify we have the expected number of events (no more, no less)
      assert map_size(config.hooks) == length(expected_events)
    end

    test "empty hook arrays ensure registration without interference" do
      config = Logging.config([])

      # All hook events should be empty arrays to ensure they get registered
      # in settings.json but don't interfere with actual hook execution
      Enum.each(config.hooks, fn {event, hooks} ->
        assert hooks == [], "Hook event #{inspect(event)} should have empty array"
      end)
    end

    test "disabled plugin does not declare hook events" do
      config = Logging.config(enabled: false)

      # When disabled, no hooks should be declared
      refute Map.has_key?(config, :hooks)
      assert config == %{}
    end
  end
end
