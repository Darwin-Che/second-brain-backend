defmodule SecondBrain.Management.Delete do
  @moduledoc false

  import Ecto.Query, only: [from: 2]

  alias SecondBrain.Repo

  alias SecondBrain.Db.Account
  alias SecondBrain.Db.BrainCache

  alias SecondBrain.BrainDiskS3.DiskS3Manager

  @doc false
  @spec delete_account(Account.id_t()) :: :ok | {:error, any()}
  def delete_account(account_id) do
    account = Repo.get!(Account, account_id)

    result =
      Repo.transact(fn ->
        with {:ok, d1} <- Repo.delete(account),
             {d2, _} <-
               Repo.delete_all(from(b in BrainCache, where: b.account_id == ^account_id)) do
          {:ok, [d1, d2]}
        end
      end)

    case result do
      {:ok, _} ->
        DiskS3Manager.bucket_name()
        |> ExAws.S3.list_objects_v2(prefix: account_object_prefix(account.id))
        |> ExAws.stream!()
        |> Stream.chunk_every(64)
        |> Stream.each(fn list_of_objects ->
          ExAws.S3.delete_multiple_objects(
            DiskS3Manager.bucket_name(),
            Enum.map(list_of_objects, & &1.key)
          )
          |> ExAws.request!()
        end)
        |> Stream.run()

        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp account_object_prefix(account_id) do
    "brain_disk/#{account_id}"
  end
end
