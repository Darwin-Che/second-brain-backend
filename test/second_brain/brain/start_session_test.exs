defmodule SecondBrain.Brain.StartSessionTest do
  @moduledoc false

  use SecondBrain.DataCase, async: true

  import SecondBrain.Factory

  alias SecondBrain.Brain
  alias SecondBrain.Db.BrainCache
  alias SecondBrain.Repo

  describe "start_session/3" do
    test "starts a session when brain is onboarding" do
      account = insert_account()

      insert_brain_cache_onboarding(account.id)
      {:ok, brain_state} = Brain.get_brain_state(account.id)

      task_name = "onboarding task"
      end_ts = SecondBrain.Helper.shift_cur_ts_am(60)

      {:ok, new_state} = Brain.start_session(brain_state, task_name, end_ts)
      assert new_state.brain_status == :busy
      assert new_state.last_session.task_name == task_name
      assert new_state.last_session.end_ts == end_ts

      verify_brain_cache_in_db(BrainCache.from_brain_state(new_state))
    end

    test "starts a session when brain is idle" do
      account = insert_account()

      insert_brain_cache_idle(account.id)
      {:ok, brain_state} = Brain.get_brain_state(account.id)

      task_name = "new task"
      end_ts = SecondBrain.Helper.shift_cur_ts_am(60)

      {:ok, new_state} = Brain.start_session(brain_state, task_name, end_ts)
      assert new_state.brain_status == :busy
      assert new_state.last_session.task_name == task_name
      assert new_state.last_session.end_ts == end_ts

      verify_brain_cache_in_db(BrainCache.from_brain_state(new_state))
    end

    test "returns error when brain is busy" do
      account = insert_account()

      insert_brain_cache_busy(account.id)
      {:ok, brain_state} = Brain.get_brain_state(account.id)

      task_name = "busy task"
      end_ts = SecondBrain.Helper.shift_cur_ts_am(60)

      assert {:error, "Brain is busy, stop the current session first"} =
               Brain.start_session(brain_state, task_name, end_ts)

      verify_brain_cache_in_db(BrainCache.from_brain_state(brain_state))
    end

    test "returns error for invalid session" do
      account = insert_account()

      insert_brain_cache_idle(account.id)
      {:ok, brain_state} = Brain.get_brain_state(account.id)

      task_name = "invalid task"
      # end_ts before start_ts triggers invalid session
      end_ts = SecondBrain.Helper.shift_cur_ts_am(-60)

      assert {:error, _} = Brain.start_session(brain_state, task_name, end_ts)

      verify_brain_cache_in_db(BrainCache.from_brain_state(brain_state))
    end
  end

  defp verify_brain_cache_in_db(brain_cache) do
    real_fields = [
      :account_id,
      :brain_status,
      :last_session_task_name,
      :last_session_start_ts,
      :last_session_end_ts,
      :last_session_notes
    ]

    object = Repo.get_by(BrainCache, account_id: brain_cache.account_id)

    assert Map.take(brain_cache, real_fields) == Map.take(object, real_fields)
  end
end
