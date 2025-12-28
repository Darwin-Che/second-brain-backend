defmodule SecondBrain.TestSupport.S3Cleanup do
  @moduledoc false

  require Logger

  def cleanup_bucket! do
    IO.puts("Cleaning up S3 bucket...")

    bucket_name = Application.get_env(:second_brain, SecondBrain.BrainDiskS3)[:bucket_name]

    delete_all_objects(bucket_name)
  end

  # ---------- Internals ----------

  defp delete_all_objects(bucket) do
    case ExAws.S3.list_objects_v2(bucket) |> ExAws.request() do
      {:ok, %{body: body}} ->
        for %{key: key} <- body.contents || [] do
          ExAws.S3.delete_object(bucket, key)
          |> ExAws.request!()
        end

      {:error, {:http_error, 404, _}} ->
        :ok

      {:error, reason} ->
        raise "Failed to list objects in #{bucket}: #{inspect(reason)}"
    end
  end
end
