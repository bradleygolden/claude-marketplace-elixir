defmodule Claude.Plugins.Credo do
  @moduledoc """
  Credo plugin for Claude Code providing code quality and static analysis support.

  This plugin automatically configures Claude Code for Credo-enabled projects by:

  * **Automatic Analysis**: Runs Credo after file edits to catch issues early
  * **Configurable Strictness**: Control whether to run Credo in strict mode
  * **Optional Pre-commit Checks**: Can run Credo before git commits to ensure code quality

  ## Usage

  Add to your `.claude.exs`:

      %{
        plugins: [Claude.Plugins.Credo]
      }

  Or with options:

      %{
        plugins: [{Claude.Plugins.Credo, strict?: true, pre_commit_check?: true}]
      }

  ## Options

  * `:strict?` - Whether to run Credo in strict mode (default: `false`)
  * `:pre_commit_check?` - Whether to run Credo before git commits (default: `false`)
  """

  @behaviour Claude.Plugin

  @impl Claude.Plugin
  def config(opts) do
    opts
    |> build_credo_command()
    |> build_base_hooks()
    |> maybe_add_pre_commit(opts)
    |> wrap_in_config()
  end

  defp build_credo_command(opts) do
    strict_flag = if Keyword.get(opts, :strict?, false), do: " --strict", else: ""
    "credo#{strict_flag} {{tool_input.file_path}}"
  end

  defp build_base_hooks(credo_command) do
    %{
      post_tool_use: [
        {credo_command, when: [:write, :edit, :multi_edit]}
      ]
    }
  end

  defp maybe_add_pre_commit(hooks, opts) do
    if Keyword.get(opts, :pre_commit_check?, false) do
      credo_command = build_credo_command(opts)

      Map.put(hooks, :pre_tool_use, [
        {credo_command, when: "Bash", command: ~r/^git commit/}
      ])
    else
      hooks
    end
  end

  defp wrap_in_config(hooks) do
    %{hooks: hooks}
  end
end
