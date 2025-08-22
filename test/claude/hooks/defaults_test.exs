defmodule Claude.Hooks.DefaultsTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.Defaults

  describe "expand_hook/2" do
    test "expands :compile atom for stop event" do
      assert Defaults.expand_hook(:compile, :stop) ==
               {"compile --warnings-as-errors", halt_pipeline?: true, blocking?: false}
    end

    test "expands :compile atom for subagent_stop event" do
      assert Defaults.expand_hook(:compile, :subagent_stop) ==
               {"compile --warnings-as-errors", halt_pipeline?: true, blocking?: false}
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
               {"format --check-formatted", blocking?: false}
    end

    test "expands :format atom for subagent_stop event" do
      assert Defaults.expand_hook(:format, :subagent_stop) ==
               {"format --check-formatted", blocking?: false}
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

    test "expands atom with options and merges them" do
      hook = {:compile, env: %{"MIX_ENV" => "test"}}
      expanded = Defaults.expand_hook(hook, :stop)

      assert expanded ==
               {"compile --warnings-as-errors",
                [halt_pipeline?: true, blocking?: false, env: %{"MIX_ENV" => "test"}]}
    end

    test "expands :format atom with custom options" do
      hook = {:format, env: %{"MIX_ENV" => "dev"}, blocking?: false}
      expanded = Defaults.expand_hook(hook, :stop)

      assert expanded ==
               {"format --check-formatted", [env: %{"MIX_ENV" => "dev"}, blocking?: false]}
    end

    test "expands atom with options for post_tool_use preserving existing options" do
      hook = {:compile, env: %{"MIX_ENV" => "test"}}
      expanded = Defaults.expand_hook(hook, :post_tool_use)

      assert expanded ==
               {"compile --warnings-as-errors",
                [
                  when: [:write, :edit, :multi_edit],
                  halt_pipeline?: true,
                  env: %{"MIX_ENV" => "test"}
                ]}
    end

    test "handles tuple with non-atom first element unchanged" do
      hook = {"custom task", env: %{"FOO" => "bar"}}
      assert Defaults.expand_hook(hook, :stop) == hook
    end

    test "expands unknown atom with options returns as-is" do
      hook = {:unknown_atom, env: %{"TEST" => "value"}}
      assert Defaults.expand_hook(hook, :stop) == hook
    end
  end

  describe "expand_hooks/2" do
    test "expands multiple atom hooks in a list" do
      hooks = [:compile, :format]

      expanded = Defaults.expand_hooks(hooks, :stop)

      assert expanded == [
               {"compile --warnings-as-errors", halt_pipeline?: true, blocking?: false},
               {"format --check-formatted", blocking?: false}
             ]
    end

    test "handles mixed atoms and non-atoms" do
      hooks = [:compile, "custom task", {:format, when: [:write]}]

      expanded = Defaults.expand_hooks(hooks, :stop)

      assert expanded == [
               {"compile --warnings-as-errors", halt_pipeline?: true, blocking?: false},
               "custom task",
               {"format --check-formatted", blocking?: false, when: [:write]}
             ]
    end

    test "expands multiple atoms with options" do
      hooks = [
        {:compile, env: %{"MIX_ENV" => "test"}},
        {:format, blocking?: false},
        :unused_deps
      ]

      expanded = Defaults.expand_hooks(hooks, :pre_tool_use)

      assert expanded == [
               {"compile --warnings-as-errors",
                [
                  when: "Bash",
                  command: ~r/^git commit/,
                  halt_pipeline?: true,
                  env: %{"MIX_ENV" => "test"}
                ]},
               {"format --check-formatted",
                [when: "Bash", command: ~r/^git commit/, blocking?: false]},
               {"deps.unlock --check-unused", when: "Bash", command: ~r/^git commit/}
             ]
    end

    test "returns non-list input unchanged" do
      assert Defaults.expand_hooks(nil, :stop) == nil
      assert Defaults.expand_hooks(%{}, :stop) == %{}
    end
  end

  describe "env option preservation" do
    test "preserves env through all event types for :compile" do
      env = %{"MIX_ENV" => "test", "DEBUG" => "1"}

      # stop event
      assert {"compile --warnings-as-errors", opts} =
               Defaults.expand_hook({:compile, env: env}, :stop)

      assert opts[:env] == env
      assert opts[:halt_pipeline?] == true

      # subagent_stop event
      assert {"compile --warnings-as-errors", opts} =
               Defaults.expand_hook({:compile, env: env}, :subagent_stop)

      assert opts[:env] == env
      assert opts[:halt_pipeline?] == true

      # post_tool_use event
      assert {"compile --warnings-as-errors", opts} =
               Defaults.expand_hook({:compile, env: env}, :post_tool_use)

      assert opts[:env] == env
      assert opts[:when] == [:write, :edit, :multi_edit]
      assert opts[:halt_pipeline?] == true

      # pre_tool_use event
      assert {"compile --warnings-as-errors", opts} =
               Defaults.expand_hook({:compile, env: env}, :pre_tool_use)

      assert opts[:env] == env
      assert opts[:when] == "Bash"
      assert opts[:command] == ~r/^git commit/
      assert opts[:halt_pipeline?] == true
    end

    test "preserves env through all event types for :format" do
      env = %{"MIX_ENV" => "dev"}

      # stop event - format returns simple string, env should be added as options
      assert {"format --check-formatted", opts} =
               Defaults.expand_hook({:format, env: env}, :stop)

      assert opts[:env] == env

      # subagent_stop event
      assert {"format --check-formatted", opts} =
               Defaults.expand_hook({:format, env: env}, :subagent_stop)

      assert opts[:env] == env

      # post_tool_use event
      assert {"format --check-formatted {{tool_input.file_path}}", opts} =
               Defaults.expand_hook({:format, env: env}, :post_tool_use)

      assert opts[:env] == env
      assert opts[:when] == [:write, :edit, :multi_edit]

      # pre_tool_use event
      assert {"format --check-formatted", opts} =
               Defaults.expand_hook({:format, env: env}, :pre_tool_use)

      assert opts[:env] == env
      assert opts[:when] == "Bash"
      assert opts[:command] == ~r/^git commit/
    end

    test "env option combines with other custom options" do
      hook = {:compile, env: %{"MIX_ENV" => "test"}, blocking?: false, timeout: 5000}

      assert {"compile --warnings-as-errors", opts} =
               Defaults.expand_hook(hook, :stop)

      assert opts[:env] == %{"MIX_ENV" => "test"}
      assert opts[:blocking?] == false
      assert opts[:timeout] == 5000
      assert opts[:halt_pipeline?] == true
    end

    test "different env values for different hooks in same list" do
      hooks = [
        {:compile, env: %{"MIX_ENV" => "test"}},
        {:format, env: %{"MIX_ENV" => "dev"}},
        :unused_deps
      ]

      expanded = Defaults.expand_hooks(hooks, :pre_tool_use)

      assert [
               {"compile --warnings-as-errors", compile_opts},
               {"format --check-formatted", format_opts},
               {"deps.unlock --check-unused", deps_opts}
             ] = expanded

      assert compile_opts[:env] == %{"MIX_ENV" => "test"}
      assert format_opts[:env] == %{"MIX_ENV" => "dev"}
      assert deps_opts[:when] == "Bash"
      refute Keyword.has_key?(deps_opts, :env)
    end

    test "env option with empty map is preserved" do
      hook = {:compile, env: %{}}

      assert {"compile --warnings-as-errors", opts} =
               Defaults.expand_hook(hook, :stop)

      assert opts[:env] == %{}
      assert opts[:halt_pipeline?] == true
    end
  end
end
