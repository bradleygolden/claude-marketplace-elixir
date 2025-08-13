if Code.ensure_loaded?(Req) do
  defmodule Claude.Hooks.Reporters.Webhook do
    @moduledoc """
    Webhook reporter for Claude hooks events.

    Sends raw event data to configured HTTP endpoints using the Req library.

    ## Configuration

    Configure in your `.claude.exs`:

        reporters: [
          {:webhook,
            url: "https://example.com/webhook",
            headers: %{"Authorization" => "Bearer token"},
            timeout: 5000,
            retry_count: 3
          }
        ]

    ## Options

    - `:url` (required) - The webhook endpoint URL (must use HTTPS for security)
    - `:headers` - Map of HTTP headers to include (default: `%{}`)
    - `:timeout` - Request timeout in milliseconds (default: 5000)
    - `:retry_count` - Number of retries for transient failures (default: 3)

    ## Security: Webhook Signing

    For production use, you should sign your webhooks to prevent MITM attacks and verify
    authenticity. Since headers are fully customizable, you can implement any signing scheme
    your endpoint requires.

    ### Example: HMAC-SHA256 Signing

    In your `.claude.exs`:

        # Read secret from environment for security
        secret = System.get_env("WEBHOOK_SECRET") || raise "WEBHOOK_SECRET not set"
        
        # Create signature of the event data  
        event_json = Jason.encode!(event_data)
        signature = :crypto.mac(:hmac, :sha256, secret, event_json)
          |> Base.encode16(case: :lower)
        
        # Include signature and timestamp in headers
        reporters: [
          {:webhook,
            url: "https://example.com/webhook",
            headers: %{
              "X-Webhook-Signature" => "sha256=\#{signature}",
              "X-Webhook-Timestamp" => "\#{System.system_time(:second)}",
              "Content-Type" => "application/json"
            }
          }
        ]

    ### Common Webhook Signing Patterns

    Different services expect different header formats:

    **GitHub Style:**

        headers: %{
          "X-Hub-Signature-256" => "sha256=\#{signature}"
        }

    **Stripe Style:**

        timestamp = System.system_time(:second)
        sig_payload = "\#{timestamp}.\#{event_json}"
        signature = :crypto.mac(:hmac, :sha256, secret, sig_payload)
          |> Base.encode16(case: :lower)
        
        headers: %{
          "Stripe-Signature" => "t=\#{timestamp},v1=\#{signature}"
        }

    **Custom with JWT:**

        headers: %{
          "Authorization" => "Bearer \#{generate_jwt_token()}"
        }

    ### Replay Attack Prevention

    Include timestamps in your signatures to prevent replay attacks. The receiver
    should reject webhooks older than a reasonable threshold (e.g., 5 minutes):

        headers: %{
          "X-Webhook-Signature" => computed_signature,
          "X-Webhook-Timestamp" => "\#{System.system_time(:second)}",
          "X-Request-ID" => Ecto.UUID.generate()  # Unique ID for idempotency
        }

    ### Security Best Practices

    1. **Always use HTTPS** - Never send webhooks over plain HTTP
    2. **Store secrets securely** - Use environment variables, not hardcoded values
    3. **Rotate secrets periodically** - Update shared secrets regularly
    4. **Validate timestamps** - Reject old webhooks to prevent replay attacks
    5. **Use strong secrets** - Generate cryptographically secure random secrets
    6. **Log failures** - Monitor and alert on signature validation failures
    """

    @behaviour Claude.Hooks.Reporter
    require Logger

    @impl true
    def report(event_data, opts) do
      payload = %{
        timestamp: System.system_time(:second),
        claude_event: event_data
      }

      url = Keyword.fetch!(opts, :url)
      headers = Keyword.get(opts, :headers, %{})
      timeout = Keyword.get(opts, :timeout, 5_000)
      retry_count = Keyword.get(opts, :retry_count, 3)

      req_options = Keyword.get(opts, :req_options, [])

      base_options = [
        json: payload,
        headers: headers,
        retry: :transient,
        max_retries: retry_count,
        receive_timeout: timeout
      ]

      final_options = Keyword.merge(base_options, req_options)

      case Req.post(url, final_options) do
        {:ok, %{status: status}} when status in 200..299 ->
          :ok

        {:ok, %{status: status}} ->
          Logger.debug("Webhook returned non-success status: #{status}")
          {:error, "HTTP #{status}"}

        {:error, %Req.TransportError{reason: reason}} ->
          Logger.debug("Webhook transport error: #{inspect(reason)}")
          {:error, reason}

        {:error, reason} ->
          Logger.debug("Webhook error: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      error in [Req.TransportError, Req.HTTPError, RuntimeError] ->
        Logger.error("Webhook reporter crashed: #{Exception.message(error)}")
        {:error, Exception.message(error)}
    end
  end
else
  defmodule Claude.Hooks.Reporters.Webhook do
    @moduledoc """
    Webhook reporter stub - Req library not available.

    To enable webhook reporting, add Req to your dependencies:

        {:req, "~> 0.5"}

    Then run `mix deps.get` to install it.
    """

    @behaviour Claude.Hooks.Reporter
    require Logger

    @impl true
    def report(_event_data, _opts) do
      Logger.error("""
      Webhook reporter requires the Req library.
      Add {:req, "~> 0.5"} to your mix.exs dependencies and run mix deps.get
      """)

      {:error, :req_not_available}
    end
  end
end
