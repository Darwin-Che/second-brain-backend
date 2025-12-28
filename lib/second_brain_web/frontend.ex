defmodule SecondBrainWeb.Frontend do
  @moduledoc false

  def url do
    Application.get_env(:second_brain, SecondBrainWeb.Frontend)[:url]
  end
end
