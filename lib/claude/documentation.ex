defmodule Claude.Documentation do
  @moduledoc """
  Main interface for documentation reference functionality.

  Handles fetching, processing, and managing documentation references
  in CLAUDE.md files, supporting both link-only and inline content.

  This module provides a clean API that abstracts the implementation
  details of URL fetching (via Pythonx + MarkItDown) and content
  processing (markdown block management).

  ## Usage

  The primary function used by the nested memories system:

      Claude.Documentation.process_references(content, doc_refs)

  Where `doc_refs` is a list of URL tuples like:

      [
        {:url, "https://example.com/docs", as: "Example Docs"},
        {:url, "https://api.guide.com", as: "API Guide", inline: true}
      ]

  ## Configuration

  For inline documentation fetching, ensure Pythonx is available:

      # In mix.exs
      {:pythonx, "~> 0.4"}

  The module will automatically initialize the Python environment
  with MarkItDown when inline content is requested.
  """

  alias Claude.Documentation.{Fetcher, Processor}

  @doc """
  Process documentation references for content.

  This is the main entry point used by Claude.NestedMemories.
  Takes existing content and a list of documentation references,
  then updates the content with the new documentation section.

  ## Parameters

  - `content` - Existing content (may be empty)
  - `doc_refs` - List of `{:url, url}` or `{:url, url, opts}` tuples

  ## Options

  - `:as` - Custom name for the documentation link
  - `:inline` - Whether to fetch and embed content (requires Pythonx)

  ## Examples

      # Link-only references
      doc_refs = [
        {:url, "https://hexdocs.pm/phoenix"},
        {:url, "https://guides.rubyonrails.org", as: "Rails Guide"}
      ]

      # Mixed references with inline content
      doc_refs = [
        {:url, "https://hexdocs.pm/phoenix", as: "Phoenix Docs"},
        {:url, "https://api.example.com", as: "API Guide", inline: true}
      ]

      result = Claude.Documentation.process_references(content, doc_refs)

  ## Errors

  Raises `Claude.Documentation.Fetcher.FetchError` if:
  - Pythonx is not available but inline content is requested
  - Network fetch fails for inline content
  - MarkItDown conversion fails
  """
  def process_references(content, doc_refs) do
    Processor.process_documentation_references(content, doc_refs)
  end

  @doc """
  Generate a consistent documentation ID from a URL.

  This utility function creates unique identifiers used for
  documentation block markers. Useful for testing or debugging.

  ## Examples

      iex> Claude.Documentation.generate_doc_id("https://hexdocs.pm/phoenix/overview.html")
      "hexdocs-pm-phoenix-overview-html"

      iex> Claude.Documentation.generate_doc_id("https://docs.example.com/api/v1")
      "docs-example-com-api-v1"
  """
  defdelegate generate_doc_id(url), to: Fetcher
end
