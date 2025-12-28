import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :second_brain, SecondBrain.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "second_brain_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :second_brain, SecondBrainWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "8roFbLZMihYz1amwhzLTTvjPp8wJIXVB8il2pZQks0uHcHet5055aYq0paG/t4B1",
  server: false

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :ex_aws,
  access_key_id: "minio",
  secret_access_key: "minio123",
  region: "us-east-1",
  s3: [
    scheme: "http://",
    host: "localhost",
    port: 9000
  ]

config :second_brain, SecondBrain.BrainDiskS3,
  bucket_name: "second-brain-test",
  max_sessions_per_file: 2
