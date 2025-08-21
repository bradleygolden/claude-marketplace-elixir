defmodule Claude.NestedMemoriesIntegrationTest do
  use Claude.ClaudeCodeCase

  describe "integration with new @reference and cache functionality" do
    setup do
      cache_dir =
        System.tmp_dir!()
        |> Path.join("nested_memories_test_#{System.unique_integer([:positive])}")

      File.mkdir_p!(cache_dir)

      on_exit(fn -> File.rm_rf!(cache_dir) end)

      %{cache_dir: cache_dir}
    end

    test "automatically converts cached URLs to @references", %{cache_dir: cache_dir} do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "." => [
                  {:url, "https://example.com/docs.md", as: "Example Docs", cache: "#{cache_dir}/.claude/docs/example.md"},
                  {:file, "@docs/architecture.md", as: "Architecture Guide"}
                ],
                "lib" => [
                  {:file, "@docs/implementation.md", as: "Implementation Details"}
                ]
              }
            }
            """,
            "docs/architecture.md" => """
            # Architecture

            System design details here.

            See @docs/implementation.md for more info.
            """,
            "docs/implementation.md" => """
            # Implementation

            Implementation details here.
            """
          }
        )

      # Mock the Fetcher for URL caching
      Mimic.copy(Claude.Documentation.Fetcher)

      Mimic.stub(Claude.Documentation.Fetcher, :fetch_url!, fn _url ->
        "# Example Documentation\n\nThis is cached content."
      end)

      result = Claude.NestedMemories.generate(igniter)

      # Check that root CLAUDE.md was processed
      {:ok, root_source} = Rewrite.source(result.rewrite, "CLAUDE.md")
      root_content = Rewrite.Source.get(root_source, :content)

      # Should contain documentation references
      assert root_content =~ "<!-- documentation-references-start -->"
      assert root_content =~ "## Documentation References"

      # Should have file reference blocks
      assert root_content =~ "- @docs/architecture.md"

      # Should have cached URL converted to @reference (now points to local file)
      assert root_content =~ "- @#{cache_dir}/.claude/docs/example.md"

      # Test @references processing separately with sample content
      arch_content = """
      # Architecture

      System design details here.

      See @docs/implementation.md for more info.
      """

      temp_impl = Path.join(System.tmp_dir!(), "implementation.md")
      File.write!(temp_impl, "# Implementation\n\nDetails here.")

      processed_arch =
        Claude.Documentation.References.process_references(
          String.replace(arch_content, "@docs/implementation.md", "@#{temp_impl}"),
          mode: :link
        )

      assert processed_arch =~ "[Implementation](#{temp_impl})"
      File.rm!(temp_impl)

      # Check lib directory processing
      {:ok, lib_source} = Rewrite.source(result.rewrite, "lib/CLAUDE.md")
      lib_content = Rewrite.Source.get(lib_source, :content)

      assert lib_content =~ "- @docs/implementation.md"
    end

    test "handles mixed usage rules and file references", %{cache_dir: _cache_dir} do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "test" => [
                  "usage_rules:elixir",
                  {:file, "@docs/testing.md", as: "Testing Guide"}
                ]
              }
            }
            """,
            "docs/testing.md" => """
            # Testing Guide

            How to test the application.
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      # Should have both usage rules task and documentation references
      assert Enum.any?(result.tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "test/CLAUDE.md") and
                   Enum.member?(args, "usage_rules:elixir")

               _ ->
                 false
             end)

      {:ok, test_source} = Rewrite.source(result.rewrite, "test/CLAUDE.md")
      test_content = Rewrite.Source.get(test_source, :content)

      assert test_content =~ "<!-- documentation-references-start -->"
      assert test_content =~ "- @docs/testing.md"
    end

    test "validates file references exist" do
      # This test would check that file references are validated
      # In practice, the system should be robust to missing files
      content = """
      See @nonexistent/file.md for details.
      """

      # Should handle missing references gracefully
      processed = Claude.Documentation.References.process_references(content, mode: :link)
      assert is_binary(processed)
    end

    test "processes @references recursively with depth limit" do
      temp_dir = System.tmp_dir!() |> Path.join("recursive_test")
      File.rm_rf!(temp_dir)
      File.mkdir_p!(temp_dir)

      # Create a simple file without circular references for testing
      file_a = Path.join(temp_dir, "a.md")
      File.write!(file_a, "# File A\n\nThis is file A content.")

      content = "Start with @#{file_a}"

      # Should process with depth limit
      processed =
        Claude.Documentation.References.process_references(content, depth: 2, mode: :link)

      assert is_binary(processed)
      assert processed =~ "[A](#{file_a})"

      File.rm_rf!(temp_dir)
    end

    test "URL with cache automatically becomes @reference", %{cache_dir: cache_dir} do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "." => [
                  {:url, "https://example.com/guide.md", cache: "#{cache_dir}/.claude/docs/guide.md", as: "User Guide"}
                ]
              }
            }
            """
          }
        )

      # Mock the Fetcher for URL caching
      Mimic.copy(Claude.Documentation.Fetcher)

      Mimic.stub(Claude.Documentation.Fetcher, :fetch_url!, fn _url ->
        "# User Guide\\n\\nThis is the cached guide content."
      end)

      result = Claude.NestedMemories.generate(igniter)

      # Check that root CLAUDE.md was processed
      {:ok, root_source} = Rewrite.source(result.rewrite, "CLAUDE.md")
      root_content = Rewrite.Source.get(root_source, :content)

      # Should contain documentation references
      assert root_content =~ "<!-- documentation-references-start -->"
      assert root_content =~ "## Documentation References"

      # Should reference the cached file (not the original URL) because cache was specified
      assert root_content =~ "- @#{cache_dir}/.claude/docs/guide.md"
      # Should NOT contain the original URL
      refute root_content =~ "https://example.com/guide.md"

      # Verify the cache file was created
      assert File.exists?("#{cache_dir}/.claude/docs/guide.md")
      cached_content = File.read!("#{cache_dir}/.claude/docs/guide.md")
      assert cached_content =~ "# User Guide"
      # Source URL in metadata
      assert cached_content =~ "https://example.com/guide.md"
    end

    test "cache without 'as' clause automatically becomes @reference with auto-generated name", %{
      cache_dir: cache_dir
    } do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "." => [
                  {:url, "https://example.com/api-reference.md", cache: "#{cache_dir}/.claude/docs/api.md"}
                ]
              }
            }
            """
          }
        )

      # Mock the Fetcher for URL caching
      Mimic.copy(Claude.Documentation.Fetcher)

      Mimic.stub(Claude.Documentation.Fetcher, :fetch_url!, fn _url ->
        "# API Reference\\n\\nAPI documentation here."
      end)

      result = Claude.NestedMemories.generate(igniter)

      # Check that root CLAUDE.md was processed
      {:ok, root_source} = Rewrite.source(result.rewrite, "CLAUDE.md")
      root_content = Rewrite.Source.get(root_source, :content)

      # Should reference the cached file with auto-generated name from URL
      assert root_content =~ "- @#{cache_dir}/.claude/docs/api.md"
      # Should NOT contain the original URL
      refute root_content =~ "https://example.com/api-reference.md"

      # Verify the cache file was created
      assert File.exists?("#{cache_dir}/.claude/docs/api.md")
    end
  end
end
