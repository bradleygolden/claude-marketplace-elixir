ExUnit.start(capture_log: true)

Mimic.copy(Mix.Task)
Mimic.copy(System)
Mimic.copy(File)
Mimic.copy(Claude.Core.Project)

# Set up a global stub to isolate tests from the project's .claude.exs
# Individual tests can override this by using expect() or stub()
test_isolation_dir = Path.join(System.tmp_dir!(), "claude_test_isolation_#{System.unique_integer([:positive])}")
File.mkdir_p!(test_isolation_dir)
Mimic.stub(Claude.Core.Project, :root, fn -> test_isolation_dir end)
