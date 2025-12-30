defmodule SecondBrain.Struct.TaskSchedule do
  @moduledoc false

  import SecondBrain.Helper

  alias SecondBrain.Struct.TaskSchedule

  @derive {Jason.Encoder, only: [:start_at, :end_at, :hours_per_week]}
  defstruct [
    :start_at,
    :end_at,
    hours_per_week: 0.0
  ]

  @type t() :: %__MODULE__{
          start_at: DateTime.t(),
          end_at: DateTime.t() | nil,
          hours_per_week: float()
        }

  def from_json(task_schedule) do
    %TaskSchedule{
      start_at: parse_datetime(task_schedule["start_at"]),
      end_at: parse_datetime(task_schedule["end_at"]),
      hours_per_week: task_schedule["hours_per_week"]
    }
  end
end
