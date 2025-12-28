defmodule SecondBrainWeb.Api.V1.TaskController do
  use SecondBrainWeb, :controller

  # alias SecondBrain.Brain

  # def add_task(conn, %{"task_name" => task_name, "hours_per_week" => hours_per_week}) do
  #   account_id = "account_id"

  #   with {:ok, brain_state} <- Brain.get_brain_state(account_id),
  #        {:ok, new_brain_state} <- Brain.add_task(brain_state, task_name, hours_per_week) do
  #     conn
  #     |> put_status(:ok)
  #     |> json(%{status: "ok", brain_state: new_brain_state})
  #   end
  # end
end
