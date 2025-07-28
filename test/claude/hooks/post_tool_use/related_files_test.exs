defmodule Claude.Hooks.PostToolUse.RelatedFilesTest do
  use Claude.Test.ClaudeCodeCase
  import Claude.Test.SystemHaltHelpers

  alias Claude.Hooks.PostToolUse.RelatedFiles

  describe "run/1" do
    test "returns :ok for :eof input" do
      assert RelatedFiles.run(:eof) == :ok
    end

    test "returns :ok when JSON parsing fails" do
      assert RelatedFiles.run("invalid json") == :ok
    end

    test "returns :ok for non-edit tools" do
      json_input =
        Jason.encode!(%{
          "hook_event_name" => "PostToolUse",
          "tool_name" => "Read",
          "tool_input" => %{
            "file_path" => "lib/example.ex"
          }
        })

      assert RelatedFiles.run(json_input) == :ok
    end

    test "returns :ok when no related files exist" do
      json_input =
        Jason.encode!(%{
          "hook_event_name" => "PostToolUse",
          "tool_name" => "Write",
          "tool_input" => %{
            "file_path" => "lib/nonexistent/deeply/nested/file.ex"
          }
        })

      assert RelatedFiles.run(json_input) == :ok
    end

    test "exits with code 2 when related test file exists" do
      # Create a temporary lib file and test file
      in_tmp(fn tmp_dir ->
        File.cd!(tmp_dir)

        File.mkdir_p!("lib")
        File.mkdir_p!("test")

        lib_file = "lib/example.ex"
        test_file = "test/example_test.exs"

        File.write!(lib_file, "defmodule Example do\nend")
        File.write!(test_file, "defmodule ExampleTest do\nend")

        json_input =
          Jason.encode!(%{
            "hook_event_name" => "PostToolUse",
            "tool_name" => "Write",
            "tool_input" => %{
              "file_path" => lib_file
            }
          })

        # Expect halt with code 2
        expect_halt(2)

        output =
          capture_io(:stderr, fn ->
            assert {:halt, 2} = RelatedFiles.run(json_input)
          end)

        assert output =~ "Related files need updating"
      end)
    end

    test "suggests multiple related files when they exist" do
      in_tmp(fn tmp_dir ->
        File.cd!(tmp_dir)

        # Create directory structure
        File.mkdir_p!("lib")
        File.mkdir_p!("test")

        lib_file = "lib/mymodule.ex"
        test_file = "test/mymodule_test.exs"

        File.write!(lib_file, "defmodule MyModule do\nend")
        File.write!(test_file, "defmodule MyModuleTest do\nend")

        json_input =
          Jason.encode!(%{
            "hook_event_name" => "PostToolUse",
            "tool_name" => "Edit",
            "tool_input" => %{
              "file_path" => test_file
            }
          })

        # Expect halt with code 2
        expect_halt(2)

        output =
          capture_io(:stderr, fn ->
            assert {:halt, 2} = RelatedFiles.run(json_input)
          end)

        assert output =~ "Related files need updating"
        assert output =~ lib_file
        assert output =~ "You modified: #{test_file}"
      end)
    end
  end

  describe "run/2" do
    test "ignores user config and calls run/1" do
      json_input =
        Jason.encode!(%{
          "hook_event_name" => "PostToolUse",
          "tool_name" => "Write",
          "tool_input" => %{
            "file_path" => "lib/example.ex"
          }
        })

      user_config = %{patterns: [{"custom", "pattern"}]}

      # Should behave the same as run/1
      assert RelatedFiles.run(json_input, user_config) == :ok
    end
  end
end
