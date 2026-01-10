defmodule SecondBrain.Management.ProdDataDumper do
  @moduledoc """
  Utility module to dump production data for use as test state.
  """

  # credo:disable-for-this-file Credo.Check.Warning.IoInspect
  # credo:disable-for-this-file Credo.Check.Warning.IoPuts

  alias SecondBrain.Brain
  alias SecondBrain.BrainDiskS3.SessionHistory
  alias SecondBrain.BrainDiskS3.Tasks

  alias SecondBrain.Management.ArchiveV1

  @doc """
  Dumps data of an account (other than the account info).
  The output is written to a single large file for use in unit tests.
  """
  def dump_all_data(account_id, output_path \\ "prod_tasks_dump.json") do
    IO.puts("Fetching Brain State of #{account_id}")
    {:ok, brain_state} = Brain.get_brain_state(account_id)
    IO.inspect(brain_state)

    IO.puts("Fetching Tasks of #{account_id}")
    {:ok, tasks} = Tasks.load_tasks_from_disk(account_id)
    IO.inspect(tasks)

    IO.puts("Fetching Session History of #{account_id}")

    file_entries = SessionHistory.get_all_session_history_files(account_id)

    files_content =
      Map.new(
        file_entries,
        fn file_entry ->
          {:ok, content} =
            SessionHistory.load_brain_disk_session_history(account_id, file_entry.file_name)

          {file_entry.file_name, content}
        end
      )

    session_history = %{
      file_entries: file_entries,
      files_content: files_content
    }

    Enum.each(file_entries, fn file_entry ->
      IO.puts("""
      Session History File #{file_entry.file_name},
      length = #{length(files_content[file_entry.file_name] || [])}
      """)
    end)

    archive = %ArchiveV1{
      account_id: account_id,
      brain_state: brain_state,
      tasks: tasks,
      session_history: session_history
    }

    File.write!(output_path, Jason.encode!(archive, pretty: true))
    IO.puts("Dumped ArchiveV1 to #{output_path}")
    :ok
  end
end
