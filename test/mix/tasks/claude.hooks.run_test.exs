defmodule Mix.Tasks.Claude.Hooks.RunTest do
  use Claude.ClaudeCodeCase, setup_project?: true
  use Mimic

  alias Mix.Tasks.Claude.Hooks.Run

  setup :verify_on_exit!
  setup :setup_test_directory
  setup :stub_system_calls

  setup do
    [
      project_files: %{
        ".claude.exs" => """
        %{}
        """
      }
    ]
  end

  defp stub_system_calls(_context) do
    test_pid = self()

    stub(System, :get_env, fn key -> System.get_env(key) end)

    stub(IO, :puts, fn :stderr, msg ->
      send(test_pid, {:stderr_output, msg})
      :ok
    end)

    stub(System, :halt, fn code ->
      send(test_pid, {:system_halt, code})
      :ok
    end)

    :ok
  end

  describe "atom expansion for default hooks" do
    test "expands :compile atom in stop event" do
      config = %{
        hooks: %{
          stop: [:compile]
        }
      }

      event_data = %{
        "tool_name" => "Stop",
        "hook_event_name" => "stop"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "compile", ["--warnings-as-errors"]}
    end

    test "expands :format atom with file path interpolation in post_tool_use" do
      config = %{
        hooks: %{
          post_tool_use: [:format]
        }
      }

      event_data = %{
        "tool_name" => "Write",
        "tool_input" => %{"file_path" => "lib/test.ex"},
        "hook_event_name" => "post_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "format", ["--check-formatted", "lib/test.ex"]}
    end

    test "expands multiple atoms in pre_tool_use for git commit" do
      config = %{
        hooks: %{
          pre_tool_use: [:compile, :format, :unused_deps]
        }
      }

      event_data = %{
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "git commit -m 'test'"},
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "compile", ["--warnings-as-errors"]}
      assert_received {:mix_task_run, "format", ["--check-formatted"]}
      assert_received {:mix_task_run, "deps.unlock", ["--check-unused"]}
    end

    test "handles mixed atoms and explicit configurations" do
      config = %{
        hooks: %{
          stop: [
            :compile,
            "custom task",
            {"another --task", halt_pipeline?: false}
          ]
        }
      }

      event_data = %{
        "tool_name" => "Stop",
        "hook_event_name" => "stop"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "compile", ["--warnings-as-errors"]}
      assert_received {:mix_task_run, "custom", ["task"]}
      assert_received {:mix_task_run, "another", ["--task"]}
    end
  end

  describe "cmd prefix for shell commands" do
    test "executes shell commands with 'cmd' prefix" do
      config = %{
        hooks: %{
          pre_tool_use: [
            {"cmd echo 'Hello from shell'", when: "Write"},
            {"compile --warnings-as-errors", when: "Edit"}
          ]
        }
      }

      event_data = %{
        "tool_name" => "Write",
        "tool_input" => %{"file_path" => "test.ex"},
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:task_executed, task, args})
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:task_executed, "cmd", ["echo", "'Hello", "from", "shell'"]}
    end

    test "executes Mix tasks without 'cmd' prefix" do
      config = %{
        hooks: %{
          pre_tool_use: [
            {"format --check-formatted", when: "Write"}
          ]
        }
      }

      event_data = %{
        "tool_name" => "Write",
        "tool_input" => %{"file_path" => "test.ex"},
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:task_executed, task, args})
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:task_executed, "format", ["--check-formatted"]}
    end

    test "provides helpful error message for non-existent Mix tasks" do
      config = %{
        hooks: %{
          pre_tool_use: [
            {"nonexistent_task --some-flag", when: "Write"}
          ]
        }
      }

      event_data = %{
        "tool_name" => "Write",
        "tool_input" => %{"file_path" => "test.ex"},
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:task_executed, task, args})
        # Simulate Mix.NoTaskError for non-cmd tasks
        if task != "cmd" do
          raise Mix.NoTaskError, task: task
        else
          :ok
        end
      end

      # Stub System.halt to prevent test from exiting
      stub_system_calls(self())

      output =
        capture_io(:stderr, fn ->
          Run.run(["pre_tool_use"],
            io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
            config_reader: fn -> {:ok, config} end,
            task_runner: task_runner
          )
        end)

      # Verify the error was raised and System.halt was called
      assert_received {:task_executed, "nonexistent_task", ["--some-flag"]}
      assert_received {:system_halt, 2}

      # If output is captured, verify the error message
      if output != "" do
        assert output =~ "nonexistent_task"
        assert output =~ "could not be found"
        assert output =~ "cmd" and output =~ "shell command"
      end
    end

    test "cmd prefix works with complex shell commands" do
      config = %{
        hooks: %{
          pre_tool_use: [
            {"cmd echo 'Error: --no-verify is not allowed' >&2; exit 2",
             when: "Bash", command: ~r/^git commit.*--no-verify/}
          ]
        }
      }

      event_data = %{
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "git commit --no-verify -m 'test'"},
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:task_executed, task, args})
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:task_executed, "cmd",
                       [
                         "echo",
                         "'Error:",
                         "--no-verify",
                         "is",
                         "not",
                         "allowed'",
                         ">&2;",
                         "exit",
                         "2"
                       ]}
    end
  end

  describe "hook filtering" do
    test "filters hooks by tool name for atoms", _context do
      config = %{
        hooks: %{
          pre_tool_use: [
            {"task1", when: [:write, :edit]},
            {"task2", when: [:read]},
            {"task3", when: [:write, :edit, :multi_edit]}
          ]
        }
      }

      event_data = %{
        "tool_name" => "Edit",
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "task1", _}
      assert_received {:mix_task_run, "task3", _}
      refute_received {:mix_task_run, "task2", _}
    end

    test "matches Bash command patterns with regex", _context do
      config = %{
        hooks: %{
          pre_tool_use: [
            {"task1", when: "Bash", command: ~r/^git commit/},
            {"task2", when: "Bash", command: ~r/^npm/},
            {"task3", when: "Bash", command: ~r/^ls/}
          ]
        }
      }

      event_data = %{
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "git commit -m 'test'"},
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "task1", _}
      refute_received {:mix_task_run, "task2", _}
      refute_received {:mix_task_run, "task3", _}
    end

    test "supports complex regex patterns for commands", _context do
      config = %{
        hooks: %{
          pre_tool_use: [
            {"security-check", when: "Bash", command: ~r/curl.*(-X\s*POST|-d)/},
            {"test-runner", when: "Bash", command: ~r/^(npm|yarn|pnpm)\s+(test|jest)/},
            {"docker-build", when: "Bash", command: ~r/docker\s+build/i}
          ]
        }
      }

      # Test curl POST detection
      event_data = %{
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "curl -X POST https://api.example.com"},
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "security-check", _}
      refute_received {:mix_task_run, "test-runner", _}
      refute_received {:mix_task_run, "docker-build", _}
    end

    test "backwards compatible with old Bash() syntax", _context do
      config = %{
        hooks: %{
          pre_tool_use: [
            {"task1", when: "Bash(git commit:*)"},
            # New syntax
            {"task2", when: "Bash", command: ~r/^npm/}
          ]
        }
      }

      event_data = %{
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "git commit -m 'test'"},
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "task1", _}
      refute_received {:mix_task_run, "task2", _}
    end

    test "blocks git commit with --no-verify flag", _context do
      stub_system_calls(self())

      config = %{
        hooks: %{
          pre_tool_use: [
            {"cmd echo 'Error: --no-verify is not allowed' >&2; exit 2",
             when: "Bash", command: ~r/^git commit.*--no-verify/, halt_pipeline?: true},
            {"compile --warnings-as-errors",
             when: "Bash", command: ~r/^git commit(?!.*--no-verify)/}
          ]
        }
      }

      # Test git commit with --no-verify
      event_data = %{
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "git commit --no-verify -m 'test'"},
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        # Simulate the cmd echo/exit command - it should fail with exit code 2
        if task == "cmd" && Enum.any?(args, &String.contains?(&1, "--no-verify")) do
          IO.puts(:stderr, "Error: --no-verify is not allowed")
          exit({:shutdown, 2})
        end

        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "cmd", _}
      refute_received {:mix_task_run, "compile", _}
      assert_received {:system_halt, 2}
    end

    test "matches tool without command pattern", _context do
      config = %{
        hooks: %{
          pre_tool_use: [
            # Runs for any Write tool
            {"format", when: "Write"},
            # Runs for any Bash command (no command filter)
            {"compile", when: "Bash"}
          ]
        }
      }

      # Test Write tool
      event_data = %{
        "tool_name" => "Write",
        "tool_input" => %{"file_path" => "test.ex"},
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "format", _}
      refute_received {:mix_task_run, "compile", _}
    end

    test "handles hooks without matchers", _context do
      config = %{
        hooks: %{
          post_tool_use: [
            "task1",
            {"task2", when: [:write]},
            "task3"
          ]
        }
      }

      event_data = %{
        "tool_name" => "Read",
        "hook_event_name" => "post_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "task1", _}
      refute_received {:mix_task_run, "task2", _}
      assert_received {:mix_task_run, "task3", _}
    end

    test "template interpolation replaces variables", _context do
      config = %{
        hooks: %{
          post_tool_use: [
            "format --check-formatted {{tool_input.file_path}}"
          ]
        }
      }

      event_data = %{
        "tool_input" => %{"file_path" => "lib/test.ex"},
        "hook_event_name" => "post_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "format", ["--check-formatted", "lib/test.ex"]}
    end

    test "template interpolation handles nested paths", _context do
      config = %{
        hooks: %{
          post_tool_use: [
            "echo {{tool_response.output.status}}"
          ]
        }
      }

      event_data = %{
        "tool_response" => %{
          "output" => %{"status" => "success"}
        },
        "hook_event_name" => "post_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "echo", ["success"]}
    end

    test "template interpolation handles missing values", _context do
      config = %{
        hooks: %{
          post_tool_use: [
            "echo {{missing.path}}"
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "post_tool_use"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "echo", [""]}
    end
  end

  describe "exit code handling" do
    test "exits with 0 when all hooks succeed", _context do
      config = %{
        hooks: %{
          post_tool_use: ["test.success"]
        }
      }

      event_data = %{
        "hook_event_name" => "post_tool_use",
        "tool_name" => "Write",
        "tool_input" => %{"file_path" => "test.ex"}
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        :ok
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.success"}
      refute_received {:system_halt, _}
    end

    test "exits with 2 when any hook fails with blocking error", _context do
      config = %{
        hooks: %{
          pre_tool_use: ["test.blocking_error"]
        }
      }

      event_data = %{
        "hook_event_name" => "pre_tool_use",
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "rm -rf /"}
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        if String.contains?(task, "blocking"), do: raise("Blocking error")
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.blocking_error"}
      assert_received {:system_halt, 2}
    end

    test "converts exit code 1 to 2 for PreToolUse events", _context do
      config = %{
        hooks: %{
          pre_tool_use: ["compile --warnings-as-errors"]
        }
      }

      event_data = %{
        "hook_event_name" => "pre_tool_use",
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "git commit -m 'test'"}
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        # Simulate a task that exits with code 1 (like compile --warnings-as-errors failing)
        if task == "compile" && "--warnings-as-errors" in args do
          exit({:shutdown, 1})
        end
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "compile", ["--warnings-as-errors"]}
      # Should convert exit code 1 to 2 for PreToolUse
      assert_received {:system_halt, 2}
    end

    test "converts exit code 1 to 2 for UserPromptSubmit events", _context do
      config = %{
        hooks: %{
          user_prompt_submit: ["validate"]
        }
      }

      event_data = %{
        "hook_event_name" => "user_prompt_submit",
        "prompt" => "delete everything"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        # Simulate a validation task that fails
        if task == "validate" do
          exit({:shutdown, 1})
        end
      end

      Run.run(["user_prompt_submit"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "validate", []}
      # Should convert exit code 1 to 2 for UserPromptSubmit to block the prompt
      assert_received {:system_halt, 2}
    end

    test "escalates exit code 1 to 2 by default for all events", _context do
      config = %{
        hooks: %{
          post_tool_use: ["compile --warnings-as-errors"]
        }
      }

      event_data = %{
        "hook_event_name" => "post_tool_use",
        "tool_name" => "Write",
        "tool_input" => %{"file_path" => "test.ex"}
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})

        if task == "compile" && "--warnings-as-errors" in args do
          exit({:shutdown, 1})
        end
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "compile", ["--warnings-as-errors"]}
      assert_received {:system_halt, 2}
    end

    test "escalates exit code 1 to 2 by default for Stop events", _context do
      config = %{
        hooks: %{
          stop: ["check"]
        }
      }

      event_data = %{
        "hook_event_name" => "stop",
        "stop_hook_active" => false
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        # Simulate a check that fails but shouldn't block stoppage
        if task == "check" do
          exit({:shutdown, 1})
        end
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "check", []}
      assert_received {:system_halt, 2}
    end

    test "exits with 0 when all failed stop hooks have blocking?: false", _context do
      config = %{
        hooks: %{
          stop: [
            {"check", blocking?: false}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop",
        "stop_hook_active" => false
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})

        if task == "check" do
          exit({:shutdown, 1})
        end
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "check", []}
      assert_received {:system_halt, 0}
    end

    test "preserves exit codes when mixed blocking and non-blocking hooks fail", _context do
      config = %{
        hooks: %{
          stop: [
            {"check1", blocking?: true},
            {"check2", blocking?: false}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop",
        "stop_hook_active" => false
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})

        cond do
          task == "check1" -> exit({:shutdown, 1})
          task == "check2" -> exit({:shutdown, 3})
          true -> :ok
        end
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "check1"}
      assert_received {:mix_task_run, "check2"}
      assert_received {:system_halt, 3}
    end

    test "converts all non-zero exit codes to 2 when blocking? is true", _context do
      config = %{
        hooks: %{
          stop: [
            {"check", blocking?: true}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop",
        "stop_hook_active" => false
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})

        if task == "check" do
          exit({:shutdown, 3})
        end
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "check", []}
      assert_received {:system_halt, 2}
    end

    test "exits with 0 when all stop hooks have blocking?: false and fail", _context do
      config = %{
        hooks: %{
          stop: [
            {"test.check1", blocking?: false},
            {"test.check2", blocking?: false},
            {"test.check3", blocking?: false}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop",
        "stop_hook_active" => false
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        # All tasks fail with exit code 1
        exit({:shutdown, 1})
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      # Should receive all task runs
      assert_received {:mix_task_run, "test.check1"}
      assert_received {:mix_task_run, "test.check2"}
      assert_received {:mix_task_run, "test.check3"}

      assert_received {:system_halt, 0}

      informational_messages =
        Stream.repeatedly(fn ->
          receive do
            {:stderr_output, msg} -> msg
          after
            50 -> nil
          end
        end)
        |> Enum.take_while(&(&1 != nil))
        |> Enum.join(" ")

      assert informational_messages =~ "informational only - non-blocking"
    end

    test "aggregates multiple hook failures", _context do
      config = %{
        hooks: %{
          stop: [
            "test.success",
            "test.failure",
            "test.another_failure"
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop",
        "session_id" => "test123"
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})

        cond do
          String.contains?(task, "failure") -> raise "Task failed"
          String.contains?(task, "success") -> :ok
          true -> :ok
        end
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.success"}
      assert_received {:mix_task_run, "test.failure"}
      assert_received {:mix_task_run, "test.another_failure"}
      assert_received {:system_halt, 2}

      # Skip over any exception stacktraces to find the summary
      {pipeline_found, issues_found} =
        Enum.reduce(1..10, {false, false}, fn _, {p, i} ->
          if p and i do
            {p, i}
          else
            receive do
              {:stderr_output, msg} when is_binary(msg) ->
                new_p = p or msg =~ "Hook Pipeline Failures"
                new_i = i or msg =~ "2 of 3 hooks reported issues"
                {new_p, new_i}
            after
              50 -> {p, i}
            end
          end
        end)

      assert pipeline_found, "Should receive Hook Pipeline Failures message"
      assert issues_found, "Should receive hook count message"
    end

    test "continues execution with non-blocking errors", _context do
      config = %{
        hooks: %{
          post_tool_use: [
            "test.non_blocking_error",
            "test.success"
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "post_tool_use",
        "tool_name" => "Edit",
        "tool_input" => %{"file_path" => "test.ex"}
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        if String.contains?(task, "error"), do: raise("Non-blocking error")
        :ok
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.non_blocking_error"}
      assert_received {:mix_task_run, "test.success"}
      assert_received {:system_halt, 2}
    end
  end

  describe "output routing" do
    test "stdout shown to user on success", _context do
      config = %{
        hooks: %{
          post_tool_use: ["test.success"]
        }
      }

      event_data = %{
        "hook_event_name" => "post_tool_use"
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        :ok
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.success"}
    end

    test "stderr fed to Claude on blocking error", _context do
      config = %{
        hooks: %{
          pre_tool_use: ["test.blocking"]
        }
      }

      event_data = %{
        "hook_event_name" => "pre_tool_use"
      }

      task_runner = fn _task, _args, _env_vars, _output_mode ->
        raise "Blocking error"
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:system_halt, 2}
      assert_received {:stderr_output, msg}
      assert is_binary(msg) and msg =~ "Blocking error"
    end

    test "stderr shown to user on non-blocking error", _context do
      config = %{
        hooks: %{
          post_tool_use: ["test.warning"]
        }
      }

      event_data = %{
        "hook_event_name" => "post_tool_use"
      }

      task_runner = fn _task, _args, _env_vars, _output_mode ->
        raise "Warning message"
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:system_halt, 2}
      assert_received {:stderr_output, msg}
      assert is_binary(msg) and msg =~ "Warning message"
    end
  end

  describe "event-specific behaviors" do
    test "PreToolUse with exit 2 blocks tool execution", _context do
      config = %{
        hooks: %{
          pre_tool_use: [
            {"test.validate_permissions", when: [:write]}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "pre_tool_use",
        "tool_name" => "Write",
        "tool_input" => %{"file_path" => "/etc/passwd"}
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        if String.contains?(task, "validate"), do: raise("Permission denied")
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.validate_permissions"}
      assert_received {:system_halt, 2}
    end

    test "PostToolUse with exit 2 shows error to Claude", _context do
      config = %{
        hooks: %{
          post_tool_use: [
            {"test.check_format", when: [:edit]}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "post_tool_use",
        "tool_name" => "Edit",
        "tool_input" => %{"file_path" => "lib/test.ex"},
        "tool_response" => %{"success" => true}
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        if String.contains?(task, "check_format"), do: raise("Format error")
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.check_format"}
      assert_received {:system_halt, 2}
    end

    test "Stop hook with exit 2 blocks stoppage", _context do
      config = %{
        hooks: %{
          stop: ["test.validate_before_stop"]
        }
      }

      event_data = %{
        "hook_event_name" => "stop",
        "stop_hook_active" => false
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        raise "Validation failed"
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.validate_before_stop"}
      assert_received {:system_halt, 2}
    end

    test "UserPromptSubmit stdout added to context", _context do
      config = %{
        hooks: %{
          user_prompt_submit: ["test.add_context"]
        }
      }

      event_data = %{
        "hook_event_name" => "user_prompt_submit",
        "prompt" => "Test prompt"
      }

      test_pid = self()

      task_runner = fn _task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, "test.add_context"})
        :ok
      end

      Run.run(["user_prompt_submit"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.add_context"}
    end
  end

  describe "integration tests" do
    test "full hook pipeline with multiple hooks", _context do
      config = %{
        hooks: %{
          post_tool_use: [
            {"test.success", when: [:write, :edit]},
            {"test.check_format", when: [:edit]}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "post_tool_use",
        "tool_name" => "Edit",
        "tool_input" => %{"file_path" => "lib/test.ex"}
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        if String.contains?(task, "check_format"), do: raise("Format check failed")
        :ok
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.success"}
      assert_received {:mix_task_run, "test.check_format"}
      assert_received {:system_halt, 2}
    end

    test "hook pipeline continues after non-halt_pipeline errors", _context do
      config = %{
        hooks: %{
          pre_tool_use: [
            "test.success",
            "test.error",
            "test.another_task"
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "pre_tool_use",
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "dangerous command"}
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        if String.contains?(task, "error"), do: raise("Error occurred")
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.success"}
      assert_received {:mix_task_run, "test.error"}
      assert_received {:mix_task_run, "test.another_task"}
      assert_received {:system_halt, 2}
    end

    test "parallel hook execution", _context do
      config = %{
        hooks: %{
          stop: [
            "test.success",
            "test.non_blocking_error",
            "test.blocking_error"
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop",
        "session_id" => "test123"
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})

        cond do
          String.contains?(task, "blocking_error") -> raise "Blocking error"
          String.contains?(task, "non_blocking_error") -> raise "Non-blocking error"
          true -> :ok
        end
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.success"}
      assert_received {:mix_task_run, "test.non_blocking_error"}
      assert_received {:mix_task_run, "test.blocking_error"}
      assert_received {:system_halt, 2}
    end

    test "template interpolation in real hook execution", _context do
      config = %{
        hooks: %{
          post_tool_use: [
            {"echo {{tool_input.file_path}}", when: [:write]}
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "post_tool_use",
        "tool_name" => "Write",
        "tool_input" => %{"file_path" => "lib/my_file.ex"}
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "echo", ["lib/my_file.ex"]}
    end

    test "error aggregation with multiple failures", _context do
      config = %{
        hooks: %{
          stop: [
            "test.failure",
            "test.another_failure",
            "test.blocking_error"
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop",
        "session_id" => "test123"
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        raise "#{task} failed"
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.failure"}
      assert_received {:mix_task_run, "test.another_failure"}
      assert_received {:mix_task_run, "test.blocking_error"}
      assert_received {:system_halt, 2}

      {pipeline_found, issues_found} =
        Enum.reduce(1..10, {false, false}, fn _, {p, i} ->
          if p and i do
            {p, i}
          else
            receive do
              {:stderr_output, msg} when is_binary(msg) ->
                new_p = p or msg =~ "Hook Pipeline Failures"
                new_i = i or msg =~ "3 of 3 hooks reported issues"
                {new_p, new_i}
            after
              50 -> {p, i}
            end
          end
        end)

      assert pipeline_found, "Should receive Hook Pipeline Failures message"
      assert issues_found, "Should receive hook count message"
    end
  end

  describe "session_start hooks" do
    test "filters hooks by source matcher" do
      config = %{
        hooks: %{
          session_start: [
            {"startup_task", when: :startup},
            {"resume_task", when: "resume"},
            {"clear_task", when: [:clear]},
            "always_runs"
          ]
        }
      }

      event_data = %{
        "session_id" => "test123",
        "hook_event_name" => "SessionStart",
        "source" => "startup"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["session_start"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "startup_task", []}
      assert_received {:mix_task_run, "always_runs", []}
      refute_received {:mix_task_run, "resume_task", _}
      refute_received {:mix_task_run, "clear_task", _}
    end

    test "supports multiple source matchers in list" do
      config = %{
        hooks: %{
          session_start: [
            {"multi_source_task", when: [:startup, :resume]},
            {"clear_only_task", when: "clear"}
          ]
        }
      }

      event_data = %{
        "session_id" => "test123",
        "hook_event_name" => "SessionStart",
        "source" => "resume"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["session_start"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "multi_source_task", []}
      refute_received {:mix_task_run, "clear_only_task", _}
    end

    test "runs hooks without source matcher for all sources" do
      config = %{
        hooks: %{
          session_start: [
            "no_matcher_task",
            {"specific_task", when: :startup}
          ]
        }
      }

      event_data = %{
        "session_id" => "test123",
        "hook_event_name" => "SessionStart",
        "source" => "clear"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["session_start"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "no_matcher_task", []}
      refute_received {:mix_task_run, "specific_task", _}
    end

    test "handles mixed atom and string source matchers" do
      config = %{
        hooks: %{
          session_start: [
            {"atom_matcher", when: :startup},
            {"string_matcher", when: "startup"},
            {"mixed_list", when: [:resume, "clear"]}
          ]
        }
      }

      event_data = %{
        "session_id" => "test123",
        "hook_event_name" => "SessionStart",
        "source" => "startup"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["session_start"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "atom_matcher", []}
      assert_received {:mix_task_run, "string_matcher", []}
      refute_received {:mix_task_run, "mixed_list", _}
    end

    test "session_start doesn't use tool_name matching" do
      config = %{
        hooks: %{
          session_start: [
            {"session_task", when: :startup}
          ]
        }
      }

      event_data = %{
        "session_id" => "test123",
        "hook_event_name" => "SessionStart",
        "source" => "startup"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["session_start"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "session_task", []}
    end

    test "validates all three source types: startup, resume, clear" do
      config = %{
        hooks: %{
          session_start: [
            {"startup_only", when: "startup"},
            {"resume_only", when: :resume},
            {"clear_only", when: "clear"}
          ]
        }
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      ["startup", "resume", "clear"]
      |> Enum.each(fn source ->
        event_data = %{
          "session_id" => "test123",
          "hook_event_name" => "SessionStart",
          "source" => source
        }

        Run.run(["session_start"],
          io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
          config_reader: fn -> {:ok, config} end,
          task_runner: task_runner
        )

        expected_task = source <> "_only"
        assert_received {:mix_task_run, ^expected_task, []}
      end)
    end
  end

  describe "halt_pipeline? flag" do
    test "stops execution when hook with halt_pipeline? fails", _context do
      config = %{
        hooks: %{
          pre_tool_use: [
            {"test.validator", [halt_pipeline?: true]},
            "test.should_not_run"
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        if String.contains?(task, "validator"), do: raise("Validation failed")
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.validator"}
      refute_received {:mix_task_run, "test.should_not_run"}
      assert_received {:system_halt, 2}
    end

    test "continues when hooks with halt_pipeline? succeed", _context do
      config = %{
        hooks: %{
          post_tool_use: [
            {"test.check1", [halt_pipeline?: true]},
            {"test.check2", [halt_pipeline?: true]},
            "test.final"
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "post_tool_use"
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        :ok
      end

      Run.run(["post_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.check1"}
      assert_received {:mix_task_run, "test.check2"}
      assert_received {:mix_task_run, "test.final"}
    end

    test "continues after failure when halt_pipeline? is false", _context do
      config = %{
        hooks: %{
          pre_tool_use: [
            {"test.check1", []},
            {"test.check2", []},
            "test.final"
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "pre_tool_use"
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})
        if String.contains?(task, "check"), do: raise("Check failed")
        :ok
      end

      Run.run(["pre_tool_use"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.check1"}
      assert_received {:mix_task_run, "test.check2"}
      assert_received {:mix_task_run, "test.final"}
      assert_received {:system_halt, 2}
    end

    test "handles mixed halt_pipeline? flags", _context do
      config = %{
        hooks: %{
          stop: [
            {"test.check1", []},
            {"test.check2", []},
            {"test.critical", [halt_pipeline?: true]},
            "test.should_not_run"
          ]
        }
      }

      event_data = %{
        "hook_event_name" => "stop"
      }

      test_pid = self()

      task_runner = fn task, _args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task})

        cond do
          String.contains?(task, "check") -> raise "Check failed"
          String.contains?(task, "critical") -> raise "Critical failure"
          true -> :ok
        end
      end

      Run.run(["stop"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "test.check1"}
      assert_received {:mix_task_run, "test.check2"}
      assert_received {:mix_task_run, "test.critical"}
      refute_received {:mix_task_run, "test.should_not_run"}
      assert_received {:system_halt, 2}
    end
  end

  describe "session_end hooks" do
    test "runs session_end hooks with reason" do
      config = %{
        hooks: %{
          session_end: [
            "cleanup_task",
            {"log_session_stats", when: "logout"}
          ]
        }
      }

      event_data = %{
        "session_id" => "test123",
        "hook_event_name" => "SessionEnd",
        "reason" => "logout"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["session_end"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      # cleanup_task should run (no matcher)
      assert_received {:mix_task_run, "cleanup_task", []}
      # log_session_stats should run (matches "logout" reason)
      assert_received {:mix_task_run, "log_session_stats", []}
    end

    test "session_end hooks respect reason matching" do
      config = %{
        hooks: %{
          session_end: [
            {"clear_cache", when: "clear"},
            {"save_session", when: ["logout", "exit"]},
            "always_run"
          ]
        }
      }

      event_data = %{
        "session_id" => "test123",
        "hook_event_name" => "SessionEnd",
        "reason" => "clear"
      }

      test_pid = self()

      task_runner = fn task, args, _env_vars, _output_mode ->
        send(test_pid, {:mix_task_run, task, args})
        :ok
      end

      Run.run(["session_end"],
        io_reader: fn :stdio, :eof -> Jason.encode!(event_data) end,
        config_reader: fn -> {:ok, config} end,
        task_runner: task_runner
      )

      assert_received {:mix_task_run, "clear_cache", []}
      assert_received {:mix_task_run, "always_run", []}
      refute_received {:mix_task_run, "save_session", _}
    end
  end
end
