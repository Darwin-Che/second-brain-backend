defmodule SecondBrain.BrainTest do
  use SecondBrain.DataCase, async: true

  import SecondBrain.Factory

  alias SecondBrain.Brain

  describe "get_brain_state/1" do
    test "returns error when brain not found" do
      assert Brain.get_brain_state(Ecto.UUID.generate()) == {:error, "Brain not found"}
    end

    test "returns brain state when found" do
      account = insert_account()

      insert_brain_cache_idle(account.id)

      {:ok, brain_state} = Brain.get_brain_state(account.id)

      assert brain_state.account_id == account.id
      assert brain_state.brain_status == :idle
      assert brain_state.last_session.task_name == "finished test task"
      assert brain_state.last_session.notes == "Already finished"
    end
  end
end
