defmodule Claude.Hooks.DefaultsTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.Defaults

  describe "expand_hook/2" do
    test "expands :compile atom for stop event" do
      assert Defaults.expand_hook(:compile, :stop) ==
               {"compile --warnings-as-errors", halt_pipeline?: true}
    end

    test "expands :compile atom for subagent_stop event" do
      assert Defaults.expand_hook(:compile, :subagent_stop) ==
               {"compile --warnings-as-errors", halt_pipeline?: true}
    end

    test "expands :compile atom for post_tool_use event" do
      assert Defaults.expand_hook(:compile, :post_tool_use) ==
               {"compile --warnings-as-errors",
                when: [:write, :edit, :multi_edit], halt_pipeline?: true}
    end

    test "expands :compile atom for pre_tool_use event" do
      assert Defaults.expand_hook(:compile, :pre_tool_use) ==
               {"compile --warnings-as-errors",
                when: "Bash", command: ~r/^git commit/, halt_pipeline?: true}
    end

    test "expands :format atom for stop event" do
      assert Defaults.expand_hook(:format, :stop) ==
               "format --check-formatted"
    end

    test "expands :format atom for subagent_stop event" do
      assert Defaults.expand_hook(:format, :subagent_stop) ==
               "format --check-formatted"
    end

    test "expands :format atom for post_tool_use event" do
      assert Defaults.expand_hook(:format, :post_tool_use) ==
               {"format --check-formatted {{tool_input.file_path}}",
                when: [:write, :edit, :multi_edit]}
    end

    test "expands :format atom for pre_tool_use event" do
      assert Defaults.expand_hook(:format, :pre_tool_use) ==
               {"format --check-formatted", when: "Bash", command: ~r/^git commit/}
    end

    test "expands :unused_deps atom for pre_tool_use event" do
      assert Defaults.expand_hook(:unused_deps, :pre_tool_use) ==
               {"deps.unlock --check-unused", when: "Bash", command: ~r/^git commit/}
    end

    test "returns unknown atom as-is" do
      assert Defaults.expand_hook(:unknown_atom, :stop) == :unknown_atom
    end

    test "returns non-atom hooks unchanged" do
      hook = {"custom --task", when: [:write]}
      assert Defaults.expand_hook(hook, :post_tool_use) == hook
    end

    test "returns string hooks unchanged" do
      hook = "simple task"
      assert Defaults.expand_hook(hook, :stop) == hook
    end
  end

  describe "expand_hooks/2" do
    test "expands multiple atom hooks in a list" do
      hooks = [:compile, :format]

      expanded = Defaults.expand_hooks(hooks, :stop)

      assert expanded == [
               {"compile --warnings-as-errors", halt_pipeline?: true},
               "format --check-formatted"
             ]
    end

    test "handles mixed atoms and non-atoms" do
      hooks = [:compile, "custom task", {:format, when: [:write]}]

      expanded = Defaults.expand_hooks(hooks, :stop)

      assert expanded == [
               {"compile --warnings-as-errors", halt_pipeline?: true},
               "custom task",
               {:format, when: [:write]}
             ]
    end

    test "returns non-list input unchanged" do
      assert Defaults.expand_hooks(nil, :stop) == nil
      assert Defaults.expand_hooks(%{}, :stop) == %{}
    end
  end
end
