defmodule SecondBrain.Management.ProdDataDumper do
  @moduledoc """
  Utility module to dump production data for use as test state.
  """

  # credo:disable-for-this-file Credo.Check.Warning.IoInspect
  # credo:disable-for-this-file Credo.Check.Warning.IoPuts

  alias SecondBrain.Brain
  alias SecondBrain.BrainDiskS3.SessionHistory

  alias SecondBrain.Management.ArchiveV1

  @doc """
  Dumps data of an account (other than the account info).
  The output is written to a single large file for use in unit tests.
  """
  def dump_all_data(account_id, output_path \\ "prod_tasks_dump.json") do
    IO.puts("Fetching Brain State of #{account_id}")
    {:ok, brain_state} = Brain.get_brain_state(account_id)
    IO.inspect(brain_state)

    IO.puts("Fetching Session History of #{account_id}")

    session_history =
      account_id
      |> SessionHistory.get_work_session_history_stream()
      |> Enum.to_list()

    IO.inspect(session_history)
    IO.puts("Length of Session History: #{length(session_history)}")

    archive = %ArchiveV1{
      account_id: account_id,
      brain_state: brain_state,
      session_history: session_history
    }

    File.write!(output_path, Jason.encode!(archive, pretty: true))
    IO.puts("Dumped ArchiveV1 to #{output_path}")
    :ok
  end
end
