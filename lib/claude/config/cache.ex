defmodule Claude.Config.Cache do
  @moduledoc """
  A simple cache for Claude configuration to avoid repeated file I/O.
  
  This GenServer maintains an in-memory cache of the .claude.exs configuration
  with automatic invalidation when the file changes.
  """
  
  use GenServer
  
  @cache_name __MODULE__
  @check_interval 5_000
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: @cache_name)
  end
  
  @doc """
  Gets the cached configuration or loads it if not cached.
  """
  def get do
    case Process.whereis(@cache_name) do
      nil ->
        Claude.Config.load()
        
      _pid ->
        GenServer.call(@cache_name, :get)
    end
  end
  
  @doc """
  Clears the cache, forcing a reload on next access.
  """
  def clear do
    if Process.whereis(@cache_name) do
      GenServer.cast(@cache_name, :clear)
    end
  end
  
  
  @impl true
  def init(_opts) do
    Process.send_after(self(), :check_file_change, @check_interval)
    
    state = %{
      config: nil,
      last_modified: nil,
      config_path: nil
    }
    
    {:ok, state}
  end
  
  @impl true
  def handle_call(:get, _from, state) do
    {config, new_state} = ensure_loaded(state)
    {:reply, config, new_state}
  end
  
  @impl true
  def handle_cast(:clear, state) do
    {:noreply, %{state | config: nil, last_modified: nil}}
  end
  
  @impl true
  def handle_info(:check_file_change, state) do
    new_state = check_and_reload_if_changed(state)
    Process.send_after(self(), :check_file_change, @check_interval)
    {:noreply, new_state}
  end
  
  
  defp ensure_loaded(%{config: nil} = state) do
    load_config(state)
  end
  
  defp ensure_loaded(%{config: config} = state) do
    {{:ok, config}, state}
  end
  
  defp load_config(state) do
    case Claude.Config.find_config_file() do
      {:ok, path} ->
        case File.stat(path) do
          {:ok, %{mtime: mtime}} ->
            case Claude.Config.load() do
              {:ok, config} ->
                new_state = %{state | config: config, last_modified: mtime, config_path: path}
                {{:ok, config}, new_state}
                
              error ->
                {error, state}
            end
            
          _ ->
            case Claude.Config.load() do
              {:ok, config} ->
                new_state = %{state | config: config, last_modified: nil, config_path: nil}
                {{:ok, config}, new_state}
                
              error ->
                {error, state}
            end
        end
        
      _ ->
        {{:error, "No .claude.exs file found"}, state}
    end
  end
  
  defp check_and_reload_if_changed(%{config_path: nil} = state) do
    case load_config(state) do
      {_result, new_state} -> new_state
    end
  end
  
  defp check_and_reload_if_changed(%{config_path: path, last_modified: last_mtime} = state) do
    case File.stat(path) do
      {:ok, %{mtime: current_mtime}} when current_mtime != last_mtime ->
        case load_config(state) do
          {_result, new_state} -> new_state
        end
        
      _ ->
        state
    end
  end
end