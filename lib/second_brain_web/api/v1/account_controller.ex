defmodule SecondBrainWeb.Api.V1.AccountController do
  use SecondBrainWeb, :controller

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
end
