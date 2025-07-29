#!/usr/bin/env elixir
# Hook script for Checks for compilation errors after Claude edits Elixir files
# This script is called with JSON input via stdin from Claude Code

# Install dependencies
Mix.install([{:claude, path: "."}, {:jason, "~> 1.4"}, {:igniter, "~> 0.6"}])

# Read JSON from stdin
input = IO.read(:stdio, :eof)

# Reuse the existing hook module
case Claude.Hooks.PostToolUse.CompilationChecker.run(input) do
  :ok -> System.halt(0)
  _ -> System.halt(1)
end
