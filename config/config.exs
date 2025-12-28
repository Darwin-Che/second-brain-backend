# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :second_brain,
  ecto_repos: [SecondBrain.Repo],
  generators: [timestamp_type: :utc_datetime]

config :second_brain, SecondBrain.Repo,
  migration_primary_key: [name: :id, type: :binary_id],
  migration_foreign_key: [type: :binary_id]

# Ueberauth

config :ueberauth, Ueberauth,
  providers: [
    google:
      {Ueberauth.Strategy.Google,
       [
         default_scope: "email profile"
       ]}
  ]

# Guardian

config :second_brain, SecondBrain.Auth.Guardian,
  issuer: "second_brain",
  secret_key: "LpY6d4fbtN0IPlW2LIIaScBfogi6zC5Gg28VXdd0HYG43bBj1V6WcIP2OS9S-9__"

# Configure the endpoint
config :second_brain, SecondBrainWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: SecondBrainWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SecondBrain.PubSub,
  live_view: [signing_salt: "aZdZjZsg"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :account_id, :object_path]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
