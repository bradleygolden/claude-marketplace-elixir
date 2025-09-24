defmodule Mix.Tasks.Claude.Hooks.RunEnvTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Mix.Tasks.Claude.Hooks.Run

  describe "env option with isolated port environment" do
    test "env variables are passed to task runner" do
      config = %{
        hooks: %{
          stop: [
            {:compile, env: %{"MIX_ENV" => "custom_test", "DEBUG" => "true"}}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop"
      }

      test_pid = self()

      task_runner = fn task, _args, env_vars, _output_mode ->
        send(test_pid, {:task_executed, task, env_vars})
        :ok
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      # Verify task was executed with correct env vars
      assert_received {:task_executed, "compile", env}
      assert env == %{"MIX_ENV" => "custom_test", "DEBUG" => "true"}
    end

    test "multiple hooks receive their own env values" do
      config = %{
        hooks: %{
          stop: [
            {:compile, env: %{"MIX_ENV" => "test"}},
            {:format, env: %{"MIX_ENV" => "dev", "FORMAT_STRICT" => "true"}}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop"
      }

      test_pid = self()

      task_runner = fn task, _args, env_vars, _output_mode ->
        send(test_pid, {:task_executed, task, env_vars})
        :ok
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      # Each hook should receive its own env
      assert_received {:task_executed, "compile", %{"MIX_ENV" => "test"}}
      assert_received {:task_executed, "format", %{"MIX_ENV" => "dev", "FORMAT_STRICT" => "true"}}
    end

    test "env option works across different event types" do
      # Test post_tool_use
      config = %{
        hooks: %{
          post_tool_use: [
            {:compile, env: %{"MIX_ENV" => "prod"}}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "post_tool_use",
        "tool_name" => "Write",
        "tool_input" => %{"file_path" => "/test.ex"}
      }

      test_pid = self()

      task_runner = fn task, _args, env_vars, _output_mode ->
        send(test_pid, {:task_executed, task, env_vars})
        :ok
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:task_executed, "compile", %{"MIX_ENV" => "prod"}}
    end

    test "empty env map results in no env vars" do
      config = %{
        hooks: %{
          stop: [
            {:compile, env: %{}}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop"
      }

      test_pid = self()

      task_runner = fn task, _args, env_vars, _output_mode ->
        send(test_pid, {:task_executed, task, env_vars})
        :ok
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:task_executed, "compile", %{}}
    end

    test "hooks without env option receive empty map" do
      config = %{
        hooks: %{
          stop: [
            "format"
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop"
      }

      test_pid = self()

      task_runner = fn task, args, env_vars, _output_mode ->
        send(test_pid, {:task_executed, task, args, env_vars})
        :ok
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:task_executed, "format", [], %{}}
    end

    test "env vars work with cmd prefix" do
      config = %{
        hooks: %{
          stop: [
            {"cmd echo $TEST_VAR", env: %{"TEST_VAR" => "hello"}}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop"
      }

      test_pid = self()

      task_runner = fn task, args, env_vars, _output_mode ->
        send(test_pid, {:task_executed, task, args, env_vars})
        :ok
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:task_executed, "cmd", ["echo", "$TEST_VAR"], %{"TEST_VAR" => "hello"}}
    end

    test "env vars preserved through hook expansion" do
      config = %{
        hooks: %{
          pre_tool_use: [
            {:compile, env: %{"MIX_ENV" => "test", "CI" => "true"}},
            {:format, env: %{"CHECK_FORMATTED" => "strict"}}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "pre_tool_use",
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "git commit -m 'test'"}
      }

      test_pid = self()

      task_runner = fn task, _args, env_vars, _output_mode ->
        send(test_pid, {:task_executed, task, env_vars})
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      # Verify env vars were preserved through expansion
      assert_received {:task_executed, "compile", %{"MIX_ENV" => "test", "CI" => "true"}}
      assert_received {:task_executed, "format", %{"CHECK_FORMATTED" => "strict"}}
    end
  end
end
