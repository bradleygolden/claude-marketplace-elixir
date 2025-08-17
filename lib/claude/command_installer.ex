defmodule Claude.CommandInstaller do
  @moduledoc """
  Installs Claude slash commands into the project's .claude/commands directory.

  This module handles:
  - Installing bundled commands from the package
  - Detecting existing user commands
  - Prompting for confirmation on conflicts
  - Preserving user customizations
  """

  @target_commands_dir ".claude/commands"

  @doc """
  Installs bundled commands into the project's .claude/commands directory.

  Returns the updated igniter.
  """
  def install(igniter) do
    igniter
    |> copy_bundled_commands()
  end

  defp copy_bundled_commands(igniter) do
    bundled_path = Path.join([:code.priv_dir(:claude), "commands"])

    if File.exists?(bundled_path) do
      igniter
      |> process_command_directory(bundled_path, @target_commands_dir)
    else
      dev_commands_path = Path.join([File.cwd!(), ".claude", "commands"])

      if File.exists?(dev_commands_path) do
        igniter
        |> process_command_directory(dev_commands_path, @target_commands_dir)
      else
        igniter
      end
    end
  end

  defp process_command_directory(igniter, source_dir, target_dir) do
    source_dir
    |> File.ls!()
    |> Enum.reduce(igniter, fn item, acc ->
      source_path = Path.join(source_dir, item)
      target_path = Path.join(target_dir, item)

      cond do
        File.dir?(source_path) ->
          process_command_directory(acc, source_path, target_path)

        Path.extname(item) == ".md" ->
          process_command_file(acc, source_path, target_path)

        true ->
          acc
      end
    end)
  end

  defp process_command_file(igniter, source_path, target_path) do
    source_content = File.read!(source_path)

    if Igniter.exists?(igniter, target_path) do
      case Rewrite.source(igniter.rewrite, target_path) do
        {:ok, source} ->
          existing_content = Rewrite.Source.get(source, :content)

          if existing_content != source_content do
            handle_conflict(igniter, target_path, source_content, existing_content)
          else
            igniter
          end

        _ ->
          Igniter.create_new_file(igniter, target_path, source_content, on_exists: :skip)
      end
    else
      Igniter.create_new_file(igniter, target_path, source_content)
    end
  end

  defp handle_conflict(igniter, target_path, new_content, existing_content) do
    command_name = Path.basename(target_path, ".md")
    category = Path.dirname(target_path) |> Path.basename()

    # Extract descriptions from frontmatter
    existing_desc = extract_description(existing_content)
    new_desc = extract_description(new_content)

    choices = [
      {"Keep existing", :keep},
      {"Update to new version", :update},
      {"Keep both (rename new)", :both},
      {"Skip", :skip}
    ]

    IO.puts("""

    Conflict detected for command: /#{category}/#{command_name}
    Existing: #{existing_desc || "custom command"}
    New:      #{new_desc || "bundled command"}
    """)

    case Igniter.Util.IO.select("What would you like to do?", choices, default: :keep) do
      {:ok, :keep} ->
        igniter

      {:ok, :update} ->
        backup_path = "#{target_path}.backup"

        igniter
        |> Igniter.create_new_file(backup_path, existing_content)
        |> Igniter.update_file(target_path, new_content)

      {:ok, :both} ->
        new_path = String.replace(target_path, ".md", ".new.md")
        Igniter.create_new_file(igniter, new_path, new_content)

      {:ok, :skip} ->
        igniter

      _ ->
        igniter
    end
  end

  defp extract_description(content) do
    case Regex.run(~r/^description:\s*(.+)$/m, content) do
      [_, desc] -> String.trim(desc)
      _ -> nil
    end
  end

  @doc """
  Lists all available bundled commands for documentation purposes.
  """
  def list_bundled_commands do
    bundled_path = Path.join([:code.priv_dir(:claude), "commands"])
    dev_path = Path.join([File.cwd!(), ".claude", "commands"])

    path = if File.exists?(bundled_path), do: bundled_path, else: dev_path

    if File.exists?(path) do
      path
      |> find_all_commands()
      |> Enum.map(fn {category, commands} ->
        {category, Enum.map(commands, &Path.basename(&1, ".md"))}
      end)
      |> Enum.into(%{})
    else
      %{}
    end
  end

  defp find_all_commands(base_path) do
    base_path
    |> File.ls!()
    |> Enum.filter(&File.dir?(Path.join(base_path, &1)))
    |> Enum.map(fn category ->
      category_path = Path.join(base_path, category)

      commands =
        category_path
        |> File.ls!()
        |> Enum.filter(&String.ends_with?(&1, ".md"))

      {category, commands}
    end)
  end
end
