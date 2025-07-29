#!/usr/bin/env elixir
# Hook script for Suggests updating related files based on naming patterns
# This script is called with JSON input via stdin from Claude Code

# Install dependencies
Mix.install([{:claude, path: "."}, {:jason, "~> 1.4"}, {:igniter, "~> 0.6"}])

# Read JSON from stdin
input = IO.read(:stdio, :eof)

# Load user configuration from .claude.exs
user_config = 
  case File.read(".claude.exs") do
    {:ok, content} ->
      try do
        {config_map, _} = Code.eval_string(content)
        # Find the RelatedFiles hook configuration
        config_map
        |> Map.get(:hooks, [])
        |> Enum.find_value(%{}, fn
          {Claude.Hooks.PostToolUse.RelatedFiles, config} -> config
          _ -> nil
        end)
      rescue
        _ -> %{}
      end
    _ -> %{}
  end

# Reuse the existing hook module with user configuration
case Claude.Hooks.PostToolUse.RelatedFiles.run(input, user_config) do
  :ok -> System.halt(0)
  _ -> System.halt(1)
end
