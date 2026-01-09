defmodule SecondBrain.Management.ProdDataDumperTest do
  use ExUnit.Case, async: true

  alias SecondBrain.Management.ProdDataDumper

  setup do
    :meck.new(SecondBrain.Brain, [:passthrough])
    :meck.new(SecondBrain.BrainDiskS3.SessionHistory, [:passthrough])
    :meck.new(Jason, [:passthrough])
    :meck.new(File, [:passthrough])

    on_exit(fn ->
      :meck.unload()
    end)

    :ok
  end

  @tag :tmp_dir
  test "dump_all_data/2 writes archive to file and prints info", %{tmp_dir: tmp_dir} do
    account_id = "test_account"
    output_path = Path.join(tmp_dir, "test_dump.json")

    brain_state = %{foo: "bar"}
    session_history = [%{session: 1}, %{session: 2}]

    archive = %SecondBrain.Management.ArchiveV1{
      account_id: account_id,
      brain_state: brain_state,
      session_history: session_history
    }

    :meck.expect(SecondBrain.Brain, :get_brain_state, fn ^account_id -> {:ok, brain_state} end)

    :meck.expect(
      SecondBrain.BrainDiskS3.SessionHistory,
      :get_work_session_history_stream,
      fn ^account_id -> session_history end
    )

    :meck.expect(Jason, :encode!, fn ^archive, pretty: true -> "ARCHIVE_JSON" end)
    :meck.expect(File, :write!, fn ^output_path, "ARCHIVE_JSON" -> :ok end)

    assert :ok = ProdDataDumper.dump_all_data(account_id, output_path)
  end
end
