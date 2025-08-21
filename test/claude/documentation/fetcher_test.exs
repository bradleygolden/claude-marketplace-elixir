defmodule Claude.Documentation.FetcherTest do
  use Claude.ClaudeCodeCase

  alias Claude.Documentation.Fetcher
  alias Claude.Documentation.Fetcher.FetchError

  describe "generate_doc_id/1" do
    test "generates consistent IDs from URLs" do
      assert Fetcher.generate_doc_id("https://hexdocs.pm/phoenix/overview.html") ==
               "hexdocs-pm-phoenix-overview-html"

      assert Fetcher.generate_doc_id("https://docs.anthropic.com/hooks.md") ==
               "docs-anthropic-com-hooks-md"

      assert Fetcher.generate_doc_id("https://example.com/") ==
               "example-com"
    end

    test "handles special characters and paths" do
      assert Fetcher.generate_doc_id("https://api.example.com/docs/v1/getting-started") ==
               "api-example-com-docs-v1-getting-started"
    end
  end

  describe "build_doc_block/3" do
    test "builds link-only block by default" do
      result = Fetcher.build_doc_block("https://example.com", "Example")

      assert result =~ "<!-- doc-ref:example-com:start -->"
      assert result =~ "- [Example](https://example.com)"
      assert result =~ "<!-- doc-ref:example-com:end -->"
      refute result =~ "<details>"
    end

    test "builds inline block when inline: true and content provided" do
      content = "# Example\n\nThis is example content."

      result =
        Fetcher.build_doc_block("https://example.com", "Example",
          inline: true,
          content: content
        )

      assert result =~ "<!-- doc-ref:example-com:start -->"
      assert result =~ "- [Example](https://example.com)"
      assert result =~ "<details>"
      assert result =~ "<summary>View inline documentation</summary>"
      assert result =~ content
      assert result =~ "<!-- doc-ref:example-com:end -->"
    end
  end

  describe "fetch_url!/1" do
    test "raises clear error when Pythonx is not available" do
      # This test assumes Pythonx is not loaded/available
      if Code.ensure_loaded?(Pythonx) do
        # Skip test if Pythonx is actually available
        :ok
      else
        assert_raise RuntimeError, ~r/Pythonx is required for inline documentation/, fn ->
          Fetcher.fetch_url!("https://example.com")
        end
      end
    end
  end

  describe "error handling" do
    test "FetchError includes URL and reason" do
      error = FetchError.exception({"https://example.com", "Network timeout"})

      assert error.url == "https://example.com"
      assert error.reason == "Network timeout"
      assert error.message == "Failed to fetch documentation from https://example.com"
    end
  end
end
