defmodule SecondBrain.Repo do
  use Ecto.Repo,
    otp_app: :second_brain,
    adapter: Ecto.Adapters.Postgres
end
