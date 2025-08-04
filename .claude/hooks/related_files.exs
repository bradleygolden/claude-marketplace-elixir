#!/usr/bin/env elixir
# Hook script for Suggests updating related files based on naming patterns

Mix.install([{:claude, path: "."}, {:jason, "~> 1.4"}, {:igniter, "~> 0.6"}])

input = IO.read(:stdio, :eof)

Claude.Hooks.PostToolUse.RelatedFiles.run(input)

System.halt(0)
