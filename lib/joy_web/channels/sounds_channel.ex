defmodule JoyWeb.SoundsChannel do
  @moduledoc false
  use JoyWeb, :channel

  @impl true
  def join("sounds:home", _payload, socket) do
    {:ok, socket}
  end
end
