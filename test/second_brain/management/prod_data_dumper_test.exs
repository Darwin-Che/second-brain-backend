defmodule SecondBrain.Management.ProdDataDumperTest do
  use SecondBrain.DataCase, async: true

  import SecondBrain.Factory

  import SecondBrain.Helper

  alias SecondBrain.Management.Delete
  alias SecondBrain.Management.ProdDataDumper

  alias SecondBrain.BrainDiskS3.SessionHistory
  alias SecondBrain.BrainDiskS3.Tasks

  alias SecondBrain.Brain

  alias SecondBrain.Struct.BrainState

  alias SecondBrain.TestSupport.ArchiveRestore

  setup do
    account = insert_account()

    task1 = build_task(task_name: "Task 1")
    task2 = build_task(task_name: "Task 2")

    :ok = Tasks.put_tasks_to_disk(account.id, [task1, task2])

    session1 =
      build_work_session_finished(
        account.id,
        task_name: "Task 1",
        start_ts: shift_cur_ts_am(-(60 * 3 + 60)),
        end_ts: shift_cur_ts_am(-(60 * 3 + 30))
      )

    SessionHistory.prepend_work_session(account.id, session1)

    session2 =
      build_work_session_finished(
        account.id,
        task_name: "Task 2",
        start_ts: shift_cur_ts_am(-(60 * 2 + 60)),
        end_ts: shift_cur_ts_am(-(60 * 2 + 30))
      )

    SessionHistory.prepend_work_session(account.id, session2)

    session3 =
      build_work_session_finished(
        account.id,
        task_name: "Task 1",
        start_ts: shift_cur_ts_am(-(60 + 60)),
        end_ts: shift_cur_ts_am(-(60 + 30))
      )

    SessionHistory.prepend_work_session(account.id, session3)

    brain_cache =
      insert_brain_cache_busy(
        account.id,
        last_session:
          build_work_session_wip(
            account.id,
            task_name: "session4",
            start_ts: shift_cur_ts_am(-30),
            end_ts: shift_cur_ts_am(30)
          )
      )

    {:ok,
     account: account,
     session1: session1,
     session2: session2,
     session3: session3,
     task1: task1,
     task2: task2,
     brain_cache: brain_cache,
     brain_state: BrainState.from_brain_cache(brain_cache)}
  end

  test "test dump and restore", %{
    account: account,
    session1: session1,
    session2: session2,
    session3: session3,
    task1: task1,
    task2: task2,
    brain_state: brain_state
  } do
    output_path = Path.join("test/fixture/archives/", "dump_test_dump.json")

    ProdDataDumper.dump_all_data(account.id, output_path)

    # Clear the existing data
    :ok = Delete.delete_account(account.id)

    # assert account data is cleared
    assert {:error, "Account not found"} = Brain.get_brain_state(account.id)
    assert {:ok, []} = Tasks.load_tasks_from_disk(account.id)
    assert [] = SessionHistory.get_all_work_session_history(account.id)

    # Restore the archive
    {account_id, _} = ArchiveRestore.restore_file("dump_test_dump.json")
    assert account_id == account.id

    # assert the restored data matches the original data
    assert {:ok, ^brain_state} = Brain.get_brain_state(account.id)
    assert {:ok, [^task1, ^task2]} = Tasks.load_tasks_from_disk(account.id)

    assert [^session3, ^session2, ^session1] =
             SessionHistory.get_all_work_session_history(account.id)
  end
end
