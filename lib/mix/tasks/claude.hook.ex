defmodule Mix.Tasks.Claude.Hook do
  @moduledoc """
  Execute Claude hooks defined in .claude.exs by ID.

  This task reads the Claude event JSON from stdin and executes the hooks
  associated with the given ID. It handles template interpolation and
  proper exit codes for Claude integration.

  ## Usage

      mix claude.hook <hook_id>

  ## Example

      echo '{"tool_name": "Write", "tool_input": {"file_path": "lib/foo.ex"}}' | mix claude.hook elixir_quality_checks
  """

  use Mix.Task

  @shortdoc "Execute Claude hooks by ID"

  @impl Mix.Task
  def run([hook_id]) do
    # Read event JSON from stdin
    event = IO.read(:stdio, :eof)

    case Jason.decode(event) do
      {:ok, event_map} ->
        # Store the event in process dictionary for child tasks to read
        Process.put(:claude_hook_event, event)
        # Use String.to_atom since the atom might not exist yet
        execute_hook(String.to_atom(hook_id), event_map)

      {:error, _} ->
        IO.puts(:stderr, "Invalid JSON input")
        System.halt(1)
    end
  end

  def run(_) do
    IO.puts(:stderr, "Usage: mix claude.hook <hook_id>")
    System.halt(1)
  end

  defp execute_hook(hook_id, event) do
    # Load .claude.exs configuration
    config = load_claude_config()

    # Find the hook by ID across all event types
    hook_config = find_hook_by_id(config, hook_id)

    case hook_config do
      nil ->
        IO.puts(:stderr, "Hook not found: #{hook_id}")
        System.halt(1)

      hook ->
        run_hook_tasks(hook, event)
    end
  end

  defp load_claude_config do
    config_path = Path.join(File.cwd!(), ".claude.exs")

    if File.exists?(config_path) do
      {config, _} = Code.eval_file(config_path)
      config
    else
      %{}
    end
  end

  defp find_hook_by_id(config, hook_id) do
    config
    |> Map.get(:hooks, %{})
    |> Enum.flat_map(fn {_event_type, hooks} -> hooks end)
    |> Enum.find(&(&1[:id] == hook_id))
  end

  defp run_hook_tasks(hook_config, event) do
    tasks = Map.get(hook_config, :tasks, [])

    # Execute each task sequentially
    results =
      Enum.map(tasks, fn task_cmd ->
        # Interpolate templates in the command
        interpolated_cmd = interpolate_templates(task_cmd, event)

        # Split into mix task and args
        [task | args] = String.split(interpolated_cmd)

        # Run the mix task
        run_mix_task(task, args, task_cmd)
      end)

    # Check for failures
    handle_results(results)
  end

  defp interpolate_templates(template, data) do
    # Replace {{path.to.value}} with actual values from the data
    Regex.replace(~r/\{\{([^}]+)\}\}/, template, fn _, path ->
      get_nested_value(data, path) || ""
    end)
  end

  defp get_nested_value(data, path) do
    keys = String.split(path, ".")

    Enum.reduce_while(keys, data, fn key, acc ->
      case acc do
        %{^key => value} ->
          {:cont, value}

        acc when is_map(acc) ->
          case Map.get(acc, key) do
            nil -> {:halt, nil}
            value -> {:cont, value}
          end

        _ ->
          {:halt, nil}
      end
    end)
    |> to_string()
  rescue
    _ -> nil
  end

  defp run_mix_task(task, args, original_cmd) do
    # Capture IO to get task output
    captured =
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        ExUnit.CaptureIO.capture_io(fn ->
          try do
            # Run the mix task directly
            Mix.Task.run(task, args)
            :ok
          rescue
            e ->
              {:error, Exception.format(:error, e, __STACKTRACE__)}
          catch
            :exit, {:shutdown, exit_code} when is_integer(exit_code) ->
              {:exit, exit_code}

            :exit, reason ->
              {:error, "Task exited: #{inspect(reason)}"}
          end
        end)
      end)

    case captured do
      {output, :ok} ->
        {:ok, original_cmd, output}

      {output, {:exit, exit_code}} ->
        {:error, original_cmd, output, exit_code}

      {output, {:error, error}} ->
        {:error, original_cmd, output <> "\n" <> error, 1}
    end
  end

  defp handle_results(results) do
    # Find first failure
    case Enum.find(results, fn
           {:error, _, _, _} -> true
           _ -> false
         end) do
      nil ->
        # All tasks succeeded - exit 0
        System.halt(0)

      {:error, task_cmd, output, exit_code} ->
        # Task failed - exit 2 to block and show error to Claude
        IO.puts(:stderr, """
        Mix task failed: #{task_cmd}
        Exit code: #{exit_code}

        #{output}
        """)

        System.halt(2)
    end
  end
end
