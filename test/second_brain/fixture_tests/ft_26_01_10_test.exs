defmodule SecondBrain.FixtureTests.Ft260110Test do
  @moduledoc false
  use SecondBrain.DataCase, async: true

  alias SecondBrain.TestSupport.ArchiveRestore

  alias SecondBrain.Management.Delete

  alias SecondBrain.Brain

  describe "Fixture Tests for 26_01_10" do
    setup do
      {account_id, cur_ts} = ArchiveRestore.restore_file("26_01_10.json")

      on_exit(fn ->
        Delete.delete_account_disk_s3(account_id)
      end)

      {:ok, account_id: account_id, cur_ts: cur_ts}
    end

    test "recommend test", %{
      account_id: account_id,
      cur_ts: cur_ts
    } do
      {:ok, recommendation} = Brain.recommend_task(account_id, cur_ts)

      assert recommendation == [
               %SecondBrain.Struct.RecommendTask{
                 task_name: "Misc",
                 desired_effort: 5,
                 current_percent_effort: 0.0,
                 last_session: nil
               },
               %SecondBrain.Struct.RecommendTask{
                 task_name: "French",
                 desired_effort: 14,
                 current_percent_effort: 27.7,
                 last_session: %SecondBrain.Struct.WorkSession{
                   id: "019ba8a9-c89c-7674-a7ce-9dd9701ebf18",
                   account_id: "73ea63cb-7e3b-49d7-907c-1acc76c375e7",
                   task_name: "French",
                   start_ts: ~U[2026-01-10 15:21:00Z],
                   end_ts: ~U[2026-01-10 16:08:00Z],
                   notes: ""
                 }
               },
               %SecondBrain.Struct.RecommendTask{
                 task_name: "Work",
                 desired_effort: 30,
                 current_percent_effort: 99.8,
                 last_session: %SecondBrain.Struct.WorkSession{
                   id: "019ba4f2-0bf4-7e3c-b100-1767a7cbdc78",
                   account_id: "73ea63cb-7e3b-49d7-907c-1acc76c375e7",
                   task_name: "Work",
                   start_ts: ~U[2026-01-09 15:16:00Z],
                   end_ts: ~U[2026-01-09 22:49:00Z],
                   notes: ""
                 }
               },
               %SecondBrain.Struct.RecommendTask{
                 task_name: "Personal Growth",
                 desired_effort: 7,
                 current_percent_effort: 101.6,
                 last_session: %SecondBrain.Struct.WorkSession{
                   id: "019ba91b-870c-7be9-a4a9-3fbafef38589",
                   account_id: "73ea63cb-7e3b-49d7-907c-1acc76c375e7",
                   task_name: "Personal Growth",
                   start_ts: ~U[2026-01-10 17:45:00Z],
                   end_ts: ~U[2026-01-10 18:12:00Z],
                   notes: ""
                 }
               },
               %SecondBrain.Struct.RecommendTask{
                 task_name: "Run",
                 desired_effort: 10,
                 current_percent_effort: 166.3,
                 last_session: %SecondBrain.Struct.WorkSession{
                   id: "019ba618-9d9e-7978-b109-2da971e7ce14",
                   account_id: "73ea63cb-7e3b-49d7-907c-1acc76c375e7",
                   task_name: "Run",
                   start_ts: ~U[2026-01-09 23:44:00Z],
                   end_ts: ~U[2026-01-10 04:10:00Z],
                   notes: ""
                 }
               }
             ]
    end
  end
end
