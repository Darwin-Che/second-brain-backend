defmodule SecondBrain.Management.ArchiveV1 do
  @moduledoc """
  Utility module to handle archiving of production data.
  """

  import SecondBrain.Helper

  alias SecondBrain.Management.ArchiveV1

  alias SecondBrain.Db.Account
  alias SecondBrain.Db.BrainDiskS3, as: BrainDiskS3Db

  alias SecondBrain.Struct.BrainState
  alias SecondBrain.Struct.Task
  alias SecondBrain.Struct.WorkSession

  @derive {Jason.Encoder,
           only: [
             :cur_ts,
             :version,
             :account_id,
             :brain_state,
             :tasks,
             :session_history
           ]}
  defstruct cur_ts: cur_ts_am(),
            version: 1,
            account_id: nil,
            brain_state: nil,
            tasks: [],
            session_history: %{file_entries: [], files_content: %{}}

  @type map_session_history_files_t() :: %{
          String.t() => list(WorkSession.t())
        }

  @type session_history_t() :: %{
          file_entries: list(BrainDiskS3Db.t()),
          files_content: map_session_history_files_t()
        }

  @type t() :: %__MODULE__{
          cur_ts: DateTime.t(),
          version: integer(),
          account_id: Account.id_t(),
          brain_state: BrainState.t(),
          tasks: list(Task.t()),
          session_history: session_history_t()
        }

  @doc false
  @spec from_json(map()) :: ArchiveV1.t()
  def from_json(json) do
    %__MODULE__{
      cur_ts: parse_datetime(Map.get(json, "cur_ts")),
      version: Map.get(json, "version"),
      account_id: Map.get(json, "account_id"),
      brain_state:
        json
        |> Map.get("brain_state")
        |> BrainState.from_json(),
      tasks:
        json
        |> Map.get("tasks")
        |> Enum.map(&Task.from_json/1),
      session_history:
        json
        |> Map.get("session_history")
        |> from_json_session_history()
    }
  end

  def from_json_session_history(json) do
    %{
      file_entries:
        json
        |> Map.get("file_entries", [])
        |> Enum.map(&BrainDiskS3Db.from_json/1),
      files_content:
        json
        |> Map.get("files_content", %{})
        |> Map.new(fn {k, v} -> {k, Enum.map(v, &WorkSession.from_json/1)} end)
    }
  end
end
