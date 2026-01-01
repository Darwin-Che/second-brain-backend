defmodule SecondBrain.BrainDiskS3.SessionHistory.UpdateWorkSessionTest do
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

  describe "update_work_session/3" do
    setup do
      account = insert_account()
      session = build_work_session_finished(account.id)
      :ok = SessionHistory.prepend_work_session(account.id, session)
      [account: account, session: session]
    end

    test "updates notes for a session and persists to S3", %{account: account, session: session} do
      {:ok, updated} =
        SessionHistory.update_work_session(account.id, session.id, %{notes: "new notes"})

      assert updated.notes == "new notes"
      # Verify persisted S3 state
      [persisted] = get_work_session_history_list(account.id)
      assert persisted.id == session.id
      assert persisted.notes == "new notes"
    end

    test "updates duration for a session and persists to S3", %{
      account: account,
      session: session
    } do
      new_duration = 120

      {:ok, updated} =
        SessionHistory.update_work_session(account.id, session.id, %{duration: new_duration})

      assert updated.end_ts != session.end_ts
      # Verify persisted S3 state
      [persisted] = get_work_session_history_list(account.id)
      assert persisted.id == session.id
      assert persisted.end_ts == updated.end_ts
      assert persisted.end_ts == DateTime.shift(updated.start_ts, minute: new_duration)
    end

    test "returns error for non-existent id", %{account: account} do
      assert {:error, :not_found} =
               SessionHistory.update_work_session(account.id, "nonexistent-id", %{notes: "x"})
    end

    test "returns error for invalid changes", %{account: account, session: session} do
      assert {:error, _} =
               SessionHistory.update_work_session(account.id, session.id, %{start_ts: nil})
    end
  end
end
