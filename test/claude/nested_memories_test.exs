defmodule Claude.NestedMemoriesTest do
  use Claude.ClaudeCodeCase

  describe "generate/1" do
    test "does nothing when no nested_memories config exists" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                stop: [:compile]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      refute Enum.any?(result.tasks, fn
               {"usage_rules.sync", _args} -> true
               _ -> false
             end)
    end

    test "handles empty nested_memories config" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{}
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      assert result == igniter
    end

    test "handles missing .claude.exs file gracefully" do
      igniter = test_project()

      result = Claude.NestedMemories.generate(igniter)

      assert result == igniter
    end

    test "handles invalid .claude.exs syntax gracefully" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                this is invalid syntax
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      assert result == igniter
    end
  end

  describe "integration with claude.install" do
    test "nested memories are part of the install pipeline" do
      igniter = test_project()

      result = Igniter.compose_task(igniter, "claude.install")

      assert Enum.any?(result.tasks, fn
               {"usage_rules.sync", ["CLAUDE.md" | _]} -> true
               _ -> false
             end)
    end
  end

  describe "generate/1 with mocked File.dir?" do
    setup do
      Mimic.stub(File, :dir?, fn
        "lib/existing" -> true
        "lib/my_app" -> true
        "lib/my_app_web/live" -> true
        "test" -> true
        _ -> false
      end)

      :ok
    end

    test "handles root path (.) for documentation references" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "." => [
                  {:url, "https://hexdocs.pm/phoenix/overview.html", as: "Phoenix Overview"},
                  {:url, "https://guides.rubyonrails.org/", as: "Rails Guide (for patterns)"}
                ],
                "lib/my_app" => [:ash]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      # Should have created/updated root CLAUDE.md with documentation references
      {:ok, source} = Rewrite.source(result.rewrite, "CLAUDE.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "<!-- documentation-references-start -->"
      assert content =~ "## Documentation References"
      assert content =~ "- [Phoenix Overview](https://hexdocs.pm/phoenix/overview.html)"
      assert content =~ "- [Rails Guide (for patterns)](https://guides.rubyonrails.org/)"
      assert content =~ "<!-- documentation-references-end -->"

      # Should also process nested path
      assert Enum.any?(result.tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "lib/my_app/CLAUDE.md") and
                   Enum.member?(args, "ash")

               _ ->
                 false
             end)
    end

    test "root path can mix usage rules and documentation references" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "." => [
                  :usage_rules,
                  :claude,
                  {:url, "https://example.com/architecture.md", as: "Architecture Guide"}
                ]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      # Should have usage_rules.sync task for root
      assert Enum.any?(result.tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "CLAUDE.md") and
                   Enum.member?(args, "usage_rules") and
                   Enum.member?(args, "claude")

               _ ->
                 false
             end)

      # Should have documentation references
      {:ok, source} = Rewrite.source(result.rewrite, "CLAUDE.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "- [Architecture Guide](https://example.com/architecture.md)"
    end

    test "generates usage_rules.sync tasks for existing directories" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "lib/my_app" => ["phoenix:ecto", "phoenix:elixir"],
                "lib/my_app_web/live" => ["phoenix:liveview"],
                "test" => ["usage_rules:elixir"]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      tasks = result.tasks

      assert Enum.any?(tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "lib/my_app/CLAUDE.md") and
                   Enum.member?(args, "phoenix:ecto") and
                   Enum.member?(args, "phoenix:elixir") and
                   Enum.member?(args, "--yes")

               _ ->
                 false
             end)

      assert Enum.any?(tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "lib/my_app_web/live/CLAUDE.md") and
                   Enum.member?(args, "phoenix:liveview") and
                   Enum.member?(args, "--yes")

               _ ->
                 false
             end)

      assert Enum.any?(tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "test/CLAUDE.md") and
                   Enum.member?(args, "usage_rules:elixir") and
                   Enum.member?(args, "--yes")

               _ ->
                 false
             end)
    end

    test "handles documentation URLs alongside usage rules" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "lib/my_app" => [
                  "phoenix:ecto",
                  {:url, "https://hexdocs.pm/ash/readme.html"},
                  {:url, "https://example.com/guide.md", as: "Custom Guide"}
                ]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      # Should have usage_rules.sync task for atoms
      assert Enum.any?(result.tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "lib/my_app/CLAUDE.md") and
                   Enum.member?(args, "phoenix:ecto")

               _ ->
                 false
             end)

      # Should have created/updated file with documentation references
      {:ok, source} = Rewrite.source(result.rewrite, "lib/my_app/CLAUDE.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "<!-- documentation-references-start -->"
      assert content =~ "## Documentation References"
      assert content =~ "<!-- doc-ref:hexdocs-pm-ash-readme-html:start -->"
      assert content =~ "- [Readme](https://hexdocs.pm/ash/readme.html)"
      assert content =~ "<!-- doc-ref:example-com-guide-md:start -->"
      assert content =~ "- [Custom Guide](https://example.com/guide.md)"
      assert content =~ "<!-- documentation-references-end -->"
    end

    test "handles only documentation URLs without usage rules" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "lib/my_app" => [
                  {:url, "https://hexdocs.pm/phoenix/overview.html", as: "Phoenix Overview"}
                ]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      # Should NOT have usage_rules.sync task
      refute Enum.any?(result.tasks, fn
               {"usage_rules.sync", _args} -> true
               _ -> false
             end)

      # Should have created file with only documentation references
      {:ok, source} = Rewrite.source(result.rewrite, "lib/my_app/CLAUDE.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "<!-- documentation-references-start -->"
      assert content =~ "- [Phoenix Overview](https://hexdocs.pm/phoenix/overview.html)"
      refute content =~ "<!-- usage-rules-start -->"
    end

    test "only processes directories that exist" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "lib/existing" => ["phoenix:ecto"],
                "lib/non_existing" => ["phoenix:html"]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      tasks = result.tasks

      assert Enum.any?(tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "lib/existing/CLAUDE.md")

               _ ->
                 false
             end)

      refute Enum.any?(tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "lib/non_existing/CLAUDE.md")

               _ ->
                 false
             end)
    end

    test "converts atom rule specs to strings" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "lib/my_app" => [:phoenix_ecto, :usage_rules_elixir]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      assert Enum.any?(result.tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "phoenix_ecto") and
                   Enum.member?(args, "usage_rules_elixir")

               _ ->
                 false
             end)
    end

    test "adds --yes flag to all usage_rules.sync tasks" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "lib/my_app" => ["phoenix:ecto"]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      assert Enum.all?(result.tasks, fn
               {"usage_rules.sync", args} ->
                 "--yes" in args

               _ ->
                 true
             end)
    end
  end

  describe "orphaned CLAUDE.md cleanup" do
    test "cleans up CLAUDE.md files from directories no longer in configuration" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "." => [
                  {:url, "https://example.com/docs.md", as: "Documentation"}
                ],
                "test" => ["usage_rules:elixir"]
              }
            }
            """,
            "lib/old_module/CLAUDE.md" => """
            <!-- documentation-references-start -->
            ## Documentation References

            <!-- doc-ref:old-docs:start -->
            - [Old Documentation](https://old.example.com/docs.md)
            <!-- doc-ref:old-docs:end -->
            <!-- documentation-references-end -->
            """,
            "lib/another_old/CLAUDE.md" => """
            <!-- documentation-references-start -->
            ## Documentation References

            - [Another Old Doc](https://another.example.com)
            <!-- documentation-references-end -->
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      # Check that orphaned CLAUDE.md files have been cleaned up
      {:ok, old_source} = Rewrite.source(result.rewrite, "lib/old_module/CLAUDE.md")
      old_content = Rewrite.Source.get(old_source, :content)

      # Should have documentation references section removed
      refute old_content =~ "<!-- documentation-references-start -->"
      refute old_content =~ "Old Documentation"

      {:ok, another_old_source} = Rewrite.source(result.rewrite, "lib/another_old/CLAUDE.md")
      another_old_content = Rewrite.Source.get(another_old_source, :content)

      refute another_old_content =~ "<!-- documentation-references-start -->"
      refute another_old_content =~ "Another Old Doc"

      # Should have processed configured directories normally
      {:ok, root_source} = Rewrite.source(result.rewrite, "CLAUDE.md")
      root_content = Rewrite.Source.get(root_source, :content)

      assert root_content =~ "<!-- documentation-references-start -->"
      assert root_content =~ "- [Documentation](https://example.com/docs.md)"

      # Test directory should have usage rules task
      assert Enum.any?(result.tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "test/CLAUDE.md") and
                   Enum.member?(args, "usage_rules:elixir")

               _ ->
                 false
             end)
    end

    test "preserves non-documentation content when cleaning up orphaned files" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "test" => ["usage_rules:elixir"]
              }
            }
            """,
            "lib/old_module/CLAUDE.md" => """
            # Custom Instructions

            This directory has special handling for old modules.

            <!-- documentation-references-start -->
            ## Documentation References

            - [Old Documentation](https://old.example.com/docs.md)
            <!-- documentation-references-end -->
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      {:ok, old_source} = Rewrite.source(result.rewrite, "lib/old_module/CLAUDE.md")
      old_content = Rewrite.Source.get(old_source, :content)

      # Should preserve the custom content
      assert old_content =~ "# Custom Instructions"
      assert old_content =~ "This directory has special handling for old modules."

      # Should have removed only the documentation references section
      refute old_content =~ "<!-- documentation-references-start -->"
      refute old_content =~ "Old Documentation"
    end

    test "completely empties files that only contain documentation references" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "test" => ["usage_rules:elixir"]
              }
            }
            """,
            "lib/old_module/CLAUDE.md" => """
            <!-- documentation-references-start -->
            ## Documentation References

            - [Old Documentation](https://old.example.com/docs.md)
            <!-- documentation-references-end -->
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      {:ok, old_source} = Rewrite.source(result.rewrite, "lib/old_module/CLAUDE.md")
      old_content = Rewrite.Source.get(old_source, :content)

      # Should be empty since it only contained documentation references
      assert String.trim(old_content) == ""
    end

    test "does not clean up root CLAUDE.md file even if not explicitly configured" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "test" => ["usage_rules:elixir"]
              }
            }
            """,
            "CLAUDE.md" => """
            # Project Instructions

            <!-- documentation-references-start -->
            ## Documentation References

            - [Some Documentation](https://example.com/docs.md)
            <!-- documentation-references-end -->
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      {:ok, root_source} = Rewrite.source(result.rewrite, "CLAUDE.md")
      root_content = Rewrite.Source.get(root_source, :content)

      # Root CLAUDE.md should be preserved even if not in configuration
      assert root_content =~ "# Project Instructions"
      assert root_content =~ "Some Documentation"
    end
  end
end
