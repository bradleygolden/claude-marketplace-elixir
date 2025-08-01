defmodule Claude.Hooks.PostToolUse.RelatedFilesTest do
  use Claude.Test.ClaudeCodeCase
  import Claude.Test.SystemHaltHelpers
  import Claude.Test.HookTestHelpers

  alias Claude.Hooks.PostToolUse.RelatedFiles

  describe "run/1" do
    test "returns :ok for :eof input" do
      assert RelatedFiles.run(:eof) == :ok
    end

    test "returns :ok when JSON parsing fails" do
      output =
        capture_io(fn ->
          RelatedFiles.run("invalid json")
        end)

      json = Jason.decode!(output)
      assert json["suppressOutput"] == true
    end

    test "returns :ok for non-edit tools" do
      json_input =
        build_tool_input(
          tool_name: "Read",
          file_path: "lib/example.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      output =
        capture_io(fn ->
          RelatedFiles.run(json_input)
        end)

      json = Jason.decode!(output)
      assert json["suppressOutput"] == true
    end

    test "returns :ok when no related files exist" do
      json_input =
        build_tool_input(
          tool_name: "Write",
          file_path: "lib/nonexistent/deeply/nested/file.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      output =
        capture_io(fn ->
          RelatedFiles.run(json_input)
        end)

      json = Jason.decode!(output)
      assert json["suppressOutput"] == true
    end

    test "outputs block JSON when related test file exists" do
      {test_dir, cleanup} = setup_hook_test(compile: false)

      create_elixir_file(test_dir, "lib/example.ex", "defmodule Example do\nend")
      create_elixir_file(test_dir, "test/example_test.exs", "defmodule ExampleTest do\nend")

      json_input =
        build_tool_input(
          tool_name: "Write",
          file_path: "lib/example.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      expect(System, :halt, fn 0 -> :ok end)

      output =
        capture_io(fn ->
          assert :ok = RelatedFiles.run(json_input)
        end)

      json = Jason.decode!(output)
      assert json["decision"] == "block"
      assert json["reason"] =~ "Related files need updating"
      assert json["reason"] =~ "test/example_test.exs"

      cleanup.()
    end

    test "suggests multiple related files when they exist" do
      {test_dir, cleanup} = setup_hook_test(compile: false)

      # Create files with relative paths since RelatedFiles works with relative paths
      create_elixir_file(test_dir, "lib/mymodule.ex", "defmodule MyModule do\nend")
      create_elixir_file(test_dir, "test/mymodule_test.exs", "defmodule MyModuleTest do\nend")

      json_input =
        build_tool_input(
          tool_name: "Edit",
          file_path: "test/mymodule_test.exs",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      expect(System, :halt, fn 0 -> :ok end)

      output =
        capture_io(fn ->
          assert :ok = RelatedFiles.run(json_input)
        end)

      json = Jason.decode!(output)
      assert json["decision"] == "block"
      assert json["reason"] =~ "Related files need updating"
      assert json["reason"] =~ "lib/mymodule.ex"
      assert json["reason"] =~ "You modified: test/mymodule_test.exs"

      cleanup.()
    end
  end

  describe "run/2" do
    test "ignores user config and calls run/1" do
      json_input =
        build_tool_input(
          tool_name: "Write",
          file_path: "lib/example.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      user_config = %{patterns: [{"custom", "pattern"}]}

      output =
        capture_io(fn ->
          RelatedFiles.run(json_input, user_config)
        end)

      json = Jason.decode!(output)
      assert json["suppressOutput"] == true
    end
  end

  describe "path transformation patterns" do
    test "transforms lib to test with _test suffix" do
      {test_dir, cleanup} = setup_hook_test(compile: false)

      create_elixir_file(test_dir, "lib/my_app/user.ex", "defmodule MyApp.User do\nend")

      create_elixir_file(
        test_dir,
        "test/my_app/user_test.exs",
        "defmodule MyApp.UserTest do\nend"
      )

      json_input =
        build_tool_input(
          tool_name: "Edit",
          file_path: "lib/my_app/user.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      expect(System, :halt, fn 0 -> :ok end)

      output =
        capture_io(fn ->
          assert :ok = RelatedFiles.run(json_input)
        end)

      json = Jason.decode!(output)
      assert json["decision"] == "block"
      assert json["reason"] =~ "test/my_app/user_test.exs"

      cleanup.()
    end

    test "transforms test to lib by removing _test suffix" do
      {test_dir, cleanup} = setup_hook_test(compile: false)

      create_elixir_file(test_dir, "lib/my_app/user.ex", "defmodule MyApp.User do\nend")

      create_elixir_file(
        test_dir,
        "test/my_app/user_test.exs",
        "defmodule MyApp.UserTest do\nend"
      )

      json_input =
        build_tool_input(
          tool_name: "Edit",
          file_path: "test/my_app/user_test.exs",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      expect(System, :halt, fn 0 -> :ok end)

      output =
        capture_io(fn ->
          assert :ok = RelatedFiles.run(json_input)
        end)

      json = Jason.decode!(output)
      assert json["decision"] == "block"
      assert json["reason"] =~ "lib/my_app/user.ex"

      cleanup.()
    end

    test "handles nested directory structures" do
      {test_dir, cleanup} = setup_hook_test(compile: false)

      create_elixir_file(
        test_dir,
        "lib/accounts/user.ex",
        "defmodule MyApp.Accounts.User do\nend"
      )

      create_elixir_file(
        test_dir,
        "test/accounts/user_test.exs",
        "defmodule MyApp.Accounts.UserTest do\nend"
      )

      json_input =
        build_tool_input(
          tool_name: "Write",
          file_path: "lib/accounts/user.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      expect(System, :halt, fn 0 -> :ok end)

      output =
        capture_io(fn ->
          assert :ok = RelatedFiles.run(json_input)
        end)

      json = Jason.decode!(output)
      assert json["decision"] == "block"
      assert json["reason"] =~ "test/accounts/user_test.exs"

      cleanup.()
    end

    test "handles files with special characters in names" do
      {test_dir, cleanup} = setup_hook_test(compile: false)

      create_elixir_file(
        test_dir,
        "lib/my_app/special-name.ex",
        "defmodule MyApp.SpecialName do\nend"
      )

      create_elixir_file(
        test_dir,
        "test/my_app/special-name_test.exs",
        "defmodule MyApp.SpecialNameTest do\nend"
      )

      json_input =
        build_tool_input(
          tool_name: "Edit",
          file_path: "lib/my_app/special-name.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      expect(System, :halt, fn 0 -> :ok end)

      output =
        capture_io(fn ->
          assert :ok = RelatedFiles.run(json_input)
        end)

      json = Jason.decode!(output)
      assert json["decision"] == "block"
      assert json["reason"] =~ "test/my_app/special-name_test.exs"

      cleanup.()
    end

    test "does not suggest the same file being edited" do
      {test_dir, cleanup} = setup_hook_test(compile: false)

      create_elixir_file(test_dir, "lib/example.ex", "defmodule Example do\nend")
      create_elixir_file(test_dir, "test/example_test.exs", "defmodule ExampleTest do\nend")

      json_input =
        build_tool_input(
          tool_name: "Write",
          file_path: "lib/example.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      expect(System, :halt, fn 0 -> :ok end)

      output =
        capture_io(fn ->
          assert :ok = RelatedFiles.run(json_input)
        end)

      json = Jason.decode!(output)
      assert json["decision"] == "block"
      assert json["reason"] =~ "test/example_test.exs"
      refute json["reason"] =~ ~r/lib\/example\.ex.*lib\/example\.ex/

      cleanup.()
    end
  end

  describe "glob pattern matching" do
    test "handles wildcard patterns correctly" do
      {test_dir, cleanup} = setup_hook_test(compile: false)

      create_elixir_file(test_dir, "lib/phoenix/channel.ex", "defmodule Phoenix.Channel do\nend")

      create_elixir_file(
        test_dir,
        "test/phoenix/channel_test.exs",
        "defmodule Phoenix.ChannelTest do\nend"
      )

      json_input =
        build_tool_input(
          tool_name: "Edit",
          file_path: "lib/phoenix/channel.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      expect(System, :halt, fn 0 -> :ok end)

      output =
        capture_io(fn ->
          assert :ok = RelatedFiles.run(json_input)
        end)

      json = Jason.decode!(output)
      assert json["decision"] == "block"
      assert json["reason"] =~ "test/phoenix/channel_test.exs"

      cleanup.()
    end

    test "returns ok when no files match patterns" do
      {test_dir, cleanup} = setup_hook_test(compile: false)

      create_elixir_file(test_dir, "lib/isolated_module.ex", "defmodule IsolatedModule do\nend")

      json_input =
        build_tool_input(
          tool_name: "Write",
          file_path: "lib/isolated_module.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      output =
        capture_io(fn ->
          RelatedFiles.run(json_input)
        end)

      json = Jason.decode!(output)
      assert json["suppressOutput"] == true

      cleanup.()
    end
  end

  describe "edge cases" do
    test "handles files without extensions" do
      json_input =
        build_tool_input(
          tool_name: "Write",
          file_path: "lib/README",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      output =
        capture_io(fn ->
          RelatedFiles.run(json_input)
        end)

      json = Jason.decode!(output)
      assert json["suppressOutput"] == true
    end
  end
end
