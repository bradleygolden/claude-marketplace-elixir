#!/usr/bin/env elixir
# Hook script for Checks for compilation errors after Claude edits Elixir files
# This script is called with JSON input via stdin from Claude Code

# Install dependencies
Mix.install([{:claude, path: "."}, {:jason, "~> 1.4"}, {:igniter, "~> 0.6"}])

# Read JSON from stdin
input = IO.read(:stdio, :eof)

# Run the hook module
# The hook now handles JSON output internally using JsonOutput.write_and_exit/1
# which will output JSON and exit with code 0
Claude.Hooks.PostToolUse.CompilationChecker.run(input)

# If we reach here, the hook didn't exit properly, so we exit with success
System.halt(0)
