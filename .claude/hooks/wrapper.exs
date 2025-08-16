#!/usr/bin/env elixir

defmodule ClaudeHookWrapper do
  @moduledoc false

  def main(args) do
    case args do
      [event_type] ->
        json_input = IO.read(:stdio, :eof)
        config = load_claude_config()
        ensure_dependencies_installed(config)
        run_hook(event_type, json_input)

      _ ->
        IO.puts(:stderr, "Usage: elixir claude_hook_wrapper.exs <event_type>")
        System.halt(1)
    end
  end

  defp load_claude_config() do
    config_path = ".claude.exs"

    if File.exists?(config_path) do
      try do
        {config, _} = Code.eval_file(config_path)
        config
      rescue
        _ -> %{}
      end
    else
      %{}
    end
  end

  defp ensure_dependencies_installed(config) do
    auto_install? = Map.get(config, :auto_install_deps?, false)

    if auto_install? do
      check_and_install_deps()
    end
  end

  defp check_and_install_deps() do
    port_opts = [
      :binary,
      :exit_status,
      :stderr_to_stdout,
      :use_stdio,
      :hide
    ]

    port = Port.open({:spawn, "mix deps"}, port_opts)
    {output, _exit_status} = collect_port_output(port)

    needs_deps =
      String.contains?(output, "the dependency is not available, run \"mix deps.get\"") ||
        not File.exists?("deps")

    if needs_deps do
      IO.puts(:stderr, "Dependencies not installed. Running mix deps.get...")
      deps_port = Port.open({:spawn, "mix deps.get"}, port_opts)
      {deps_output, deps_exit_status} = collect_port_output(deps_port)

      if deps_exit_status != 0 do
        IO.puts(:stderr, "Failed to install dependencies:")
        IO.puts(:stderr, deps_output)
        System.halt(1)
      else
        IO.puts(:stderr, "Dependencies installed successfully.")
      end
    end
  end

  defp run_hook(event_type, json_input) do
    temp_file = Path.join(System.tmp_dir!(), "claude_hook_#{:os.system_time()}.json")
    File.write!(temp_file, json_input)

    port_opts = [
      :binary,
      :exit_status,
      :stderr_to_stdout,
      :use_stdio,
      :hide
    ]

    command = "sh -c 'mix claude.hooks.run #{event_type} < #{temp_file}'"
    port = Port.open({:spawn, command}, port_opts)

    {output, exit_status} = collect_port_output(port)

    File.rm(temp_file)

    if exit_status == 0 do
      IO.write(:stdio, output)
    else
      IO.write(:stderr, output)
    end

    System.halt(exit_status)
  end

  defp collect_port_output(port, accumulated \\ "") do
    receive do
      {^port, {:data, data}} ->
        collect_port_output(port, accumulated <> data)

      {^port, {:exit_status, status}} ->
        {accumulated, status}
    after
      60_000 ->
        Port.close(port)
        IO.puts(:stderr, "Command timed out after 60 seconds")
        {"", 1}
    end
  end
end

ClaudeHookWrapper.main(System.argv())
