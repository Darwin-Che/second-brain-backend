defmodule SecondBrain.Struct.RecommendTask do
  @moduledoc false

  import SecondBrain.Helper

  alias SecondBrain.Struct.Task
  alias SecondBrain.Struct.TaskSchedule
  alias SecondBrain.Struct.WorkSession

  require Logger

  defstruct [
    :task_name,
    :desired_effort,
    :current_percent_effort,
    :last_session
  ]

  @type t() :: %__MODULE__{
          task_name: String.t(),
          desired_effort: float(),
          current_percent_effort: float(),
          last_session: WorkSession.t()
        }

  @type percent_effort_by_task_by_week_t() :: %{
          non_neg_integer() => %{
            String.t() => float()
          }
        }

  @type combined_percent_effort_by_task_t() :: %{
          String.t() => float()
        }

  @minutes_in_a_week 7 * 24 * 60

  @doc false
  @spec recommend_by_history([Task.t()], [WorkSession.t()], DateTime.t(), keyword()) ::
          {:ok, [__MODULE__.t()]} | {:error, String.t()}
  def recommend_by_history(available_tasks, session_history, cur_ts, opts \\ []) do
    limit_n = Keyword.get(opts, :limit_n, 5)

    desired_effort_by_task = get_desired_effort_by_task(available_tasks)
    Logger.debug("Desired effort by task: #{inspect(desired_effort_by_task)}")

    last_session_by_task = get_last_session_by_task(session_history)

    week_sessions = WorkSession.split_by_week(session_history, cur_ts)
    Logger.debug("Week sessions: #{inspect(week_sessions)}")

    percent_effort_by_task_by_week =
      percent_effort_by_task_by_week(available_tasks, week_sessions)

    Logger.debug("Percent effort by task by week: #{inspect(percent_effort_by_task_by_week)}")

    # Combine percent effort by task by week with available tasks
    combined_percent_effort_by_task =
      combined_percent_effort_by_task(percent_effort_by_task_by_week)

    Logger.debug("Combined percent effort by task: #{inspect(combined_percent_effort_by_task)}")

    recommendations =
      for %Task{task_name: task_name} <- available_tasks do
        %__MODULE__{
          task_name: task_name,
          desired_effort: Map.get(desired_effort_by_task, task_name, 0.0),
          current_percent_effort: Map.get(combined_percent_effort_by_task, task_name, 0.0),
          last_session: Map.get(last_session_by_task, task_name)
        }
      end

    Logger.debug("Recommendations: #{inspect(recommendations)}")

    selected_recommendations =
      recommendations
      |> Enum.filter(fn %{desired_effort: desired_effort} -> desired_effort > 0 end)
      |> Enum.sort_by(&{&1.current_percent_effort, -&1.desired_effort})
      |> Enum.take(limit_n)

    Logger.debug("Selected recommendations: #{inspect(selected_recommendations)}")

    {:ok, selected_recommendations}
  end

  @doc false
  @spec combined_percent_effort_by_task(percent_effort_by_task_by_week_t()) ::
          combined_percent_effort_by_task_t()
  def combined_percent_effort_by_task(percent_effort_by_task_by_week) do
    {sum_scale, combined_percent_effort_by_task} =
      Enum.reduce(percent_effort_by_task_by_week, {0, %{}}, fn {week_number,
                                                                percent_effort_by_task},
                                                               {sum_scale, result} ->
        scaling_factor = 1.0 / Float.pow(2.0, week_number)

        new_result =
          Enum.reduce(percent_effort_by_task, result, fn {task_name, percent_effort}, result ->
            scaled_percent_effort = percent_effort * scaling_factor
            Map.update(result, task_name, scaled_percent_effort, &(&1 + scaled_percent_effort))
          end)

        {sum_scale + scaling_factor, new_result}
      end)

    # Rescale the added percentage
    Map.new(combined_percent_effort_by_task, fn {task_name, percent_effort} ->
      {task_name, Float.round(percent_effort / sum_scale, 1)}
    end)
  end

  @doc false
  @spec percent_effort_by_task_by_week([Task.t()], map()) ::
          percent_effort_by_task_by_week_t()
  def percent_effort_by_task_by_week(available_tasks, week_sessions) do
    Map.new(week_sessions, fn {{week_number, week_start_end}, sessions} ->
      # Per Week Calculation
      real_effort_by_task = sum_effort_level_by_task(sessions, week_start_end)
      desired_effort_by_task = calculate_desired_effort_one_week(available_tasks, week_start_end)

      percent_effort_by_task =
        Map.new(available_tasks, fn task ->
          current_effort = Map.get(real_effort_by_task, task.task_name, 0)
          desired_effort = Map.get(desired_effort_by_task, task.task_name, 0)

          percent_effort = percent_effort(current_effort, desired_effort)

          {task.task_name, percent_effort}
        end)

      {week_number, percent_effort_by_task}
    end)
  end

  defp percent_effort(current_effort, desired_effort) do
    if desired_effort > 0 do
      current_effort * 100 / desired_effort
    else
      0
    end
  end

  @doc false
  @spec get_last_session_by_task([WorkSession.t()]) :: %{String.t() => WorkSession.t()}
  def get_last_session_by_task(session_history) do
    Enum.reduce(session_history, %{}, fn session, acc ->
      if Map.has_key?(acc, session.task_name) do
        acc
      else
        Map.put(acc, session.task_name, session)
      end
    end)
  end

  @doc false
  @spec get_desired_effort_by_task([Task.t()]) :: %{String.t() => float()}
  def get_desired_effort_by_task(available_tasks) do
    Map.new(available_tasks, fn task ->
      case task.schedules do
        [%TaskSchedule{hours_per_week: nil} | _] ->
          {task.task_name, 0.0}

        [%TaskSchedule{hours_per_week: hours_per_week} | _] when hours_per_week > 0 ->
          {task.task_name, hours_per_week}

        _ ->
          {task.task_name, 0.0}
      end
    end)
  end

  @doc false
  @spec calculate_desired_effort_one_week([Task.t()], {DateTime.t(), DateTime.t()}) :: %{
          String.t() => float()
        }
  def calculate_desired_effort_one_week(available_tasks, week_start_end) do
    Map.new(available_tasks, fn task ->
      {task.task_name, calculate_desired_effort_one_week_one_task(task, week_start_end)}
    end)
  end

  @doc false
  @spec calculate_desired_effort_one_week_one_task(Task.t(), {DateTime.t(), DateTime.t()}) ::
          float()
  def calculate_desired_effort_one_week_one_task(%Task{} = task, {week_start, week_end}) do
    Enum.reduce(task.schedules, 0, fn schedule, acc ->
      # Check if schedule overlap with this week
      if (schedule.end_at == nil || DateTime.compare(schedule.end_at, week_start) == :gt) and
           DateTime.compare(schedule.start_at, week_end) == :lt do
        # Only add the proportion the week that has this effort value
        period_start = datetime_max(schedule.start_at, week_start)
        period_end = datetime_min(schedule.end_at, week_end)

        proportion = DateTime.diff(period_end, period_start, :minute) / @minutes_in_a_week

        acc + schedule.hours_per_week * proportion
      else
        acc
      end
    end)
  end

  @doc false
  @spec sum_effort_level_by_task([WorkSession.t()], {DateTime.t(), DateTime.t()}) :: %{
          String.t() => float()
        }
  def sum_effort_level_by_task(session_history, _week_start_end) do
    Enum.reduce(session_history, %{}, fn session, acc ->
      interval_minutes = DateTime.diff(session.end_ts, session.start_ts, :minute)
      effort = Float.round(interval_minutes / 60.0, 1)

      Map.update(acc, session.task_name, effort, &(&1 + effort))
    end)
  end
end
