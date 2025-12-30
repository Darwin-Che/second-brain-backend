defmodule SecondBrainWeb.AuthController do
  use SecondBrainWeb, :controller

  plug Ueberauth

  alias SecondBrain.Auth.Guardian, as: AuthGuardian

  alias SecondBrain.Db.Account

  alias Ueberauth.Auth

  require Logger

  def request(conn, _params) do
    # Ueberauth handles redirect to Google
    conn
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    account_info = to_account(auth)

    {:ok, account} = Account.find_or_create_account(account_info)

    {:ok, access_token, _claims} =
      AuthGuardian.encode_and_sign(account, %{}, token_type: "access", ttl: {15, :minute})

    {:ok, refresh_token, _claims} =
      AuthGuardian.encode_and_sign(account, %{}, token_type: "refresh", ttl: {30, :day})

    html = ~s|<!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Authentication complete</title>
      </head>
      <body>
        <script>
          try {
            // Post the access token to the opener window. The opener should validate origin.
            if (window.opener && !window.opener.closed) {
              // send to opener regardless of origin; opener must validate origin in its message handler
              window.opener.postMessage({ type: 'oauth', access_token: #{inspect(access_token)} }, "*");
            }
          } catch (e) {
            // ignore
          }
          // Close the popup
          window.close();
        </script>
      </body>
    </html>|

    conn
    |> put_resp_cookie("refresh_token", refresh_token,
      http_only: true,
      secure: true,
      same_site: "None",
      path: "/auth/refresh"
    )
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    Logger.error("Ueberauth Failure: #{inspect(fails)}")

    conn
    |> put_status(401)
    |> json(%{error: "Authentication failed"})
  end

  def refresh(conn, _params) do
    with {:ok, refresh_token} <- fetch_cookie(conn, "refresh_token"),
         {:ok, account, _claims} <-
           AuthGuardian.resource_from_token(refresh_token, %{"typ" => "refresh"}) do
      {:ok, access_token, _} =
        AuthGuardian.encode_and_sign(account, %{}, token_type: "access")

      json(conn, %{access_token: access_token})
    else
      _ -> send_resp(conn, 401, "")
    end
  end

  def logout(conn, _params) do
    conn
    |> delete_resp_cookie("refresh_token",
      http_only: true,
      secure: true,
      same_site: "None",
      path: "/auth/refresh"
    )
    |> put_status(:ok)
    |> json(%{message: "Logged out"})
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

  defp fetch_cookie(conn, key) do
    case Plug.Conn.get_cookies(conn)[key] do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end
end
