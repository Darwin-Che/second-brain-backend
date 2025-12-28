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
end
