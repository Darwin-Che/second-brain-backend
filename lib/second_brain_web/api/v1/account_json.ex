defmodule SecondBrainWeb.Api.V1.AccountJSON do
  @moduledoc false

  @doc """
  Renders a list of accounts.
  """
  def index(%{accounts: accounts}) do
    for(account <- accounts, do: data(account))
  end

  @doc """
  Renders a single account.
  """
  def show(%{account: account}) do
    data(account)
  end

  defp data(account) do
    %{
      id: account.id,
      email: account.email,
      name: account.name
    }
  end
end
