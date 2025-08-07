defmodule Mix.Tasks.Claude.Hooks.Run do
  @moduledoc """
  Dispatcher for Claude hooks. This task reads the .claude.exs configuration
  and executes the appropriate hooks based on the event type and tool matcher.

  ## Usage

      mix claude.hooks.run EVENT_TYPE

  Where EVENT_TYPE is one of:
  - pre_tool_use
  - post_tool_use
  - stop
  - subagent_stop
  - user_prompt_submit
  - notification
  - pre_compact

  The task reads the event data from stdin and executes matching hooks sequentially.
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
      "cmd", args ->
        shell_command = Enum.join(args, " ")

        case System.shell(shell_command, stderr_to_stdout: true) do
          {_output, 0} -> :ok
          {_output, code} -> exit({:shutdown, code})
        end

      command, args ->
        Mix.Task.run(command, args)
    end

    task_runner = Keyword.get(opts, :task_runner, default_task_runner)

    do_run(args, io_reader, config_reader, task_runner)
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
    IO.puts(:stderr, "Usage: mix claude.hooks.run <event_type>")
    System.halt(1)
  end

  defp execute_hooks(event_type, event_data, config, task_runner) do
    event_atom = String.to_atom(event_type)
    hooks = get_hooks_for_event(config, event_atom)
    expanded_hooks = Claude.Hooks.Defaults.expand_hooks(hooks, event_atom)
    matching_hooks = filter_hooks_by_matcher(expanded_hooks, event_data)

    {results, _halted?} = execute_hooks_with_halt(matching_hooks, event_data, task_runner)

    failed_hooks = Enum.filter(results, fn {_hook, exit_code} -> exit_code != 0 end)

    if length(failed_hooks) > 0 do
      IO.puts(:stderr, "\n=== Hook Pipeline Failures ===")

      IO.puts(
        :stderr,
        "#{length(failed_hooks)} of #{length(matching_hooks)} hooks reported issues:"
      )

      Enum.each(failed_hooks, fn {hook, exit_code} ->
        task_name =
          case hook do
            {task, _opts} -> task
            task when is_binary(task) -> task
          end

        IO.puts(:stderr, "  • #{task_name} (exit code: #{exit_code})")
      end)

      IO.puts(:stderr, "\nReview the output above for details on each issue.")

      max_exit_code =
        failed_hooks
        |> Enum.map(fn {_hook, exit_code} -> exit_code end)
        |> Enum.max()

      System.halt(max_exit_code)
    end
  end

  defp get_hooks_for_event(config, event_type) do
    config
    |> Map.get(:hooks, %{})
    |> Map.get(event_type, [])
  end

  defp filter_hooks_by_matcher(hooks, event_data) do
    tool_name = Map.get(event_data, "tool_name")

    Enum.filter(hooks, fn hook ->
      result =
        case hook do
          {_task, opts} when is_list(opts) ->
            matcher = opts[:when]
            command_pattern = opts[:command]

            tool_matches = matches_tool?(matcher, tool_name, event_data)

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

    Process.put(:claude_hook_event, Jason.encode!(event_data))

    env_vars = opts[:env] || %{}
    original_env = save_and_set_env(env_vars)

    exit_code =
      try do
        task_runner.(command, args)
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

        e ->
          IO.puts(:stderr, Exception.format(:error, e, __STACKTRACE__))
          2
      catch
        :exit, {:shutdown, code} when is_integer(code) ->
          code

        :exit, reason ->
          IO.puts(:stderr, "Hook exited: #{inspect(reason)}")
          2
      after
        restore_env(original_env)
      end

    event_name = Map.get(event_data, "hook_event_name", "")

    case {event_name, exit_code} do
      {name, 1} when name in ["pre_tool_use", "user_prompt_submit"] -> 2
      {_, code} -> code
    end
  end

  defp save_and_set_env(env_vars) do
    Enum.map(env_vars, fn {key, value} ->
      original = System.get_env(key)
      System.put_env(key, value)
      {key, original}
    end)
  end

  defp restore_env(original_env) do
    Enum.each(original_env, fn
      {key, nil} -> System.delete_env(key)
      {key, value} -> System.put_env(key, value)
    end)
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
        Keyword.get(opts, :stop_on_failure?, false)

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
