defmodule SecondBrain.Brain.AddTaskTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias SecondBrain.BrainDiskS3

  alias SecondBrain.TestSupport.S3Cleanup

  @moduletag :external
  @account_id "test_account_s3"

  setup do
    # Clean up S3 before each test
    S3Cleanup.cleanup_bucket!()
    :ok
  end

  test "add_task creates and updates tasks in S3" do
    # Add a new task
    assert :ok = BrainDiskS3.Tasks.add_task(@account_id, "task1", 5)
    {:ok, tasks} = BrainDiskS3.Tasks.load_tasks_from_disk(@account_id)
    assert Enum.any?(tasks, &(&1.task_name == "task1"))

    # Add another schedule to the same task
    assert :ok = BrainDiskS3.Tasks.edit_task(@account_id, "task1", 10)
    {:ok, tasks2} = BrainDiskS3.Tasks.load_tasks_from_disk(@account_id)
    task1 = Enum.find(tasks2, &(&1.task_name == "task1"))
    assert length(task1.schedules) == 2

    # Fail to add task with the same name
    assert {:error, "Task already exists"} = BrainDiskS3.Tasks.add_task(@account_id, "task1", 5)
    {:ok, tasks3} = BrainDiskS3.Tasks.load_tasks_from_disk(@account_id)
    task2 = Enum.find(tasks3, &(&1.task_name == "task1"))
    assert length(task2.schedules) == 2

    # Add a different task
    assert :ok = BrainDiskS3.Tasks.add_task(@account_id, "task2", 3)
    {:ok, tasks4} = BrainDiskS3.Tasks.load_tasks_from_disk(@account_id)
    assert Enum.any?(tasks4, &(&1.task_name == "task2"))
  end
end
