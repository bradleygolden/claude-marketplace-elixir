defmodule Claude.Hooks.Reporters.JsonlTest do
  use Claude.ClaudeCodeCase, async: true
  use Mimic

  alias Claude.Hooks.Reporters.Jsonl

  import ExUnit.CaptureLog

  setup :verify_on_exit!

  setup do
    Mimic.copy(DateTime)
    :ok
  end

  @sample_event_data %{
    "hook_event_name" => "post_tool_use",
    "tool_name" => "Write",
    "session_id" => "test-session-123",
    "tool_input" => %{
      "file_path" => "/test/file.ex",
      "content" => "defmodule Test do\nend"
    },
    "tool_response" => %{
      "success" => true
    },
    "timestamp" => "2024-01-20T15:30:45Z"
  }

  describe "report/2" do
    test "writes event data to JSONL file" do
      with_temp_dir(fn temp_dir ->
        log_path = Path.join(temp_dir, "logs")
        opts = [path: log_path, filename_pattern: "test-events.jsonl"]

        assert Jsonl.report(@sample_event_data, opts) == :ok

        log_file = Path.join(log_path, "test-events.jsonl")
        assert File.exists?(log_file)

        content = File.read!(log_file)
        assert String.ends_with?(content, "\n")

        [line] = String.split(content, "\n", trim: true)
        parsed = Jason.decode!(line)

        assert parsed["session_id"] == "test-session-123"
        assert parsed["event"] == "post_tool_use"
        assert parsed["tool"] == "Write"
        assert parsed["data"]["tool_input"]["file_path"] == "/test/file.ex"
        assert is_binary(parsed["timestamp"])
      end)
    end

    test "appends to existing log file" do
      with_temp_dir(fn temp_dir ->
        log_path = Path.join(temp_dir, "logs")
        opts = [path: log_path, filename_pattern: "append-test.jsonl"]

        assert Jsonl.report(@sample_event_data, opts) == :ok

        second_event = Map.put(@sample_event_data, "tool_name", "Edit")
        assert Jsonl.report(second_event, opts) == :ok

        log_file = Path.join(log_path, "append-test.jsonl")
        content = File.read!(log_file)
        lines = String.split(content, "\n", trim: true)

        assert length(lines) == 2

        first_parsed = Jason.decode!(Enum.at(lines, 0))
        second_parsed = Jason.decode!(Enum.at(lines, 1))

        assert first_parsed["tool"] == "Write"
        assert second_parsed["tool"] == "Edit"
      end)
    end

    test "creates log directory automatically when create_dirs is true" do
      with_temp_dir(fn temp_dir ->
        nested_path = Path.join([temp_dir, "nested", "log", "directory"])
        opts = [path: nested_path, filename_pattern: "auto-dir.jsonl", create_dirs: true]

        assert Jsonl.report(@sample_event_data, opts) == :ok

        log_file = Path.join(nested_path, "auto-dir.jsonl")
        assert File.exists?(log_file)
        assert File.dir?(nested_path)
      end)
    end

    test "fails gracefully when directory doesn't exist and create_dirs is false" do
      with_temp_dir(fn temp_dir ->
        nonexistent_path = Path.join(temp_dir, "nonexistent")
        opts = [path: nonexistent_path, filename_pattern: "no-create.jsonl", create_dirs: false]

        assert {:error, _} = Jsonl.report(@sample_event_data, opts)
        refute File.exists?(Path.join(nonexistent_path, "no-create.jsonl"))
      end)
    end

    test "uses default options when not provided" do
      with_temp_dir(fn temp_dir ->
        File.cd!(temp_dir, fn ->
          File.mkdir_p!(".claude/logs")

          assert Jsonl.report(@sample_event_data, []) == :ok

          today = Date.utc_today() |> Date.to_iso8601()
          expected_file = ".claude/logs/events-#{today}.jsonl"
          assert File.exists?(expected_file)
        end)
      end)
    end

    test "expands filename patterns correctly" do
      with_temp_dir(fn temp_dir ->
        opts = [
          path: temp_dir,
          filename_pattern: "events-{date}-custom.jsonl"
        ]

        assert Jsonl.report(@sample_event_data, opts) == :ok

        today = Date.utc_today() |> Date.to_iso8601()
        expected_file = Path.join(temp_dir, "events-#{today}-custom.jsonl")
        assert File.exists?(expected_file)
      end)
    end

    test "handles datetime pattern in filename" do
      with_temp_dir(fn temp_dir ->
        stub(DateTime, :utc_now, fn ->
          ~U[2024-01-20 15:30:45.123456Z]
        end)

        opts = [
          path: temp_dir,
          filename_pattern: "events-{datetime}.jsonl"
        ]

        assert Jsonl.report(@sample_event_data, opts) == :ok

        expected_file = Path.join(temp_dir, "events-2024_01_20_15_30_45.jsonl")
        assert File.exists?(expected_file)
      end)
    end

    test "handles invalid event data gracefully" do
      with_temp_dir(fn temp_dir ->
        opts = [path: temp_dir, filename_pattern: "error-test.jsonl"]

        log =
          capture_log(fn ->
            assert {:error, :invalid_event_data} = Jsonl.report("invalid", opts)
          end)

        assert log =~ "Failed to build log entry"
        refute File.exists?(Path.join(temp_dir, "error-test.jsonl"))
      end)
    end

    test "handles JSON encoding failures gracefully" do
      invalid_data = %{
        "hook_event_name" => "test",
        "circular" => :this_will_fail_json_encoding
      }

      with_temp_dir(fn temp_dir ->
        opts = [path: temp_dir, filename_pattern: "json-error.jsonl"]

        stub(Jason, :encode, fn _ -> {:error, "encoding failed"} end)

        log =
          capture_log(fn ->
            assert {:error, {:json_encode_failed, "encoding failed"}} =
                     Jsonl.report(invalid_data, opts)
          end)

        assert log =~ "Failed to build log entry"
        refute File.exists?(Path.join(temp_dir, "json-error.jsonl"))
      end)
    end

    test "logs warnings on directory creation failure" do
      opts = [path: "/invalid/path/that/cannot/be/created", filename_pattern: "test.jsonl"]

      log =
        capture_log(fn ->
          assert {:error, {:directory_creation_failed, _}} =
                   Jsonl.report(@sample_event_data, opts)
        end)

      assert log =~ "Failed to create log directory"
    end
  end

  describe "log entry format" do
    test "includes required fields in log entry" do
      with_temp_dir(fn temp_dir ->
        opts = [path: temp_dir, filename_pattern: "format-test.jsonl"]

        assert Jsonl.report(@sample_event_data, opts) == :ok

        log_file = Path.join(temp_dir, "format-test.jsonl")
        content = File.read!(log_file)
        [line] = String.split(content, "\n", trim: true)
        parsed = Jason.decode!(line)

        assert Map.has_key?(parsed, "timestamp")
        assert Map.has_key?(parsed, "session_id")
        assert Map.has_key?(parsed, "event")
        assert Map.has_key?(parsed, "tool")
        assert Map.has_key?(parsed, "data")

        assert parsed["data"] == @sample_event_data
      end)
    end

    test "handles nil values in event data" do
      event_data = %{
        "hook_event_name" => "stop",
        "session_id" => nil,
        "tool_name" => nil
      }

      with_temp_dir(fn temp_dir ->
        opts = [path: temp_dir, filename_pattern: "nil-test.jsonl"]

        assert Jsonl.report(event_data, opts) == :ok

        log_file = Path.join(temp_dir, "nil-test.jsonl")
        content = File.read!(log_file)
        [line] = String.split(content, "\n", trim: true)
        parsed = Jason.decode!(line)

        assert parsed["session_id"] == nil
        assert parsed["tool"] == nil
        assert parsed["event"] == "stop"
      end)
    end

    test "preserves complete event data in data field" do
      complex_event =
        Map.merge(@sample_event_data, %{
          "transcript_path" => "/path/to/transcript.jsonl",
          "cwd" => "/project/root",
          "tool_response" => %{
            "success" => true,
            "file_path" => "/test/file.ex",
            "bytes_written" => 42
          }
        })

      with_temp_dir(fn temp_dir ->
        opts = [path: temp_dir, filename_pattern: "complete-test.jsonl"]

        assert Jsonl.report(complex_event, opts) == :ok

        log_file = Path.join(temp_dir, "complete-test.jsonl")
        content = File.read!(log_file)
        [line] = String.split(content, "\n", trim: true)
        parsed = Jason.decode!(line)

        assert parsed["data"]["transcript_path"] == "/path/to/transcript.jsonl"
        assert parsed["data"]["tool_response"]["bytes_written"] == 42
        assert parsed["data"] == complex_event
      end)
    end
  end

  defp with_temp_dir(fun) do
    temp_dir = System.tmp_dir!() |> Path.join("claude_jsonl_test_#{:rand.uniform(1_000_000)}")

    try do
      File.mkdir_p!(temp_dir)
      fun.(temp_dir)
    after
      File.rm_rf!(temp_dir)
    end
  end
end
