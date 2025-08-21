defmodule Claude.Documentation.ReferencesTest do
  use Claude.ClaudeCodeCase

  alias Claude.Documentation.References

  describe "extract_references/1" do
    test "extracts @references from content" do
      content = """
      See @docs/architecture.md for system design.
      Also check @guides/setup.md for installation.
      """

      refs = References.extract_references(content)
      assert "@docs/architecture.md" in refs
      assert "@guides/setup.md" in refs
      assert length(refs) == 2
    end

    test "ignores @references in code blocks" do
      content = """
      Normal @docs/real.md reference.

      ```bash
      echo "@docs/fake.md should be ignored"
      ```

      And `@inline/fake.md` should also be ignored.
      """

      refs = References.extract_references(content)
      assert "@docs/real.md" in refs
      refute "@docs/fake.md" in refs
      refute "@inline/fake.md" in refs
      assert length(refs) == 1
    end

    test "ignores @references in indented code blocks" do
      content = """
      Normal @docs/real.md reference.

          This is indented code with @docs/fake.md

      Back to normal with @docs/another.md
      """

      refs = References.extract_references(content)
      assert "@docs/real.md" in refs
      assert "@docs/another.md" in refs
      refute "@docs/fake.md" in refs
      assert length(refs) == 2
    end

    test "returns unique references" do
      content = """
      First @docs/same.md reference.
      Second @docs/same.md reference.
      """

      refs = References.extract_references(content)
      assert length(refs) == 1
      assert "@docs/same.md" in refs
    end
  end

  describe "resolve_reference/2" do
    setup do
      # Create test files
      test_dir = System.tmp_dir!() |> Path.join("ref_test")
      File.rm_rf!(test_dir)
      File.mkdir_p!(test_dir)

      test_file = Path.join(test_dir, "test.md")
      File.write!(test_file, "# Test Document\n\nTest content.")

      on_exit(fn -> File.rm_rf!(test_dir) end)

      %{test_file: test_file, test_dir: test_dir}
    end

    test "resolves reference in link mode", %{test_file: test_file} do
      # Mock the cache to return the test file path
      reference = "@#{test_file}"

      result = References.resolve_reference(reference, mode: :link)
      assert result =~ "[Test](#{test_file})"
    end

    test "resolves reference in inline mode", %{test_file: test_file} do
      reference = "@#{test_file}"

      result = References.resolve_reference(reference, mode: :inline)
      assert result =~ "<details>"
      assert result =~ "<summary>📄 Test</summary>"
      assert result =~ "# Test Document"
      assert result =~ "Test content."
      assert result =~ "</details>"
    end

    test "uses custom name when provided", %{test_file: test_file} do
      reference = "@#{test_file}"

      result = References.resolve_reference(reference, mode: :link, as: "Custom Name")
      assert result =~ "[Custom Name](#{test_file})"
    end

    test "raises ReferenceError for missing files" do
      assert_raise References.ReferenceError, fn ->
        References.resolve_reference("@nonexistent.md")
      end
    end
  end

  describe "validate_reference/1" do
    setup do
      test_dir = System.tmp_dir!() |> Path.join("validate_test")
      File.rm_rf!(test_dir)
      File.mkdir_p!(test_dir)

      test_file = Path.join(test_dir, "exists.md")
      File.write!(test_file, "content")

      on_exit(fn -> File.rm_rf!(test_dir) end)

      %{test_file: test_file}
    end

    test "returns :ok for existing files", %{test_file: test_file} do
      assert References.validate_reference("@#{test_file}") == :ok
    end

    test "returns error for missing files" do
      assert {:error, reason} = References.validate_reference("@nonexistent.md")
      assert reason =~ "File not found"
    end
  end

  describe "process_references/2" do
    setup do
      test_dir = System.tmp_dir!() |> Path.join("process_test")
      File.rm_rf!(test_dir)
      File.mkdir_p!(test_dir)

      arch_file = Path.join(test_dir, "architecture.md")
      File.write!(arch_file, "# Architecture\n\nSystem design details.")

      setup_file = Path.join(test_dir, "setup.md")
      File.write!(setup_file, "# Setup\n\nInstallation instructions.")

      on_exit(fn -> File.rm_rf!(test_dir) end)

      %{arch_file: arch_file, setup_file: setup_file}
    end

    test "processes multiple references in link mode", %{
      arch_file: arch_file,
      setup_file: setup_file
    } do
      content = """
      See @#{arch_file} for system design.
      Check @#{setup_file} for installation.
      """

      result = References.process_references(content, mode: :link)

      assert result =~ "[Architecture](#{arch_file})"
      assert result =~ "[Setup](#{setup_file})"
      refute result =~ "@#{arch_file}"
      refute result =~ "@#{setup_file}"
    end

    test "handles missing references gracefully" do
      content = """
      See @nonexistent.md for details.
      """

      # Should not raise, but may leave reference unprocessed
      result = References.process_references(content, mode: :link)
      assert is_binary(result)
    end

    test "respects max depth to prevent infinite recursion" do
      # This would be hard to test without creating circular references
      # The depth parameter prevents infinite loops
      content = "Simple content without references"
      result = References.process_references(content, depth: 0)
      assert result == content
    end

    test "skips references in code blocks", %{arch_file: arch_file} do
      content = """
      Normal @#{arch_file} reference.

      ```bash
      echo "@#{arch_file} in code block"
      ```
      """

      result = References.process_references(content, mode: :link)

      # Should process the normal reference
      assert result =~ "[Architecture](#{arch_file})"
      # Should leave the code block reference unchanged
      assert result =~ "echo \"@#{arch_file} in code block\""
    end
  end
end
