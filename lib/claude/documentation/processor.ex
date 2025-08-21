defmodule Claude.Documentation.Processor do
  @moduledoc """
  Processes and manages documentation reference sections in CLAUDE.md files.

  Handles parsing existing content, updating individual documentation blocks,
  and removing orphaned blocks when configuration changes.
  """

  alias Claude.Documentation.{Fetcher, Cache}

  @doc """
  Processes documentation references and updates the content accordingly.

  Extracts existing doc-ref blocks, updates them based on the new configuration,
  removes orphaned blocks, and rebuilds the documentation section. Also processes
  any @references found in the content.
  """
  def process_documentation_references(content, doc_refs) do
    existing_blocks = extract_existing_blocks(content)
    updated_blocks = update_blocks(existing_blocks, doc_refs)
    _orphaned_blocks = find_orphaned_blocks(existing_blocks, doc_refs)

    content
    |> remove_documentation_section()
    |> append_documentation_section(updated_blocks)
  end

  @doc """
  Extracts all existing doc-ref blocks from content.

  Returns a map where keys are doc IDs and values are the full block content.
  """
  def extract_existing_blocks(content) do
    pattern = ~r/<!-- doc-ref:([^:]+):start -->(.*?)<!-- doc-ref:\1:end -->/s

    Regex.scan(pattern, content)
    |> Map.new(fn [_full_match, doc_id, block_content] ->
      {doc_id, String.trim(block_content)}
    end)
  end

  @doc """
  Updates documentation blocks based on the provided configuration.

  Returns a list of documentation blocks in configuration order.
  """
  def update_blocks(existing_blocks, doc_refs) do
    Enum.map(doc_refs, fn doc_ref ->
      build_block_for_ref(doc_ref, existing_blocks)
    end)
  end

  @doc """
  Finds blocks that exist in content but are not in the current configuration.

  These are considered orphaned and should be removed.
  """
  def find_orphaned_blocks(existing_blocks, doc_refs) do
    configured_ids =
      doc_refs
      |> Enum.map(&get_doc_id_from_ref/1)
      |> MapSet.new()

    existing_blocks
    |> Map.keys()
    |> Enum.reject(&MapSet.member?(configured_ids, &1))
  end

  defp build_block_for_ref({:url, url}, _existing_blocks) do
    name = extract_name_from_url(url)
    Fetcher.build_doc_block(url, name)
  end

  defp build_block_for_ref({:url, url, opts}, existing_blocks) do
    name = Keyword.get(opts, :as, extract_name_from_url(url))
    inline = Keyword.get(opts, :inline, false)
    cache_path = Keyword.get(opts, :cache)

    if cache_path do
      Cache.cache_url!(url, cache_path)

      build_file_block("@" <> cache_path, name)
    else
      if inline do
        doc_id = Fetcher.generate_doc_id(url)

        case Map.get(existing_blocks, doc_id) do
          nil ->
            content = Fetcher.fetch_url!(url)
            Fetcher.build_doc_block(url, name, inline: true, content: content)

          _existing_content ->
            content = Fetcher.fetch_url!(url)
            Fetcher.build_doc_block(url, name, inline: true, content: content)
        end
      else
        Fetcher.build_doc_block(url, name)
      end
    end
  end

  defp build_block_for_ref({:file, path}, _existing_blocks) do
    name = extract_name_from_path(path)
    build_file_block(path, name)
  end

  defp build_block_for_ref({:file, path, opts}, _existing_blocks) do
    name = Keyword.get(opts, :as, extract_name_from_path(path))
    build_file_block(path, name)
  end

  defp get_doc_id_from_ref({:url, url}), do: Fetcher.generate_doc_id(url)
  defp get_doc_id_from_ref({:url, url, _opts}), do: Fetcher.generate_doc_id(url)
  defp get_doc_id_from_ref({:file, path}), do: generate_file_doc_id(path)
  defp get_doc_id_from_ref({:file, path, _opts}), do: generate_file_doc_id(path)

  defp extract_name_from_url(url) do
    uri = URI.parse(url)

    case uri.path do
      nil ->
        uri.host || "Documentation"

      "" ->
        uri.host || "Documentation"

      path ->
        case Path.basename(path) do
          "" ->
            uri.host || "Documentation"

          filename ->
            filename
            |> Path.rootname()
            |> String.replace(~r/[-_]/, " ")
            |> String.split()
            |> Enum.map(&String.capitalize/1)
            |> Enum.join(" ")
        end
    end
  end

  defp remove_documentation_section(content) do
    content
    |> String.replace(
      ~r/<!-- documentation-references-start -->.*<!-- documentation-references-end -->/s,
      ""
    )
    |> String.trim_trailing()
  end

  defp append_documentation_section(content, []) do
    content
  end

  defp append_documentation_section(content, blocks) do
    doc_section = build_documentation_section(blocks)

    if String.trim(content) == "" do
      doc_section
    else
      content <> "\n\n" <> doc_section
    end
  end

  defp build_documentation_section(blocks) do
    references = Enum.join(blocks, "\n\n")

    """
    <!-- documentation-references-start -->
    ## Documentation References

    #{references}
    <!-- documentation-references-end -->
    """
  end

  defp build_file_block(path, _name) do
    doc_id = generate_file_doc_id(path)

    """
    <!-- doc-ref:#{doc_id}:start -->
    - #{path}
    <!-- doc-ref:#{doc_id}:end -->
    """
  end

  defp extract_name_from_path(path) do
    cleaned_path = String.replace_leading(path, "@", "")

    case Path.basename(cleaned_path) do
      "" ->
        "Documentation"

      filename ->
        filename
        |> Path.rootname()
        |> String.replace(~r/[-_]/, " ")
        |> String.split()
        |> Enum.map(&String.capitalize/1)
        |> Enum.join(" ")
    end
  end

  defp generate_file_doc_id(path) do
    path
    |> String.replace_leading("@", "")
    |> String.replace(~r/[^a-z0-9]+/i, "-")
    |> String.trim("-")
    |> String.downcase()
  end
end
