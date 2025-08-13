defmodule Claude.Hooks.Reporters.WebhookTest do
  use Claude.ClaudeCodeCase, async: true
  use Mimic

  alias Claude.Hooks.Reporters.Webhook

  import ExUnit.CaptureLog

  setup :verify_on_exit!
  setup :set_mimic_from_context

  describe "report/2" do
    test "sends webhook successfully with correct payload" do
      event_data = %{
        "hook_event_name" => "post_tool_use",
        "tool_name" => "Write",
        "session_id" => "test-123"
      }

      test_name = :"test_#{System.unique_integer([:positive])}"

      Req.Test.stub(test_name, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/webhook"

        assert ["application/json"] = Plug.Conn.get_req_header(conn, "content-type")

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert decoded["claude_event"] == event_data
        assert is_integer(decoded["timestamp"])

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{received: true}))
      end)

      opts = [
        url: "http://localhost/webhook",
        headers: %{"Authorization" => "Bearer test-token"}
      ]

      req_opts = [plug: {Req.Test, test_name}]
      opts_with_req = Keyword.put(opts, :req_options, req_opts)

      assert :ok = Webhook.report(event_data, opts_with_req)
    end

    test "includes custom headers in request" do
      test_name = :"test_#{System.unique_integer([:positive])}"

      Req.Test.stub(test_name, fn conn ->
        assert ["secret"] = Plug.Conn.get_req_header(conn, "x-api-key")
        assert ["value"] = Plug.Conn.get_req_header(conn, "x-custom")
        assert ["Bearer token"] = Plug.Conn.get_req_header(conn, "authorization")

        Plug.Conn.send_resp(conn, 200, "ok")
      end)

      opts = [
        url: "http://localhost",
        headers: %{
          "x-api-key" => "secret",
          "x-custom" => "value",
          "Authorization" => "Bearer token"
        },
        req_options: [plug: {Req.Test, test_name}]
      ]

      assert :ok = Webhook.report(%{}, opts)
    end

    test "handles non-200 responses" do
      test_name = :"test_#{System.unique_integer([:positive])}"

      Req.Test.stub(test_name, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.send_resp(500, "Internal Server Error")
      end)

      opts = [
        url: "http://localhost/webhook",
        req_options: [plug: {Req.Test, test_name}]
      ]

      log =
        capture_log(fn ->
          assert {:error, "HTTP 500"} = Webhook.report(%{}, opts)
        end)

      assert log =~ "Webhook returned non-success status: 500"
    end

    test "handles 404 responses" do
      test_name = :"test_#{System.unique_integer([:positive])}"

      Req.Test.stub(test_name, fn conn ->
        Plug.Conn.send_resp(conn, 404, "Not Found")
      end)

      opts = [
        url: "http://localhost/nonexistent",
        req_options: [plug: {Req.Test, test_name}]
      ]

      assert {:error, "HTTP 404"} = Webhook.report(%{}, opts)
    end

    test "handles transport errors" do
      test_name = :"test_#{System.unique_integer([:positive])}"

      Req.Test.stub(test_name, fn conn ->
        Req.Test.transport_error(conn, :timeout)
      end)

      opts = [
        url: "http://localhost",
        timeout: 100,
        req_options: [plug: {Req.Test, test_name}]
      ]

      log =
        capture_log(fn ->
          assert {:error, :timeout} = Webhook.report(%{}, opts)
        end)

      assert log =~ "Webhook transport error: :timeout"
    end

    test "requires url in opts" do
      assert_raise KeyError, ~r/key :url not found/, fn ->
        Webhook.report(%{}, [])
      end
    end

    test "passes timeout option to Req" do
      test_name = :"test_#{System.unique_integer([:positive])}"

      Req.Test.stub(test_name, fn conn ->
        Plug.Conn.send_resp(conn, 200, "ok")
      end)

      opts = [
        url: "http://localhost",
        timeout: 1000,
        req_options: [plug: {Req.Test, test_name}]
      ]

      assert :ok = Webhook.report(%{}, opts)
    end

    test "handles empty event data" do
      test_name = :"test_#{System.unique_integer([:positive])}"

      Req.Test.stub(test_name, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert decoded["claude_event"] == nil
        assert is_integer(decoded["timestamp"])

        Plug.Conn.send_resp(conn, 200, "ok")
      end)

      opts = [
        url: "http://localhost",
        req_options: [plug: {Req.Test, test_name}]
      ]

      assert :ok = Webhook.report(nil, opts)
    end

    test "handles complex nested event data" do
      event_data = %{
        "hook_event_name" => "post_tool_use",
        "tool_input" => %{
          "file_path" => "/test/file.ex",
          "content" => "defmodule Test do\nend"
        },
        "tool_response" => %{
          "success" => true,
          "metadata" => %{
            "lines" => 2,
            "chars" => 20
          }
        },
        "nested" => %{
          "deep" => %{
            "value" => [1, 2, 3]
          }
        }
      }

      test_name = :"test_#{System.unique_integer([:positive])}"

      Req.Test.stub(test_name, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert decoded["claude_event"] == event_data
        assert decoded["claude_event"]["nested"]["deep"]["value"] == [1, 2, 3]

        Plug.Conn.send_resp(conn, 200, "ok")
      end)

      opts = [
        url: "http://localhost",
        req_options: [plug: {Req.Test, test_name}]
      ]

      assert :ok = Webhook.report(event_data, opts)
    end

    test "logs errors when webhook crashes" do
      test_name = :"test_#{System.unique_integer([:positive])}"

      Req.Test.stub(test_name, fn _conn ->
        raise "simulated crash"
      end)

      opts = [
        url: "http://localhost",
        req_options: [plug: {Req.Test, test_name}]
      ]

      log =
        capture_log(fn ->
          assert {:error, "simulated crash"} = Webhook.report(%{}, opts)
        end)

      assert log =~ "Webhook reporter crashed: simulated crash"
    end
  end

  describe "configuration" do
    test "uses default timeout when not specified" do
      test_name = :"test_#{System.unique_integer([:positive])}"
      start_time = System.monotonic_time(:millisecond)

      Req.Test.stub(test_name, fn conn ->
        Process.sleep(100)
        Plug.Conn.send_resp(conn, 200, "ok")
      end)

      opts = [
        url: "http://localhost",
        req_options: [plug: {Req.Test, test_name}]
      ]

      assert :ok = Webhook.report(%{}, opts)
      elapsed = System.monotonic_time(:millisecond) - start_time

      assert elapsed >= 100
    end

    test "uses default empty headers when not specified" do
      test_name = :"test_#{System.unique_integer([:positive])}"

      Req.Test.stub(test_name, fn conn ->
        refute Plug.Conn.get_req_header(conn, "x-custom") == ["value"]
        Plug.Conn.send_resp(conn, 200, "ok")
      end)

      opts = [
        url: "http://localhost",
        req_options: [plug: {Req.Test, test_name}]
      ]

      assert :ok = Webhook.report(%{}, opts)
    end
  end
end
