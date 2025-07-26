defmodule Mix.Tasks.Claude.Install do
  @shortdoc "Setup Claude for your Elixir project"

  @moduledoc """
  Setup Claude for your Elixir project.

  This task is automatically run when you execute:

      mix igniter.install claude

  It sets up Claude Code integration for your Elixir project by:

  1. Installing all Claude hooks for auto-formatting and compilation checking
  2. Ensuring your project is properly configured for Claude Code integration

  ## Example

  ```sh
  mix igniter.install claude
  ```

  ## Direct Usage

  ```sh
  mix claude.install
  ```
  """

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :claude,
      example: "mix igniter.install claude",
      only: [:dev],
      dep_opts: [runtime: false]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    igniter
    |> Igniter.compose_task("claude.hooks.install", [])
  end
end
