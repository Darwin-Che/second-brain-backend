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
    %WorkSession{
      account_id: work_session["account_id"],
      task_name: work_session["task_name"],
      start_ts: parse_datetime(work_session["start_ts"]),
      end_ts: parse_datetime(work_session["end_ts"]),
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

      DateTime.compare(work_session.start_ts, work_session.end_ts) == :gt ->
        {:error,
         "Start #{inspect(work_session.start_ts)} must be before End #{inspect(work_session.end_ts)}: #{DateTime.compare(work_session.start_ts, work_session.end_ts)}"}

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

  @doc false
  @spec split_by_week([WorkSession.t()], DateTime.t()) :: %{
          {non_neg_integer(), {DateTime.t(), DateTime.t()}} => [WorkSession.t()]
        }
  def split_by_week(session_history, cur_ts) do
    Enum.group_by(session_history, fn session ->
      week_number = week_number_from_datetime(session, cur_ts)
      week_start = DateTime.shift(cur_ts, week: -(week_number + 1))
      week_end = DateTime.shift(week_start, week: 1)

      {week_number, {week_start, week_end}}
    end)
  end

  defp week_number_from_datetime(session, cur_ts) do
    DateTime.diff(cur_ts, session.start_ts, :day) |> div(7)
  end

  @doc false
  @spec update_notes(WorkSession.t(), String.t()) :: WorkSession.t()
  def update_notes(%WorkSession{} = work_session, notes) do
    %WorkSession{work_session | notes: notes}
  end
end
