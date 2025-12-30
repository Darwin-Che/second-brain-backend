defmodule SecondBrain.Db.BrainCache do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  import SecondBrain.Db.EctoHelper

  alias SecondBrain.Db.Account
  alias SecondBrain.Db.BrainCache
  alias SecondBrain.Struct.BrainState

  require Logger

  @type t() :: %BrainCache{
          account_id: Account.id_t(),
          brain_status: integer(),
          last_session_task_name: String.t() | nil,
          last_session_start_ts: DateTime.t() | nil,
          last_session_end_ts: DateTime.t() | nil,
          last_session_notes: String.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "brain_cache" do
    belongs_to :account, Account, type: :binary_id

    field :brain_status, :integer
    field :last_session_task_name, :string
    field :last_session_start_ts, :utc_datetime
    field :last_session_end_ts, :utc_datetime
    field :last_session_notes, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(brain_cache, attrs \\ %{}) do
    brain_cache
    |> cast_with_empty(attrs, [
      :account_id,
      :brain_status,
      :last_session_task_name,
      :last_session_start_ts,
      :last_session_end_ts,
      :last_session_notes
    ])
    |> validate_not_nil([
      :account_id,
      :brain_status
    ])
    |> validate_last_session_fields()
  end

  defp validate_last_session_fields(changeset) do
    case get_field(changeset, :brain_status) do
      0 ->
        changeset

      1 ->
        validate_not_nil(changeset, [
          :last_session_task_name,
          :last_session_start_ts,
          :last_session_end_ts
        ])

      2 ->
        changeset
        |> validate_not_nil([
          :last_session_task_name,
          :last_session_start_ts,
          :last_session_end_ts
        ])
    end
  end

  @doc false
  def brain_status_encode(:onboarding), do: 0
  def brain_status_encode(:idle), do: 1
  def brain_status_encode(:busy), do: 2

  @doc false
  def brain_status_decode(0), do: :onboarding
  def brain_status_decode(1), do: :idle
  def brain_status_decode(2), do: :busy

  @doc false
  @spec update(map()) :: {:ok, BrainCache.t()} | {:error, any()}
  def update(%BrainCache{} = brain_cache) do
    repo = SecondBrain.Repo
    attrs = Map.from_struct(brain_cache)

    case repo.get_by(BrainCache, account_id: brain_cache.account_id) do
      nil ->
        # Insert new record if not exists
        Logger.warning("BrainCache.update: Inserting new BrainCache record",
          account_id: brain_cache.account_id
        )

        %BrainCache{}
        |> BrainCache.changeset(attrs)
        |> repo.insert()

      brain_cache ->
        # Update existing record
        brain_cache
        |> BrainCache.changeset(attrs)
        |> repo.update()
    end
  end

  @doc false
  def from_brain_state(%BrainState{last_session: nil} = brain_state) do
    %BrainCache{
      account_id: brain_state.account_id,
      brain_status: brain_status_encode(brain_state.brain_status),
      last_session_task_name: nil,
      last_session_start_ts: nil,
      last_session_end_ts: nil,
      last_session_notes: nil
    }
  end

  def from_brain_state(%BrainState{} = brain_state) do
    %BrainCache{
      account_id: brain_state.account_id,
      brain_status: brain_status_encode(brain_state.brain_status),
      last_session_task_name: brain_state.last_session.task_name,
      last_session_start_ts: brain_state.last_session.start_ts,
      last_session_end_ts: brain_state.last_session.end_ts,
      last_session_notes: brain_state.last_session.notes
    }
  end
end
