defmodule SecondBrainWeb.Api.V1.AccountController do
  use SecondBrainWeb, :controller

  alias SecondBrain.Auth.Guardian, as: AuthGuardian

  action_fallback SecondBrainWeb.FallbackController

  def show(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})

      account ->
        render(conn, :show, account: account)
    end
  end

  def logout(conn, _params) do
    conn
    |> AuthGuardian.Plug.sign_out()
    |> put_status(:ok)
    |> json(%{message: "Logged out"})
  end
end
