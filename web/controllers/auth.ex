defmodule Rumbl.Auth do
  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

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

  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)

    # Protects us from session fixation attacks. It tells Plug to send the session
    # cookie back to the client with a different identifier, in case an attacker knew
    # the previous one.
    |> configure_session(renew: true)
  end

  def login_by_username_and_pass(conn, username, given_pass, opts) do
    repo = Keyword.fetch!(opts, :repo)
    user = repo.get_by(Rumbl.User, username: username)

    # Match against different conditions to find first one that evaluates to true
    cond do

        # if user exists, then it will call Comeonin's checkpw function. If it returns
        # good, it will run the login function for that user and return the conn, then
        # return the conn
        user && checkpw(given_pass, user.password_hash) ->
          {:ok, login(conn, user)}

        # If user, then it means the password was all that failed from above.  This will
        # return the conn with an error :unauthorized.
        user ->
          {:error, :unauthorized, conn}

        # If all above fails, then it runs a dummy function to simulate password check
        # with variable timing. This hardens the authentication layer against timing
        # attacks.
        true ->
          dummy_checkpw()
          {:error, :not_found, conn}
    end
  end

  def logout(conn) do
    # Drops the entire session. Could have used delete_session(conn, :user_id) to keep
    # everything else besides the :user_id.
    configure_session(conn, drop: true)
  end
end