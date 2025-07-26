defmodule Claude.Hooks.HookExecutionTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  # Test hook that sends a message to the test process
  defmodule ProcessCommunicationHook do
    @behaviour Claude.Hooks.Hook.Behaviour

    def config do
      %Claude.Hooks.Hook{
        type: "command",
        command:
          "mix claude hooks run hooks.hook_execution_test.process_communication_hook",
        matcher: "Write"
      }
    end

    def description do
      "Test hook that communicates via process messages"
    end

    def run(tool_name, json_params) do
      case Jason.decode(json_params) do
        {:ok, %{"file_path" => file_path} = params} ->
          # Send message to test process if PID is provided
          if pid_string = params["test_pid"] do
            pid = pid_string |> Base.decode64!() |> :erlang.binary_to_term()
            send(pid, {:hook_executed, self(), tool_name, file_path})

            # Wait for acknowledgment
            receive do
              :ack -> :ok
            after
              1000 -> {:error, :timeout}
            end
          else
            :ok
          end

        _ ->
          {:error, "Invalid params"}
      end
    end
  end

  # Test hook that uses GenServer for more complex communication
  defmodule GenServerHook do
    @behaviour Claude.Hooks.Hook.Behaviour

    def config do
      %Claude.Hooks.Hook{
        type: "command",
        command: "mix claude hooks run hooks.hook_execution_test.gen_server_hook",
        matcher: "Edit"
      }
    end

    def description do
      "Test hook that uses GenServer for state tracking"
    end

    def run(tool_name, json_params) do
      case Jason.decode(json_params) do
        {:ok, %{"file_path" => file_path} = params} ->
          # Register execution with a test GenServer if provided
          if server_name = params["test_server"] do
            server = String.to_atom(server_name)

            if Process.whereis(server) do
              GenServer.call(server, {:hook_executed, tool_name, file_path})
            else
              {:error, "Server not found"}
            end
          else
            :ok
          end

        _ ->
          {:error, "Invalid params"}
      end
    end
  end

  describe "hook execution with process communication" do
    test "hook sends message to test process and receives acknowledgment" do
      test_pid = self()
      encoded_pid = test_pid |> :erlang.term_to_binary() |> Base.encode64()

      json_params =
        Jason.encode!(%{
          file_path: "/tmp/test.ex",
          test_pid: encoded_pid
        })

      # Execute hook in a separate process to simulate real execution
      task =
        Task.async(fn ->
          ProcessCommunicationHook.run("Write", json_params)
        end)

      # Assert we receive the message from the hook
      assert_receive {:hook_executed, hook_pid, "Write", "/tmp/test.ex"}, 1000

      # Send acknowledgment
      send(hook_pid, :ack)

      # Verify hook completed successfully
      assert :ok = Task.await(task)
    end

    test "multiple hooks can communicate concurrently" do
      test_pid = self()
      encoded_pid = test_pid |> :erlang.term_to_binary() |> Base.encode64()

      # Start multiple hooks concurrently
      tasks =
        for i <- 1..5 do
          Task.async(fn ->
            json_params =
              Jason.encode!(%{
                file_path: "/tmp/test#{i}.ex",
                test_pid: encoded_pid
              })

            ProcessCommunicationHook.run("Write", json_params)
          end)
        end

      # Collect all messages
      received =
        for _ <- 1..5 do
          assert_receive {:hook_executed, hook_pid, "Write", file_path}, 1000
          send(hook_pid, :ack)
          file_path
        end

      # Verify all hooks executed
      assert length(received) == 5

      assert Enum.sort(received) == [
               "/tmp/test1.ex",
               "/tmp/test2.ex",
               "/tmp/test3.ex",
               "/tmp/test4.ex",
               "/tmp/test5.ex"
             ]

      # Verify all tasks completed
      assert Enum.all?(tasks, fn task -> Task.await(task) == :ok end)
    end
  end

  describe "hook execution with GenServer state tracking" do
    defmodule TestServer do
      use GenServer

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, %{executions: []}, opts)
      end

      def init(state) do
        {:ok, state}
      end

      def handle_call({:hook_executed, tool_name, file_path}, _from, state) do
        execution = %{tool: tool_name, file: file_path, timestamp: System.system_time()}
        new_state = %{state | executions: [execution | state.executions]}
        {:reply, :ok, new_state}
      end

      def handle_call(:get_executions, _from, state) do
        {:reply, Enum.reverse(state.executions), state}
      end
    end

    test "hook communicates with GenServer for state tracking" do
      {:ok, server} = TestServer.start_link(name: :test_hook_server)

      json_params =
        Jason.encode!(%{
          file_path: "/tmp/tracked.ex",
          test_server: "test_hook_server"
        })

      # Execute hook
      assert :ok = GenServerHook.run("Edit", json_params)

      # Verify execution was tracked
      executions = GenServer.call(server, :get_executions)
      assert [%{tool: "Edit", file: "/tmp/tracked.ex", timestamp: _}] = executions

      # Clean up
      GenServer.stop(server)
    end

    test "multiple hooks update shared state correctly" do
      {:ok, server} = TestServer.start_link(name: :multi_hook_server)

      # Execute multiple hooks concurrently
      tasks =
        for i <- 1..10 do
          Task.async(fn ->
            json_params =
              Jason.encode!(%{
                file_path: "/tmp/file#{i}.ex",
                test_server: "multi_hook_server"
              })

            GenServerHook.run("Edit", json_params)
          end)
        end

      # Wait for all to complete
      assert Enum.all?(tasks, fn task -> Task.await(task) == :ok end)

      # Verify all executions were tracked
      executions = GenServer.call(server, :get_executions)
      assert length(executions) == 10

      files = Enum.map(executions, & &1.file) |> Enum.sort()
      expected_files = for i <- 1..10, do: "/tmp/file#{i}.ex"
      assert Enum.sort(files) == Enum.sort(expected_files)

      # Clean up
      GenServer.stop(server)
    end
  end

  describe "real hook execution through hook modules" do
    test "built-in hooks execute with real side effects" do
      in_tmp(fn ->
        # Create an unformatted Elixir file
        File.write!("unformatted.ex", """
        defmodule   Unformatted   do
        def   hello(   name   )   do
        "Hello, \#{  name  }!"
        end
        end
        """)

        json_params = Jason.encode!(%{file_path: Path.expand("unformatted.ex")})

        # Execute the real formatter hook
        output =
          capture_io(:stderr, fn ->
            result = Claude.Hooks.PostToolUse.ElixirFormatter.run("Write", json_params)
            assert result == :ok
          end)

        # Verify it detected formatting issues
        assert output =~ "File needs formatting"
        assert output =~ "unformatted.ex"
      end)
    end

    test "custom hooks can be executed directly" do
      test_pid = self()
      encoded_pid = test_pid |> :erlang.term_to_binary() |> Base.encode64()

      json_params =
        Jason.encode!(%{
          file_path: "/tmp/direct_test.ex",
          test_pid: encoded_pid
        })

      # Execute hook directly (simulating what CLI.Hooks.Run does)
      task =
        Task.async(fn ->
          ProcessCommunicationHook.run("Write", json_params)
        end)

      # Verify communication works
      assert_receive {:hook_executed, hook_pid, "Write", "/tmp/direct_test.ex"}, 1000
      send(hook_pid, :ack)
      assert :ok = Task.await(task)
    end
  end

  defp in_tmp(fun) do
    path = Path.join(System.tmp_dir!(), "hook_execution_test_#{:rand.uniform(999_999)}")
    File.mkdir_p!(path)

    original_cwd = File.cwd!()

    try do
      File.cd!(path)
      fun.()
    after
      File.cd!(original_cwd)
      File.rm_rf!(path)
    end
  end
end
