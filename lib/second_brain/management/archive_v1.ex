defmodule SecondBrain.Management.ArchiveV1 do
  @moduledoc """
  Utility module to handle archiving of production data.
  """

  @derive {Jason.Encoder,
           only: [
             :version,
             :account_id,
             :brain_state,
             :session_history
           ]}
  defstruct version: 1,
            account_id: nil,
            brain_state: nil,
            session_history: nil
end
