defmodule Rumbl.Video do
  use Rumbl.Web, :model

  schema "videos" do
    field :url, :string
    field :title, :string
    field :description, :string
    belongs_to :user, Rumbl.User
    belongs_to :category, Rumbl.Category

    timestamps
  end

  @required_fields ~w(url title description)
  @optional_fields ~w(category_id)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)

    # Because we established an association in the migration when creating the table, any
    # attempt to pick an invalid category resulting in an operation fail will create a constraint
    # error. This function allows us to catch the constraint error in the changeset, which
    # contains error information fit for human consumption.
    |> assoc_constraint(:category)
  end
end
