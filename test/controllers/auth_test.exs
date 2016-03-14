defmodule Rumbl.AuthTest do
  use Rumbl.ConnCase
  alias Rumbl.Auth

  setup %{conn: conn} do
    # bypass_through is a test helper that prepares a connection and sends throught the
    # endpoint, router, and desired pipelines, but bypasses the route dispatch. This gives us
    # a connection to test all the transformations we require without going down the typical
    # integration test rabbit holes.
    conn =
      conn
      # Passes our router and explicity sets our pipeline
      |> bypass_through(Rumbl.Router, :browser)

      # Sets endpoint, stops at the :browser pipeline. The path is not used by the router when
      # bypassing - this simply stores the endpoint in the connection.
      |> get("/")

    # With all the requirements for a plug with a valid session and flash message support, we
    # pull the conn from the context and return it for use with our tests.
    {:ok, %{conn: conn}}
  end

  test "authenticate_user halts when no current_user exists", %{conn: conn} do
    conn = Auth.authenticate_user(conn, [])
    assert conn.halted
  end

  test "authenticate_user continues when the current_user exists", %{conn: conn} do
    conn =
      conn
      |> assign(:current_user, %Rumbl.User{})
      |> Auth.authenticate_user([])
      refute conn.halted
  end

  test "login puts the user in the session", %{conn: conn} do
    login_conn =
      conn
      |> Auth.login(%Rumbl.User{id: 123})
      |> send_resp(:ok, "")

    next_conn = get(login_conn, "/")
    assert get_session(next_conn, :user_id) == 123
  end

  test "logout drops the session", %{conn: conn} do
    logout_conn =
      conn
      |> put_session(:user_id, 123)
      |> Auth.logout()
      |> send_resp(:ok, "")

    next_conn = get(logout_conn, "/")
    refute get_session(next_conn, :user_id)
  end
end
