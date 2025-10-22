defmodule Claude.Plugin do
  @moduledoc "Support for Claude configuration plugins."

  @doc "Detect if this plugin should be active for the current project."
  @callback detect(igniter :: Igniter.t() | nil) :: boolean()

  @doc "Generate configuration for this plugin."
  @callback config(opts :: keyword()) :: map()

  @doc "Load a single plugin and return its configuration."
  def load_plugin({module, opts}) when is_atom(module) and is_list(opts) do
    load_plugin(module, opts)
  end

  def load_plugin(module) when is_atom(module) do
    load_plugin(module, [])
  end

  def load_plugin(module, opts) when is_atom(module) and is_list(opts) do
    if Code.ensure_loaded?(module) do
      behaviours = module.module_info(:attributes)[:behaviour] || []

      if Claude.Plugin in behaviours do
        try do
          igniter = Keyword.get(opts, :igniter)

          if module.detect(igniter) do
            config = module.config(Keyword.delete(opts, :igniter))
            {:ok, config}
          else
            {:ok, %{}}
          end
        rescue
          error ->
            {:error, "Plugin #{inspect(module)} failed to load: #{Exception.message(error)}"}
        end
      else
        {:error, "Plugin #{inspect(module)} does not implement Claude.Plugin behaviour"}
      end
    else
      {:error, "Plugin module #{inspect(module)} not found"}
    end
  end

  @doc "Load multiple plugins and return their configurations."
  def load_plugins(plugins) when is_list(plugins) do
    results = Enum.map(plugins, &load_plugin/1)

    case Enum.split_with(results, fn {status, _} -> status == :ok end) do
      {successes, []} ->
        configs = Enum.map(successes, fn {:ok, config} -> config end)
        {:ok, configs}

      {_, errors} ->
        error_messages = Enum.map(errors, fn {:error, message} -> message end)
        {:error, error_messages}
    end
  end

  @doc "Extract nested memories from plugin configurations."
  def get_nested_memories(configs) when is_list(configs) do
    configs
    |> Enum.flat_map(fn config ->
      Map.get(config, :nested_memories, %{})
      |> Enum.to_list()
    end)
    |> Enum.group_by(fn {path, _} -> path end, fn {_, memories} -> memories end)
    |> Enum.into(%{}, fn {path, memory_lists} ->
      {path, List.flatten(memory_lists)}
    end)
  end

  @doc "Merge multiple configuration maps together."
  def merge_configs([]), do: %{}
  def merge_configs([single_config]), do: single_config

  def merge_configs([first | rest]) do
    Enum.reduce(rest, first, fn next_config, acc -> deep_merge(acc, next_config) end)
  end

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      merge_values(left_value, right_value)
    end)
  end

  defp deep_merge(_left, right), do: right

  defp merge_values(left, right) when is_map(left) and is_map(right) do
    deep_merge(left, right)
  end

  defp merge_values(left, right) when is_list(left) and is_list(right) do
    cond do
      Enum.all?(left ++ right, &is_simple_value/1) ->
        (left ++ right) |> Enum.uniq()

      Enum.all?(left, &is_map/1) and Enum.all?(right, &is_map/1) ->
        merge_map_lists(left, right)

      true ->
        left ++ right
    end
  end

  defp merge_values(_left, right), do: right

  defp is_simple_value(value)
       when is_atom(value) or is_binary(value) or is_number(value) or is_boolean(value),
       do: true

  defp is_simple_value(_), do: false

  defp merge_map_lists(left, right) do
    left_by_key = Enum.group_by(left, &get_merge_key/1)
    right_by_key = Enum.group_by(right, &get_merge_key/1)

    all_keys = MapSet.union(MapSet.new(Map.keys(left_by_key)), MapSet.new(Map.keys(right_by_key)))

    Enum.flat_map(all_keys, fn key ->
      left_items = Map.get(left_by_key, key, [])
      right_items = Map.get(right_by_key, key, [])

      case {left_items, right_items} do
        {[], right_items} -> right_items
        {left_items, []} -> left_items
        {[left_item], [right_item]} -> [deep_merge(left_item, right_item)]
        _ -> left_items ++ right_items
      end
    end)
  end

  defp get_merge_key(map) when is_map(map) do
    cond do
      Map.has_key?(map, :name) -> {:name, Map.get(map, :name)}
      Map.has_key?(map, "name") -> {:name, Map.get(map, "name")}
      Map.has_key?(map, :id) -> {:id, Map.get(map, :id)}
      Map.has_key?(map, "id") -> {:id, Map.get(map, "id")}
      true -> :no_key
    end
  end

  defp get_merge_key(_), do: :no_key
end
