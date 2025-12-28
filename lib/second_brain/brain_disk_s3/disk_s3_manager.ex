defmodule SecondBrain.BrainDiskS3.DiskS3Manager do
  @moduledoc false

  require Logger

  @doc false
  def bootstrap do
    bucket_name = bucket_name()

    :ok = bootstrap_ensure_bucket(bucket_name)

    :ok
  end

  defp bootstrap_ensure_bucket(bucket_name) do
    env = Application.get_env(:second_brain, :env)
    region = Application.get_env(:ex_aws, :region, "us-east-1")

    case ExAws.S3.head_bucket(bucket_name) |> ExAws.request() do
      {:ok, _} ->
        :ok

      {:error, {:http_error, 404, _}} when env in [:dev, :test] ->
        Logger.info("S3 bucket #{bucket_name} not found, creating it")

        case ExAws.S3.put_bucket(bucket_name, region) |> ExAws.request() do
          {:ok, _} ->
            Logger.info("S3 bucket #{bucket_name} created")

          {:error, reason} ->
            raise "Failed to create bucket #{bucket_name}: #{inspect(reason)}"
        end

      {:error, {:http_error, 404, _}} ->
        raise """
        S3 bucket #{bucket_name} does not exist in #{env}.
        Buckets must be provisioned explicitly in production.
        """

      {:error, reason} ->
        raise "Failed to check bucket #{bucket_name}: #{inspect(reason)}"
    end
  end

  @doc false
  @spec bucket_name() :: String.t()
  def bucket_name do
    Application.get_env(:second_brain, SecondBrain.BrainDiskS3)[:bucket_name]
  end
end
