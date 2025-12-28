defmodule SecondBrain.Auth.Guardian do
  use Guardian, otp_app: :second_brain

  alias SecondBrain.Db.Account
  alias SecondBrain.Repo

  @spec subject_for_token(map(), map()) :: {:ok, String.t()} | {:error, atom()}
  def subject_for_token(%{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :no_id_for_token}
  end

  @spec resource_from_claims(map()) :: {:ok, Account.t()} | {:error, atom()}
  def resource_from_claims(%{"sub" => id}) do
    account = Repo.get!(Account, id)
    {:ok, account}
  rescue
    Ecto.NoResultsError -> {:error, :account_not_found}
  end

  def resource_from_claims(_) do
    {:error, :no_subject_for_resource}
  end
end
