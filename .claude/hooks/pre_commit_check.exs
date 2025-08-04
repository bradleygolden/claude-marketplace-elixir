#!/usr/bin/env elixir
# Hook script for Validates formatting, compilation, and dependencies before allowing commits

Mix.install([{:claude, path: "."}, {:jason, "~> 1.4"}, {:igniter, "~> 0.6"}])

input = IO.read(:stdio, :eof)

Claude.Hooks.PreToolUse.PreCommitCheck.run(input)

System.halt(0)
