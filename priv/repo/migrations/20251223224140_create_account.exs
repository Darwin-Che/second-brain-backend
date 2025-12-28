defmodule SecondBrain.Repo.Migrations.CreateAccount do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")

    # Account Table

    create table(:account, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :name, :string
      add :email, :string
      add :google_sub, :string

      timestamps(type: :utc_datetime)
    end

    # Brain Cache Table

    create table(:brain_cache) do
      add :account_id, references(:account, type: :uuid, on_delete: :delete_all), null: false
      add :brain_status, :integer
      add :last_session_task_name, :string
      add :last_session_start_ts, :utc_datetime
      add :last_session_end_ts, :utc_datetime
      add :last_session_notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:brain_cache, [:account_id])

    # Brain Disk S3 Table

    create table(:brain_disk_s3) do
      add :account_id, references(:account, type: :uuid, on_delete: :delete_all), null: false
      add :file_name, :string
      add :file_entry_cnt, :integer
      add :seq_1, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
