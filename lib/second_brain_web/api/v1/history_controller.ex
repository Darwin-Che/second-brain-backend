defmodule SecondBrainWeb.Api.V1.HistoryController do
  use SecondBrainWeb, :controller

  alias SecondBrain.BrainDiskS3.SessionHistory

  require Logger

  def index(conn, params) do
    account = Guardian.Plug.current_resource(conn)

    page_size = Map.get(params, "page_size", "20") |> String.to_integer()

    session_history = SessionHistory.get_work_session_history_by_n(account.id, page_size)
    Logger.debug("Fetched session history: #{inspect(session_history)}")

    conn
    |> put_status(:ok)
    |> json(%{session_history: session_history})
  end
end
