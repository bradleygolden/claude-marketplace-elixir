#!/usr/bin/env elixir
# Hook script for Checks if Elixir files need formatting after Claude edits them

Mix.install([{:claude, path: "."}, {:jason, "~> 1.4"}, {:igniter, "~> 0.6"}])

input = IO.read(:stdio, :eof)

Claude.Hooks.PostToolUse.ElixirFormatter.run(input)

System.halt(0)
