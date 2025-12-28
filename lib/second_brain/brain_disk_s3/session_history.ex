defmodule SecondBrain.BrainDiskS3.SessionHistory do
  @moduledoc false

  import Ecto.Query, only: [from: 2]

  alias SecondBrain.Repo

  alias SecondBrain.Db.Account
  alias SecondBrain.Db.BrainDiskS3, as: BrainDiskS3Db

  alias SecondBrain.BrainDiskS3.DiskS3Manager

  alias SecondBrain.Struct.WorkSession

  require Logger

  # WorkSession is ordered from newest to oldest
  @type file_t() :: {String.t(), [%WorkSession{}]}

  # List of WorkSessions is ordered from newest to oldest
  @type files_t() :: [file_t()]

  ### READER FUNCTIONS

  def get_work_session_history_by_time(account_id, start_ts, end_ts) do
    # Can be optimized
    account_id
    |> get_work_session_history_stream()
    |> Stream.take_while(fn session ->
      session.start_ts >= start_ts and session.end_ts <= end_ts
    end)
    |> Enum.to_list()
  end

  def get_work_session_history_by_n(account_id, n) do
    # Can be optimized
    account_id
    |> get_work_session_history_stream()
    |> Stream.take(n)
    |> Enum.to_list()
  end

  @doc false
  def get_work_session_history_stream(account_id) do
    Stream.unfold(
      {account_id, :root},
      &unfold_next_session/1
    )
  end

  # It is a two level tree structure
  # Root -> Session Files -> Sessions
  # Use BFS to traverse it

  defp unfold_next_session({account_id, :root}) do
    # Load all files
    session_files =
      account_id
      |> get_all_session_history_files()
      |> Enum.sort_by(& &1.seq_1, :desc)

    unfold_next_session({account_id, session_files})
  end

  defp unfold_next_session({account_id, session_files}) do
    case session_files do
      [] ->
        # End of Stream.unfold
        nil

      [%BrainDiskS3Db{file_name: file_name} | rest_files] ->
        case load_brain_disk_session_history(account_id, file_name) do
          {:ok, session_list} ->
            unfold_next_session({account_id, rest_files, session_list})

          {:error, reason} ->
            Logger.error(
              "Failed to load brain disk session history #{file_name} #{inspect(reason)}",
              account_id: account_id
            )

            # Skip this file and continue
            unfold_next_session({account_id, rest_files})
        end
    end
  end

  defp unfold_next_session({account_id, session_files, session_list}) do
    case session_list do
      [] ->
        # Goto next session file
        unfold_next_session({account_id, session_files})

      [head_session | rest_sessions] ->
        {head_session, {account_id, session_files, rest_sessions}}
    end
  end

  ### WRITER FUNCTIONS

  @doc false
  @spec prepend_work_session(Account.id_t(), WorkSession.t()) :: :ok | {:error, any()}
  def prepend_work_session(account_id, work_session) do
    # Load the latest file via lookup the Repo
    case get_latest_session_history_file(account_id) do
      nil ->
        # Create a file
        files = create_new_file_with_one_session(work_session)

        :ok = update_brain_disk_session_history_files(account_id, files)

        :ok = update_brain_disk_session_history_db_entries(account_id, files)

        :ok

      %BrainDiskS3Db{file_name: file_name} ->
        case load_brain_disk_session_history(account_id, file_name) do
          {:ok, session_list} ->
            new_session_list = [work_session | session_list]

            # Split file if needed
            files = split_file_if_needed(new_session_list, file_name)

            # Persist files
            :ok = update_brain_disk_session_history_files(account_id, files)

            # Update the DB entries
            :ok = update_brain_disk_session_history_db_entries(account_id, files)

            :ok

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc false
  @spec split_file_if_needed([WorkSession.t()], String.t()) :: files_t()
  def split_file_if_needed(session_list, prev_file_name) do
    if length(session_list) > max_sessions_per_file() do
      [oldest_list | list_of_new_list] =
        session_list
        |> Enum.reverse()
        |> Enum.chunk_every(max_sessions_per_file())
        |> Enum.map(&Enum.reverse/1)

      Enum.reverse([
        {prev_file_name, oldest_list}
        | Enum.map(list_of_new_list, fn new_list ->
            new_file_name = generate_file_name()
            {new_file_name, new_list}
          end)
      ])
    else
      [
        {prev_file_name, session_list}
      ]
    end
  end

  @doc false
  @spec update_brain_disk_session_history_db_entries(
          Account.id_t(),
          files_t()
        ) :: :ok | {:error, any()}
  def update_brain_disk_session_history_db_entries(account_id, files) do
    # Update from oldest to newest
    files
    |> Enum.reverse()
    |> Enum.each(fn {file_name, session_list} ->
      # Search for existing entry
      case Repo.get_by(BrainDiskS3Db, account_id: account_id, file_name: file_name) do
        nil ->
          # Create new entry
          seq_1 =
            (Repo.one(
               from b in BrainDiskS3Db,
                 where: b.account_id == ^account_id,
                 select: max(b.seq_1)
             ) || 0) + 1

          %BrainDiskS3Db{
            account_id: account_id,
            file_name: file_name,
            file_entry_cnt: length(session_list),
            seq_1: seq_1
          }
          |> Repo.insert!()

        %BrainDiskS3Db{} = existing_entry ->
          # Update existing entry
          existing_entry
          |> Ecto.Changeset.change(%{file_entry_cnt: length(session_list)})
          |> Repo.update!()
      end
    end)

    :ok
  end

  @doc false
  @spec update_brain_disk_session_history_files(Account.id_t(), files_t()) ::
          :ok | {:error, any()}
  def update_brain_disk_session_history_files(account_id, files) do
    results =
      Enum.map(files, fn {file_name, session_list} ->
        update_brain_disk_session_history(account_id, file_name, session_list)
      end)

    if Enum.any?(results, fn result -> result != :ok end) do
      Logger.error("Failed to update brain disk session history files #{inspect(results)}",
        account_id: account_id
      )

      # TODO: Handle this gracefully with Retry or Revert

      {:error, :failed_to_update_files}
    else
      :ok
    end
  end

  @doc false
  @spec update_brain_disk_session_history(Account.id_t(), String.t(), [WorkSession.t()]) ::
          :ok | {:error, any()}
  def update_brain_disk_session_history(account_id, file_name, sessions) do
    object_path = session_history_object_path(account_id, file_name)

    case DiskS3Manager.bucket_name()
         |> ExAws.S3.put_object(object_path, Jason.encode!(sessions))
         |> ExAws.request() do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to create new session history file #{inspect(reason)}",
          account_id: account_id,
          object_path: object_path
        )

        {:error, reason}
    end
  end

  ### HELPER FUNCTIONS

  @doc false
  @spec create_new_file_with_one_session(WorkSession.t()) :: files_t()
  def create_new_file_with_one_session(work_session) do
    file_name = generate_file_name()
    [{file_name, [work_session]}]
  end

  @doc false
  def get_all_session_history_files(account_id) do
    Repo.all(
      from b in BrainDiskS3Db,
        where: b.account_id == ^account_id,
        order_by: [desc: b.seq_1]
    )
  end

  @doc false
  @spec get_latest_session_history_file(Account.id_t()) ::
          nil | %BrainDiskS3Db{}
  def get_latest_session_history_file(account_id) do
    # Get the latest file name from the database
    case Repo.one(
           from b in BrainDiskS3Db,
             where: b.account_id == ^account_id,
             order_by: [desc: b.seq_1],
             limit: 1
         ) do
      nil ->
        Logger.warning("No existing brain disk session_history found!", account_id: account_id)

        nil

      %BrainDiskS3Db{} = brain_disk_s3_file_entry ->
        brain_disk_s3_file_entry
    end
  end

  @doc false
  @spec load_brain_disk_session_history(Account.id_t(), String.t()) ::
          {:ok, [WorkSession.t()]} | {:error, String.t()}
  def load_brain_disk_session_history(account_id, file_name) do
    object_path = session_history_object_path(account_id, file_name)

    case DiskS3Manager.bucket_name()
         |> ExAws.S3.get_object(object_path)
         |> ExAws.request() do
      {:ok, %{body: body}} ->
        {:ok, body |> Jason.decode!() |> Enum.map(&WorkSession.from_json/1)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  @spec put_brain_disk_session_history(
          Account.id_t(),
          String.t(),
          [WorkSession.t()]
        ) ::
          :ok | {:error, any()}
  def put_brain_disk_session_history(account_id, file_name, session_list) do
    object_path = session_history_object_path(account_id, file_name)

    case DiskS3Manager.bucket_name()
         |> ExAws.S3.put_object(object_path, Jason.encode!(session_list))
         |> ExAws.request() do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to update session history file #{inspect(reason)}",
          account_id: account_id,
          object_path: object_path
        )

        {:error, reason}
    end
  end

  def session_history_object_path(account_id, file_name) do
    "brain_disk/#{account_id}/session_history/#{file_name}.json"
  end

  def generate_file_name do
    "#{UUIDv7.cast!(UUIDv7.bingenerate())}"
  end

  def max_sessions_per_file do
    Application.get_env(:second_brain, SecondBrain.BrainDiskS3)[:max_sessions_per_file]
  end
end
