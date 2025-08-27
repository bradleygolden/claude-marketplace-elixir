defmodule TestPlugins do
  defmodule Simple do
    @behaviour Claude.Plugin

    def config(_opts) do
      %{
        hooks: %{
          stop: [:compile]
        },
        test_value: :simple
      }
    end
  end

  defmodule WithOptions do
    @behaviour Claude.Plugin

    def config(opts) do
      mode = Keyword.get(opts, :mode, :default)

      %{
        mode: mode,
        hooks: %{
          stop:
            case mode do
              :strict -> [:compile, :format, :test]
              :minimal -> [:compile]
              _ -> [:compile, :format]
            end
        }
      }
    end
  end

  defmodule Hooks do
    @behaviour Claude.Plugin

    def config(_opts) do
      %{
        hooks: %{
          stop: [:format],
          post_tool_use: [:compile],
          pre_tool_use: [:unused_deps]
        }
      }
    end
  end

  defmodule Subagents do
    @behaviour Claude.Plugin

    def config(_opts) do
      %{
        subagents: [
          %{
            name: "test-runner",
            description: "Runs tests automatically",
            prompt: "You run tests",
            tools: [:bash, :read]
          },
          %{
            name: "code-reviewer",
            description: "Reviews code quality",
            prompt: "You review code",
            tools: [:read, :grep]
          }
        ]
      }
    end
  end

  defmodule Complex do
    @behaviour Claude.Plugin

    def config(_opts) do
      %{
        hooks: %{
          stop: [:compile, :format],
          post_tool_use: [:format]
        },
        subagents: [
          %{
            name: "complex-agent",
            description: "Complex test agent",
            prompt: "Complex prompt",
            tools: [:read, :write, :edit]
          }
        ],
        mcp_servers: [:tidewave],
        auto_install_deps?: true,
        nested_value: %{
          inner: %{
            deep: [:value1, :value2]
          }
        }
      }
    end
  end

  defmodule Invalid do
    def config(_opts) do
      %{test: :invalid}
    end
  end

  defmodule Failing do
    @behaviour Claude.Plugin

    def config(_opts) do
      raise "Intentional failure for testing"
    end
  end

  defmodule WithReporters do
    @behaviour Claude.Plugin

    def config(_opts) do
      %{
        reporters: [
          {:webhook, url: "https://example.com/plugin-webhook"}
        ],
        hooks: %{
          stop: [:compile]
        }
      }
    end
  end

  defmodule WithMemories do
    @behaviour Claude.Plugin

    def config(_opts) do
      %{
        nested_memories: %{
          "." => [
            {:url, "https://example.com/api-docs.md",
             as: "API Documentation", cache: "./ai/api/docs.md"},
            "usage_rules:elixir",
            "custom:memory"
          ],
          "test" => [
            "usage_rules:otp",
            {:url, "https://example.com/test-guide.md",
             as: "Test Guide", cache: "./ai/test/guide.md"}
          ]
        }
      }
    end
  end

  defmodule WithSubagentMemories do
    @behaviour Claude.Plugin

    def config(_opts) do
      %{
        subagents: [
          %{
            name: "memory-test-agent",
            description: "Agent for testing memories",
            prompt: "Test prompt",
            tools: [:read],
            memories: [
              "usage_rules:elixir",
              {:url, "https://example.com/agent-docs.md",
               as: "Agent Docs", cache: "./ai/agent/docs.md"}
            ]
          }
        ]
      }
    end
  end
end
