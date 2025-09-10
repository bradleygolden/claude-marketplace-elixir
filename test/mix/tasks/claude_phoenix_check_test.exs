defmodule Mix.Tasks.Claude.Phoenix.CheckTest do
  use Claude.ClaudeCodeCase, async: false

  setup do
    test_name = :"test_#{System.unique_integer([:positive])}"
    Application.put_env(:claude, :phoenix_check_req_options, plug: {Req.Test, test_name})
    on_exit(fn -> Application.delete_env(:claude, :phoenix_check_req_options) end)
    {:ok, test_name: test_name}
  end

  test "server_running?/1 returns true when request succeeds", %{test_name: test_name} do
    Req.Test.stub(test_name, fn conn -> Plug.Conn.send_resp(conn, 200, "ok") end)

    owner = self()
    Req.Test.allow(test_name, owner, self())

    assert Mix.Tasks.Claude.Phoenix.Check.server_running?("http://example.com")
  end

  test "server_running?/1 returns false on transport error", %{test_name: test_name} do
    Req.Test.stub(test_name, &Req.Test.transport_error(&1, :econnrefused))

    owner = self()
    Req.Test.allow(test_name, owner, self())

    refute Mix.Tasks.Claude.Phoenix.Check.server_running?("http://example.com")
  end
end
