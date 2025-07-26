defmodule Claude.Utils.Glob do
  @moduledoc """
  Simple glob pattern matching utilities.
  
  Provides basic glob pattern matching without filesystem access.
  """
  
  @doc """
  Checks if a path matches a glob pattern.
  
  Supports:
  - `*` - matches any characters except path separator
  - `**` - matches any characters including path separators
  - `?` - matches exactly one character
  - `[abc]` - matches any character in the set
  - `[!abc]` or `[^abc]` - matches any character not in the set
  - Literal characters
  
  ## Examples
  
      iex> Claude.Utils.Glob.match?("lib/foo/bar.ex", "lib/**/*.ex")
      true
      
      iex> Claude.Utils.Glob.match?("test.exs", "*.ex")
      false
  """
  def match?(path, pattern) do
    regex = glob_to_regex(pattern)
    Regex.match?(regex, path)
  end
  
  defp glob_to_regex(pattern) do
    pattern
    |> escape_special_chars()
    |> convert_glob_syntax()
    |> compile_regex()
  end
  
  defp escape_special_chars(pattern) do
    pattern
    |> String.replace(".", "\\.")
    |> String.replace("+", "\\+")
    |> String.replace("^", "\\^")
    |> String.replace("$", "\\$")
    |> String.replace("{", "\\{")
    |> String.replace("}", "\\}")
    |> String.replace("(", "\\(")
    |> String.replace(")", "\\)")
    |> String.replace("|", "\\|")
  end
  
  defp convert_glob_syntax(pattern) do
    pattern
    |> String.replace("**", "DOUBLE_STAR_PLACEHOLDER")
    |> String.replace("*", "[^/]*")
    |> String.replace("DOUBLE_STAR_PLACEHOLDER", ".*")
    |> String.replace("?", ".")
    |> String.replace(~r/\[!([^\]]+)\]/, "[^\\1]")
    |> String.replace(~r/\[\^([^\]]+)\]/, "[^\\1]")
  end
  
  defp compile_regex(pattern) do
    Regex.compile!("^#{pattern}$")
  end
end