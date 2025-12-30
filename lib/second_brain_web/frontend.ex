defmodule SecondBrainWeb.Frontend do
  @moduledoc false

  def url do
    Application.get_env(:second_brain, SecondBrainWeb.Frontend)[:url]
  end

  def cors_plug_config do
    [url()]
  end
end
