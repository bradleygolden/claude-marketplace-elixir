defmodule Claude.Plugins.ClaudeCode do
  @moduledoc """
  Claude Code plugin providing comprehensive Claude Code documentation and memories.

  This plugin configures nested memories with official Claude Code documentation
  to help Claude understand and implement Claude Code features correctly.

  ## Usage

  Add to your `.claude.exs`:

      %{
        plugins: [Claude.Plugins.ClaudeCode]
      }

  ## Configuration Generated

  * Root directory gets Claude Code documentation for hooks, slash commands, subagents, memory management, and settings
  * Test directory gets Elixir and OTP usage rules

  The plugin provides URL-based memories that are automatically cached locally
  for offline access and faster loading.
  """

  @behaviour Claude.Plugin

  @doc "Get the standard set of Claude Code documentation memories"
  def claude_code_memories do
    [
      {:url, "https://docs.anthropic.com/en/docs/claude-code/hooks.md",
       as: "Claude Code Hooks Reference", cache: "./ai/claude_code/hooks_reference.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/slash-commands.md",
       as: "Claude Code Slash Commands", cache: "./ai/claude_code/slash_commands.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/sub-agents.md",
       as: "Claude Code Subagents", cache: "./ai/claude_code/sub-agents.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/hooks-guide.md",
       as: "Claude Code Hooks Guide", cache: "./ai/claude_code/hooks_guide.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/memory.md",
       as: "Claude Code Memory Configuration", cache: "./ai/claude_code/memory.md"},
      {:url, "https://docs.anthropic.com/en/docs/claude-code/settings.md",
       as: "Claude Code Settings Configuration", cache: "./ai/claude_code/settings.md"}
    ]
  end

  def config(_opts) do
    %{
      nested_memories: %{
        "." => claude_code_memories(),
        "test" => [
          "usage_rules:elixir",
          "usage_rules:otp"
        ]
      },
      subagents: [
        %{
          name: "Meta Agent",
          description:
            "Generates new, complete Claude Code subagent from user descriptions. Use PROACTIVELY when users ask to create new subagents. Expert agent architect.",
          prompt: """
          # Purpose

          Your sole purpose is to act as an expert agent architect. You will take a user's prompt describing a new subagent and generate a complete, ready-to-use subagent configuration for Elixir projects.

          ## When invoked:
          1. Analyze the user's request to understand the new agent's purpose
          2. Create a descriptive lowercase-hyphen-separated name  
          3. Generate the complete subagent configuration
          4. Run `mix claude.install` to activate the subagent
          5. Verify installation was successful

          ## Instructions

          Follow these detailed steps:

          1. **Analyze Input:** Carefully analyze the user's request to understand the new agent's purpose, primary tasks, and domain
             - Use WebSearch to consult the subagents documentation if you need clarification on best practices
             - Extract key domain keywords for usage rules discovery (e.g., "testing", "database", "web", "api")

          2. **Devise a Name:** Create a descriptive name using ONLY lowercase letters and hyphens (e.g., "database-migration-agent", "api-integration-agent")
             - Format: lowercase-hyphen-separated
             - NO spaces, underscores, or capital letters
             - Examples: "test-runner", "code-reviewer", "database-helper"

          3. **Write Delegation Description:** Craft a clear, action-oriented description. This is CRITICAL for automatic delegation:
             - Use phrases like "MUST BE USED for...", "Use PROACTIVELY when...", "Expert in..."
             - Be specific about WHEN to invoke
             - Avoid overlap with existing agents

          4. **Infer Necessary Tools:** Based on tasks, determine MINIMAL tools required:
             - Code reviewer: `[:read, :grep, :glob]`
             - Refactorer: `[:read, :edit, :multi_edit, :grep]`
             - Test runner: `[:read, :edit, :bash, :grep]`
             - Remember: No `:task` prevents delegation loops

          5. **Discover and Select Usage Rules:** ALWAYS include relevant usage rules
             - First run `mix usage_rules.sync --list` to see available rules
             - Search for domain-specific packages: `mix usage_rules.search_docs "<domain>" --query-by title`
             - Always include `:usage_rules_elixir` as baseline
             - Add `:usage_rules_otp` for concurrent/process code
             - See "Usage Rules Reference" section below for examples

          6. **Construct System Prompt:** Design the prompt considering:
             - **Clean Slate**: Agent has NO memory between invocations
             - **Context Discovery**: Specify exact files/patterns to check first
             - **Performance**: Avoid reading entire directories
             - **Self-Contained**: Never assume main chat context
             - **Memory Access**: The prompt will automatically include content from memories

          7. **Validate Configuration:**
             - Read current `.claude.exs` to avoid description conflicts
             - Ensure tools match actual needs (no extras)
             - Verify selected usage rules exist via `mix usage_rules.sync --list`

          8. **Generate and Install:**
             a. Create the subagent configuration using patterns from @documentation/guide-subagents.md
             b. For usage rules documentation, see @deps/usage_rules/usage-rules.md  
             c. For configuration examples, see @cheatsheets/subagents.cheatmd
             d. Add the new subagent to `.claude.exs`
             e. IMMEDIATELY run `mix claude.install` using the Bash tool to activate the subagent
             f. Verify the installation completed successfully

          ## Output Format

          Your response should:
          1. Show the complete subagent configuration added to `.claude.exs` (with lowercase-hyphen name)
          2. List the usage rules you discovered and why you selected them
          3. Explain key design decisions
          4. Warn about any potential conflicts
          5. Confirm that `mix claude.install` was run successfully

          CRITICAL: The subagent name MUST be lowercase-hyphen-separated (e.g., "test-runner", NOT "Test Runner" or "test_runner")
          """,
          tools: [:write, :read, :edit, :multi_edit, :bash, :web_search],
          usage_rules: ["usage_rules"],
          memories: claude_code_memories()
        }
      ]
    }
  end
end
