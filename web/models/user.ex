defmodule Rumbl.User do
  use Rumbl.Web, :model

  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps
  end

  def changeset(model, params \\ :empty) do
    model
    # Using ~w(name username) is the same as typing ["name", "username"]
    # This 3rd parameter is a tuple for required fields
    # The 4th parameter is a tuple for optional fields
    # Returns an Ecto.Changeset, with all required and optional values assigned to
    # schema types
    |> cast(params, ~w(name username), [])
    |> validate_length(:username, min: 1, max: 20)
  end
end