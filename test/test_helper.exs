ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(SecondBrain.Repo, :manual)

ExUnit.after_suite(fn _ ->
  SecondBrain.TestSupport.S3Cleanup.cleanup_bucket!()
end)
