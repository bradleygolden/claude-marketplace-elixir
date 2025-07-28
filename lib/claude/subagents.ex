defmodule Claude.Subagents do
  @moduledoc """
  Main interface for working with Claude Code subagents.

  Provides functionality to create, enhance, and apply plugins to subagents.
  """

  alias Claude.Subagents.Subagent

  @doc """
  Applies all configured plugins to enhance a subagent.

  Takes a subagent with plugins and returns an enhanced version with
  all plugin enhancements applied.
  """
  def apply_plugins(%Subagent{plugins: plugins} = subagent) do
    Enum.reduce_while(plugins, {:ok, subagent}, fn {plugin_module, opts}, {:ok, acc_subagent} ->
      case apply_plugin(plugin_module, opts, acc_subagent) do
        {:ok, enhanced_subagent} -> {:cont, {:ok, enhanced_subagent}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp apply_plugin(plugin_module, opts, subagent) do
    with :ok <- plugin_module.validate_config(opts),
         {:ok, enhancement} <- plugin_module.enhance(opts) do
      enhanced_subagent = %{
        subagent
        | prompt: join_prompts(subagent.prompt, enhancement.prompt_additions),
          tools: merge_tools(subagent.tools, enhancement.tools)
      }

      {:ok, enhanced_subagent}
    end
  end

  defp join_prompts(base_prompt, nil), do: base_prompt
  defp join_prompts(base_prompt, ""), do: base_prompt

  defp join_prompts(base_prompt, additions) do
    """
    #{base_prompt}

    #{additions}
    """
    |> String.trim()
  end

  defp merge_tools(existing_tools, new_tools) do
    (existing_tools ++ new_tools)
    |> Enum.uniq()
  end
end
