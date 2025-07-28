defmodule Claude.Core.Settings do
  @moduledoc """
  Generic settings management for Claude configuration files.
  Handles JSON-based settings that can be used by any feature.

  ## Security Notice

  This module evaluates `.claude.exs` files using `Code.eval_string/3`. Only load
  `.claude.exs` files from trusted sources, as they can execute arbitrary Elixir code.

  The `.claude.exs` file is intended for project-specific configuration that can be
  shared with your team. Avoid putting sensitive information in this file.
  """

  alias Claude.Core.Project

  @settings_filename "settings.json"
  @claude_exs_filename ".claude.exs"

  @doc """
  Returns the path to the settings.json file.
  """
  def path do
    Path.join(Project.claude_path(), @settings_filename)
  end

  @doc """
  Reads settings from the JSON file and merges with .claude.exs if it exists.
  Returns {:ok, map} or {:error, reason}.
  """
  def read do
    json_settings = read_json_settings()
    exs_settings = read_exs_settings()

    case {json_settings, exs_settings} do
      {{:ok, json}, {:ok, exs}} ->
        {:ok, deep_merge(json, exs)}

      {{:ok, json}, _} ->
        {:ok, json}

      {{:error, :enoent}, {:ok, exs}} ->
        {:ok, exs}

      {{:error, reason}, _} ->
        {:error, reason}
    end
  end

  defp read_json_settings do
    case File.read(path()) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, settings} -> {:ok, settings}
          {:error, _} -> {:error, :invalid_json}
        end

      {:error, :enoent} ->
        {:ok, %{}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp read_exs_settings do
    exs_path = Path.join(Project.root(), @claude_exs_filename)

    case File.read(exs_path) do
      {:ok, content} ->
        try do
          # SECURITY: This evaluates arbitrary Elixir code. Only use with trusted files.
          # The empty binding [] prevents access to current variables, but the evaluated
          # code can still call any Elixir function.
          {result, _binding} = Code.eval_string(content, [], file: exs_path)

          case result do
            map when is_map(map) ->
              {:ok, stringify_keys(map)}

            _ ->
              {:error, :invalid_exs_format}
          end
        rescue
          error in [SyntaxError, TokenMissingError, CompileError] ->
            IO.warn("Syntax error in .claude.exs at #{exs_path}: #{Exception.message(error)}")
            {:ok, %{}}

          error ->
            IO.warn(
              "Error evaluating .claude.exs: #{inspect(error)}\n#{Exception.format_stacktrace(__STACKTRACE__)}"
            )

            {:ok, %{}}
        end

      {:error, :enoent} ->
        {:ok, %{}}

      {:error, _reason} ->
        {:ok, %{}}
    end
  end

  defp stringify_keys(map) when is_map(map) do
    map
    |> Enum.map(fn
      # Filter out the hooks array from .claude.exs as it's only for discovery
      {:hooks, v} when is_list(v) -> nil
      {k, v} when is_atom(k) -> {Atom.to_string(k), stringify_keys(v)}
      {k, v} -> {k, stringify_keys(v)}
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  defp stringify_keys(list) when is_list(list) do
    Enum.map(list, &stringify_keys/1)
  end

  defp stringify_keys(value), do: value

  defp deep_merge(left, right) do
    Map.merge(left, right, fn
      _k, l, r when is_map(l) and is_map(r) -> deep_merge(l, r)
      _k, _l, r -> r
    end)
  end

  @doc """
  Writes settings to the JSON file.
  Creates the directory structure if needed.
  """
  def write(settings) when is_map(settings) do
    ensure_directory()

    content = Jason.encode!(settings, pretty: true)
    File.write(path(), content)
  end

  @doc """
  Updates settings by applying a function to the current settings.
  """
  def update(fun) when is_function(fun, 1) do
    with {:ok, current} <- read(),
         updated when is_map(updated) <- fun.(current),
         :ok <- write(updated) do
      :ok
    end
  end

  @doc """
  Gets a value from settings using a path of keys.

  ## Examples

      get(["hooks", "PostToolUse"])
      get(["memory", "auto_update"], false)
  """
  def get(key_path, default \\ nil) do
    case read() do
      {:ok, settings} -> get_in(settings, key_path) || default
      _ -> default
    end
  end

  @doc """
  Sets a value in settings using a path of keys.
  """
  def put(key_path, value) do
    update(fn settings ->
      put_in(settings, Enum.map(key_path, &Access.key(&1, %{})), value)
    end)
  end

  @doc """
  Checks if the settings file exists.
  """
  def exists? do
    File.exists?(path())
  end

  @doc """
  Removes the settings file if it exists.
  """
  def remove do
    if exists?() do
      File.rm(path())
    else
      :ok
    end
  end

  @doc """
  Checks if settings are effectively empty.
  """
  def empty?(settings) when is_map(settings) do
    settings == %{} or
      (map_size(settings) == 1 and Map.has_key?(settings, "hooks") and settings["hooks"] == %{})
  end

  # Private functions

  defp ensure_directory do
    File.mkdir_p!(Project.claude_path())
  end
end
