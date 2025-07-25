defmodule Claude.Core.Settings do
  @moduledoc """
  Generic settings management for Claude configuration files.
  Handles JSON-based settings that can be used by any feature.
  """

  alias Claude.Core.Project

  @settings_filename "settings.json"

  @doc """
  Returns the path to the settings.json file.
  """
  def path do
    Path.join(Project.claude_path(), @settings_filename)
  end

  @doc """
  Reads settings from the JSON file.
  Returns {:ok, map} or {:error, reason}.
  """
  def read do
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
