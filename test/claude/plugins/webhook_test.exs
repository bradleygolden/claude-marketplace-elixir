defmodule Claude.Plugins.WebhookTest do
  use Claude.ClaudeCodeCase, async: true
  use Mimic

  alias Claude.Plugins.Webhook

  setup :verify_on_exit!
  setup :set_mimic_from_context

  describe "config/1" do
    test "returns empty config when disabled" do
      assert Webhook.config(enabled: false) == %{}
    end

    test "returns webhook configuration when enabled" do
      config = Webhook.config([])

      assert %{
               reporters: reporters
             } = config

      # Should configure webhook reporter
      assert [{:webhook, webhook_config}] = reporters
      assert is_list(webhook_config)
    end

    test "uses default configuration values" do
      System
      |> stub(:get_env, fn "CLAUDE_WEBHOOK_URL" -> "http://example.com/webhooks" end)

      config = Webhook.config([])
      [{:webhook, webhook_config}] = config.reporters

      assert Keyword.get(webhook_config, :url) == "http://example.com/webhooks"
      assert Keyword.get(webhook_config, :timeout) == 5000
      assert Keyword.get(webhook_config, :retry_count) == 3

      headers = Keyword.get(webhook_config, :headers)
      assert headers["Content-Type"] == "application/json"
    end

    test "accepts custom configuration options" do
      custom_headers = %{
        "Authorization" => "Bearer token123",
        "X-Custom-Header" => "custom-value"
      }

      config =
        Webhook.config(
          url: "https://custom.example.com/hooks",
          timeout: 10000,
          retry_count: 5,
          headers: custom_headers
        )

      [{:webhook, webhook_config}] = config.reporters

      assert Keyword.get(webhook_config, :url) == "https://custom.example.com/hooks"
      assert Keyword.get(webhook_config, :timeout) == 10000
      assert Keyword.get(webhook_config, :retry_count) == 5
      assert Keyword.get(webhook_config, :headers) == custom_headers
    end

    test "uses environment variable for URL when no custom URL provided" do
      System
      |> stub(:get_env, fn "CLAUDE_WEBHOOK_URL" -> "http://env-webhook-url.com" end)

      config = Webhook.config([])
      [{:webhook, webhook_config}] = config.reporters

      assert Keyword.get(webhook_config, :url) == "http://env-webhook-url.com"
    end

    test "custom URL overrides environment variable" do
      System
      |> stub(:get_env, fn "CLAUDE_WEBHOOK_URL" -> "http://env-webhook-url.com" end)

      config = Webhook.config(url: "http://custom-webhook-url.com")
      [{:webhook, webhook_config}] = config.reporters

      assert Keyword.get(webhook_config, :url) == "http://custom-webhook-url.com"
    end
  end
end
