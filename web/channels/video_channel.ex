defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel
  alias Rumbl.AnnotationView

  def join("videos:" <> video_id, _params, socket) do
    video_id = String.to_integer(video_id)

    # Fetches the video from the repo
    video = Repo.get!(Rumbl.Video, video_id)

    # Fetches all annotations for the video, using the index. Preloads user
    # associations.
    annotations = Repo.all(
      from a in assoc(video, :annotations),
        order_by: [desc: a.at],
        limit: 200,
        preload: [:user]
    )

    # Composed a response by rendering an annotation.json view for every
    # annotation in our list using Phoenix.View.render_many. That function
    # essentially offloads the work to the work to the view layer.
    resp = %{annotations: Phoenix.View.render_many(annotations, AnnotationView,
                                                   "annotation.json")}

    {:ok, resp, assign(socket, :video_id, video_id)}
  end

  # Ensures every incoming event has the current_user, then calls our
  # handle_in/4 clause with the user as the 3rd argument.
  def handle_in(event, params, socket) do
    user = Repo.get(Rumbl.User, socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  # Builds an annotation changeset for our user to persist the comment before
  # broadcasting it on the channel.
  def handle_in("new_annotation", params, user, socket) do
    changeset =
      user
      |> build_assoc(:annotations, video_id: socket.assigns.video_id)
      |> Rumbl.Annotation.changeset(params)

    case Repo.insert(changeset) do
      {:ok, annotation} ->
        broadcast! socket, "new_annotation", %{
          id:   annotation.id,
          user: Rumbl.UserView.render("user.json", %{user: user}),
          body: annotation.body,
          at:   annotation.at
        }
        {:reply, :ok, socket}
      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end
end
