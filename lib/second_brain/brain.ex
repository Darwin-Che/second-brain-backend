defmodule SecondBrain.Brain do
  @moduledoc """
  Operation on a brain:

  WRITE
  - Start a work session
  - End a work session
  - Add a task

  READ
  - Recommend tasks
  - Get work session history

  ##########

  Start a work session
  - Only write to the database

  End a work session
  - Write to the database
  - Persist the finished session to brain disk
  - Split the brain disk file if needed
  - Update the db's picture of brain disk

  Add a task
  - Write to the brain disk, only append is needed

  Recommend tasks
  - Read from the brain disk to find tasks lack of effort

  Get work session history
  - Read from the brain disk to find work session history

  ##########

  For the WRITE tasks, need to add a lock to ensure that
  only one write operation can happen at a time

  """

  import SecondBrain.Helper

  alias SecondBrain.Repo

  alias SecondBrain.Db.Account
  alias SecondBrain.Db.BrainCache

  alias SecondBrain.BrainDiskS3

  alias SecondBrain.Struct.BrainState
  alias SecondBrain.Struct.RecommendTask
  alias SecondBrain.Struct.WorkSession

  @doc false
  @spec get_brain_state(Account.id_t()) :: {:ok, BrainState.t()} | {:error, String.t()}
  def get_brain_state(account_id) do
    case Repo.get_by(BrainCache, account_id: account_id) do
      nil ->
        # if account actually exists, should insert a new row
        if Repo.get(Account, account_id) do
          account_id
          |> BrainState.new_onboarding()
          |> BrainState.cache_brain()
        else
          {:error, "Account not found"}
        end

      brain_cache ->
        {:ok, BrainState.from_brain_cache(brain_cache)}
    end
  end

  @doc false
  @spec start_session(BrainState.t(), String.t(), DateTime.t()) ::
          {:ok, BrainState.t()} | {:error, String.t()}
  # credo:disable-for-this-function Credo.Check.Refactor.Nesting
  def start_session(brain_state, task_name, end_ts) do
    case brain_state.brain_status do
      status when status in [:idle, :onboarding] ->
        do_start_session(brain_state, task_name, end_ts)

      :busy ->
        # If the brain is busy, we can't start a new session
        {:error, "Brain is busy, stop the current session first"}
    end
  end

  defp do_start_session(brain_state, task_name, end_ts) do
    case WorkSession.new(brain_state.account_id, task_name, cur_ts_am(), end_ts) do
      {:ok, session} ->
        case BrainState.start_session(brain_state, session) do
          {:ok, new_brain_state} ->
            BrainState.cache_brain(new_brain_state)

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  @spec end_session(BrainState.t()) :: {:ok, BrainState.t()} | {:error, String.t()}
  def end_session(brain_state) do
    case brain_state.brain_status do
      :idle ->
        {:error, "Brain is already idle"}

      :onboarding ->
        {:error, "Brain is already idle (onboarding)"}

      :busy ->
        case BrainState.end_session(brain_state) do
          {:ok, new_brain_state} ->
            {:ok, new_brain_state} = BrainState.cache_brain(new_brain_state)

            :ok =
              BrainDiskS3.SessionHistory.prepend_work_session(
                new_brain_state.account_id,
                new_brain_state.last_session
              )

            {:ok, new_brain_state}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc false
  @spec update_notes(BrainState.t(), String.t()) :: {:ok, BrainState.t()} | {:error, String.t()}
  def update_notes(brain_state, notes) do
    case BrainState.update_notes(brain_state, notes) do
      {:ok, new_brain_state} ->
        BrainState.cache_brain(new_brain_state)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  @spec recommend_task(Account.id_t()) :: {:ok, [RecommendTask.t()]} | {:error, String.t()}
  def recommend_task(account_id) do
    end_time = cur_ts_am()
    start_time = DateTime.shift(end_time, week: -4)

    with {:ok, tasks} <- BrainDiskS3.Tasks.load_tasks_from_disk(account_id),
         session_history <-
           BrainDiskS3.SessionHistory.get_work_session_history_by_time(
             account_id,
             start_time,
             end_time
           ) do
      RecommendTask.recommend_by_history(tasks, session_history, end_time, limit_n: 5)
    else
      {:error, error} -> {:error, error}
    end
  end

  @doc false
  @spec get_work_session_history(Account.id_t()) :: [WorkSession.t()]
  def get_work_session_history(account_id) do
    BrainDiskS3.SessionHistory.get_work_session_history_by_n(account_id, 10)
  end
end
