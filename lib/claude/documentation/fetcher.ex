defmodule Claude.Documentation.Fetcher do
  @moduledoc """
  Fetches and converts documentation from URLs to Markdown using MarkItDown via Pythonx.

  This module handles runtime initialization of Python dependencies and provides
  functions for fetching web content and converting it to LLM-friendly Markdown.
  """

  @pyproject_toml """
  [project]
  name = "claude-doc-fetcher"
  version = "0.1.0"
  requires-python = ">=3.10"
  dependencies = [
    "markitdown>=0.1.0",
    "requests>=2.31.0"
  ]
  """

  defmodule FetchError do
    @moduledoc "Exception raised when documentation fetching fails"
    defexception [:message, :url, :reason]

    def exception({url, reason}) do
      %__MODULE__{
        message: "Failed to fetch documentation from #{url}",
        url: url,
        reason: reason
      }
    end
  end

  @doc """
  Fetches content from a URL and converts it to Markdown.

  Raises `FetchError` if the fetch or conversion fails.
  """
  def fetch_url!(url) do
    ensure_pythonx!()
    ensure_initialized!()
    convert_to_markdown!(url)
  end

  @doc """
  Generates a consistent identifier from a URL for use in documentation markers.

  ## Examples

      iex> Claude.Documentation.Fetcher.generate_doc_id("https://hexdocs.pm/phoenix/overview.html")
      "hexdocs-pm-phoenix-overview-html"
      
      iex> Claude.Documentation.Fetcher.generate_doc_id("https://docs.anthropic.com/hooks.md")
      "docs-anthropic-com-hooks-md"
  """
  def generate_doc_id(url) do
    uri = URI.parse(url)

    "#{uri.host}#{uri.path}"
    |> String.replace(~r/[^a-z0-9]+/i, "-")
    |> String.trim("-")
    |> String.downcase()
  end

  @doc """
  Builds a documentation block with the appropriate markers.

  For inline content, creates a collapsible details section.
  For link-only, creates a simple link.
  """
  def build_doc_block(url, name, opts \\ []) do
    doc_id = generate_doc_id(url)

    case Keyword.get(opts, :inline, false) do
      true ->
        content = Keyword.fetch!(opts, :content)

        """
        <!-- doc-ref:#{doc_id}:start -->
        - [#{name}](#{url})
          <details>
          <summary>View inline documentation</summary>
          
          #{content}
          </details>
        <!-- doc-ref:#{doc_id}:end -->
        """

      false ->
        """
        <!-- doc-ref:#{doc_id}:start -->
        - [#{name}](#{url})
        <!-- doc-ref:#{doc_id}:end -->
        """
    end
  end

  defp ensure_pythonx! do
    unless Code.ensure_loaded?(Pythonx) do
      raise """
      Pythonx is required for inline documentation fetching.

      Please add {:pythonx, "~> 0.4"} to your dependencies in mix.exs:

        def deps do
          [
            {:pythonx, "~> 0.4"},
            # ... other deps
          ]
        end

      Then run: mix deps.get
      """
    end
  end

  defp ensure_initialized! do
    # Check if we've already initialized in this session
    case Process.get(:claude_pythonx_initialized) do
      true ->
        :ok

      _ ->
        try do
          # Start the Pythonx application if not already started
          case Application.ensure_all_started(:pythonx) do
            {:ok, _} -> :ok
            {:error, reason} -> raise "Failed to start Pythonx application: #{inspect(reason)}"
          end

          Pythonx.uv_init(@pyproject_toml)
          Process.put(:claude_pythonx_initialized, true)
        rescue
          e ->
            raise FetchError,
                  {"initialization",
                   "Failed to initialize Python environment: #{Exception.message(e)}"}
        end
    end
  end

  defp convert_to_markdown!(url) do
    python_code = """
    import markitdown
    from markitdown import MarkItDown
    import traceback

    md = MarkItDown()

    try:
        # Ensure url is a string, not bytes
        url_str = url.decode('utf-8') if isinstance(url, bytes) else str(url)
        result = md.convert(url_str)
        if result and hasattr(result, 'text_content'):
            markdown_content = result.text_content
        else:
            raise RuntimeError(f"Invalid result from MarkItDown: {result}")
    except Exception as e:
        error_details = f"MarkItDown conversion failed: {str(e)}\\nTraceback: {traceback.format_exc()}"
        raise RuntimeError(error_details)

    markdown_content
    """

    try do
      {result, _globals} = Pythonx.eval(python_code, %{"url" => url})

      case Pythonx.decode(result) do
        nil ->
          raise FetchError, {url, "MarkItDown returned empty content"}

        content when is_binary(content) ->
          process_markdown_content(content)

        other ->
          raise FetchError, {url, "Unexpected result type: #{inspect(other)}"}
      end
    rescue
      e in [Pythonx.Error] ->
        raise FetchError, {url, "Python execution failed: #{Exception.message(e)}"}
    end
  end

  defp process_markdown_content(content) do
    content
    |> String.trim()
    |> limit_content_size()
    |> add_source_attribution()
  end

  defp limit_content_size(content, max_chars \\ 10_000) do
    if String.length(content) > max_chars do
      content
      |> String.slice(0, max_chars)
      |> Kernel.<>("\n\n[Content truncated due to length]")
    else
      content
    end
  end

  defp add_source_attribution(content) do
    "<!-- Content fetched and converted by MarkItDown -->\n" <> content
  end
end
