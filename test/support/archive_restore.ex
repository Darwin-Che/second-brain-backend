defmodule SecondBrain.TestSupport.ArchiveRestore do
  @moduledoc false

  import SecondBrain.Factory

  alias SecondBrain.Repo

  alias SecondBrain.Struct.BrainState

  alias SecondBrain.Db.BrainDiskS3, as: BrainDiskS3Db

  alias SecondBrain.BrainDiskS3.SessionHistory
  alias SecondBrain.BrainDiskS3.Tasks

  alias SecondBrain.Management.ArchiveV1

  def restore_file(file_name) do
    # Read the file from test/fixture/archives/
    file_path = Path.join(["test/fixture/archives", file_name])

    archive =
      file_path
      |> File.read!()
      |> Jason.decode!()
      |> ArchiveV1.from_json()

    restore_archive(archive)
  end

  def restore_archive(archive) do
    account_id = archive.account_id
    insert_account(id: account_id)
    restore_brain_state(account_id, archive.brain_state)
    restore_tasks(account_id, archive.tasks)
    restore_session_history(account_id, archive.session_history)
    account_id
  end

  defp restore_brain_state(_account_id, brain_state) do
    {:ok, _} = BrainState.cache_brain(brain_state)
    :ok
  end

  defp restore_tasks(account_id, tasks) do
    :ok = Tasks.put_tasks_to_disk(account_id, tasks)
    :ok
  end

  defp restore_session_history(
         account_id,
         %{file_entries: file_entries, files_content: files_content}
       ) do
    Enum.each(file_entries, fn %BrainDiskS3Db{} = file_entry ->
      Repo.insert!(file_entry)
    end)

    Enum.each(files_content, fn {file_name, work_sessions} ->
      SessionHistory.update_brain_disk_session_history(account_id, file_name, work_sessions)
    end)

    :ok
  end
end
