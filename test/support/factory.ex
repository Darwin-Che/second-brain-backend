defmodule SecondBrain.Factory do
  @moduledoc false

  import SecondBrain.Helper

  alias SecondBrain.Db.Account
  alias SecondBrain.Db.BrainCache
  alias SecondBrain.Repo

  ### Work Sessions

  def build_work_session_wip(account_id, attrs \\ %{}) do
    defaults = %{
      account_id: account_id,
      task_name: "wip test task",
      start_ts: shift_cur_ts_am(-30),
      end_ts: shift_cur_ts_am(30),
      notes: "Finish in 30 min"
    }

    struct(
      SecondBrain.Struct.WorkSession,
      Map.merge(defaults, attrs)
    )
  end

  def build_work_session_finished(account_id, attrs \\ %{}) do
    defaults = %{
      account_id: account_id,
      task_name: "finished test task",
      start_ts: shift_cur_ts_am(-120),
      end_ts: shift_cur_ts_am(-60),
      notes: "Already finished"
    }

    struct(
      SecondBrain.Struct.WorkSession,
      Map.merge(defaults, attrs)
    )
  end

  ### Brain State

  def build_brain_state_onboarding(account_id, attrs \\ %{}) do
    defaults = %{
      account_id: account_id,
      brain_status: :onboarding,
      last_session: nil
    }

    struct(
      SecondBrain.Struct.BrainState,
      Map.merge(defaults, attrs)
    )
  end

  def build_brain_state_idle(account_id, attrs \\ %{}) do
    defaults = %{
      account_id: account_id,
      brain_status: :idle,
      last_session: build_work_session_finished(account_id, attrs)
    }

    struct(
      SecondBrain.Struct.BrainState,
      Map.merge(defaults, attrs)
    )
  end

  def build_brain_state_busy(account_id, attrs \\ %{}) do
    defaults = %{
      account_id: account_id,
      brain_status: :busy,
      last_session: build_work_session_wip(account_id, attrs)
    }

    struct(
      SecondBrain.Struct.BrainState,
      Map.merge(defaults, attrs)
    )
  end

  ### Account

  def build_account(attrs \\ %{}) do
    defaults = %{
      name: "Test Account #{rand_str(4)}",
      email: "#{rand_str(6)}@test.com",
      google_sub: rand_str(10)
    }

    struct(
      SecondBrain.Db.Account,
      Map.merge(defaults, attrs)
    )
  end

  def insert_account(attrs \\ %{}) do
    account = build_account(attrs)

    account
    |> Account.changeset(%{})
    |> Repo.insert!()
  end

  ### Brain Cache

  def build_brain_cache_onboarding(account_id, attrs \\ %{}) do
    account_id
    |> build_brain_state_onboarding(attrs)
    |> BrainCache.from_brain_state()
  end

  def insert_brain_cache_onboarding(account_id, attrs \\ %{}) do
    account_id
    |> build_brain_cache_onboarding(attrs)
    |> BrainCache.changeset(%{})
    |> Repo.insert!()
  end

  def build_brain_cache_idle(account_id, attrs \\ %{}) do
    account_id
    |> build_brain_state_idle(attrs)
    |> BrainCache.from_brain_state()
  end

  def insert_brain_cache_idle(account_id, attrs \\ %{}) do
    account_id
    |> build_brain_cache_idle(attrs)
    |> BrainCache.changeset(%{})
    |> Repo.insert!()
  end

  def build_brain_cache_busy(account_id, attrs \\ %{}) do
    account_id
    |> build_brain_state_busy(attrs)
    |> BrainCache.from_brain_state()
  end

  def insert_brain_cache_busy(account_id, attrs \\ %{}) do
    account_id
    |> build_brain_cache_busy(attrs)
    |> BrainCache.changeset(%{})
    |> Repo.insert!()
  end
end
