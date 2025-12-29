defmodule SecondBrain.BrainDiskS3.Tasks do
  @moduledoc false

  alias SecondBrain.BrainDiskS3.DiskS3Manager

  alias SecondBrain.Db.Account
  alias SecondBrain.Struct.Task
  alias SecondBrain.Struct.TaskSchedule

  import SecondBrain.Helper

  require Logger

  ### READER FUNCTIONS

  @doc false
  @spec load_tasks_from_disk(Account.id_t()) :: {:ok, [Task.t()]} | {:error, any()}
  def load_tasks_from_disk(account_id) do
    object_path = tasks_object_path(account_id)

    case DiskS3Manager.bucket_name()
         |> ExAws.S3.get_object(object_path)
         |> ExAws.request() do
      {:ok, %{body: body}} ->
        {:ok, body |> Jason.decode!() |> Enum.map(&Task.from_json/1)}

      {:error, {:http_error, 404, _}} ->
        Logger.warning("No existing tasks file found!", account_id: account_id)
        {:ok, []}

      {:error, reason} ->
        Logger.error("Failed to load tasks file #{inspect(reason)}", account_id: account_id)
        {:error, reason}
    end
  end

  ### WRITER FUNCTIONS

  @doc false
  @spec add_task(Account.id_t(), String.t(), non_neg_integer()) :: :ok | {:error, String.t()}
  def add_task(account_id, task_name, hours_per_week) do
    case load_tasks_from_disk(account_id) do
      {:ok, tasks} ->
        tasks_by_name = Map.new(tasks, &{&1.task_name, &1})

        if Map.has_key?(tasks_by_name, task_name) do
          Logger.warning("add_task: Task #{task_name} already exists", account_id: account_id)

          {:error, "Task already exists"}
        else
          task = %Task{task_name: task_name, schedules: []}

          new_task = prepend_task_schedule(task, hours_per_week)

          new_tasks =
            tasks_by_name
            |> Map.put(task_name, new_task)
            |> Map.values()

          put_tasks_to_disk(account_id, new_tasks)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  @spec edit_task(Account.id_t(), String.t(), non_neg_integer()) :: :ok | {:error, String.t()}
  def edit_task(account_id, task_name, hours_per_week) do
    case load_tasks_from_disk(account_id) do
      {:ok, tasks} ->
        tasks_by_name = Map.new(tasks, &{&1.task_name, &1})

        case Map.get(tasks_by_name, task_name) do
          nil ->
            Logger.warning("edit_task: Task #{task_name} not found", account_id: account_id)
            {:error, "Task not found"}

          task ->
            new_task = prepend_task_schedule(task, hours_per_week)

            new_tasks =
              tasks_by_name
              |> Map.put(task_name, new_task)
              |> Map.values()

            put_tasks_to_disk(account_id, new_tasks)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  def prepend_task_schedule(%Task{} = task, hours_per_week) do
    start_at = cur_ts_am()

    schedule_to_add = %TaskSchedule{
      start_at: start_at,
      end_at: nil,
      hours_per_week: hours_per_week
    }

    new_schedules =
      case task.schedules do
        [%{end_at: nil} = active_schedule | rest_schedule] ->
          # set end_at for the active schedule
          [
            schedule_to_add,
            %{active_schedule | end_at: start_at}
          ] ++
            rest_schedule

        _ ->
          [schedule_to_add | task.schedules]
      end

    %Task{
      task
      | schedules: new_schedules
    }
  end

  @doc false
  @spec put_tasks_to_disk(Account.id_t(), [Task.t()]) :: :ok | {:error, any()}
  def put_tasks_to_disk(account_id, tasks) do
    object_path = tasks_object_path(account_id)

    case DiskS3Manager.bucket_name()
         |> ExAws.S3.put_object(object_path, Jason.encode!(tasks))
         |> ExAws.request() do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to put tasks file #{inspect(reason)}", account_id: account_id)
        {:error, reason}
    end
  end

  ### HELPER

  @doc false
  def tasks_object_path(account_id) do
    "brain_disk/#{account_id}/tasks/tasks.json"
  end
end
