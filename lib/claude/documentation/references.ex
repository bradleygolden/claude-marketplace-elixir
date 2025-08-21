defmodule Claude.Documentation.References do
  @moduledoc """
  Processes @reference patterns in CLAUDE.md content and resolves them to actual content.
  """

  alias Claude.Documentation.Cache

  defmodule ReferenceError do
    @moduledoc false
    defexception [:message, :reference, :reason]

    def exception({reference, reason}) do
      %__MODULE__{
        message: "Failed to process reference #{reference}",
        reference: reference,
        reason: reason
      }
    end
  end

  @max_depth 5

  @doc "Processes all @references in the given content, resolving them to actual file content."
  def process_references(content, opts \\ []) do
    mode = Keyword.get(opts, :mode, :inline)
    depth = Keyword.get(opts, :depth, @max_depth)

    if depth <= 0 do
      content
    else
      process_references_recursive(content, mode, depth)
    end
  end

  @doc "Extracts all @references from content, excluding those in code blocks/spans."
  def extract_references(content) do
    content_without_code = remove_code_blocks(content)

    ~r/@([^\s\)]+)/
    |> Regex.scan(content_without_code)
    |> Enum.map(fn [full_match, _path] -> full_match end)
    |> Enum.uniq()
  end

  @doc "Resolves a single @reference to its content or markdown link."
  def resolve_reference(reference, opts \\ []) do
    mode = Keyword.get(opts, :mode, :inline)
    custom_name = Keyword.get(opts, :as)

    try do
      case mode do
        :inline ->
          resolve_inline_reference(reference)

        :link ->
          resolve_link_reference(reference, custom_name)
      end
    rescue
      e in [Cache.CacheError, File.Error] ->
        raise ReferenceError, {reference, Exception.message(e)}
    end
  end

  @doc "Validates that a reference exists and can be resolved."
  def validate_reference(reference) do
    try do
      resolved_path = Cache.resolve_reference(reference)

      if File.exists?(resolved_path) do
        :ok
      else
        {:error, "File not found: #{resolved_path}"}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp process_references_recursive(content, mode, depth) do
    references = extract_references(content)

    if Enum.empty?(references) do
      content
    else
      updated_content =
        Enum.reduce(references, content, fn ref, acc ->
          case resolve_reference(ref, mode: mode) do
            resolved when is_binary(resolved) ->
              replace_references_outside_code_blocks(acc, ref, resolved)

            _ ->
              acc
          end
        end)

      if updated_content != content do
        process_references_recursive(updated_content, mode, depth - 1)
      else
        updated_content
      end
    end
  end

  defp resolve_inline_reference(reference) do
    content = Cache.read_cached!(reference)
    name = extract_name_from_reference(reference)

    """
    <details>
    <summary>📄 #{name}</summary>

    #{content}
    </details>
    """
  end

  defp resolve_link_reference(reference, custom_name) do
    resolved_path = Cache.resolve_reference(reference)
    name = custom_name || extract_name_from_reference(reference)

    "[#{name}](#{resolved_path})"
  end

  defp extract_name_from_reference("@" <> path) do
    path
    |> Path.basename()
    |> Path.rootname()
    |> String.replace(~r/[-_]/, " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp remove_code_blocks(content) do
    content
    |> String.replace(~r/```.*?```/s, "__CODE_BLOCK__")
    |> String.replace(~r/^[ ]{4,}.*$/m, "__CODE_LINE__")
    |> String.replace(~r/`[^`]*`/, "__CODE_SPAN__")
  end

  defp replace_references_outside_code_blocks(content, reference, replacement) do
    parts = String.split(content, ~r/(```.*?```|^[ ]{4,}.*$|`[^`]*`)/s, include_captures: true)

    Enum.map(parts, fn part ->
      if is_code_block?(part) do
        part
      else
        String.replace(part, reference, replacement)
      end
    end)
    |> Enum.join("")
  end

  defp is_code_block?(text) do
    String.starts_with?(text, "```") or
      String.starts_with?(text, "`") or
      String.match?(text, ~r/^[ ]{4,}/)
  end
end
