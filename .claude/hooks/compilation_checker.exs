#!/usr/bin/env elixir
# Hook script for Checks for compilation errors after Claude edits Elixir files

Mix.install([{:claude, path: "."}, {:jason, "~> 1.4"}, {:igniter, "~> 0.6"}])

input = IO.read(:stdio, :eof)

Claude.Hooks.PostToolUse.CompilationChecker.run(input)

System.halt(0)
