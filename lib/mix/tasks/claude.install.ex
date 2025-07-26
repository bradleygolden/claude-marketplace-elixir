if Code.ensure_loaded?(Igniter) do
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
    """

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :claude,
        # *other* dependencies to add
        # i.e `{:foo, "~> 2.0"}`
        adds_deps: [{:claude, "~> 0.1"}],
        # *other* dependencies to add and call their associated installers, if they exist
        # i.e `{:foo, "~> 2.0"}`
        installs: [],
        # An example invocation
        example: "mix igniter.install claude",
        # A list of environments that this should be installed in.
        only: :dev,
        # a list of positional arguments, i.e `[:file]`
        positional: [],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: [],
        # `OptionParser` schema
        schema: [],
        # Default values for the options in the `schema`
        defaults: [],
        # CLI aliases
        aliases: [],
        # A list of options in the schema that are required
        required: [],
        # Installer dependency options
        dep_opts: [runtime: false]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      # Install the hooks by composing the existing task
      # This ensures the hooks are properly set up in .claude/settings.json
      igniter
      |> Igniter.compose_task("claude", ["hooks", "install"])
    end
  end
else
  defmodule Mix.Tasks.Claude.Install do
    @shortdoc "Setup Claude for your Elixir project"

    @moduledoc """
    Setup Claude for your Elixir project.

    This is a fallback task when Igniter is not available.
    For the best experience, install Igniter and use `mix igniter.install claude`.

    ## Usage

        mix claude.install

    ## What it does

    Installs all available Claude hooks including:
    - Auto-formatting for Elixir files after edits
    - Compilation checking to catch errors immediately
    """

    use Mix.Task

    def run(_args) do
      Mix.Task.run("compile", ["--no-deps-check"])
      Mix.Task.run("claude", ["hooks", "install"])
    end
  end
end
