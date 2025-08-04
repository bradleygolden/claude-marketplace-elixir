defmodule Claude.Hooks do
  @moduledoc """
  Core hooks functionality and utilities for Claude Code hooks.

  This module provides:
  - The Config struct for JSON configuration
  - Utility functions for formatting matchers and generating identifiers
  """

  defmodule Config do
    @moduledoc """
    Struct representing a Claude Code hook configuration for JSON serialization.

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

  @doc """
  Generates an identifier from a module name.

  Used internally by the Claude.Hook macro.
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
