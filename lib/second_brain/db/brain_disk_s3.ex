defmodule SecondBrain.Db.BrainDiskS3 do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias SecondBrain.Db.Account

  @primary_key {:id, :binary_id, autogenerate: true}

  @type t() :: %__MODULE__{
          id: Ecto.UUID.t(),
          account_id: Ecto.UUID.t(),
          file_name: String.t(),
          file_entry_cnt: non_neg_integer(),
          seq_1: non_neg_integer()
        }

  schema "brain_disk_s3" do
    belongs_to :account, Account, type: :binary_id

    field :file_name, :string
    field :file_entry_cnt, :integer
    field :seq_1, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(brain_disk_s3, attrs) do
    brain_disk_s3
    |> cast(attrs, [:account_id, :file_name, :file_entry_cnt, :seq_1])
    |> validate_required([:account_id, :file_name, :file_entry_cnt, :seq_1])
  end
end
