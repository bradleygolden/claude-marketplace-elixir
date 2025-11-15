defmodule PhoenixLiveViewTest do
  @moduledoc """
  Test file that uses ONLY Phoenix.LiveView.
  Should match only phoenix_live_view, NOT phoenix or phoenix_html.
  """
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    {:cont, socket}
  end
end
