defmodule Claude.Subagents.Plugin do
  @moduledoc """
  Behaviour for subagent plugins that enhance subagent capabilities.

  Plugins can add prompt content, tools, and other enhancements to subagents.
  """

  @type opts :: map()
  @type enhancement :: %{
          prompt_additions: String.t() | nil,
          tools: [Claude.Tools.tool()],
          metadata: map()
        }

  @doc """
  Returns the name of the plugin.
  """
  @callback name() :: atom()

  @doc """
  Returns a description of what the plugin does.
  """
  @callback description() :: String.t()

  @doc """
  Enhances a subagent with additional capabilities.

  Receives the plugin options and returns enhancement data that will be
  applied to the subagent.
  """
  @callback enhance(opts()) :: {:ok, enhancement()} | {:error, term()}

  @doc """
  Validates the plugin configuration.

  This is called before enhance/1 to ensure the configuration is valid.
  """
  @callback validate_config(opts()) :: :ok | {:error, String.t()}
end
