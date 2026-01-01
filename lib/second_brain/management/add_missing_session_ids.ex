defmodule SecondBrain.Management.AddMissingSessionIds do
  @moduledoc """
  Add unique IDs to all existing work sessions in session history files.
  """

  alias SecondBrain.Repo

  alias SecondBrain.Db.BrainDiskS3, as: BrainDiskS3Db

  alias SecondBrain.BrainDiskS3.SessionHistory

  def run(_args) do
    IO.puts("Migrating session history files to add unique IDs...")

    Repo.all(BrainDiskS3Db)
    |> Enum.each(&maybe_update_file/1)

    IO.puts("Migration complete.")
  end

  defp maybe_update_file(file_entry) do
    account_id = file_entry.account_id
    file_name = file_entry.file_name

    case SessionHistory.load_brain_disk_session_history(account_id, file_name) do
      {:ok, sessions} ->
        updated_sessions = Enum.map(sessions, &maybe_add_id/1)

        if updated_sessions != sessions do
          IO.puts("Updating file #{file_name} for account #{account_id}")

          :ok =
            SessionHistory.put_brain_disk_session_history(account_id, file_name, updated_sessions)
        end

      {:error, reason} ->
        IO.puts("Failed to load #{file_name} for account #{account_id}: #{inspect(reason)}")
    end
  end

  defp maybe_add_id(session) do
    if Map.get(session, :id) do
      session
    else
      %{session | id: "#{UUIDv7.cast!(UUIDv7.bingenerate())}"}
    end
  end
end
