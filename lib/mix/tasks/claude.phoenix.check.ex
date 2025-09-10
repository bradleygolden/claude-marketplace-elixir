defmodule Mix.Tasks.Claude.Phoenix.Check do
  @moduledoc """
  Checks if a Phoenix endpoint is reachable by making an HTTP request to its URL.

  Only prints status information when the endpoint responds to a `HEAD` request.
  Connection failures or timeouts are treated as "not running" and produce no
  output. This gives Claude context about running servers while avoiding false
  positives from configuration-only checks.

  ## Usage

      mix claude.phoenix.check MyAppWeb.Endpoint
  """

  use Mix.Task

  @shortdoc "Detects running Phoenix servers"

  def run([endpoint_str]) do
    Mix.Task.run("loadpaths")
    endpoint = Module.concat([endpoint_str])

    case endpoint_status(endpoint) do
      {:ok, url} ->
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

      {:error, :undefined_function} ->
        :ok

      {:error, :not_running} ->
        :ok

      {:error, reason} ->
        Mix.shell().error("Phoenix server check failed: #{inspect(reason)}")
        :ok
    end
  end

  def run(_) do
    IO.puts(:stderr, "Usage: mix claude.phoenix.check <EndpointModule>")
    System.halt(1)
  end

  defp endpoint_status(endpoint) do
    url = endpoint.url()

    if server_running?(url) do
      {:ok, url}
    else
      {:error, :not_running}
    end
  rescue
    _e in UndefinedFunctionError ->
      {:error, :undefined_function}

    e ->
      {:error, e}
  end

  defp server_running?(url) do
    :inets.start()
    :ssl.start()

    case :httpc.request(:head, {String.to_charlist(url), []}, [timeout: 1_000], []) do
      {:ok, {{_, status, _}, _headers, _body}} when status < 400 ->
        true

      {:ok, _} ->
        false

      {:error, _} ->
        false
    end
  end
end
