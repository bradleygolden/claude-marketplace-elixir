defmodule Claude.Hooks do
  @moduledoc """
  Core hooks functionality including registry and installation.
  """

  alias Claude.Core.Settings

  defmodule Hook do
    @moduledoc """
    Struct representing a Claude Code hook configuration.

    This struct is automatically encoded to JSON for the settings.json file.
    """

    @derive Jason.Encoder
    defstruct [:type, :command, :matcher]

    @type t :: %__MODULE__{
            type: String.t(),
            command: String.t(),
            matcher: String.t()
          }

    @doc """
    Creates a new hook configuration.
    """
    def new(attrs) do
      struct!(__MODULE__, attrs)
    end
  end

  defmodule Hook.Behaviour do
    @moduledoc """
    Behaviour for implementing Claude Code hooks.

    Hooks must implement:
    - `config/0` to return their hook configuration as a %Claude.Hooks.Hook{} struct
    - `run/2` to execute the hook logic
    - `description/0` to provide a human-readable description
    """

    @doc """
    Returns the hook configuration as a %Claude.Hook{} struct.

    This configuration will be automatically encoded to JSON and written
    to the settings.json file during installation.
    """
    @callback config() :: Claude.Hooks.Hook.t()

    @doc """
    Executes the hook logic with stdin JSON input.

    ## Parameters
    - `json_input` - The raw JSON string from stdin containing the full hook data

    ## Return values
    - `:ok` - Hook executed successfully
    - `{:error, reason}` - Hook execution failed
    """
    @callback run(json_input :: String.t()) :: :ok | {:error, term()}

    @doc """
    Returns a human-readable description of what this hook does.
    """
    @callback description() :: String.t()
  end

  @hooks [
    Claude.Hooks.PostToolUse.ElixirFormatter,
    Claude.Hooks.PostToolUse.CompilationChecker,
    Claude.Hooks.PreToolUse.PreCommitCheck
  ]

  @doc """
  Returns all available hook modules.
  """
  def all_hooks, do: @hooks

  @doc """
  Finds a hook module by its identifier.

  The identifier is derived from the module name, e.g.:
  - Claude.Hooks.PostToolUse.ElixirFormatter -> "post_tool_use.elixir_formatter"
  """
  def find_hook_by_identifier(identifier) do
    Enum.find(@hooks, fn hook_module ->
      hook_identifier(hook_module) == identifier
    end)
  end

  @doc """
  Returns the identifier for a hook module.
  """
  def hook_identifier(hook_module) do
    hook_module
    |> Module.split()
    |> Enum.drop(2)
    |> Enum.map(&Macro.underscore/1)
    |> Enum.join(".")
  end

  @doc """
  Installs all Claude hooks to the project's settings.json.
  """
  def install do
    case add_all_hooks() do
      :ok ->
        {:ok, "Claude hooks installed successfully in .claude/settings.json"}

      {:error, reason} ->
        {:error, "Failed to install hooks: #{inspect(reason)}"}
    end
  end

  @doc """
  Uninstalls all Claude hooks from the project's settings.json.
  """
  def uninstall do
    case remove_all_hooks() do
      :ok ->
        settings_path = Settings.path()
        dir_path = Path.dirname(settings_path)

        if File.exists?(dir_path) and File.ls!(dir_path) == [] do
          File.rmdir(dir_path)
        end

        {:ok, "Claude hooks uninstalled successfully"}

      {:error, reason} ->
        {:error, "Failed to uninstall hooks: #{inspect(reason)}"}
    end
  end

  defp add_all_hooks do
    Settings.update(fn settings ->
      settings = Map.put_new(settings, "hooks", %{})
      claude_commands = Enum.map(@hooks, fn hook -> hook.config().command end)
      settings = remove_claude_hooks_from_settings(settings, claude_commands)

      hooks_by_event_and_matcher =
        @hooks
        |> Enum.group_by(fn hook_module ->
          event_type =
            hook_module
            |> Module.split()
            |> Enum.at(2)

          matcher = hook_module.config().matcher

          {event_type, matcher}
        end)

      updated_hooks = get_in(settings, ["hooks"]) || %{}

      new_hooks =
        Enum.reduce(hooks_by_event_and_matcher, updated_hooks, fn {{event_type, matcher},
                                                                   hook_modules},
                                                                  acc ->
          existing_matchers = Map.get(acc, event_type, [])

          matcher_index =
            Enum.find_index(existing_matchers, fn m ->
              Map.get(m, "matcher") == matcher
            end)

          hook_configs =
            Enum.map(hook_modules, fn hook_module ->
              config = hook_module.config()

              %{
                "type" => config.type,
                "command" => config.command
              }
            end)

          if matcher_index do
            updated_matchers =
              List.update_at(existing_matchers, matcher_index, fn matcher_obj ->
                existing_hooks = Map.get(matcher_obj, "hooks", [])
                Map.put(matcher_obj, "hooks", existing_hooks ++ hook_configs)
              end)

            Map.put(acc, event_type, updated_matchers)
          else
            new_matcher_obj = %{
              "matcher" => matcher,
              "hooks" => hook_configs
            }

            Map.put(acc, event_type, existing_matchers ++ [new_matcher_obj])
          end
        end)

      Map.put(settings, "hooks", new_hooks)
    end)
  end

  defp remove_all_hooks do
    with {:ok, settings} <- Settings.read() do
      claude_commands = Enum.map(@hooks, fn hook -> hook.config().command end)
      updated = remove_claude_hooks_from_settings(settings, claude_commands)

      if updated == %{} do
        Settings.remove()
      else
        Settings.write(updated)
      end
    end
  end

  defp remove_claude_hooks_from_settings(settings, claude_commands) do
    hooks = Map.get(settings, "hooks", %{})

    updated_hooks =
      hooks
      |> Enum.map(fn
        {event_type, matchers} when is_list(matchers) ->
          updated_matchers =
            matchers
            |> Enum.map(fn matcher_obj ->
              hooks_list = Map.get(matcher_obj, "hooks", [])

              filtered_hooks =
                hooks_list
                |> Enum.reject(fn hook ->
                  command = Map.get(hook, "command", "")

                  Enum.any?(claude_commands, fn claude_cmd ->
                    command == claude_cmd or
                      String.contains?(command, "mix claude hooks run")
                  end)
                end)

              if filtered_hooks == [] do
                :remove
              else
                Map.put(matcher_obj, "hooks", filtered_hooks)
              end
            end)
            |> Enum.reject(&(&1 == :remove))

          if updated_matchers == [] do
            {event_type, :remove}
          else
            {event_type, updated_matchers}
          end

        {event_type, other} ->
          {event_type, other}
      end)
      |> Enum.reject(fn {_, value} -> value == :remove end)
      |> Map.new()

    if updated_hooks == %{} do
      Map.delete(settings, "hooks")
    else
      Map.put(settings, "hooks", updated_hooks)
    end
  end
end
