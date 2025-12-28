defmodule SecondBrainWeb.AuthController do
  use SecondBrainWeb, :controller

  plug Ueberauth

  alias SecondBrain.Db.Account

  alias SecondBrainWeb.Frontend

  alias Ueberauth.Auth

  require Logger

  def request(conn, _params) do
    # Ueberauth handles redirect to Google
    conn
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    account_info = to_account(auth)

    # Find or create user in DB
    {:ok, account} = Account.find_or_create_account(account_info)

    # Issue your own session/JWT
    {:ok, token, _claims} = SecondBrain.Auth.Guardian.encode_and_sign(account)

    # Redirect or respond as needed
    redirect(conn, external: "#{Frontend.url()}/?jwt=#{token}")
  end

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    Logger.error("Ueberauth Failure: #{inspect(fails)}")

    conn
    |> put_status(401)
    |> json(%{error: "Authentication failed"})
  end

  defp to_account(%Auth{
         provider: :google,
         uid: google_sub,
         info: %{
           email: email,
           name: name
         }
       }) do
    %{
      name: name,
      email: email,
      google_sub: google_sub
    }
  end
end
