defmodule SecondBrain.Helper do
  @moduledoc false

  def cur_ts_am do
    DateTime.shift(%{DateTime.utc_now() | second: 0, microsecond: {0, 0}}, minute: 1)
  end

  def shift_cur_ts_am(minutes) do
    DateTime.shift(cur_ts_am(), minute: minutes)
  end

  def aligned_to_minute?(datetime) do
    datetime.second == 0 && datetime.microsecond == {0, 0}
  end

  def rand_str(length) do
    chars = Enum.to_list(?A..?Z) ++ Enum.to_list(?0..?9)

    for _ <- 1..length, into: "", do: <<Enum.random(chars)>>
  end

  def datetime_max(nil, datetime2), do: datetime2
  def datetime_max(datetime1, nil), do: datetime1

  def datetime_max(datetime1, datetime2) do
    if DateTime.compare(datetime1, datetime2) == :gt do
      datetime1
    else
      datetime2
    end
  end

  def datetime_min(nil, datetime2), do: datetime2
  def datetime_min(datetime1, nil), do: datetime1

  def datetime_min(datetime1, datetime2) do
    if DateTime.compare(datetime1, datetime2) == :lt do
      datetime1
    else
      datetime2
    end
  end

  def parse_datetime(nil), do: nil

  def parse_datetime(datetime_str) do
    case DateTime.from_iso8601(datetime_str) do
      {:ok, datetime, _} -> datetime
      _ -> nil
    end
  end
end
