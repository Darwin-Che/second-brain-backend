defmodule SecondBrain.Struct.Task do
  @moduledoc false

  alias SecondBrain.Struct.TaskSchedule

  @derive {Jason.Encoder, only: [:task_name, :schedules]}
  defstruct [
    :task_name,
    :schedules
  ]

  @type t() :: %__MODULE__{
          task_name: String.t(),
          schedules: [TaskSchedule.t()]
        }

  def from_json(task) do
    %__MODULE__{
      task_name: task["task_name"],
      schedules:
        Enum.map(
          task["schedules"],
          &TaskSchedule.from_json/1
        )
    }
  end
end
