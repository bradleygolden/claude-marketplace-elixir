defmodule Claude.Hook do
  @moduledoc """
  Simple DSL for defining Claude Code hooks.

  Provides a declarative way to define hooks that handles the boilerplate
  of JSON I/O and response formatting while giving direct access to the
  Claude Code native event structures.

  ## Matcher System

  The `matcher` option filters which tools trigger your hook. Claude Code only
  invokes hooks when the tool matches, so you don't need to check `tool_name`
  in your `handle/1` function. For example, if you specify `matcher: [:write, :edit]`,
  your hook will only be called for Write and Edit tools - never for other tools.

  ## Example

      defmodule MyApp.Hooks.ElixirFormatter do
        use Claude.Hook,
          event: :post_tool_use,
          matcher: [:write, :edit, :multi_edit]  # Hook only called for these tools
        
        @impl true
        def handle(%Claude.Hooks.Events.PostToolUse.Input{} = input) do
          # No need to check tool_name - matcher already filtered for us
          case input.tool_input do
            %{file_path: path} when is_binary(path) ->
              if Path.extname(path) in [".ex", ".exs"] do
                case System.cmd("mix", ["format", "--check-formatted", path]) do
                  {_, 0} -> :ok
                  {_, 1} -> {:block, "File needs formatting: \#{path}"}
                  {output, _} -> {:block, "Format failed: \#{output}"}
                end
              else
                :ok  # Not an Elixir file
              end
            _ ->
              :ok  # No file path
          end
        end
      end
  """

  @doc """
  Handle the hook input and return a result.

  The input will be the appropriate parsed event struct based on the event type:
  - PostToolUse: `Claude.Hooks.Events.PostToolUse.Input`
  - PreToolUse: `Claude.Hooks.Events.PreToolUse.Input`
  - UserPromptSubmit: `Claude.Hooks.Events.UserPromptSubmit.Input`
  - Notification: `Claude.Hooks.Events.Notification.Input`
  - Stop: `Claude.Hooks.Events.Stop.Input`
  - SubagentStop: `Claude.Hooks.Events.SubagentStop.Input`
  - PreCompact: `Claude.Hooks.Events.PreCompact.Input`

  ## Return values

  For all events:
  - `:ok` - Success
  - `{:error, reason}` - Error occurred

  For PreToolUse:
  - `{:deny, reason}` - Deny the tool call
  - `{:allow, reason}` - Allow the tool call
  - `{:ask, reason}` - Ask user for confirmation

  For PostToolUse:
  - `{:block, reason}` - Block with feedback to Claude

  For UserPromptSubmit:
  - `{:block, reason}` - Block the prompt
  - `{:add_context, context}` - Add context to the prompt

  For Stop/SubagentStop:
  - `{:block, reason}` - Prevent Claude from stopping
  """
  @callback handle(input :: struct()) ::
              :ok
              | {:error, String.t()}
              | {:block, String.t()}
              | {:deny, String.t()}
              | {:allow, String.t() | nil}
              | {:ask, String.t()}
              | {:add_context, String.t()}

  @doc """
  Executes the hook logic with stdin JSON input.
  """
  @callback run(json_input :: String.t()) :: :ok | {:error, term()}

  def generate_result_handler(event) do
    cases =
      case event do
        :post_tool_use ->
          quote do
            case result do
              :ok ->
                JsonOutput.success(suppress_output: true)
                |> JsonOutput.write_and_exit()

              {:block, reason} ->
                JsonOutput.block_post_tool(reason)
                |> JsonOutput.write_and_exit()

              other ->
                JsonOutput.block_post_tool("Invalid hook response: #{inspect(other)}")
                |> JsonOutput.write_and_exit()
            end
          end

        :pre_tool_use ->
          quote do
            case result do
              :ok ->
                # For PreToolUse, :ok means allow
                JsonOutput.allow_pre_tool(nil, suppress_output: true)
                |> JsonOutput.write_and_exit()

              {:deny, reason} ->
                JsonOutput.deny_pre_tool(reason)
                |> JsonOutput.write_and_exit()

              {:allow, reason} ->
                JsonOutput.allow_pre_tool(reason)
                |> JsonOutput.write_and_exit()

              {:ask, reason} ->
                JsonOutput.ask_pre_tool(reason)
                |> JsonOutput.write_and_exit()

              {:error, reason} ->
                JsonOutput.block_post_tool("Hook error: #{reason}")
                |> JsonOutput.write_and_exit()

              other ->
                JsonOutput.block_post_tool("Invalid hook response: #{inspect(other)}")
                |> JsonOutput.write_and_exit()
            end
          end

        :user_prompt_submit ->
          quote do
            case result do
              :ok ->
                JsonOutput.success(suppress_output: true)
                |> JsonOutput.write_and_exit()

              {:add_context, context} ->
                JsonOutput.add_context(context)
                |> JsonOutput.write_and_exit()

              {:block, reason} ->
                JsonOutput.block_prompt(reason)
                |> JsonOutput.write_and_exit()

              {:error, reason} ->
                JsonOutput.block_post_tool("Hook error: #{reason}")
                |> JsonOutput.write_and_exit()

              other ->
                JsonOutput.block_post_tool("Invalid hook response: #{inspect(other)}")
                |> JsonOutput.write_and_exit()
            end
          end

        event when event in [:stop, :subagent_stop] ->
          quote do
            case result do
              :ok ->
                JsonOutput.success(suppress_output: true)
                |> JsonOutput.write_and_exit()

              {:block, reason} ->
                JsonOutput.block_stop(reason)
                |> JsonOutput.write_and_exit()

              {:error, reason} ->
                JsonOutput.block_post_tool("Hook error: #{reason}")
                |> JsonOutput.write_and_exit()

              other ->
                JsonOutput.block_post_tool("Invalid hook response: #{inspect(other)}")
                |> JsonOutput.write_and_exit()
            end
          end

        _ ->
          quote do
            case result do
              :ok ->
                JsonOutput.success(suppress_output: true)
                |> JsonOutput.write_and_exit()

              {:error, reason} ->
                JsonOutput.block_post_tool("Hook error: #{reason}")
                |> JsonOutput.write_and_exit()

              other ->
                JsonOutput.block_post_tool("Invalid hook response: #{inspect(other)}")
                |> JsonOutput.write_and_exit()
            end
          end
      end

    cases
  end

  @doc """
  Returns a human-readable description of what this hook does.
  """
  @callback description() :: String.t()

  defmacro __using__(opts) do
    event = Keyword.fetch!(opts, :event)
    raw_matcher = Keyword.get(opts, :matcher)
    description = Keyword.get(opts, :description, "Claude Code hook")

    # Convert matcher to the format expected by Claude Code
    # If it's a list of atoms, convert to pipe-separated string
    # If it's a string, keep it as is for regex matching
    matcher =
      case raw_matcher do
        nil -> nil
        str when is_binary(str) -> str
        list when is_list(list) -> Claude.Hooks.format_matcher(list)
        atom when is_atom(atom) -> Claude.Hooks.format_matcher([atom])
      end

    quote do
      @behaviour Claude.Hook

      alias Claude.Hooks.{Helpers, JsonOutput}

      @hook_event unquote(event)
      @hook_matcher unquote(matcher)
      @hook_description unquote(description)
      @hook_identifier Claude.Hooks.generate_identifier(__MODULE__)

      def __hook_event__, do: @hook_event
      def __hook_matcher__, do: @hook_matcher
      def __hook_identifier__, do: @hook_identifier

      @impl Claude.Hook
      def description, do: @hook_description

      @impl Claude.Hook
      def run(:eof), do: :ok

      def run(json_input) when is_binary(json_input) do
        event_type = unquote(event)

        with {:ok, parsed} <- parse_hook_input(json_input, event_type) do
          result = handle(parsed)
          unquote(Claude.Hook.generate_result_handler(event))
        else
          {:error, reason} ->
            JsonOutput.block_post_tool("Hook error: #{reason}")
            |> JsonOutput.write_and_exit()
        end
      rescue
        error ->
          JsonOutput.block_post_tool("Hook crashed: #{inspect(error)}")
          |> JsonOutput.write_and_exit()
      end

      defp parse_hook_input(json_input, event_type) do
        case event_type do
          :post_tool_use ->
            Claude.Hooks.Events.PostToolUse.Input.from_json(json_input)

          :pre_tool_use ->
            Claude.Hooks.Events.PreToolUse.Input.from_json(json_input)

          :notification ->
            Claude.Hooks.Events.Notification.Input.from_json(json_input)

          :user_prompt_submit ->
            Claude.Hooks.Events.UserPromptSubmit.Input.from_json(json_input)

          :stop ->
            Claude.Hooks.Events.Stop.Input.from_json(json_input)

          :subagent_stop ->
            Claude.Hooks.Events.SubagentStop.Input.from_json(json_input)

          :pre_compact ->
            Claude.Hooks.Events.PreCompact.Input.from_json(json_input)

          _ ->
            {:error, "Unknown event type: #{event_type}"}
        end
      end
    end
  end
end
