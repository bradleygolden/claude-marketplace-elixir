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
