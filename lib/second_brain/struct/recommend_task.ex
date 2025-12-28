defmodule SecondBrain.Struct.RecommendTask do
  @moduledoc false

  alias SecondBrain.Struct.WorkSession

  defstruct [
    :task_name,
    :desired_effort,
    :current_effort,
    :last_session
  ]

  @type t() :: %__MODULE__{
          task_name: String.t(),
          desired_effort: non_neg_integer(),
          current_effort: non_neg_integer(),
          last_session: WorkSession.t()
        }

  @spec recommend_by_history([map()], [map()]) :: {:ok, [__MODULE__.t()]} | {:error, String.t()}
  def recommend_by_history(_available_tasks, _session_history) do
    # Implement your recommendation logic here
    # For now, let's just return the first available task
    {:ok, []}
  end
end
