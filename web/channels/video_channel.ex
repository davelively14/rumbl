defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  def join("videos:" <> video_id, _params, socket) do
    _ = video_id
    {:ok, socket}
  end

  def handle_in("new_annotation", params, socket) do

    # Broadcast sends an event to all users on the current topic. It takes 3
    # arguments: socket, name of the event, and a payload [an arbitrary map].
    broadcast! socket, "new_annotation", %{
      user: %{username: "anon"},
      body: params["body"],
      at:   params["at"]
    }

    {:reply, :ok, socket}
  end
end
