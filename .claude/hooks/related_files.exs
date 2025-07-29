#!/usr/bin/env elixir
# Hook script for Suggests updating related files based on naming patterns
# This script is called with JSON input via stdin from Claude Code

# Install dependencies
Mix.install([{:claude, path: "."}, {:jason, "~> 1.4"}])

# Read JSON from stdin
input = IO.read(:stdio, :eof)

# Reuse the existing hook module
case Claude.Hooks.PostToolUse.RelatedFiles.run(input) do
  :ok -> System.halt(0)
  _ -> System.halt(1)
end
