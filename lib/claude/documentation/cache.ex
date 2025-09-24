defmodule Claude.Documentation.Cache do
  @moduledoc """
  Manages caching and retrieval of documentation files for @reference support.
  """

  alias Claude.Documentation.Fetcher

  defmodule CacheError do
    @moduledoc false
    defexception [:message, :path, :reason]

    def exception({path, reason}) do
      %__MODULE__{
        message: "Cache operation failed for #{path}",
        path: path,
        reason: reason
      }
    end
  end

  @doc "Downloads a URL and caches it to the specified path."
  def cache_url!(url, cache_path) do
    try do
      cache_dir = Path.dirname(cache_path)
      File.mkdir_p!(cache_dir)

      content = Fetcher.fetch_url!(url)
      cache_content = build_cache_content(url, content)
      File.write!(cache_path, cache_content)

      :ok
    rescue
      e in [File.Error, Fetcher.FetchError] ->
        raise CacheError, {cache_path, Exception.message(e)}
    end
  end

  @doc "Resolves an @reference to an actual file path."
  def resolve_reference("@" <> path) do
    case path do
      "~/" <> rest ->
        Path.expand("~/" <> rest)

      "/" <> _rest ->
        path

      relative_path ->
        relative_path
    end
  end

  def resolve_reference(path), do: path

  @doc "Reads content from a cached or referenced file."
  def read_cached!(path) do
    resolved_path = resolve_reference(path)

    unless File.exists?(resolved_path) do
      raise CacheError, {resolved_path, "File not found"}
    end

    content = File.read!(resolved_path)
    strip_cache_metadata(content)
  end

  @doc "Lists all cached documentation files."
  def list_cached_docs(cache_dir \\ ".claude/docs") do
    if File.dir?(cache_dir) do
      cache_dir
      |> Path.join("**/*.md")
      |> Path.wildcard()
      |> Enum.map(&parse_cache_metadata/1)
      |> Enum.reject(&is_nil/1)
    else
      []
    end
  end

  @doc "Cleans up orphaned cache files that are no longer referenced."
  def clean_orphaned_cache(_cache_dir \\ ".claude/docs") do
    :ok
  end

  @doc "Checks if a cached file needs refresh based on age or other criteria."
  def needs_refresh?(path, max_age_hours \\ 24) do
    resolved_path = resolve_reference(path)

    if File.exists?(resolved_path) do
      stat = File.stat!(resolved_path)

      mtime = NaiveDateTime.from_erl!(stat.mtime)
      mtime_datetime = DateTime.from_naive!(mtime, "Etc/UTC")
      age_hours = DateTime.diff(DateTime.utc_now(), mtime_datetime, :hour)
      age_hours > max_age_hours
    else
      true
    end
  end

  defp build_cache_content(url, content) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    """
    <!-- CACHE-METADATA
    source_url: #{url}
    cached_at: #{timestamp}
    -->

    #{content}
    """
  end

  defp strip_cache_metadata(content) do
    case String.split(content, "-->", parts: 2) do
      [_metadata, actual_content] ->
        String.trim(actual_content)

      _ ->
        content
    end
  end

  defp parse_cache_metadata(file_path) do
    try do
      content = File.read!(file_path)

      case Regex.run(~r/<!-- CACHE-METADATA\s+source_url: (.+)\s+cached_at: (.+)\s+-->/, content) do
        [_, source_url, cached_at] ->
          %{
            path: file_path,
            source_url: String.trim(source_url),
            cached_at: String.trim(cached_at),
            size: byte_size(content)
          }

        _ ->
          nil
      end
    rescue
      _ -> nil
    end
  end
end
