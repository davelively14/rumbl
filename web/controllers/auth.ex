defmodule Rumbl.Auth do
  import Plug.Conn

  # Extracts the repository, raising error if given key doesn't exist.
  # Rumbl.Auth will always require the :repo option
  #
  # Note: Keyword.fetch([a: 1, b: 2], :a) would return {:ok, 1}
  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, repo) do
    # If a session :user_id exists, it will be assigned to user_id, otherwise nil
    user_id = get_session(conn, :user_id)

    # If user_id is false, it won't go execute repo.get. Same as:
    #   if user_id, do: repo.get(Rumbl.User, user_id)
    user = user_id && repo.get(Rumbl.User, user_id)

    # Stores the user (or nil, if no existing session) in the :current_user
    assign(conn, :current_user, user)
  end
end