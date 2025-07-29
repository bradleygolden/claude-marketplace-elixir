defmodule Claude.Hooks do
  @moduledoc """
  Core hooks functionality providing the Hook behaviour for implementing Claude Code hooks.
  """

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
    require Logger

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

        # Note: config/0 and config/1 are no longer used with script-based hooks
        # They remain here for backwards compatibility but return empty configs
        @impl Claude.Hooks.Hook.Behaviour
        def config do
          %Claude.Hooks.Hook{
            type: "command",
            command: "# Hook command configured by installer"
          }
        end

        @impl Claude.Hooks.Hook.Behaviour
        def config(_user_config) do
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

        @doc """
        Emits a custom telemetry event for this hook.

        This is a convenience function that automatically includes hook metadata
        in the telemetry event. If telemetry is not available, this is a no-op.

        ## Parameters

        - `event_suffix` - Atom or list of atoms to append to [:claude, :hook]
        - `measurements` - Map of measurement data (default: %{})
        - `metadata` - Additional metadata to include (default: %{})

        ## Examples

            # Emit a simple event
            emit_telemetry(:validated)

            # Emit with measurements
            emit_telemetry(:processed, %{file_count: 3, duration_ms: 45})

            # Emit with metadata
            emit_telemetry(:failed, %{}, %{reason: :invalid_syntax})

            # Emit with nested event name
            emit_telemetry([:format, :check], %{files: 10}, %{status: :needs_formatting})
        """
        @spec emit_telemetry(atom() | [atom()], map(), map()) :: :ok
        def emit_telemetry(event_suffix, measurements \\ %{}, metadata \\ %{}) do
          if Code.ensure_loaded?(:telemetry) and Code.ensure_loaded?(Claude.Hooks.Telemetry) do
            Claude.Hooks.Telemetry.emit_event(event_suffix, measurements, metadata, __MODULE__)
          else
            :ok
          end
        end

        defoverridable config: 0, config: 1, description: 0, run: 1, run: 2
      end
    end
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

  @doc """
  Returns the identifier for a hook module.
  """
  def hook_identifier(hook_module) when is_atom(hook_module) do
    if function_exported?(hook_module, :__hook_identifier__, 0) do
      hook_module.__hook_identifier__()
    else
      generate_identifier(hook_module)
    end
  end
end
