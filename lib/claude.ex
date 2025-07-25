defmodule Claude do
  @moduledoc """
  Opinionated Claude Code integration for Elixir projects.

  A Claude that writes code like an experienced Elixir developer.

  ## Our Opinions

  1. Code should always be production-ready
  2. Project-scoped by default
  3. Zero configuration

  ## Installation

  Add `claude` to your dependencies:

      def deps do
        [
          {:claude, "~> 0.1.0"}
        ]
      end

  ## Usage

  Install Claude hooks (one time per project):

      mix claude.install

  That's it. Claude will now automatically:
  - Format every Elixir file it edits
  - Check for compilation errors after each edit

  For more information, see the [README](https://github.com/bradleygolden/claude).
  """
end
