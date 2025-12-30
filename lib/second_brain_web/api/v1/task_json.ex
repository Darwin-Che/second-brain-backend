defmodule SecondBrainWeb.Api.V1.TaskJSON do
  @moduledoc false

  alias SecondBrain.Struct.RecommendTask
  alias SecondBrain.Struct.Task
  alias SecondBrain.Struct.TaskSchedule
  alias SecondBrain.Struct.WorkSession

  def index(%{tasks: tasks}) do
    Enum.map(tasks, &task/1)
  end

  def task(%Task{task_name: task_name, schedules: schedules}) do
    case schedules do
      [%TaskSchedule{hours_per_week: hours_per_week} | _] ->
        %{task_name: task_name, hours_per_week: hours_per_week}

      _ ->
        %{task_name: task_name, hours_per_week: 0}
    end
  end

  def recommend_tasks(%{recommend_tasks: recommend_tasks}) do
    Enum.map(recommend_tasks, &recommend_task/1)
  end

  def recommend_task(%RecommendTask{
        task_name: task_name,
        desired_effort: desired_effort,
        current_percent_effort: current_percent_effort,
        last_session: last_session
      }) do
    %{
      task_name: task_name,
      desired_effort: desired_effort,
      current_percent_effort: current_percent_effort,
      last_session: last_session && work_session(last_session)
    }
  end

  def work_session(nil), do: nil

  def work_session(%WorkSession{
        task_name: task_name,
        start_ts: start_ts,
        end_ts: end_ts,
        notes: notes
      }) do
    %{task_name: task_name, start_ts: start_ts, end_ts: end_ts, notes: notes}
  end
end
