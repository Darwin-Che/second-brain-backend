defmodule SecondBrain.BrainDiskS3.SessionHistoryTest do
  @moduledoc false

  use SecondBrain.DataCase, async: false

  import SecondBrain.Factory

  alias SecondBrain.BrainDiskS3.SessionHistory

  alias SecondBrain.TestSupport.S3Cleanup

  setup do
    # Clean up S3 before each test
    S3Cleanup.cleanup_bucket!()
    :ok
  end

  defp get_work_session_history_list(account_id) do
    account_id
    |> SessionHistory.get_work_session_history_stream()
    |> Enum.to_list()
  end

  describe "prepend_work_session/2 && get_work_session_history_stream/1" do
    test "when there's no existing file for this user" do
      account = insert_account()

      session = build_work_session_finished(account.id)

      # Before the prepend, no entry
      assert [] == SessionHistory.get_all_session_history_files(account.id)
      assert [] == get_work_session_history_list(account.id)

      assert :ok = SessionHistory.prepend_work_session(account.id, session)

      # There should be an entry created in the database
      assert [%{} = file_entry] = SessionHistory.get_all_session_history_files(account.id)
      assert [session] == get_work_session_history_list(account.id)
      assert file_entry.seq_1 == 1
      assert file_entry.file_entry_cnt == 1
    end

    test "exists file, limit not reached" do
      account = insert_account()
      session1 = build_work_session_finished(account.id)

      assert :ok = SessionHistory.prepend_work_session(account.id, session1)

      # There should be two entry in the database
      assert [%{} = file_entry] = SessionHistory.get_all_session_history_files(account.id)
      assert [session1] == get_work_session_history_list(account.id)
      assert file_entry.seq_1 == 1
      assert file_entry.file_entry_cnt == 1

      # Add another session
      session2 = build_work_session_finished(account.id)
      assert :ok = SessionHistory.prepend_work_session(account.id, session2)

      assert [%{} = file_entry1] = SessionHistory.get_all_session_history_files(account.id)
      assert [session2, session1] == get_work_session_history_list(account.id)
      assert file_entry1.seq_1 == 1
      assert file_entry1.file_entry_cnt == 2
    end

    test "exists file, limit = 3 reached, break into new file" do
      account = insert_account()
      session1 = build_work_session_finished(account.id)
      session2 = build_work_session_finished(account.id)

      assert :ok = SessionHistory.prepend_work_session(account.id, session1)
      assert :ok = SessionHistory.prepend_work_session(account.id, session2)

      # There should be two entry in the database
      assert [%{} = file_entry] = SessionHistory.get_all_session_history_files(account.id)
      assert [session2, session1] == get_work_session_history_list(account.id)
      assert file_entry.seq_1 == 1
      assert file_entry.file_entry_cnt == 2

      # Add another session
      session3 = build_work_session_finished(account.id)
      assert :ok = SessionHistory.prepend_work_session(account.id, session3)

      assert [%{} = file_entry_2, %{} = file_entry_1] =
               SessionHistory.get_all_session_history_files(account.id)

      assert [session3, session2, session1] == get_work_session_history_list(account.id)
      assert file_entry_1.file_name == file_entry.file_name
      assert file_entry_1.seq_1 == 1
      assert file_entry_2.seq_1 == 2
      assert file_entry_1.file_entry_cnt == 2
      assert file_entry_2.file_entry_cnt == 1
    end
  end
end
