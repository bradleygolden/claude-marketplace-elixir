defmodule Claude.Test do
  @moduledoc """
  General testing utilities for Elixir applications.

  This module provides helpful functions for testing, particularly for
  code that outputs structured data to stdout.
  """

  import ExUnit.CaptureIO

  @doc """
  Creates a file with the given content in the specified directory.

  Returns the full path to the created file.

  ## Examples

      # Create a simple Elixir module
      path = Claude.Test.create_file(test_dir, "lib/example.ex", \"\"\"
      defmodule Example do
        def hello, do: :world
      end
      \"\"\")

      # Create a config file
      Claude.Test.create_file(test_dir, "config/config.exs", \"\"\"
      import Config
      config :my_app, key: :value
      \"\"\")

  ## Arguments

  - `base_dir` - The base directory where the file should be created
  - `relative_path` - The relative path from the base directory
  - `content` - The content to write to the file

  The function will create any necessary parent directories.
  """
  def create_file(base_dir, relative_path, content) do
    full_path = Path.join(base_dir, relative_path)
    dir = Path.dirname(full_path)
    File.mkdir_p!(dir)
    File.write!(full_path, content)
    full_path
  end

  @doc """
  Runs a hook with the given input and returns the parsed JSON output.

  This helper automatically:
  - Encodes the input struct to JSON (if not already a string)
  - Calls the hook's run/1 function
  - Captures the stdout output
  - Parses the output as JSON

  ## Options

  - `:stderr` - When `true`, also captures stderr output during hook execution.
                This is useful when the hook may output to stderr (e.g., compilation
                warnings) that would otherwise interfere with JSON parsing.
                Default: `false`

  ## Examples

      # With a fixture struct
      input = Fixtures.pre_tool_use_input(tool_name: "Edit")
      json = Claude.Test.run_hook(MyHook, input)
      assert json["decision"] == "allow"
      
      # With already-encoded JSON
      json_string = ~s({"tool_name": "Write"})
      json = Claude.Test.run_hook(MyHook, json_string)
      
      # Inline with fixtures
      json = Claude.Test.run_hook(MyHook, Fixtures.post_tool_use_input())
      assert json["suppressOutput"] == true
      
      # Capture stderr during hook execution
      json = Claude.Test.run_hook(MyHook, input, stderr: true)
      assert json["decision"] == "block"

  ## Arguments

  - `hook_module` - The hook module with a run/1 function
  - `input` - Either a struct that can be JSON encoded, or a JSON string
  - `opts` - Keyword list of options (optional)

  ## Returns

  The parsed JSON output from the hook as an Elixir map.
  """
  def run_hook(hook_module, input, opts \\ []) do
    json_input =
      case input do
        input when is_binary(input) -> input
        input -> Jason.encode!(input)
      end

    capture_json_stdout(
      fn -> hook_module.run(json_input) end,
      opts
    )
  end

  @doc """
  Captures stdout output from a function and parses it as JSON.

  This is useful for testing code that outputs JSON to stdout,
  such as CLI tools, hooks, or any code that communicates via
  structured output rather than return values.

  ## Options

  - `:stderr` - When `true`, also captures stderr output during function execution.
                This is useful when the function being tested may output to stderr
                (e.g., compilation warnings) that would otherwise interfere with
                JSON parsing. Default: `false`

  ## Examples

      json = Claude.Test.capture_json_stdout(fn ->
        MyModule.process(input)
      end)
      
      assert json["status"] == "success"
      assert json["data"]["count"] == 42

      # Capture stderr as well to avoid interference
      json = Claude.Test.capture_json_stdout(fn ->
        MyModule.compile_and_run(input)
      end, stderr: true)

  ## Raises

  Raises an error if the captured output is not valid JSON.

  ## Returns

  Returns the parsed JSON as an Elixir map.
  """
  def capture_json_stdout(fun, opts \\ []) do
    capture_stderr? = Keyword.get(opts, :stderr, false)

    output =
      if capture_stderr? do
        capture_io(fn ->
          capture_io(:stderr, fun)
        end)
      else
        capture_io(fun)
      end

    case Jason.decode(output) do
      {:ok, json} -> json
      {:error, _} -> raise "Expected JSON output but got: #{inspect(output)}"
    end
  end
end
