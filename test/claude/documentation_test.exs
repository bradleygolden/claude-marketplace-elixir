defmodule Claude.DocumentationTest do
  use Claude.ClaudeCodeCase

  alias Claude.Documentation

  describe "generate_doc_id/1" do
    test "delegates to Fetcher module" do
      # Test the delegation works
      result = Documentation.generate_doc_id("https://example.com/test")
      assert result == "example-com-test"
    end
  end

  describe "process_references/2" do
    test "handles empty doc_refs list" do
      content = "# My Project\n\nSome content here."
      doc_refs = []

      result = Documentation.process_references(content, doc_refs)

      # Should return original content when no docs to process
      assert result == "# My Project\n\nSome content here."
    end

    test "processes simple URL references" do
      content = ""

      doc_refs = [
        {:url, "https://example.com", as: "Example"}
      ]

      result = Documentation.process_references(content, doc_refs)

      assert result =~ "<!-- documentation-references-start -->"
      assert result =~ "## Documentation References"
      assert result =~ "<!-- doc-ref:example-com:start -->"
      assert result =~ "- [Example](https://example.com)"
      assert result =~ "<!-- doc-ref:example-com:end -->"
      assert result =~ "<!-- documentation-references-end -->"
    end

    test "preserves existing content when adding documentation" do
      content = "# My Project\n\nExisting content here."

      doc_refs = [
        {:url, "https://example.com", as: "Example"}
      ]

      result = Documentation.process_references(content, doc_refs)

      assert result =~ "# My Project"
      assert result =~ "Existing content here."
      assert result =~ "- [Example](https://example.com)"
    end
  end
end
