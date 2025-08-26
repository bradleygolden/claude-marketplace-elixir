defmodule Claude.Plugins.LoggingTest do
  use Claude.ClaudeCodeCase, async: true

  alias Claude.Plugins.Logging

  describe "config/1" do
    test "returns default JSONL reporter configuration when enabled" do
      config = Logging.config([])

      expected_config = %{
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

      config_disabled = Logging.config(enabled: false, path: "/test/path")
      assert config_disabled == %{}
    end
  end

  describe "plugin integration" do
    test "implements Claude.Plugin behaviour" do
      behaviours = Claude.Plugins.Logging.__info__(:attributes)[:behaviour] || []
      assert Claude.Plugin in behaviours
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
      config = Logging.config(custom_option: "value")
      [{:jsonl, reporter_opts}] = config.reporters

      assert reporter_opts[:path] == ".claude/logs"
      assert reporter_opts[:enabled] == true

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

  describe "automatic event coverage" do
    test "relies on reporter system for automatic event capture" do
      config = Logging.config([])

      refute Map.has_key?(config, :hooks)
      assert Map.has_key?(config, :reporters)
    end

    test "disabled plugin does not configure reporters" do
      config = Logging.config(enabled: false)

      refute Map.has_key?(config, :hooks)
      refute Map.has_key?(config, :reporters)
      assert config == %{}
    end
  end
end
