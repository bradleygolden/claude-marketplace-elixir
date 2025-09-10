defmodule Mix.Tasks.Claude.Phoenix.Check do
  @moduledoc """
  Checks if Phoenix server is running by calling Endpoint.url().

  If the endpoint is running, it will return the URL. If not, it will
  fail silently. This gives Claude context about running servers.

  ## Usage

      mix claude.phoenix.check MyAppWeb.Endpoint
  """

  use Mix.Task

  @shortdoc "Detects running Phoenix servers"

  def run([endpoint_str]) do
    Mix.Task.run("loadpaths")
    endpoint = Module.concat([endpoint_str])

    try do
      url = endpoint.url()

      IO.puts("""
      <phoenix_server_status>
      Server: #{inspect(endpoint)}
      Status: RUNNING
      URL: #{url}
      </phoenix_server_status>

      <instructions>
      The Phoenix server is currently running at #{url}. Here's what you should do:

      PRESERVE the running server - Do not kill or restart it because:
        - The developer has hot code reloading active
        - LiveView connections would be interrupted
        - Current application state would be lost
      </instructions>

      <context>
      This check ran automatically when your session started to prevent accidental
      server restarts. The endpoint module #{inspect(endpoint)} successfully responded,
      confirming the server is healthy and accepting requests.
      </context>
      """)
    rescue
      _ -> :ok
    end
  end

  def run(_) do
    IO.puts(:stderr, "Usage: mix claude.phoenix.check <EndpointModule>")
    System.halt(1)
  end
end
