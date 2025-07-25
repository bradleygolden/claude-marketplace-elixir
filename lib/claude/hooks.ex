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
    Executes the hook logic.

    ## Parameters
    - `event_type` - The type of event that triggered this hook (e.g., "Write", "Edit")
    - `file_path` - The path to the file being processed

    ## Return values
    - `:ok` - Hook executed successfully
    - `{:error, reason}` - Hook execution failed
    """
    @callback run(event_type :: String.t(), file_path :: String.t()) :: :ok | {:error, term()}

    @doc """
    Returns a human-readable description of what this hook does.
    """
    @callback description() :: String.t()
  end

  @hooks [
    Claude.Hooks.PostToolUse.ElixirFormatter,
    Claude.Hooks.PostToolUse.CompilationChecker
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
      # First remove any existing Claude hooks to ensure clean installation
      claude_commands = Enum.map(@hooks, fn hook -> hook.config().command end)
      settings = remove_claude_hooks_from_settings(settings, claude_commands)

      # Group hooks by event type
      hooks_by_event =
        @hooks
        |> Enum.group_by(fn hook_module ->
          # Extract event type from module name (e.g., PostToolUse)
          hook_module
          |> Module.split()
          |> Enum.at(2)
        end)

      Enum.reduce(hooks_by_event, settings, fn {event_type, hook_modules}, acc ->
        hook_configs = Enum.map(hook_modules, fn hook_module -> hook_module.config() end)

        existing_hooks = get_in(acc, [event_type, "hooks"]) || []
        updated_hooks = existing_hooks ++ hook_configs

        put_in(acc, [event_type], %{"hooks" => updated_hooks})
      end)
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
    settings
    |> Enum.map(fn {event_type, event_config} ->
      case event_config do
        %{"hooks" => hooks} when is_list(hooks) ->
          filtered_hooks =
            hooks
            |> Enum.reject(fn hook ->
              hook["command"] in claude_commands
            end)

          if filtered_hooks == [] do
            {event_type, :remove}
          else
            {event_type, %{"hooks" => filtered_hooks}}
          end

        _ ->
          {event_type, event_config}
      end
    end)
    |> Enum.reject(fn {_, value} -> value == :remove end)
    |> Map.new()
  end
end
