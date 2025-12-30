defmodule SecondBrain.Struct.TaskSchedule do
  @moduledoc false

  alias SecondBrain.Struct.TaskSchedule

  @derive {Jason.Encoder, only: [:start_at, :end_at, :hours_per_week]}
  defstruct [
    :start_at,
    :end_at,
    hours_per_week: 0.0
  ]

  @type t() :: %__MODULE__{
          start_at: DateTime.t(),
          end_at: DateTime.t(),
          hours_per_week: float()
        }

  def from_json(task_schedule) do
    %TaskSchedule{
      start_at: task_schedule["start_at"],
      end_at: task_schedule["end_at"],
      hours_per_week: task_schedule["hours_per_week"]
    }
  end
end
