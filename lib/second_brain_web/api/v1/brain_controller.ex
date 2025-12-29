defmodule SecondBrainWeb.Api.V1.BrainController do
  use SecondBrainWeb, :controller

  alias SecondBrain.Brain

  action_fallback SecondBrainWeb.FallbackController

  def start_session(conn, %{"task_name" => task_name, "end_ts" => end_ts_str}) do
    account = Guardian.Plug.current_resource(conn)

    with {:ok, brain_state} <- Brain.get_brain_state(account.id),
         {:ok, end_ts, _} <- DateTime.from_iso8601(end_ts_str),
         {:ok, task} <- Brain.start_session(brain_state, task_name, end_ts) do
      conn
      |> put_status(:created)
      |> json(%{task: task})
    else
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: error})
    end
  end

  def end_session(conn, _) do
    account = Guardian.Plug.current_resource(conn)

    with {:ok, brain_state} <- Brain.get_brain_state(account.id),
         {:ok, task} <- Brain.end_session(brain_state) do
      conn
      |> put_status(:ok)
      |> json(%{task: task})
    else
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: error})
    end
  end
end
