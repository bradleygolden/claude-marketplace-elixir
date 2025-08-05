defmodule Claude.Hooks.PostToolUse.RelatedFilesTest do
  use Claude.ClaudeCodeCase, setup_project?: true

  alias Claude.Hooks.PostToolUse.RelatedFiles
  alias Claude.Test.Fixtures
  import Claude.Test.HookTestHelpers

  describe "run/1" do
    test "returns :ok for :eof input" do
      assert RelatedFiles.run(:eof) == :ok
    end

    test "handles invalid JSON input gracefully" do
      assert_hook_success(RelatedFiles, "invalid json")
    end

    test "ignores non-edit tools", %{test_dir: test_dir} do
      input =
        Fixtures.post_tool_use_input(
          tool_name: "Read",
          tool_input:
            Fixtures.tool_input(:read, file_path: Path.join(test_dir, "lib/example.ex")),
          cwd: test_dir
        )

      assert_hook_success(RelatedFiles, input)
    end

    test "returns success when no related files exist", %{test_dir: test_dir} do
      input =
        Fixtures.post_tool_use_input(
          tool_name: "Write",
          tool_input:
            Fixtures.tool_input(:write,
              file_path: Path.join(test_dir, "lib/nonexistent/deeply/nested/file.ex")
            ),
          cwd: test_dir
        )

      assert_hook_success(RelatedFiles, input)
    end

    test "suggests related test file when lib file is edited", %{test_dir: test_dir} do
      create_file(test_dir, "lib/example.ex", "defmodule Example do\nend")
      create_file(test_dir, "test/example_test.exs", "defmodule ExampleTest do\nend")

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input:
            Fixtures.tool_input(:edit, file_path: Path.join(test_dir, "lib/example.ex")),
          cwd: test_dir
        )

      stderr = assert_hook_error(RelatedFiles, input)
      assert stderr =~ "Related files need updating"
      assert stderr =~ "lib/example.ex"
      assert stderr =~ "test/example_test.exs"
    end

    test "suggests related lib file when test file is edited", %{test_dir: test_dir} do
      create_file(test_dir, "lib/example.ex", "defmodule Example do\nend")
      create_file(test_dir, "test/example_test.exs", "defmodule ExampleTest do\nend")

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Write",
          tool_input:
            Fixtures.tool_input(:write, file_path: Path.join(test_dir, "test/example_test.exs")),
          cwd: test_dir
        )

      stderr = assert_hook_error(RelatedFiles, input)
      assert stderr =~ "Related files need updating"
      assert stderr =~ "test/example_test.exs"
      assert stderr =~ "lib/example.ex"
    end

    test "works with MultiEdit tool", %{test_dir: test_dir} do
      create_file(test_dir, "lib/multi.ex", "defmodule Multi do\nend")
      create_file(test_dir, "test/multi_test.exs", "defmodule MultiTest do\nend")

      input =
        Fixtures.post_tool_use_input(
          tool_name: "MultiEdit",
          tool_input:
            Fixtures.tool_input(:multi_edit, file_path: Path.join(test_dir, "lib/multi.ex")),
          cwd: test_dir
        )

      stderr = assert_hook_error(RelatedFiles, input)
      assert stderr =~ "Related files need updating"
    end

    test "handles missing file_path in tool_input" do
      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: %{},
          cwd: "."
        )

      assert_hook_success(RelatedFiles, input)
    end

    test "handles deeply nested lib files", %{test_dir: test_dir} do
      create_file(test_dir, "lib/myapp/accounts/user.ex", "defmodule MyApp.Accounts.User do\nend")

      create_file(
        test_dir,
        "test/myapp/accounts/user_test.exs",
        "defmodule MyApp.Accounts.UserTest do\nend"
      )

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input:
            Fixtures.tool_input(:edit,
              file_path: Path.join(test_dir, "lib/myapp/accounts/user.ex")
            ),
          cwd: test_dir
        )

      stderr = assert_hook_error(RelatedFiles, input)
      assert stderr =~ "lib/myapp/accounts/user.ex"
      assert stderr =~ "test/myapp/accounts/user_test.exs"
    end

    test "handles files with special characters in names", %{test_dir: test_dir} do
      create_file(test_dir, "lib/my-app/user_name.ex", "defmodule MyApp.UserName do\nend")

      create_file(
        test_dir,
        "test/my-app/user_name_test.exs",
        "defmodule MyApp.UserNameTest do\nend"
      )

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input:
            Fixtures.tool_input(:edit, file_path: Path.join(test_dir, "lib/my-app/user_name.ex")),
          cwd: test_dir
        )

      stderr = assert_hook_error(RelatedFiles, input)
      assert stderr =~ "lib/my-app/user_name.ex"
      assert stderr =~ "test/my-app/user_name_test.exs"
    end

    test "returns success when no files match patterns", %{test_dir: test_dir} do
      # Create a file that doesn't match any patterns
      create_file(test_dir, "some_random_file.txt", "content")

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input:
            Fixtures.tool_input(:edit, file_path: Path.join(test_dir, "some_random_file.txt")),
          cwd: test_dir
        )

      assert_hook_success(RelatedFiles, input)
    end
  end
end
