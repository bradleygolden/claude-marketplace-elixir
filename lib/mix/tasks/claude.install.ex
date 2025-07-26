if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Claude.Install do
    use Igniter.Mix.Task

    @shortdoc "Setup Claude for your Elixir project"

    @moduledoc """
    Setup Claude for your Elixir project.

    This task is automatically run when you execute:

        mix igniter.install claude
    """

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        schema: [],
        positional: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> Igniter.Project.Deps.add_dep({:claude, "~> 0.1"}, only: :dev, runtime: false)
      |> Igniter.compose_task("claude", ["hooks", "install"])
    end
  end
else
  defmodule Mix.Tasks.Claude.Install do
    use Mix.Task

    @shortdoc "Setup Claude for your Elixir project"

    def run(_) do
      Mix.shell().error("""
      The task 'claude.install' requires igniter to be run.

      Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter
      """)

      exit({:shutdown, 1})
    end
  end
end
