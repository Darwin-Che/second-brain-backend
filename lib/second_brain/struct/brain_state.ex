defmodule SecondBrain.Struct.BrainState do
  @moduledoc false

  import SecondBrain.Helper

  alias SecondBrain.Db.Account
  alias SecondBrain.Db.BrainCache
  alias SecondBrain.Struct.BrainState
  alias SecondBrain.Struct.WorkSession

  alias SecondBrain.Db.BrainCache

  @type brain_status() :: :idle | :busy | :onboarding

  defstruct [
    :account_id,
    :brain_status,
    :last_session
  ]

  @type t() :: %__MODULE__{
          account_id: Account.id_t(),
          brain_status: brain_status(),
          last_session: WorkSession.t() | nil
        }

  @doc false
  @spec new_onboarding(Account.id_t()) :: t()
  def new_onboarding(account_id) do
    %BrainState{
      account_id: account_id,
      brain_status: :onboarding,
      last_session: nil
    }
  end

  @doc false
  @spec cache_brain(BrainState.t()) :: {:ok, BrainState.t()} | {:error, String.t()}
  def cache_brain(%BrainState{} = brain_state) do
    brain_cache = BrainCache.from_brain_state(brain_state)

    case BrainCache.update(brain_cache) do
      {:ok, new_brain_cache} -> {:ok, BrainState.from_brain_cache(new_brain_cache)}
      {:error, error} -> {:error, error}
    end
  end

  @doc false
  @spec from_brain_cache(BrainCache.t()) :: t()
  def from_brain_cache(%BrainCache{} = brain_cache) do
    %BrainState{
      account_id: brain_cache.account_id,
      brain_status: BrainCache.brain_status_decode(brain_cache.brain_status),
      last_session: %WorkSession{
        account_id: brain_cache.account_id,
        task_name: brain_cache.last_session_task_name,
        start_ts: brain_cache.last_session_start_ts,
        end_ts: brain_cache.last_session_end_ts,
        notes: brain_cache.last_session_notes
      }
    }
  end

  @doc false
  def start_session(brain_state, session) do
    cond do
      brain_state.brain_status == :busy ->
        {:error, "Brain is busy, stop the current session first"}

      WorkSession.valid?(session) |> elem(0) != :ok ->
        {:error, "Invalid session"}

      brain_state.account_id != session.account_id ->
        {:error, "Session does not belong to the current account"}

      true ->
        {:ok,
         %{
           brain_state
           | brain_status: :busy,
             last_session: session
         }}
    end
  end

  @doc false
  def end_session(brain_state) do
    if brain_state.brain_status == :idle do
      {:error, "Brain is already idle"}
    else
      case WorkSession.valid?(%{brain_state.last_session | end_ts: cur_ts_am()}) do
        {:ok, new_work_session} ->
          {:ok,
           %{
             brain_state
             | brain_status: :idle,
               last_session: new_work_session
           }}

        {:error, error} ->
          {:error, error}
      end
    end
  end
end
