defmodule Claude.Config do
  def read do
    claude_exs_path = ".claude.exs"

    if File.exists?(claude_exs_path) do
      try do
        {config, _bindings} = Code.eval_file(claude_exs_path)
        {:ok, config}
      rescue
        e ->
          {:error, Exception.format(:error, e, __STACKTRACE__)}
      end
    else
      {:error, ".claude.exs not found"}
    end
  end
end
