defmodule SecondBrainWeb.Api.V1.TaskController do
  use SecondBrainWeb, :controller

  alias SecondBrain.Brain

  alias SecondBrain.BrainDiskS3.Tasks

  action_fallback SecondBrainWeb.FallbackController

  def index(conn, _params) do
    account = Guardian.Plug.current_resource(conn)

    {:ok, tasks} = Tasks.load_tasks_from_disk(account.id)

    render(conn, :index, tasks: tasks)
  end

  def add_task(conn, %{"task_name" => task_name, "hours_per_week" => hours_per_week}) do
    account = Guardian.Plug.current_resource(conn)

    case Tasks.add_task(account.id, task_name, hours_per_week) do
      :ok ->
        {:ok, tasks} = Tasks.load_tasks_from_disk(account.id)

        render(conn, :index, tasks: tasks)

      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: error})
    end
  end

  def edit_task(conn, %{"task_name" => task_name, "hours_per_week" => hours_per_week}) do
    account = Guardian.Plug.current_resource(conn)

    case Tasks.edit_task(account.id, task_name, hours_per_week) do
      :ok ->
        {:ok, tasks} = Tasks.load_tasks_from_disk(account.id)

        render(conn, :index, tasks: tasks)

      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: error})
    end
  end

  def recommend(conn, _params) do
    account = Guardian.Plug.current_resource(conn)

    case Brain.recommend_task(account.id) do
      {:ok, recommend_tasks} ->
        render(conn, :recommend_tasks, recommend_tasks: recommend_tasks)

      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: error})
    end
  end
end
