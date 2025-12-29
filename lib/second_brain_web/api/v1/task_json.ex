defmodule SecondBrainWeb.Api.V1.TaskJSON do
  @moduledoc false

  alias SecondBrain.Struct.Task
  alias SecondBrain.Struct.TaskSchedule

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
end
