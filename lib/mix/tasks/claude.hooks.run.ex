defmodule Mix.Tasks.Claude.Hooks.Run do
  @moduledoc """
  Dispatcher for Claude hooks. This task reads the .claude.exs configuration
  and executes the appropriate hooks based on the event type and tool matcher.

  ## Usage

      mix claude.hooks.run EVENT_TYPE [--json-file PATH]

  Where EVENT_TYPE is one of:
  - pre_tool_use
  - post_tool_use
  - stop
  - subagent_stop
  - user_prompt_submit
  - notification
  - pre_compact
  - session_start
  - session_end

  The task reads the event data from stdin by default, or from a file when
  --json-file is provided, and executes matching hooks sequentially.
  """

  use Mix.Task

  @shortdoc "Executes Claude hooks for a given event type"

  @impl Mix.Task
  def run(args) do
    run(args, [])
  end

  @doc false
  def run(args, opts) when is_list(opts) do
    io_reader = Keyword.get(opts, :io_reader, &IO.read/2)
    config_reader = Keyword.get(opts, :config_reader, &Claude.Config.read/0)

    default_task_runner = fn
      "cmd", args, env_vars, output_mode ->
        shell_command = Enum.join(args, " ")
        run_with_port(shell_command, env_vars, output_mode)

      command, args, env_vars, output_mode ->
        mix_command = "mix #{command} #{Enum.join(args, " ")}"
        run_with_port(mix_command, env_vars, output_mode)
    end

    task_runner = Keyword.get(opts, :task_runner, default_task_runner)

    do_run(args, io_reader, config_reader, task_runner)
  end

  defp run_with_port(command, env_vars, output_mode) do
    port_opts = [
      :binary,
      :exit_status,
      :stderr_to_stdout,
      :use_stdio,
      :hide
    ]

    port_opts =
      if map_size(env_vars) > 0 do
        env_list = Enum.map(env_vars, fn {k, v} -> {to_string(k), to_string(v)} end)
        [{:env, env_list} | port_opts]
      else
        port_opts
      end

    port = Port.open({:spawn, command}, port_opts)
    handle_port_output(port, output_mode)
  end

  defp handle_port_output(port, output_mode, accumulated_output \\ "") do
    receive do
      {^port, {:data, data}} ->
        new_accumulated = accumulated_output <> data

        if output_mode == :full do
          IO.write(:stderr, data)
        end

        handle_port_output(port, output_mode, new_accumulated)

      {^port, {:exit_status, 0}} ->
        :ok

      {^port, {:exit_status, status}} ->
        exit({:shutdown, status})
    end
  end

  defp do_run([event_type, "--json-file", file_path], _io_reader, config_reader, task_runner) do
    event_json = File.read!(file_path)

    with {:ok, event_data} <- Jason.decode(event_json),
         {:ok, config} <- config_reader.() do
      execute_hooks(event_type, event_data, config, task_runner)
    else
      {:error, %Jason.DecodeError{}} ->
        IO.puts(:stderr, "Invalid JSON input")
        System.halt(1)

      {:error, reason} ->
        IO.puts(:stderr, "Failed to read .claude.exs: #{reason}")
        System.halt(1)
    end
  end

  defp do_run([event_type], io_reader, config_reader, task_runner) do
    event_json = io_reader.(:stdio, :eof)

    with {:ok, event_data} <- Jason.decode(event_json),
         {:ok, config} <- config_reader.() do
      execute_hooks(event_type, event_data, config, task_runner)
    else
      {:error, %Jason.DecodeError{}} ->
        IO.puts(:stderr, "Invalid JSON input")
        System.halt(1)

      {:error, reason} ->
        IO.puts(:stderr, "Failed to read .claude.exs: #{reason}")
        System.halt(1)
    end
  end

  defp do_run(_, _, _, _) do
    IO.puts(:stderr, "Usage: mix claude.hooks.run <event_type> [--json-file <path>]")
    System.halt(1)
  end

  defp execute_hooks(event_type, event_data, config, task_runner) do
    event_atom = String.to_atom(event_type)
    hooks = get_hooks_for_event(config, event_atom)
    expanded_hooks = Claude.Hooks.Defaults.expand_hooks(hooks, event_atom)
    matching_hooks = filter_hooks_by_matcher(expanded_hooks, event_data)

    {results, _halted?} = execute_hooks_with_halt(matching_hooks, event_data, task_runner)

    Claude.Hooks.Reporter.dispatch(event_data, config)

    failed_hooks = Enum.filter(results, fn {_hook, exit_code} -> exit_code != 0 end)

    if length(failed_hooks) > 0 do
      IO.puts(:stderr, "\n=== Hook Pipeline Failures ===")

      IO.puts(
        :stderr,
        "#{length(failed_hooks)} of #{length(matching_hooks)} hooks reported issues:"
      )

      Enum.each(failed_hooks, fn {hook, exit_code} ->
        {task_name, opts} =
          case hook do
            {task, opts} -> {task, opts}
            task when is_binary(task) -> {task, []}
          end

        is_non_blocking_stop =
          Keyword.get(opts, :blocking?, true) == false and
            event_atom in [:stop, :subagent_stop]

        if is_non_blocking_stop do
          IO.puts(
            :stderr,
            "  • #{task_name} (informational only - non-blocking to prevent loops)"
          )
        else
          IO.puts(:stderr, "  • #{task_name} (exit code: #{exit_code})")
        end
      end)

      IO.puts(:stderr, "\nRun the failed commands directly to see details.")

      all_failed_are_non_blocking_stop_hooks? =
        event_atom in [:stop, :subagent_stop] and
          Enum.all?(failed_hooks, fn {hook, _exit_code} ->
            case hook do
              {_task, opts} when is_list(opts) ->
                Keyword.get(opts, :blocking?, true) == false

              _ ->
                false
            end
          end)

      if all_failed_are_non_blocking_stop_hooks? do
        System.halt(0)
      else
        max_exit_code =
          failed_hooks
          |> Enum.map(fn {_hook, exit_code} -> exit_code end)
          |> Enum.max()

        System.halt(max_exit_code)
      end
    end
  end

  defp get_hooks_for_event(config, event_type) do
    config
    |> Map.get(:hooks, %{})
    |> Map.get(event_type, [])
  end

  defp filter_hooks_by_matcher(hooks, event_data) do
    tool_name = Map.get(event_data, "tool_name")
    source = Map.get(event_data, "source")
    reason = Map.get(event_data, "reason")
    event_type = Map.get(event_data, "hook_event_name")

    Enum.filter(hooks, fn hook ->
      result =
        case hook do
          {_task, opts} when is_list(opts) ->
            matcher = opts[:when]
            command_pattern = opts[:command]

            tool_matches =
              cond do
                event_type == "SessionStart" ->
                  matches_source?(matcher, source, event_data)

                event_type == "SessionEnd" ->
                  matches_source?(matcher, reason, event_data)

                true ->
                  matches_tool?(matcher, tool_name, event_data)
              end

            if tool_matches && command_pattern do
              matches_command?(command_pattern, event_data)
            else
              tool_matches
            end

          task when is_binary(task) ->
            true
        end

      result
    end)
  end

  defp matches_source?(nil, _source, _event_data), do: true
  defp matches_source?("*", _source, _event_data), do: true

  defp matches_source?(matchers, source, _event_data) when is_list(matchers) do
    Enum.any?(matchers, fn matcher ->
      matches_single_source?(matcher, source)
    end)
  end

  defp matches_source?(matcher, source, _event_data) do
    matches_single_source?(matcher, source)
  end

  defp matches_single_source?(matcher, source) when is_atom(matcher) do
    Atom.to_string(matcher) == source
  end

  defp matches_single_source?(matcher, source) when is_binary(matcher) do
    matcher == source
  end

  defp matches_single_source?(_matcher, _source), do: false

  defp matches_tool?(nil, _tool_name, _event_data), do: true
  defp matches_tool?("*", _tool_name, _event_data), do: true

  defp matches_tool?(matchers, tool_name, event_data) when is_list(matchers) do
    Enum.any?(matchers, fn matcher ->
      matches_single_matcher?(matcher, tool_name, event_data)
    end)
  end

  defp matches_tool?(matcher, tool_name, event_data) do
    matches_single_matcher?(matcher, tool_name, event_data)
  end

  defp matches_single_matcher?(matcher, tool_name, _event_data) when is_atom(matcher) do
    formatted_tool = matcher |> Atom.to_string() |> Macro.camelize()
    formatted_tool == tool_name
  end

  defp matches_single_matcher?(matcher, tool_name, event_data) when is_binary(matcher) do
    cond do
      String.starts_with?(matcher, "Bash(") and String.ends_with?(matcher, ")") ->
        if tool_name == "Bash" do
          pattern =
            matcher
            |> String.trim_leading("Bash(")
            |> String.trim_trailing(")")
            |> String.trim_trailing(":*")

          command = get_in(event_data, ["tool_input", "command"]) || ""
          String.starts_with?(command, pattern)
        else
          false
        end

      true ->
        matcher == tool_name
    end
  end

  defp matches_single_matcher?(_matcher, _tool_name, _event_data), do: false

  defp matches_command?(pattern, event_data) when is_struct(pattern, Regex) do
    command = get_in(event_data, ["tool_input", "command"]) || ""
    Regex.match?(pattern, command)
  end

  defp matches_command?(pattern, event_data) when is_binary(pattern) do
    command = get_in(event_data, ["tool_input", "command"]) || ""
    String.starts_with?(command, pattern)
  end

  defp matches_command?(_pattern, _event_data), do: false

  defp execute_single_hook(hook, event_data, task_runner) do
    {task, opts} =
      case hook do
        {task, opts} when is_list(opts) ->
          {task, opts}

        {task} when is_binary(task) ->
          {task, []}

        tuple when is_tuple(tuple) and tuple_size(tuple) >= 2 ->
          [task | keyword_args] = Tuple.to_list(tuple)
          {task, keyword_args}

        task when is_binary(task) ->
          {task, []}
      end

    interpolated_task = interpolate_templates(task, event_data)

    {command, args} =
      if String.starts_with?(interpolated_task, "cmd ") do
        ["cmd" | rest_parts] = String.split(interpolated_task, " ")
        {"cmd", rest_parts}
      else
        [command | args] = String.split(interpolated_task, " ")
        {command, args}
      end

    env_vars = opts[:env] || %{}
    output_mode = opts[:output] || :none

    exit_code =
      try do
        task_runner.(command, args, env_vars, output_mode)
        0
      rescue
        Mix.NoTaskError ->
          IO.puts(:stderr, """
          The Mix task "#{command}" could not be found.

          If this is meant to be a shell command, prefix it with 'cmd':
            Example: "cmd #{command} #{Enum.join(args, " ")}"

          If this is meant to be a Mix task, ensure it exists by running:
            mix help
          """)

          2

        e in Mix.Error ->
          IO.puts(:stderr, e.message)
          2

        e ->
          IO.puts(:stderr, Exception.format(:error, e, __STACKTRACE__))
          2
      catch
        :exit, {:shutdown, code} when is_integer(code) ->
          code

        :exit, reason ->
          IO.puts(:stderr, "Hook exited: #{inspect(reason)}")
          2
      end

    apply_exit_code_rules(exit_code, opts, event_data)
  end

  defp apply_exit_code_rules(exit_code, opts, _event_data) do
    blocking? = Keyword.get(opts, :blocking?, true)

    cond do
      exit_code == 0 ->
        0

      blocking? ->
        2

      true ->
        exit_code
    end
  end

  defp execute_hooks_with_halt(hooks, event_data, task_runner) do
    Enum.reduce_while(hooks, {[], false}, fn hook, {results, _halted?} ->
      exit_code = execute_single_hook(hook, event_data, task_runner)
      new_results = [{hook, exit_code} | results]

      should_halt = hook_should_halt?(hook) and exit_code != 0

      if should_halt do
        {:halt, {Enum.reverse(new_results), true}}
      else
        {:cont, {new_results, false}}
      end
    end)
    |> case do
      {results, halted?} -> {Enum.reverse(results), halted?}
    end
  end

  defp hook_should_halt?(hook) do
    case hook do
      {_task, opts} when is_list(opts) ->
        Keyword.get(opts, :halt_pipeline?, false)

      _ ->
        false
    end
  end

  defp interpolate_templates(task, event_data) do
    Regex.replace(~r/\{\{([^}]+)\}\}/, task, fn _, path ->
      keys = String.split(path, ".")

      case get_in(event_data, keys) do
        nil -> ""
        value -> to_string(value)
      end
    end)
  end
end
