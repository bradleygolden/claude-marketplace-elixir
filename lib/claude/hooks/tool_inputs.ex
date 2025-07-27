defmodule Claude.Hooks.ToolInputs do
  @moduledoc """
  Structs for specific tool input types used by Claude Code.

  Each tool has its own input structure that matches the parameters
  Claude Code sends to hooks in the tool_input field.
  """

  defmodule Task do
    @moduledoc """
    Input for the Task tool (sub-agent).
    """
    @derive Jason.Encoder
    defstruct [:description, :prompt]

    @type t :: %__MODULE__{
            description: String.t(),
            prompt: String.t()
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        description: attrs["description"],
        prompt: attrs["prompt"]
      }
    end
  end

  defmodule Bash do
    @moduledoc """
    Input for the Bash tool.
    """
    @derive Jason.Encoder
    defstruct [:command, :description, :timeout]

    @type t :: %__MODULE__{
            command: String.t(),
            description: String.t() | nil,
            timeout: integer() | nil
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        command: attrs["command"],
        description: attrs["description"],
        timeout: attrs["timeout"]
      }
    end
  end

  defmodule Edit do
    @moduledoc """
    Input for the Edit tool.
    """
    @derive Jason.Encoder
    defstruct [:file_path, :old_string, :new_string, :replace_all]

    @type t :: %__MODULE__{
            file_path: String.t(),
            old_string: String.t(),
            new_string: String.t(),
            replace_all: boolean() | nil
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        file_path: attrs["file_path"],
        old_string: attrs["old_string"],
        new_string: attrs["new_string"],
        replace_all: attrs["replace_all"] || false
      }
    end
  end

  defmodule MultiEdit do
    @moduledoc """
    Input for the MultiEdit tool.
    """
    @derive Jason.Encoder
    defstruct [:file_path, :edits]

    @type edit :: %{
            old_string: String.t(),
            new_string: String.t(),
            replace_all: boolean() | nil
          }

    @type t :: %__MODULE__{
            file_path: String.t(),
            edits: [edit()]
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        file_path: attrs["file_path"],
        edits: parse_edits(attrs["edits"] || [])
      }
    end

    defp parse_edits(edits) when is_list(edits) do
      Enum.map(edits, fn edit ->
        %{
          old_string: edit["old_string"],
          new_string: edit["new_string"],
          replace_all: edit["replace_all"] || false
        }
      end)
    end
  end

  defmodule Write do
    @moduledoc """
    Input for the Write tool.
    """
    @derive Jason.Encoder
    defstruct [:file_path, :content]

    @type t :: %__MODULE__{
            file_path: String.t(),
            content: String.t()
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        file_path: attrs["file_path"],
        content: attrs["content"]
      }
    end
  end

  defmodule Read do
    @moduledoc """
    Input for the Read tool.
    """
    @derive Jason.Encoder
    defstruct [:file_path, :limit, :offset]

    @type t :: %__MODULE__{
            file_path: String.t(),
            limit: integer() | nil,
            offset: integer() | nil
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        file_path: attrs["file_path"],
        limit: attrs["limit"],
        offset: attrs["offset"]
      }
    end
  end

  defmodule Glob do
    @moduledoc """
    Input for the Glob tool.
    """
    @derive Jason.Encoder
    defstruct [:path, :pattern]

    @type t :: %__MODULE__{
            path: String.t() | nil,
            pattern: String.t()
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        path: attrs["path"],
        pattern: attrs["pattern"]
      }
    end
  end

  defmodule Grep do
    @moduledoc """
    Input for the Grep tool.
    """
    @derive Jason.Encoder
    defstruct [
      :pattern,
      :path,
      :type,
      :glob,
      :output_mode,
      :head_limit,
      :multiline,
      "-A": nil,
      "-B": nil,
      "-C": nil,
      "-i": nil,
      "-n": nil
    ]

    @type output_mode :: :content | :files_with_matches | :count

    @type t :: %__MODULE__{
            pattern: String.t(),
            path: String.t() | nil,
            type: String.t() | nil,
            glob: String.t() | nil,
            output_mode: output_mode() | nil,
            head_limit: integer() | nil,
            multiline: boolean() | nil,
            "-A": integer() | nil,
            "-B": integer() | nil,
            "-C": integer() | nil,
            "-i": boolean() | nil,
            "-n": boolean() | nil
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        pattern: attrs["pattern"],
        path: attrs["path"],
        type: attrs["type"],
        glob: attrs["glob"],
        output_mode: parse_output_mode(attrs["output_mode"]),
        head_limit: attrs["head_limit"],
        multiline: attrs["multiline"],
        "-A": attrs["-A"],
        "-B": attrs["-B"],
        "-C": attrs["-C"],
        "-i": attrs["-i"],
        "-n": attrs["-n"]
      }
    end

    defp parse_output_mode("content"), do: :content
    defp parse_output_mode("files_with_matches"), do: :files_with_matches
    defp parse_output_mode("count"), do: :count
    defp parse_output_mode(_), do: :files_with_matches
  end

  defmodule LS do
    @moduledoc """
    Input for the LS tool.
    """
    @derive Jason.Encoder
    defstruct [:path, :ignore]

    @type t :: %__MODULE__{
            path: String.t(),
            ignore: [String.t()] | nil
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        path: attrs["path"],
        ignore: attrs["ignore"]
      }
    end
  end

  defmodule NotebookRead do
    @moduledoc """
    Input for the NotebookRead tool.
    """
    @derive Jason.Encoder
    defstruct [:notebook_path, :cell_id]

    @type t :: %__MODULE__{
            notebook_path: String.t(),
            cell_id: String.t() | nil
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        notebook_path: attrs["notebook_path"],
        cell_id: attrs["cell_id"]
      }
    end
  end

  defmodule NotebookEdit do
    @moduledoc """
    Input for the NotebookEdit tool.
    """
    @derive Jason.Encoder
    defstruct [:notebook_path, :new_source, :cell_id, :cell_type, :edit_mode]

    @type cell_type :: :code | :markdown
    @type edit_mode :: :replace | :insert | :delete

    @type t :: %__MODULE__{
            notebook_path: String.t(),
            new_source: String.t(),
            cell_id: String.t() | nil,
            cell_type: cell_type() | nil,
            edit_mode: edit_mode() | nil
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        notebook_path: attrs["notebook_path"],
        new_source: attrs["new_source"],
        cell_id: attrs["cell_id"],
        cell_type: parse_cell_type(attrs["cell_type"]),
        edit_mode: parse_edit_mode(attrs["edit_mode"])
      }
    end

    defp parse_cell_type("code"), do: :code
    defp parse_cell_type("markdown"), do: :markdown
    defp parse_cell_type(_), do: nil

    defp parse_edit_mode("replace"), do: :replace
    defp parse_edit_mode("insert"), do: :insert
    defp parse_edit_mode("delete"), do: :delete
    defp parse_edit_mode(_), do: :replace
  end

  defmodule WebFetch do
    @moduledoc """
    Input for the WebFetch tool.
    """
    @derive Jason.Encoder
    defstruct [:url, :prompt]

    @type t :: %__MODULE__{
            url: String.t(),
            prompt: String.t()
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        url: attrs["url"],
        prompt: attrs["prompt"]
      }
    end
  end

  defmodule WebSearch do
    @moduledoc """
    Input for the WebSearch tool.
    """
    @derive Jason.Encoder
    defstruct [:query, :allowed_domains, :blocked_domains]

    @type t :: %__MODULE__{
            query: String.t(),
            allowed_domains: [String.t()] | nil,
            blocked_domains: [String.t()] | nil
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        query: attrs["query"],
        allowed_domains: attrs["allowed_domains"],
        blocked_domains: attrs["blocked_domains"]
      }
    end
  end

  defmodule TodoWrite do
    @moduledoc """
    Input for the TodoWrite tool.
    """
    @derive Jason.Encoder
    defstruct [:todos]

    @type todo :: %{
            content: String.t(),
            status: :pending | :in_progress | :completed,
            priority: :high | :medium | :low,
            id: String.t()
          }

    @type t :: %__MODULE__{
            todos: [todo()]
          }

    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        todos: parse_todos(attrs["todos"] || [])
      }
    end

    defp parse_todos(todos) when is_list(todos) do
      Enum.map(todos, fn todo ->
        %{
          content: todo["content"],
          status: parse_status(todo["status"]),
          priority: parse_priority(todo["priority"]),
          id: todo["id"]
        }
      end)
    end

    defp parse_status("pending"), do: :pending
    defp parse_status("in_progress"), do: :in_progress
    defp parse_status("completed"), do: :completed
    defp parse_status(_), do: :pending

    defp parse_priority("high"), do: :high
    defp parse_priority("medium"), do: :medium
    defp parse_priority("low"), do: :low
    defp parse_priority(_), do: :medium
  end

  @doc """
  Parses a tool_input map into the appropriate tool input struct based on tool_name.

  ## Examples

      iex> tool_input = %{"file_path" => "/test.ex", "content" => "defmodule Test do\\nend"}
      iex> {:ok, input} = Claude.Hooks.ToolInputs.parse_tool_input("Write", tool_input)
      iex> match?(%Claude.Hooks.ToolInputs.Write{}, input)
      true
  """
  def parse_tool_input(tool_name, tool_input) when is_binary(tool_name) and is_map(tool_input) do
    case tool_name do
      "Task" -> {:ok, Task.new(tool_input)}
      "Bash" -> {:ok, Bash.new(tool_input)}
      "Edit" -> {:ok, Edit.new(tool_input)}
      "MultiEdit" -> {:ok, MultiEdit.new(tool_input)}
      "Write" -> {:ok, Write.new(tool_input)}
      "Read" -> {:ok, Read.new(tool_input)}
      "Glob" -> {:ok, Glob.new(tool_input)}
      "Grep" -> {:ok, Grep.new(tool_input)}
      "LS" -> {:ok, LS.new(tool_input)}
      "NotebookRead" -> {:ok, NotebookRead.new(tool_input)}
      "NotebookEdit" -> {:ok, NotebookEdit.new(tool_input)}
      "WebFetch" -> {:ok, WebFetch.new(tool_input)}
      "WebSearch" -> {:ok, WebSearch.new(tool_input)}
      "TodoWrite" -> {:ok, TodoWrite.new(tool_input)}
      # Return raw map for unknown tools
      _ -> {:ok, tool_input}
    end
  end
end
