defmodule Claude.Plugins.Dialyzer do
  @moduledoc """
  Dialyzer plugin for Claude Code providing static type analysis support.

  This plugin configures Claude Code to run Dialyzer for type checking. Since Dialyzer
  analyzes the entire project (not individual files), running it after every file edit
  can be slow on large projects.

  ## Usage

  Add to your `.claude.exs`:

      %{
        plugins: [Claude.Plugins.Dialyzer]
      }

  This will run Dialyzer before git commits by default.

  For more aggressive checking (runs after file edits):

      %{
        plugins: [{Claude.Plugins.Dialyzer, post_edit_check?: true}]
      }

  To disable all checks:

      %{
        plugins: [{Claude.Plugins.Dialyzer, pre_commit_check?: false, post_edit_check?: false}]
      }

  ## Options

  * `:pre_commit_check?` - Whether to run Dialyzer before git commits (default: `true`)
  * `:post_edit_check?` - Whether to run Dialyzer after file edits (default: `false`)
    Note: This can be slow on large projects since Dialyzer analyzes the entire codebase
  """

  @behaviour Claude.Plugin

  @impl Claude.Plugin
  def config(opts) do
    hooks = %{}

    hooks =
      if Keyword.get(opts, :post_edit_check?, false) do
        Map.put(hooks, :post_tool_use, [
          {"dialyzer", when: [:write, :edit, :multi_edit]}
        ])
      else
        hooks
      end

    hooks =
      if Keyword.get(opts, :pre_commit_check?, true) do
        pre_tool_use = Map.get(hooks, :pre_tool_use, [])

        Map.put(
          hooks,
          :pre_tool_use,
          pre_tool_use ++
            [
              {"dialyzer", when: "Bash", command: ~r/^git commit/}
            ]
        )
      else
        hooks
      end

    %{hooks: hooks}
  end
end
