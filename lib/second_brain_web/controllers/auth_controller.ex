defmodule SecondBrainWeb.AuthController do
  use SecondBrainWeb, :controller

  plug Ueberauth

  alias SecondBrain.Auth.Guardian, as: AuthGuardian

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

    {:ok, account} = Account.find_or_create_account(account_info)

    # Use Guardian.Plug.sign_in to store JWT in session
    conn
    |> Plug.Conn.fetch_session()
    |> AuthGuardian.Plug.sign_in(account)
    |> redirect(external: "#{Frontend.url()}/")
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
