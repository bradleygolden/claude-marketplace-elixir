defmodule Claude.Hooks.PostToolUse.RelatedFilesTest do
  use Claude.ClaudeCodeCase, async: true, setup_project?: true

  alias Claude.Hooks.PostToolUse.RelatedFiles
  alias Claude.Test.Fixtures

  describe "run/1" do
    test "returns :ok for :eof input" do
      assert RelatedFiles.run(:eof) == :ok
    end

    test "returns :ok when JSON parsing fails" do
      json = run_hook(RelatedFiles, "invalid json")
      assert json["decision"] == "block"
      assert json["reason"] =~ "Hook crashed"
      assert json["suppressOutput"] == false
    end

    test "returns :ok for non-edit tools", %{test_dir: test_dir} do
      input =
        Fixtures.post_tool_use_input(
          tool_name: "Read",
          tool_input: Fixtures.tool_input(:read, file_path: Path.join(test_dir, "lib/example.ex"))
        )

      json = run_hook(RelatedFiles, input)

      assert json["suppressOutput"] == true
    end

    test "returns :ok when no related files exist", %{test_dir: test_dir} do
      input =
        Fixtures.post_tool_use_input(
          tool_name: "Write",
          tool_input:
            Fixtures.tool_input(:write,
              file_path: Path.join(test_dir, "lib/nonexistent/deeply/nested/file.ex")
            )
        )

      json = run_hook(RelatedFiles, input)

      assert json["suppressOutput"] == true
    end

    test "outputs block JSON when related test file exists", %{test_dir: test_dir} do
      create_file(test_dir, "lib/example.ex", "defmodule Example do\nend")

      create_file(
        test_dir,
        "test/example_test.exs",
        "defmodule ExampleTest do\nend"
      )

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Write",
          tool_input:
            Fixtures.tool_input(:write, file_path: Path.join(test_dir, "lib/example.ex"))
        )

      expect(System, :halt, fn 0 -> :ok end)

      json = run_hook(RelatedFiles, input)

      assert json["decision"] == "block"
      assert json["reason"] =~ "Related files need updating"
      assert json["reason"] =~ "test/example_test.exs"
    end

    test "suggests multiple related files when they exist", %{test_dir: test_dir} do
      create_file(
        test_dir,
        "lib/mymodule.ex",
        "defmodule MyModule do\nend"
      )

      create_file(
        test_dir,
        "test/mymodule_test.exs",
        "defmodule MyModuleTest do\nend"
      )

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input:
            Fixtures.tool_input(:edit, file_path: Path.join(test_dir, "test/mymodule_test.exs"))
        )

      expect(System, :halt, fn 0 -> :ok end)

      json = run_hook(RelatedFiles, input)

      assert json["decision"] == "block"
      assert json["reason"] =~ "Related files need updating"
      assert json["reason"] =~ "lib/mymodule.ex"
      assert json["reason"] =~ "You modified: test/mymodule_test.exs"
    end
  end

  describe "path transformation patterns" do
    test "transforms lib to test with _test suffix", %{test_dir: test_dir} do
      create_file(
        test_dir,
        "lib/my_app/user.ex",
        "defmodule MyApp.User do\nend"
      )

      create_file(
        test_dir,
        "test/my_app/user_test.exs",
        "defmodule MyApp.UserTest do\nend"
      )

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input:
            Fixtures.tool_input(:edit, file_path: Path.join(test_dir, "lib/my_app/user.ex"))
        )

      expect(System, :halt, fn 0 -> :ok end)

      json = run_hook(RelatedFiles, input)

      assert json["decision"] == "block"
      assert json["reason"] =~ "test/my_app/user_test.exs"
    end

    test "transforms test to lib by removing _test suffix", %{test_dir: test_dir} do
      create_file(
        test_dir,
        "lib/my_app/user.ex",
        "defmodule MyApp.User do\nend"
      )

      create_file(
        test_dir,
        "test/my_app/user_test.exs",
        "defmodule MyApp.UserTest do\nend"
      )

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input:
            Fixtures.tool_input(:edit,
              file_path: Path.join(test_dir, "test/my_app/user_test.exs")
            )
        )

      expect(System, :halt, fn 0 -> :ok end)

      json = run_hook(RelatedFiles, input)

      assert json["decision"] == "block"
      assert json["reason"] =~ "lib/my_app/user.ex"
    end

    test "handles nested directory structures", %{test_dir: test_dir} do
      create_file(
        test_dir,
        "lib/accounts/user.ex",
        "defmodule MyApp.Accounts.User do\nend"
      )

      create_file(
        test_dir,
        "test/accounts/user_test.exs",
        "defmodule MyApp.Accounts.UserTest do\nend"
      )

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Write",
          tool_input:
            Fixtures.tool_input(:write, file_path: Path.join(test_dir, "lib/accounts/user.ex"))
        )

      expect(System, :halt, fn 0 -> :ok end)

      json = run_hook(RelatedFiles, input)

      assert json["decision"] == "block"
      assert json["reason"] =~ "test/accounts/user_test.exs"
    end

    test "handles files with special characters in names", %{test_dir: test_dir} do
      create_file(
        test_dir,
        "lib/my_app/special-name.ex",
        "defmodule MyApp.SpecialName do\nend"
      )

      create_file(
        test_dir,
        "test/my_app/special-name_test.exs",
        "defmodule MyApp.SpecialNameTest do\nend"
      )

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input:
            Fixtures.tool_input(:edit,
              file_path: Path.join(test_dir, "lib/my_app/special-name.ex")
            )
        )

      expect(System, :halt, fn 0 -> :ok end)

      json = run_hook(RelatedFiles, input)

      assert json["decision"] == "block"
      assert json["reason"] =~ "test/my_app/special-name_test.exs"
    end

    test "does not suggest the same file being edited", %{test_dir: test_dir} do
      create_file(test_dir, "lib/example.ex", "defmodule Example do\nend")

      create_file(
        test_dir,
        "test/example_test.exs",
        "defmodule ExampleTest do\nend"
      )

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Write",
          tool_input:
            Fixtures.tool_input(:write, file_path: Path.join(test_dir, "lib/example.ex"))
        )

      expect(System, :halt, fn 0 -> :ok end)

      json = run_hook(RelatedFiles, input)

      assert json["decision"] == "block"
      assert json["reason"] =~ "test/example_test.exs"
      refute json["reason"] =~ ~r/lib\/example\.ex.*lib\/example\.ex/
    end
  end

  describe "glob pattern matching" do
    test "handles wildcard patterns correctly", %{test_dir: test_dir} do
      create_file(
        test_dir,
        "lib/phoenix/channel.ex",
        "defmodule Phoenix.Channel do\nend"
      )

      create_file(
        test_dir,
        "test/phoenix/channel_test.exs",
        "defmodule Phoenix.ChannelTest do\nend"
      )

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input:
            Fixtures.tool_input(:edit, file_path: Path.join(test_dir, "lib/phoenix/channel.ex"))
        )

      expect(System, :halt, fn 0 -> :ok end)

      json = run_hook(RelatedFiles, input)

      assert json["decision"] == "block"
      assert json["reason"] =~ "test/phoenix/channel_test.exs"
    end

    test "returns ok when no files match patterns", %{test_dir: test_dir} do
      create_file(
        test_dir,
        "lib/isolated_module.ex",
        "defmodule IsolatedModule do\nend"
      )

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Write",
          tool_input:
            Fixtures.tool_input(:write, file_path: Path.join(test_dir, "lib/isolated_module.ex"))
        )

      json = run_hook(RelatedFiles, input)

      assert json["suppressOutput"] == true
    end
  end

  describe "edge cases" do
    test "handles files without extensions", %{test_dir: test_dir} do
      input =
        Fixtures.post_tool_use_input(
          tool_name: "Write",
          tool_input: Fixtures.tool_input(:write, file_path: Path.join(test_dir, "lib/README"))
        )

      json = run_hook(RelatedFiles, input)

      assert json["suppressOutput"] == true
    end
  end
end
