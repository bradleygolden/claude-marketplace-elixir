defmodule Claude.Documentation.CacheTest do
  use Claude.ClaudeCodeCase

  alias Claude.Documentation.Cache

  describe "resolve_reference/1" do
    test "resolves @docs/file.md to relative path" do
      assert Cache.resolve_reference("@docs/architecture.md") == "docs/architecture.md"
    end

    test "resolves @~/file.md to home directory" do
      home = Path.expand("~/")
      assert Cache.resolve_reference("@~/shared/docs.md") == Path.join(home, "shared/docs.md")
    end

    test "resolves @/absolute/path to absolute path" do
      assert Cache.resolve_reference("@/absolute/path/file.md") == "/absolute/path/file.md"
    end

    test "passes through regular paths unchanged" do
      assert Cache.resolve_reference("docs/file.md") == "docs/file.md"
    end
  end

  describe "cache_url!/2" do
    setup do
      # Copy and mock the Fetcher to avoid actual HTTP requests
      Mimic.copy(Claude.Documentation.Fetcher)

      Mimic.stub(Claude.Documentation.Fetcher, :fetch_url!, fn _url ->
        "# Test Document\n\nThis is test content."
      end)

      # Use a temporary directory for testing
      cache_dir = System.tmp_dir!() |> Path.join("claude_cache_test")
      File.rm_rf!(cache_dir)

      on_exit(fn -> File.rm_rf!(cache_dir) end)

      %{cache_dir: cache_dir}
    end

    test "caches URL content to specified path", %{cache_dir: cache_dir} do
      cache_path = Path.join(cache_dir, "test.md")
      url = "https://example.com/test.md"

      assert :ok = Cache.cache_url!(url, cache_path)
      assert File.exists?(cache_path)

      content = File.read!(cache_path)
      assert content =~ "source_url: #{url}"
      assert content =~ "This is test content."
    end

    test "creates cache directory if it doesn't exist", %{cache_dir: cache_dir} do
      nested_path = Path.join([cache_dir, "nested", "deep", "test.md"])
      url = "https://example.com/nested.md"

      assert :ok = Cache.cache_url!(url, nested_path)
      assert File.exists?(nested_path)
    end

    test "raises CacheError on fetch failure" do
      Mimic.copy(Claude.Documentation.Fetcher)

      Mimic.stub(Claude.Documentation.Fetcher, :fetch_url!, fn _url ->
        raise Claude.Documentation.Fetcher.FetchError, {"https://bad.com", "Network error"}
      end)

      assert_raise Cache.CacheError, fn ->
        Cache.cache_url!("https://bad.com", "/tmp/bad.md")
      end
    end
  end

  describe "read_cached!/1" do
    setup do
      cache_dir = System.tmp_dir!() |> Path.join("claude_read_test")
      File.rm_rf!(cache_dir)
      File.mkdir_p!(cache_dir)

      # Create test files
      regular_file = Path.join(cache_dir, "regular.md")
      File.write!(regular_file, "# Regular File\n\nJust content.")

      cached_file = Path.join(cache_dir, "cached.md")

      cached_content = """
      <!-- CACHE-METADATA
      source_url: https://example.com/doc.md
      cached_at: 2024-01-01T00:00:00Z
      -->

      # Cached Document

      This is cached content.
      """

      File.write!(cached_file, cached_content)

      on_exit(fn -> File.rm_rf!(cache_dir) end)

      %{cache_dir: cache_dir, regular_file: regular_file, cached_file: cached_file}
    end

    test "reads regular file content", %{regular_file: regular_file} do
      content = Cache.read_cached!(regular_file)
      assert content == "# Regular File\n\nJust content."
    end

    test "strips cache metadata from cached files", %{cached_file: cached_file} do
      content = Cache.read_cached!(cached_file)
      assert content =~ "# Cached Document"
      assert content =~ "This is cached content."
      refute content =~ "CACHE-METADATA"
      refute content =~ "source_url:"
    end

    test "raises CacheError for missing files" do
      assert_raise Cache.CacheError, fn ->
        Cache.read_cached!("nonexistent.md")
      end
    end
  end

  describe "needs_refresh?/2" do
    setup do
      cache_dir = System.tmp_dir!() |> Path.join("claude_refresh_test")
      File.rm_rf!(cache_dir)
      File.mkdir_p!(cache_dir)

      on_exit(fn -> File.rm_rf!(cache_dir) end)

      %{cache_dir: cache_dir}
    end

    test "returns true for nonexistent files" do
      assert Cache.needs_refresh?("nonexistent.md") == true
    end

    test "returns false for fresh files", %{cache_dir: cache_dir} do
      fresh_file = Path.join(cache_dir, "fresh.md")
      File.write!(fresh_file, "fresh content")

      assert Cache.needs_refresh?(fresh_file, 24) == false
    end
  end

  describe "list_cached_docs/1" do
    test "returns empty list for nonexistent directory" do
      assert Cache.list_cached_docs("nonexistent_dir") == []
    end

    test "lists cached documents with metadata" do
      cache_dir = System.tmp_dir!() |> Path.join("claude_list_test")
      File.rm_rf!(cache_dir)
      File.mkdir_p!(cache_dir)

      cached_content = """
      <!-- CACHE-METADATA
      source_url: https://example.com/doc.md
      cached_at: 2024-01-01T00:00:00Z
      -->

      Content here
      """

      cached_file = Path.join(cache_dir, "doc.md")
      File.write!(cached_file, cached_content)

      # Also create a non-cached file to ensure it's filtered out
      regular_file = Path.join(cache_dir, "regular.md")
      File.write!(regular_file, "Regular content")

      docs = Cache.list_cached_docs(cache_dir)

      assert length(docs) == 1
      [doc] = docs
      assert doc.path == cached_file
      assert doc.source_url == "https://example.com/doc.md"
      assert doc.cached_at == "2024-01-01T00:00:00Z"

      File.rm_rf!(cache_dir)
    end
  end
end
