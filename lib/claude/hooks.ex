defmodule Claude.Hooks do
  @moduledoc """
  Core hooks functionality including registry and installation.
  """

  alias Claude.Core.Settings
  alias Claude.Settings, as: SettingsStruct

  defmodule Hook do
    @moduledoc """
    Struct representing a Claude Code hook configuration.

    This struct is automatically encoded to JSON for the settings.json file.
    """

    @derive Jason.Encoder
    defstruct [:type, :command]

    @type t :: %__MODULE__{
            type: String.t(),
            command: String.t()
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
    - `config/1` to return their hook configuration with user-provided config
    - `run/1` to execute the hook logic with JSON input
    - `run/2` to execute the hook logic with JSON input and user config
    - `description/0` to provide a human-readable description

    ## Using the macro

    You can use the `use Claude.Hooks.Hook.Behaviour` macro to reduce boilerplate:

        defmodule MyHook do
          use Claude.Hooks.Hook.Behaviour,
            event: :post_tool_use,
            matcher: "Write|Edit",
            description: "My custom hook"

          def run(input) do
            # Your hook logic here
            :ok
          end
          
          # Override to handle user config
          def run(input, user_config) do
            # Your hook logic with user config
            :ok
          end
        end

    The macro automatically:
    - Implements the behaviour callbacks
    - Generates the config/0 and config/1 functions
    - Provides helper functions for common patterns
    """

    @doc """
    Returns the hook configuration as a %Claude.Hook{} struct.

    This configuration will be automatically encoded to JSON and written
    to the settings.json file during installation.
    """
    @callback config() :: Claude.Hooks.Hook.t()

    @doc """
    Returns the hook configuration with user-provided config.
    """
    @callback config(user_config :: map()) :: Claude.Hooks.Hook.t()

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
    Executes the hook logic with stdin JSON input and user configuration.

    ## Parameters
    - `json_input` - The raw JSON string from stdin containing the full hook data
    - `user_config` - The user configuration from .claude.exs

    ## Return values
    - `:ok` - Hook executed successfully
    - `{:error, reason}` - Hook execution failed
    """
    @callback run(json_input :: String.t(), user_config :: map()) :: :ok | {:error, term()}

    @doc """
    Returns a human-readable description of what this hook does.
    """
    @callback description() :: String.t()

    defmacro __using__(opts) do
      quote bind_quoted: [opts: opts] do
        @behaviour Claude.Hooks.Hook.Behaviour

        @hook_event Keyword.get(opts, :event, :post_tool_use)

        raw_matcher = Keyword.get(opts, :matcher, :*)
        @hook_matcher Claude.Hooks.format_matcher(raw_matcher)

        @hook_description Keyword.get(opts, :description, "")

        @hook_identifier Claude.Hooks.generate_identifier(__MODULE__)

        @impl Claude.Hooks.Hook.Behaviour
        def config do
          %Claude.Hooks.Hook{
            type: "command",
            command: "cd $CLAUDE_PROJECT_DIR && mix claude hooks run #{@hook_identifier}"
          }
        end

        @impl Claude.Hooks.Hook.Behaviour
        def config(_user_config) do
          # For now, ignore user config in command generation
          config()
        end

        @impl Claude.Hooks.Hook.Behaviour
        def description, do: @hook_description

        def __hook_event__, do: @hook_event
        def __hook_matcher__, do: @hook_matcher
        def __hook_identifier__, do: @hook_identifier

        @impl Claude.Hooks.Hook.Behaviour
        def run(json_input) when is_binary(json_input) do
          if json_input == ":eof" do
            :ok
          else
            run(json_input, %{})
          end
        end

        @impl Claude.Hooks.Hook.Behaviour
        def run(json_input, _user_config) when is_binary(json_input) do
          if json_input == ":eof" do
            :ok
          else
            :ok
          end
        end

        defoverridable config: 0, config: 1, description: 0, run: 1, run: 2
      end
    end
  end

  @doc """
  Returns all available hook modules.

  This now uses the dynamic registry to discover hooks at runtime.
  """
  def all_hooks do
    Claude.Hooks.Registry.all_hooks()
  end

  @doc """
  Finds a hook module by its identifier.

  The identifier is derived from the module name, e.g.:
  - Claude.Hooks.PostToolUse.ElixirFormatter -> "post_tool_use.elixir_formatter"
  """
  def find_hook_by_identifier(identifier) do
    Claude.Hooks.Registry.find_by_identifier(identifier)
  end

  @doc """
  Returns the identifier for a hook module.
  """
  def hook_identifier(hook_module) do
    Claude.Hooks.Registry.hook_identifier(hook_module)
  end

  @doc """
  Generates an identifier from a module name.

  Used internally by the Hook.Behaviour macro.
  """
  def generate_identifier(module) when is_atom(module) do
    parts = Module.split(module)

    identifier_parts =
      if Enum.take(parts, 2) == ["Claude", "Hooks"] do
        Enum.drop(parts, 2)
      else
        parts
      end

    identifier_parts
    |> Enum.map(&Macro.underscore/1)
    |> Enum.join(".")
  end

  @doc """
  Converts a matcher specification to Claude Code's expected format.

  ## Examples

      iex> Claude.Hooks.format_matcher([:write, :edit])
      "Write|Edit"

      iex> Claude.Hooks.format_matcher(:bash)
      "Bash"

      iex> Claude.Hooks.format_matcher("Write|Edit")
      "Write|Edit"

      iex> Claude.Hooks.format_matcher([:write, :edit, :multi_edit])
      "Write|Edit|MultiEdit"

      iex> Claude.Hooks.format_matcher(:*)
      "*"

      iex> Claude.Hooks.format_matcher(:manual)
      "manual"

      iex> Claude.Hooks.format_matcher(:auto)
      "auto"
  """
  def format_matcher(:*), do: "*"
  def format_matcher("*"), do: "*"
  def format_matcher(:manual), do: "manual"
  def format_matcher(:auto), do: "auto"
  def format_matcher(matcher) when is_binary(matcher), do: matcher

  def format_matcher(matcher) when is_atom(matcher) do
    matcher
    |> Atom.to_string()
    |> to_title_case()
  end

  def format_matcher(matchers) when is_list(matchers) do
    matchers
    |> Enum.map(&format_matcher/1)
    |> Enum.join("|")
  end

  defp to_title_case(string) do
    string
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join()
  end

  defp get_hook_event_type(hook_module) do
    if function_exported?(hook_module, :__hook_event__, 0) do
      hook_module.__hook_event__()
      |> Atom.to_string()
      |> then(fn s -> s |> String.split("_") |> Enum.map(&String.capitalize/1) |> Enum.join() end)
    else
      hook_module
      |> Module.split()
      |> Enum.at(2)
    end
  end

  defp get_hook_matcher(hook_module) do
    if function_exported?(hook_module, :__hook_matcher__, 0) do
      hook_module.__hook_matcher__()
    else
      "*"
    end
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
    Settings.update(fn settings_map ->
      settings_struct = SettingsStruct.new(settings_map)

      existing_hooks = settings_struct.hooks || %{}

      claude_commands =
        Enum.map(all_hooks(), fn {hook_module, _config} ->
          hook_module.config().command
        end)

      cleaned_hooks = remove_claude_hooks_from_hooks_config(existing_hooks, claude_commands)

      hooks_by_event_and_matcher =
        all_hooks()
        |> Enum.group_by(fn {hook_module, _config} ->
          event_type = get_hook_event_type(hook_module)
          matcher = get_hook_matcher(hook_module)
          {event_type, matcher}
        end)

      new_hooks =
        Enum.reduce(hooks_by_event_and_matcher, cleaned_hooks, fn {{event_type, matcher},
                                                                   hook_modules},
                                                                  acc ->
          existing_matchers = Map.get(acc, event_type, [])

          matcher_index =
            Enum.find_index(existing_matchers, fn m ->
              Map.get(m, "matcher") == matcher
            end)

          hook_configs =
            Enum.map(hook_modules, fn {hook_module, user_config} ->
              config =
                if map_size(user_config) > 0 do
                  hook_module.config(user_config)
                else
                  hook_module.config()
                end

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

      Map.put(settings_map, "hooks", new_hooks)
    end)
  end

  defp remove_all_hooks do
    with {:ok, settings} <- Settings.read() do
      claude_commands =
        Enum.map(all_hooks(), fn {hook_module, _config} ->
          hook_module.config().command
        end)

      updated = remove_claude_hooks_from_settings(settings, claude_commands)

      if updated == %{} do
        Settings.remove()
      else
        Settings.write(updated)
      end
    end
  end

  defp remove_claude_hooks_from_hooks_config(hooks_config, claude_commands) do
    hooks_config
    |> Enum.map(fn
      {event_type, matchers} when is_list(matchers) ->
        updated_matchers =
          matchers
          |> Enum.map(fn matcher_obj ->
            hooks_list = Map.get(matcher_obj, "hooks", [])

            filtered_hooks =
              hooks_list
              |> Enum.reject(fn hook ->
                command =
                  case hook do
                    %Claude.Hooks.Hook{command: cmd} -> cmd
                    %{"command" => cmd} -> cmd
                    _ -> ""
                  end

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
  end

  defp remove_claude_hooks_from_settings(settings, claude_commands) do
    hooks = Map.get(settings, "hooks", %{})
    updated_hooks = remove_claude_hooks_from_hooks_config(hooks, claude_commands)

    if updated_hooks == %{} do
      Map.delete(settings, "hooks")
    else
      Map.put(settings, "hooks", updated_hooks)
    end
  end
end
