defmodule Claude.Subagents.Plugins.UsageRulesTest do
  use ExUnit.Case, async: false
  alias Claude.Subagents.Plugins.UsageRules
  alias Claude.TestHelpers

  describe "name/0" do
    test "returns the plugin name" do
      assert UsageRules.name() == :usage_rules
    end
  end

  describe "description/0" do
    test "returns a description" do
      assert UsageRules.description() =~ "usage rules"
    end
  end

  describe "validate_config/1" do
    test "validates config with deps list of atoms" do
      assert UsageRules.validate_config(%{deps: [:phoenix, :ecto]}) == :ok
    end

    test "validates config with string dep specs" do
      assert UsageRules.validate_config(%{deps: ["phoenix:views", "ecto:all"]}) == :ok
    end

    test "validates config with mixed atoms and strings" do
      assert UsageRules.validate_config(%{deps: [:phoenix, "ecto:migrations"]}) == :ok
    end

    test "rejects config without deps" do
      assert {:error, msg} = UsageRules.validate_config(%{})
      assert msg =~ "requires 'deps' list"
    end

    test "rejects config with invalid deps" do
      assert {:error, msg} = UsageRules.validate_config(%{deps: [123, %{}]})
      assert msg =~ "atoms or strings"
    end
  end

  describe "enhance/1" do
    test "enhances with usage rules from existing dependencies" do
      TestHelpers.in_tmp(fn tmp_dir ->
        # Create fake deps with usage rules
        deps_dir = Path.join(tmp_dir, "deps")
        File.mkdir_p!(Path.join(deps_dir, "test_dep"))

        File.write!(Path.join([deps_dir, "test_dep", "usage-rules.md"]), """
        # Test Dep Usage Rules

        This is how you use test_dep.
        """)

        File.mkdir_p!(Path.join(deps_dir, "another_dep"))

        File.write!(Path.join([deps_dir, "another_dep", "usage_rules.md"]), """
        # Another Dep Rules

        Guidelines for another_dep.
        """)

        # Change to tmp_dir so the plugin finds our deps
        original_cwd = File.cwd!()
        File.cd!(tmp_dir)

        opts = %{deps: [:test_dep, :another_dep]}
        result = UsageRules.enhance(opts)

        # Change back
        File.cd!(original_cwd)

        assert {:ok, enhancement} = result

        assert enhancement.prompt_additions =~ "Dependency Usage Rules"
        assert enhancement.prompt_additions =~ "Test Dep Usage Rules"
        assert enhancement.prompt_additions =~ "This is how you use test_dep"
        assert enhancement.prompt_additions =~ "Another Dep Usage Rules"
        assert enhancement.prompt_additions =~ "Guidelines for another_dep"

        assert enhancement.tools == []
        assert enhancement.metadata.source == :usage_rules
        assert enhancement.metadata.deps == [:test_dep, :another_dep]
        assert enhancement.metadata.found_count == 2
      end)
    end

    test "handles missing usage rules gracefully" do
      TestHelpers.in_tmp(fn tmp_dir ->
        # Create dep without usage rules
        deps_dir = Path.join(tmp_dir, "deps")
        File.mkdir_p!(Path.join(deps_dir, "no_rules_dep"))

        # Change to tmp_dir so the plugin finds our deps
        original_cwd = File.cwd!()
        File.cd!(tmp_dir)

        opts = %{deps: [:no_rules_dep, :non_existent_dep]}
        result = UsageRules.enhance(opts)

        # Change back
        File.cd!(original_cwd)

        assert {:ok, enhancement} = result

        assert enhancement.prompt_additions == nil
        assert enhancement.tools == []
        assert enhancement.metadata.found_count == 0
      end)
    end

    test "finds usage rules with different naming conventions" do
      TestHelpers.in_tmp(fn tmp_dir ->
        # Test different file name conventions
        deps_dir = Path.join(tmp_dir, "deps")
        File.mkdir_p!(Path.join(deps_dir, "dep1"))
        File.write!(Path.join([deps_dir, "dep1", "usage-rules.md"]), "Hyphenated rules")

        File.mkdir_p!(Path.join(deps_dir, "dep2"))
        File.write!(Path.join([deps_dir, "dep2", "usage_rules.md"]), "Underscored rules")

        File.mkdir_p!(Path.join(deps_dir, "dep3"))
        File.write!(Path.join([deps_dir, "dep3", "USAGE_RULES.md"]), "Uppercase rules")

        # Change to tmp_dir so the plugin finds our deps
        original_cwd = File.cwd!()
        File.cd!(tmp_dir)

        opts = %{deps: [:dep1, :dep2, :dep3]}
        result = UsageRules.enhance(opts)

        # Change back
        File.cd!(original_cwd)

        assert {:ok, enhancement} = result

        assert enhancement.prompt_additions =~ "Hyphenated rules"
        assert enhancement.prompt_additions =~ "Underscored rules"
        assert enhancement.prompt_additions =~ "Uppercase rules"
        assert enhancement.metadata.found_count == 3
      end)
    end

    test "formats dependency names nicely" do
      TestHelpers.in_tmp(fn tmp_dir ->
        deps_dir = Path.join(tmp_dir, "deps")
        File.mkdir_p!(Path.join(deps_dir, "phoenix_live_view"))

        File.write!(
          Path.join([deps_dir, "phoenix_live_view", "usage-rules.md"]),
          "LiveView rules"
        )

        # Change to tmp_dir so the plugin finds our deps
        original_cwd = File.cwd!()
        File.cd!(tmp_dir)

        opts = %{deps: [:phoenix_live_view]}
        result = UsageRules.enhance(opts)

        # Change back
        File.cd!(original_cwd)

        assert {:ok, enhancement} = result

        assert enhancement.prompt_additions =~ "Phoenix Live View Usage Rules"
      end)
    end

    test "supports sub-rules from usage-rules folder" do
      TestHelpers.in_tmp(fn tmp_dir ->
        deps_dir = Path.join(tmp_dir, "deps")
        phoenix_dir = Path.join(deps_dir, "phoenix")
        File.mkdir_p!(Path.join(phoenix_dir, "usage-rules"))

        # Create main usage rules
        File.write!(
          Path.join([phoenix_dir, "usage-rules.md"]),
          "Main Phoenix rules"
        )

        # Create sub-rules
        File.write!(
          Path.join([phoenix_dir, "usage-rules", "views.md"]),
          "Phoenix Views specific rules"
        )

        File.write!(
          Path.join([phoenix_dir, "usage-rules", "controllers.md"]),
          "Phoenix Controllers specific rules"
        )

        # Change to tmp_dir so the plugin finds our deps
        original_cwd = File.cwd!()
        File.cd!(tmp_dir)

        # Test specific sub-rule
        opts = %{deps: ["phoenix:views"]}
        result = UsageRules.enhance(opts)

        # Change back
        File.cd!(original_cwd)

        assert {:ok, enhancement} = result
        assert enhancement.prompt_additions =~ "Phoenix: Views"
        assert enhancement.prompt_additions =~ "Phoenix Views specific rules"
        refute enhancement.prompt_additions =~ "Main Phoenix rules"
        refute enhancement.prompt_additions =~ "Controllers"
      end)
    end

    test "supports :all to include all sub-rules" do
      TestHelpers.in_tmp(fn tmp_dir ->
        deps_dir = Path.join(tmp_dir, "deps")
        phoenix_dir = Path.join(deps_dir, "phoenix")
        File.mkdir_p!(Path.join(phoenix_dir, "usage-rules"))

        # Create sub-rules
        File.write!(
          Path.join([phoenix_dir, "usage-rules", "views.md"]),
          "Phoenix Views rules"
        )

        File.write!(
          Path.join([phoenix_dir, "usage-rules", "controllers.md"]),
          "Phoenix Controllers rules"
        )

        # Change to tmp_dir so the plugin finds our deps
        original_cwd = File.cwd!()
        File.cd!(tmp_dir)

        # Test :all
        opts = %{deps: ["phoenix:all"]}
        result = UsageRules.enhance(opts)

        # Change back
        File.cd!(original_cwd)

        assert {:ok, enhancement} = result
        assert enhancement.prompt_additions =~ "Phoenix: Views"
        assert enhancement.prompt_additions =~ "Phoenix Views rules"
        assert enhancement.prompt_additions =~ "Phoenix: Controllers"
        assert enhancement.prompt_additions =~ "Phoenix Controllers rules"

        # Debug the actual prompt_additions if the test fails
        # IO.puts("Prompt additions:\n#{enhancement.prompt_additions}")
        # IO.puts("Found count: #{enhancement.metadata.found_count}")

        assert enhancement.metadata.found_count == 2
      end)
    end
  end
end
