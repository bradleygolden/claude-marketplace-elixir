defmodule Mix.Tasks.Claude.Upgrade do
  @moduledoc """
  Checks if Claude configuration needs upgrading and provides instructions.

  This task checks for outdated configuration formats and provides clear
  instructions for manual migration.

  ## Usage

      mix claude.upgrade

  """

  use Igniter.Mix.Task

  @shortdoc "Checks Claude configuration and provides upgrade instructions"

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      positional: []
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    claude_exs_path = ".claude.exs"

    if Igniter.exists?(igniter, claude_exs_path) do
      result = read_and_eval_claude_exs(igniter, claude_exs_path)

      case result do
        {:ok, config} when is_map(config) ->
          hooks = Map.get(config, :hooks, %{})

          if is_list(hooks) do
            igniter
            |> Igniter.add_issue("""
            Your .claude.exs is using an outdated hooks format.

            Please manually update your .claude.exs file to use the new format:

            %{
              hooks: %{
                stop: [:compile, :format],
                subagent_stop: [:compile, :format],
                post_tool_use: [:compile, :format],
                pre_tool_use: [:compile, :format, :unused_deps]
              }
            }

            After updating, run `mix claude.install` to regenerate the hook scripts.
            """)
          else
            igniter
            |> Igniter.add_notice("Your Claude configuration is already up to date! ✨")
          end

        _error ->
          igniter
      end
    else
      igniter
      |> Igniter.add_notice("No .claude.exs file found. Run `mix claude.install` to create one.")
    end
  end

  defp read_and_eval_claude_exs(igniter, path) do
    try do
      source =
        case Rewrite.source(igniter.rewrite, path) do
          {:ok, source} ->
            source

          {:error, _} ->
            igniter = Igniter.include_existing_file(igniter, path)

            case Rewrite.source(igniter.rewrite, path) do
              {:ok, source} -> source
              _ -> nil
            end
        end

      if source do
        content = Rewrite.Source.get(source, :content)

        case Code.eval_string(content) do
          {config, _bindings} when is_map(config) ->
            {:ok, config}

          _ ->
            {:error, :invalid_config}
        end
      else
        {:error, :file_not_found}
      end
    rescue
      _ -> {:error, :eval_error}
    end
  end
end
