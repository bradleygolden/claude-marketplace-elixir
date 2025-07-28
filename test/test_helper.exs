ExUnit.start(capture_log: true)

# Copy modules that will be mocked in tests
Mimic.copy(Mix.Task)
Mimic.copy(System)
Mimic.copy(File)
Mimic.copy(IO)
Mimic.copy(Claude.Core.Project)
Mimic.copy(Claude.Hooks.Registry)
Mimic.copy(Claude.Hooks.Telemetry)
Mimic.copy(Claude.Core.Settings)

# Configure integration tests
if System.get_env("RUN_INTEGRATION_TESTS") == "true" do
  # Integration tests are included
  IO.puts("Running with integration tests enabled")
else
  # Skip integration tests by default
  ExUnit.configure(exclude: [:integration])
end

# Ensure telemetry is available for tests that need it
if Code.ensure_loaded?(:telemetry) do
  # Attach default handlers for debugging if needed
  if System.get_env("DEBUG_TELEMETRY") == "true" do
    Claude.Hooks.Telemetry.DefaultHandler.attach_default_handlers()
  end
end
