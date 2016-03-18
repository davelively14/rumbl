defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  # This callback enables clients to join topics on a channel. It will return
  # {:ok, socket} to authorize a join attempt or {:error, socket} to deny.
  # Each socket will hold its own state for the life of the conversation in the
  # socket.assigns field, which typically holds a map.
  def join("videos:" <> video_id, _params, socket) do
    {:ok, assign(socket, :video_id, String.to_integer(video_id))}
    :timer.send_interval(5_000, :ping)
    {:ok, socket}
  end

  def handle_info(:ping, socket) do
    count = socket.assigns[:count] || 1
    push socket, "ping", %{count: count}

    {:noreply, assign(socket, :count, count + 1)}
  end
end
