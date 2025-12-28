defmodule SecondBrain.Db.Account do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias SecondBrain.Repo
  alias SecondBrain.Db.Account

  @primary_key {:id, :binary_id, autogenerate: true}

  @derive {Phoenix.Param, key: :id}

  @type id_t() :: String.t()

  @type t() :: %Account{
          id: id_t(),
          name: String.t(),
          email: String.t(),
          google_sub: String.t()
        }

  schema "account" do
    field :name, :string
    field :email, :string
    field :google_sub, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :email, :google_sub])
    |> validate_required([:name, :email, :google_sub])
  end

  @doc false
  @spec find_or_create_account(map()) :: {:ok, Account.t()} | {:error, any()}
  def find_or_create_account(%{id: id}) when id != nil do
    case Repo.get(Account, id) do
      nil ->
        {:error, "Cannot create account when ID is given"}

      existing_account ->
        {:ok, existing_account}
    end
  end

  def find_or_create_account(%{google_sub: google_sub} = account) when google_sub != nil do
    case Repo.get_by(Account, google_sub: google_sub) do
      nil ->
        # Create a new account if it doesn't exist
        %Account{}
        |> Account.changeset(account)
        |> Repo.insert()

      existing_account ->
        {:ok, existing_account}
    end
  end
end
