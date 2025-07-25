defmodule Claude.TestHelpers do
  @moduledoc """
  Helper functions for tests.
  """

  @doc """
  Ensures Mix tasks are reenabled for testing.
  Call this in your setup block when testing Mix tasks.
  """
  def setup_mix_tasks do
    Mix.Task.clear()
    :ok
  end

  @doc """
  Creates a temporary directory for testing and changes into it.
  Returns the path and restores the original directory on exit.
  """
  def in_tmp(fun) do
    tmp_dir = Path.join(System.tmp_dir!(), "claude_test_#{:erlang.phash2(make_ref())}")
    File.rm_rf!(tmp_dir)
    File.mkdir_p!(tmp_dir)

    original_cwd = File.cwd!()

    try do
      File.cd!(tmp_dir)
      fun.(tmp_dir)
    after
      File.cd!(original_cwd)
      File.rm_rf!(tmp_dir)
    end
  end
end
