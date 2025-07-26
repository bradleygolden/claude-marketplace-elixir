defmodule Claude.Hooks do
  @moduledoc """
  Core hooks functionality including registry and installation.
  """

  alias Claude.Core.Settings
  alias Claude.Hooks.Registry
  alias Claude.Config

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

    @doc """
    Returns the event type for a hook module.

    Extracts from module name: Claude.Hooks.PostToolUse.Foo -> "PostToolUse"
    """
    def event_type(hook_module) do
      hook_module
      |> Module.split()
      |> Enum.at(2)
    end

    @doc """
    Returns the identifier for a hook module.

    Converts module name to identifier: Claude.Hooks.PostToolUse.Foo -> "post_tool_use.foo"
    """
    def identifier(hook_module) do
      hook_module
      |> Module.split()
      |> Enum.drop(2)
      |> Enum.map(&Macro.underscore/1)
      |> Enum.join(".")
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

  @doc """
  Finds a hook module by its identifier.

  The identifier is derived from the module name, e.g.:
  - Claude.Hooks.PostToolUse.ElixirFormatter -> "post_tool_use.elixir_formatter"

  This function delegates to the Registry for dynamic hook discovery.
  """
  defdelegate find_hook_by_identifier(identifier), to: Registry, as: :find_by_identifier

  @doc """
  Returns the identifier for a hook module.
  
  @deprecated "Use Claude.Hooks.Hook.identifier/1 directly"
  """
  def hook_identifier(hook_module) do
    Hook.identifier(hook_module)
  end

  @doc """
  Installs all Claude hooks to the project's settings.json.
  """
  def install do
    # Validate custom hooks before installation
    validate_custom_hooks()

    case add_all_hooks() do
      :ok ->
        hook_count = length(Registry.all_hooks())
        custom_count = length(Registry.custom_hooks())

        message =
          if custom_count > 0 do
            "Claude hooks installed successfully in .claude/settings.json (#{hook_count} total, #{custom_count} custom)"
          else
            "Claude hooks installed successfully in .claude/settings.json"
          end

        {:ok, message}

      {:error, reason} ->
        {:error, "Failed to install hooks: #{inspect(reason)}"}
    end
  end

  defp validate_custom_hooks do
    case load_config() do
      {:ok, config} ->
        config
        |> Map.get(:hooks, [])
        |> Enum.each(fn hook_config ->
          module = hook_config[:module]

          cond do
            !is_atom(module) ->
              IO.warn("Invalid hook module: #{inspect(module)} - must be an atom")

            !Registry.hook_module?(module) ->
              IO.warn(
                "Hook module #{module} does not implement Claude.Hooks.Hook.Behaviour or is not available"
              )

            true ->
              :ok
          end
        end)

      {:error, reason} ->
        IO.warn("Failed to load .claude.exs: #{reason}")
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
      claude_commands = Enum.map(Registry.all_hooks(), fn hook -> hook.config().command end)
      settings = remove_claude_hooks_from_settings(settings, claude_commands)

      hooks_by_event_and_matcher = Registry.group_by_event_and_matcher(Registry.all_hooks())

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
      claude_commands = Enum.map(Registry.all_hooks(), fn hook -> hook.config().command end)
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
                  Map.get(hook, "command") in claude_commands
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

  # Use cached config loading if available
  defp load_config do
    if Process.whereis(Claude.Config.Cache) do
      Claude.Config.Cache.get()
    else
      Config.load()
    end
  end
end
