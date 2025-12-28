defmodule SecondBrain.Struct.WorkSession do
  @moduledoc false

  import SecondBrain.Helper

  alias SecondBrain.Db.Account
  alias SecondBrain.Struct.WorkSession

  @derive {Jason.Encoder,
           only: [
             :account_id,
             :task_name,
             :start_ts,
             :end_ts,
             :notes
           ]}
  defstruct [
    :account_id,
    :task_name,
    :start_ts,
    :end_ts,
    :notes
  ]

  @type t() :: %WorkSession{
          account_id: Account.id_t(),
          task_name: String.t(),
          start_ts: DateTime.t(),
          end_ts: DateTime.t(),
          notes: String.t() | nil
        }

  @spec from_json(map()) :: WorkSession.t()
  def from_json(work_session) do
    {:ok, start_ts, _} = work_session["start_ts"] |> DateTime.from_iso8601()
    {:ok, end_ts, _} = work_session["end_ts"] |> DateTime.from_iso8601()

    %WorkSession{
      account_id: work_session["account_id"],
      task_name: work_session["task_name"],
      start_ts: start_ts,
      end_ts: end_ts,
      notes: work_session["notes"]
    }
  end

  @doc false
  @spec valid?(WorkSession.t()) :: {:ok, WorkSession.t()} | {:error, String.t()}
  def valid?(%WorkSession{} = work_session) do
    cond do
      is_nil(work_session.start_ts) ->
        {:error, "Start timestamp is required"}

      is_nil(work_session.end_ts) ->
        {:error, "End timestamp is required"}

      not aligned_to_minute?(work_session.start_ts) ->
        {:error, "Start timestamp is not aligned to minute"}

      not aligned_to_minute?(work_session.end_ts) ->
        {:error, "End timestamp is not aligned to minute"}

      DateTime.compare(work_session.start_ts, work_session.end_ts) != :lt ->
        {:error, "Start timestamp must be before end timestamp"}

      true ->
        {:ok, work_session}
    end
  end

  @doc false
  @spec new(Account.id_t(), String.t(), DateTime.t(), DateTime.t(), String.t() | nil) ::
          {:ok, WorkSession.t()} | {:error, String.t()}
  def new(account_id, task_name, start_ts, end_ts, notes \\ nil) do
    %WorkSession{
      account_id: account_id,
      task_name: task_name,
      start_ts: start_ts,
      end_ts: end_ts,
      notes: notes
    }
    |> valid?()
  end
end
