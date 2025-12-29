defmodule SecondBrain.Auth.Guardian do
  @moduledoc false

  use Guardian, otp_app: :second_brain

  alias SecondBrain.Db.Account
  alias SecondBrain.Repo

  require Logger

  @spec subject_for_token(map(), map()) :: {:ok, String.t()} | {:error, atom()}
  def subject_for_token(%{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :no_id_for_token}
  end

  @spec resource_from_claims(map()) :: {:ok, Account.t()} | {:error, atom()}
  def resource_from_claims(%{"sub" => id}) do
    case Repo.get(Account, id) do
      nil ->
        Logger.warning("Account not found for id: #{inspect(id)}")
        {:error, :account_not_found}

      account ->
        Logger.debug("Account loaded: #{inspect(account)}")
        {:ok, account}
    end
  end

  def resource_from_claims(_) do
    Logger.warning("No subject found for resource")
    {:error, :no_subject_for_resource}
  end
end
