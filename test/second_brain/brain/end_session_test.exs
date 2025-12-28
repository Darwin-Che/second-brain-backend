defmodule SecondBrain.Brain.EndSessionTest do
  @moduledoc false

  use SecondBrain.DataCase, async: false

  import SecondBrain.Factory

  alias SecondBrain.Brain
  alias SecondBrain.BrainDiskS3.SessionHistory

  defp get_work_session_history_list(account_id) do
    account_id
    |> SessionHistory.get_work_session_history_stream()
    |> Enum.to_list()
  end

  test "returns error when brain is already idle" do
    account = insert_account()

    insert_brain_cache_idle(account.id)
    {:ok, brain_state} = Brain.get_brain_state(account.id)

    assert Brain.end_session(brain_state) == {:error, "Brain is already idle"}
  end

  test "returns error when brain is onboarding" do
    account = insert_account()

    insert_brain_cache_onboarding(account.id)
    {:ok, brain_state} = Brain.get_brain_state(account.id)

    assert Brain.end_session(brain_state) == {:error, "Brain is already idle (onboarding)"}
  end

  test "ends session when brain is busy and session is valid" do
    account = insert_account()

    insert_brain_cache_busy(account.id)
    {:ok, brain_state} = Brain.get_brain_state(account.id)

    assert {:ok, _} = Brain.end_session(brain_state)

    # The Database is updated
    {:ok, new_brain_state} = Brain.get_brain_state(account.id)
    assert new_brain_state.brain_status == :idle
    assert new_brain_state.last_session.end_ts != nil

    # S3 is written
    [latest_session] = get_work_session_history_list(account.id)
    assert latest_session != nil
    assert latest_session.end_ts == new_brain_state.last_session.end_ts
    assert latest_session.task_name == new_brain_state.last_session.task_name
  end
end
