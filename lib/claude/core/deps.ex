defmodule Claude.Core.Deps do
  @moduledoc """
  Helper functions for working with project dependencies.
  """

  @doc """
  Check if Phoenix is a dependency in the current project.
  
  Returns true if Phoenix is found in the project's dependencies.
  """
  @spec phoenix_dep?() :: boolean()
  def phoenix_dep? do
    case Mix.Project.config()[:deps] do
      nil -> false
      deps when is_list(deps) ->
        Enum.any?(deps, &match_phoenix_dep/1)
    end
  end
  
  @doc """
  Check if Tidewave is a dependency in the current project.
  
  Returns true if Tidewave is found in the project's dependencies.
  """
  @spec tidewave_dep?() :: boolean()
  def tidewave_dep? do
    case Mix.Project.config()[:deps] do
      nil -> false
      deps when is_list(deps) ->
        Enum.any?(deps, &match_tidewave_dep/1)
    end
  end
  
  defp match_phoenix_dep({:phoenix, _}), do: true
  defp match_phoenix_dep({:phoenix, _, _}), do: true
  defp match_phoenix_dep(_), do: false
  
  defp match_tidewave_dep({:tidewave, _}), do: true
  defp match_tidewave_dep({:tidewave, _, _}), do: true
  defp match_tidewave_dep(_), do: false
end