defmodule Claude.Core.JsonUtils do
  @moduledoc """
  Utilities for converting between Elixir snake_case and JSON camelCase.
  """

  @doc """
  Converts a map with snake_case keys to camelCase keys recursively.
  """
  def to_camel_case(map) when is_map(map) do
    Map.new(map, fn {k, v} ->
      key = k |> to_string() |> camelize()
      value = if is_map(v), do: to_camel_case(v), else: v
      {key, value}
    end)
  end

  @doc """
  Converts a snake_case string to camelCase.
  """
  def camelize(string) do
    case String.split(string, "_") do
      [head | tail] ->
        head <> Enum.map_join(tail, "", &String.capitalize/1)
      [] ->
        string
    end
  end
end