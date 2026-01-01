defmodule SecondBrainWeb.Api.V1.BrainController do
  use SecondBrainWeb, :controller

  alias SecondBrain.Brain

  action_fallback SecondBrainWeb.FallbackController

  def state(conn, _) do
    account = Guardian.Plug.current_resource(conn)

    case Brain.get_brain_state(account.id) do
      {:ok, brain_state} ->
        conn
        |> put_status(:ok)
        |> json(%{brain_state: brain_state})

      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(error)})
    end
  end

  def start_session(conn, %{"task_name" => task_name, "end_ts" => end_ts_str}) do
    account = Guardian.Plug.current_resource(conn)

    with {:ok, brain_state} <- Brain.get_brain_state(account.id),
         {:ok, end_ts, _} <- DateTime.from_iso8601(end_ts_str),
         {:ok, _task} <- Brain.start_session(brain_state, task_name, end_ts),
         {:ok, new_brain_state} <- Brain.get_brain_state(account.id) do
      conn
      |> put_status(:created)
      |> json(%{new_brain_state: new_brain_state})
    else
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(error)})
    end
  end

  def end_session(conn, _) do
    account = Guardian.Plug.current_resource(conn)

    with {:ok, brain_state} <- Brain.get_brain_state(account.id),
         {:ok, _task} <- Brain.end_session(brain_state),
         {:ok, new_brain_state} <- Brain.get_brain_state(account.id) do
      conn
      |> put_status(:ok)
      |> json(%{new_brain_state: new_brain_state})
    else
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(error)})
    end
  end

  def update_notes(conn, %{"notes" => notes}) do
    account = Guardian.Plug.current_resource(conn)

    with {:ok, brain_state} <- Brain.get_brain_state(account.id),
         {:ok, new_brain_state} <- Brain.update_notes(brain_state, notes) do
      conn
      |> put_status(:ok)
      |> json(%{new_brain_state: new_brain_state})
    else
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(error)})
    end
  end
end
