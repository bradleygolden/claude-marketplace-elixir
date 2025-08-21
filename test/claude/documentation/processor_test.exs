defmodule Claude.Documentation.ProcessorTest do
  use Claude.ClaudeCodeCase

  alias Claude.Documentation.Processor

  describe "extract_existing_blocks/1" do
    test "extracts doc-ref blocks from content" do
      content = """
      # Some content

      <!-- documentation-references-start -->
      ## Documentation References

      <!-- doc-ref:example-com:start -->
      - [Example](https://example.com)
      <!-- doc-ref:example-com:end -->

      <!-- doc-ref:test-site:start -->
      - [Test Site](https://test.site)
        <details>
        <summary>View inline documentation</summary>

        Some inline content here
        </details>
      <!-- doc-ref:test-site:end -->

      <!-- documentation-references-end -->
      """

      blocks = Processor.extract_existing_blocks(content)

      assert Map.has_key?(blocks, "example-com")
      assert Map.has_key?(blocks, "test-site")

      assert blocks["example-com"] =~ "- [Example](https://example.com)"
      assert blocks["test-site"] =~ "Some inline content here"
    end

    test "returns empty map when no blocks exist" do
      content = "# Just some content\n\nNo doc blocks here."

      blocks = Processor.extract_existing_blocks(content)

      assert blocks == %{}
    end
  end

  describe "find_orphaned_blocks/2" do
    test "identifies blocks not in current configuration" do
      existing_blocks = %{
        "example-com" => "content1",
        "test-site" => "content2",
        "old-site" => "content3"
      }

      doc_refs = [
        {:url, "https://example.com", as: "Example"},
        {:url, "https://test.site", as: "Test"}
      ]

      orphaned = Processor.find_orphaned_blocks(existing_blocks, doc_refs)

      assert "old-site" in orphaned
      refute "example-com" in orphaned
      refute "test-site" in orphaned
    end

    test "returns empty list when all blocks are configured" do
      existing_blocks = %{
        "example-com" => "content1"
      }

      doc_refs = [
        {:url, "https://example.com", as: "Example"}
      ]

      orphaned = Processor.find_orphaned_blocks(existing_blocks, doc_refs)

      assert orphaned == []
    end
  end

  # Note: Full integration tests for process_documentation_references/2 
  # are complex due to mocking requirements with different function arities.
  # The basic functionality is tested through the individual function tests above,
  # and the full integration can be tested manually with `mix claude.install`.
end
