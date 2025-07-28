defmodule Features.InstallationFeatureTest do
  @moduledoc """
  Feature tests for Claude installation and project setup.

  Tests the complete user experience for:
  - Installing Claude hooks via mix claude.install
  - Uninstalling Claude hooks via mix claude.uninstall
  - Working with different Elixir project types
  """
  use ExUnit.Case, async: false

  alias Claude.Test.ProjectBuilder

  @test_projects_dir Path.join(System.tmp_dir!(), "claude_test_projects")

  setup do
    File.mkdir_p!(@test_projects_dir)

    on_exit(fn ->
      # Cleanup all test projects
      File.rm_rf!(@test_projects_dir)
    end)

    {:ok, test_dir: @test_projects_dir}
  end

  describe "Feature: Claude hooks installation" do
    test "Scenario: Installing Claude hooks in a new Elixir project", %{test_dir: test_dir} do
      # Given: A fresh Elixir project
      project_name = "install_test_app"
      System.cmd("mix", ["new", project_name], cd: test_dir)
      project_root = Path.join(test_dir, project_name)

      # When: Claude hooks are installed
      main_project = Path.expand("../..", __DIR__)

      {output, 0} =
        System.cmd(
          "mix",
          ["claude", "hooks", "install"],
          cd: main_project,
          env: [{"CLAUDE_PROJECT_DIR", project_root}],
          stderr_to_stdout: true
        )

      # Then: Installation succeeds with proper feedback
      assert output =~ "Claude hooks installed successfully"
      assert output =~ "Checks if Elixir files need formatting"
      assert output =~ "Checks for compilation errors"
      assert output =~ "Validates formatting, compilation, and dependencies"

      # And: Settings file is created with correct structure
      settings_path = Path.join(project_root, ".claude/settings.json")
      assert File.exists?(settings_path)

      settings = Jason.decode!(File.read!(settings_path))
      assert Map.has_key?(settings, "hooks")
      assert Map.has_key?(settings["hooks"], "PostToolUse")
      assert Map.has_key?(settings["hooks"], "PreToolUse")

      # And: Hook commands reference the correct project directory
      post_hooks = settings["hooks"]["PostToolUse"]

      assert Enum.all?(post_hooks, fn hook ->
               Enum.all?(hook["hooks"], &String.contains?(&1["command"], "$CLAUDE_PROJECT_DIR"))
             end)
    end

    test "Scenario: Reinstalling hooks updates existing configuration" do
      # Given: A project with Claude hooks already installed
      project = ProjectBuilder.build_elixir_project("reinstall_test")

      # First installation
      ProjectBuilder.install_claude_hooks(project)
      settings_path = Path.join(project.root, ".claude/settings.json")

      # Modify settings to simulate user changes
      settings = Jason.decode!(File.read!(settings_path))
      settings = Map.put(settings, "user_setting", "custom_value")
      File.write!(settings_path, Jason.encode!(settings, pretty: true))

      # When: Claude hooks are reinstalled
      ProjectBuilder.install_claude_hooks(project)

      # Then: Hooks are updated but user settings are preserved
      updated_settings = Jason.decode!(File.read!(settings_path))
      assert Map.has_key?(updated_settings, "hooks")
      assert Map.has_key?(updated_settings, "user_setting")
      assert updated_settings["user_setting"] == "custom_value"
    end
  end

  describe "Feature: Claude hooks uninstallation" do
    test "Scenario: Uninstalling Claude hooks from a project" do
      # Given: A project with Claude hooks installed
      project =
        ProjectBuilder.build_elixir_project()
        |> ProjectBuilder.install_claude_hooks()

      settings_path = Path.join(project.root, ".claude/settings.json")
      assert File.exists?(settings_path)

      # When: Claude hooks are uninstalled
      main_project = Path.expand("../..", __DIR__)

      {output, 0} =
        System.cmd(
          "mix",
          ["claude", "hooks", "uninstall"],
          cd: main_project,
          env: [{"CLAUDE_PROJECT_DIR", project.root}],
          stderr_to_stdout: true
        )

      # Then: Uninstallation succeeds with feedback
      assert output =~ "Claude hooks uninstalled successfully"

      # And: Hooks are removed from settings
      if File.exists?(settings_path) do
        settings = Jason.decode!(File.read!(settings_path))
        refute Map.has_key?(settings, "hooks") or settings["hooks"] == %{}
      end
    end
  end

  describe "Feature: Working with different project types" do
    test "Scenario: Claude works with standard Elixir applications", %{test_dir: test_dir} do
      # Given: A standard Elixir application
      {_, 0} = System.cmd("mix", ["new", "standard_app"], cd: test_dir)
      project_root = Path.join(test_dir, "standard_app")

      # When: Claude hooks are installed
      main_project = Path.expand("../..", __DIR__)

      System.cmd(
        "mix",
        ["claude", "hooks", "install"],
        cd: main_project,
        env: [{"CLAUDE_PROJECT_DIR", project_root}]
      )

      # Then: Hooks work with the standard project structure
      assert File.exists?(Path.join(project_root, ".claude/settings.json"))
      assert File.exists?(Path.join(project_root, "lib/standard_app.ex"))
    end

    test "Scenario: Claude works with supervised applications", %{test_dir: test_dir} do
      # Given: An application with supervision tree
      {_, 0} = System.cmd("mix", ["new", "supervised_app", "--sup"], cd: test_dir)
      project_root = Path.join(test_dir, "supervised_app")

      # When: Claude hooks are installed
      main_project = Path.expand("../..", __DIR__)

      System.cmd(
        "mix",
        ["claude", "hooks", "install"],
        cd: main_project,
        env: [{"CLAUDE_PROJECT_DIR", project_root}]
      )

      # Then: Hooks work with supervised applications
      assert File.exists?(Path.join(project_root, ".claude/settings.json"))
      assert File.exists?(Path.join(project_root, "lib/supervised_app/application.ex"))
    end

    test "Scenario: Claude works with umbrella projects", %{test_dir: test_dir} do
      # Given: An umbrella project
      {_, 0} = System.cmd("mix", ["new", "umbrella_app", "--umbrella"], cd: test_dir)
      project_root = Path.join(test_dir, "umbrella_app")

      # When: Claude hooks are installed at the umbrella root
      main_project = Path.expand("../..", __DIR__)

      System.cmd(
        "mix",
        ["claude", "hooks", "install"],
        cd: main_project,
        env: [{"CLAUDE_PROJECT_DIR", project_root}]
      )

      # Then: Hooks are installed at the umbrella level
      assert File.exists?(Path.join(project_root, ".claude/settings.json"))
      assert File.dir?(Path.join(project_root, "apps"))
    end
  end

  describe "Feature: Project structure benefits" do
    test "Scenario: mix new provides complete project setup", %{test_dir: test_dir} do
      # When: Creating a new Elixir project
      project_name = "complete_project"
      {output, 0} = System.cmd("mix", ["new", project_name], cd: test_dir)

      # Then: All essential files are created
      assert output =~ "* creating README.md"
      assert output =~ "* creating .formatter.exs"
      assert output =~ "* creating .gitignore"
      assert output =~ "* creating mix.exs"
      assert output =~ "* creating lib/#{project_name}.ex"
      assert output =~ "* creating test/test_helper.exs"
      assert output =~ "* creating test/#{project_name}_test.exs"

      project_root = Path.join(test_dir, project_name)

      # And: All files exist with proper content
      assert File.exists?(Path.join(project_root, "README.md"))
      assert File.exists?(Path.join(project_root, ".gitignore"))
      assert File.exists?(Path.join(project_root, ".formatter.exs"))
      assert File.exists?(Path.join(project_root, "mix.exs"))
      assert File.exists?(Path.join(project_root, "lib/#{project_name}.ex"))
      assert File.exists?(Path.join(project_root, "test/#{project_name}_test.exs"))
    end

    test "Scenario: Projects have proper development configurations", %{test_dir: test_dir} do
      # Given: A new Elixir project
      System.cmd("mix", ["new", "config_test"], cd: test_dir)
      project_root = Path.join(test_dir, "config_test")

      # Then: .gitignore includes important patterns
      gitignore_content = File.read!(Path.join(project_root, ".gitignore"))
      assert gitignore_content =~ "/_build"
      assert gitignore_content =~ "/cover"
      assert gitignore_content =~ "/deps"
      assert gitignore_content =~ "/doc"
      assert gitignore_content =~ "*.ez"
      assert gitignore_content =~ "erl_crash.dump"

      # And: .formatter.exs is properly configured
      formatter_path = Path.join(project_root, ".formatter.exs")
      {formatter_config, _} = Code.eval_file(formatter_path)

      assert formatter_config[:inputs] == [
               "{mix,.formatter}.exs",
               "{config,lib,test}/**/*.{ex,exs}"
             ]
    end
  end
end
