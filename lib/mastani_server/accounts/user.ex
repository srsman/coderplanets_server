defmodule MastaniServer.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts.{User, GithubUser}

  schema "users" do
    field(:nickname, :string)
    field(:avatar, :string)
    field(:sex, :string)
    field(:bio, :string)
    field(:from_github, :boolean)
    has_one(:github_profile, GithubUser)

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(nickname)a
  @optional_fields ~w(nickname bio avatar sex)a

  @doc false
  def changeset(%User{} = user, attrs) do
    # |> cast(attrs, [:username, :nickname, :bio, :company])
    # |> validate_required([:username])
    # |> cast(attrs, @required_fields, @optional_fields)
    user
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:nickname, max: 30)

    # |> unique_constraint(:username)
  end
end
