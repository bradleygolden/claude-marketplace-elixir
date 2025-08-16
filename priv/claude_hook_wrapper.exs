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
    case System.cmd("mix", ["deps"], stderr_to_stdout: true) do
      {output, _} ->
        needs_deps? =
          String.contains?(output, "the dependency is not available, run \"mix deps.get\"") ||
            not File.exists?("deps")

        if needs_deps? do
          IO.puts(:stderr, "Dependencies not installed. Running mix deps.get...")

          case System.cmd("mix", ["deps.get"], stderr_to_stdout: true) do
            {_, 0} ->
              IO.puts(:stderr, "Dependencies installed successfully.")

            {output, _} ->
              IO.puts(:stderr, "Failed to install dependencies:")
              IO.puts(:stderr, output)
              System.halt(1)
          end
        end
    end
  end

  defp run_hook(event_type, json_input) do
    temp_file = Path.join(System.tmp_dir!(), "claude_hook_#{:os.system_time()}.json")

    try do
      File.write!(temp_file, json_input)

      {output, exit_status} = System.cmd(
        "mix",
        ["claude.hooks.run", event_type, "--json-file", temp_file],
        stderr_to_stdout: true
      )

      if exit_status == 0 do
        IO.write(:stdio, output)
      else
        IO.write(:stderr, output)
      end

      System.halt(exit_status)
    after
      File.rm(temp_file)
    end
  end
end

ClaudeHookWrapper.main(System.argv())